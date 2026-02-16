# Script de Validacao de Deployment - Workshop Agent365 
# Este script valida se todos os recursos foram criados corretamente 

param(
	[Parameter(Mandatory=$true)]
	[string]$ResourceGroupName,
    
	[Parameter(Mandatory=$false)]
	[string]$DeploymentName = "main"
)

$ErrorActionPreference = "Continue"
$validationResults = @()
$ValidationTimeoutSeconds = 30
$RetryWaitSeconds = 30
$MaxRetries = 2

function Invoke-AzWithTimeout {
	param(
		[string]$AzArguments,
		[int]$TimeoutSeconds = $ValidationTimeoutSeconds
	)

	for ($attempt = 1; $attempt -le ($MaxRetries + 1); $attempt++) {
		try {
			$psi = New-Object System.Diagnostics.ProcessStartInfo
			$psi.FileName = "cmd.exe"
			$psi.Arguments = "/c az $AzArguments"
			$psi.UseShellExecute = $false
			$psi.RedirectStandardOutput = $true
			$psi.RedirectStandardError = $true
			$psi.CreateNoWindow = $true
			$proc = [System.Diagnostics.Process]::Start($psi)
			$stdout = $proc.StandardOutput.ReadToEndAsync()
			$stderr = $proc.StandardError.ReadToEndAsync()
			$finished = $proc.WaitForExit($TimeoutSeconds * 1000)
			if (-not $finished) {
				$proc.Kill()
				$proc.Dispose()
				if ($attempt -le $MaxRetries) {
					Write-Host "    Timeout na tentativa $attempt/$($MaxRetries + 1). Aguardando ${RetryWaitSeconds}s antes de tentar novamente..." -ForegroundColor DarkYellow
					Start-Sleep -Seconds $RetryWaitSeconds
					continue
				}
				return $null
			}
			[System.Threading.Tasks.Task]::WaitAll($stdout, $stderr)
			$content = $stdout.Result
			$exitCode = $proc.ExitCode
			$proc.Dispose()
			if ($exitCode -eq 0 -and $content) {
				return ($content | ConvertFrom-Json)
			}
			return $null
		} catch {
			if ($attempt -le $MaxRetries) {
				Write-Host "    Erro na tentativa $attempt/$($MaxRetries + 1). Aguardando ${RetryWaitSeconds}s antes de tentar novamente..." -ForegroundColor DarkYellow
				Start-Sleep -Seconds $RetryWaitSeconds
				continue
			}
			return $null
		}
	}
	return $null
}

function Add-ValidationResult {
	param(
		[string]$Resource,
		[string]$Check,
		[bool]$Passed,
		[string]$Message,
		[string]$Value = ""
	)
    
	$script:validationResults += [PSCustomObject]@{
		Resource = $Resource
		Check = $Check
		Passed = $Passed
		Message = $Message
		Value = $Value
	}
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   VALIDACAO DE DEPLOYMENT - AGENT365" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Deployment: $DeploymentName`n" -ForegroundColor White

# Verificar se o Resource Group existe
Write-Host "[1/8] Verificando Resource Group..." -ForegroundColor Yellow
try {
	$rg = az group show --name $ResourceGroupName --output json 2>$null | ConvertFrom-Json
	if ($rg) {
		Add-ValidationResult -Resource "Resource Group" -Check "Existencia" -Passed $true -Message "Resource group encontrado" -Value $rg.location
		Write-Host "  [OK] Resource Group encontrado em: $($rg.location)" -ForegroundColor Green
	} else {
		Add-ValidationResult -Resource "Resource Group" -Check "Existencia" -Passed $false -Message "Resource group nao encontrado"
		Write-Host "  [X] Resource Group nao encontrado" -ForegroundColor Red
		exit 1
	}
} catch {
	Add-ValidationResult -Resource "Resource Group" -Check "Existencia" -Passed $false -Message "Erro ao verificar resource group: $_"
	Write-Host "  [X] Erro ao verificar Resource Group" -ForegroundColor Red
	exit 1
}

# Obter outputs do deployment
Write-Host "`n[2/8] Obtendo outputs do deployment..." -ForegroundColor Yellow
try {
	$deployment = az deployment group show --resource-group $ResourceGroupName --name $DeploymentName --output json 2>$null | ConvertFrom-Json
	if ($deployment -and $deployment.properties.provisioningState -eq "Succeeded") {
		Write-Host "  [OK] Deployment concluido com sucesso" -ForegroundColor Green
		Add-ValidationResult -Resource "Deployment" -Check "Status" -Passed $true -Message "Deployment bem-sucedido"
        
		$outputs = $deployment.properties.outputs
	} else {
		Write-Host "  [X] Deployment nao foi bem-sucedido" -ForegroundColor Red
		Add-ValidationResult -Resource "Deployment" -Check "Status" -Passed $false -Message "Deployment falhou ou nao concluido"
	}
} catch {
	Write-Host "  [!] Nao foi possivel obter outputs do deployment" -ForegroundColor Yellow
	Add-ValidationResult -Resource "Deployment" -Check "Outputs" -Passed $false -Message "Erro ao obter outputs: $_"
}

# Validar Azure Container Registry
Write-Host "`n[3/8] Validando Azure Container Registry..." -ForegroundColor Yellow
try {
	$acrName = $outputs.acrName.value
	$rgName = $ResourceGroupName
	$acr = Invoke-AzWithTimeout -AzArguments "acr show --name $acrName --resource-group $rgName --output json"

	if ($null -eq $acr) {
		Write-Host "  [!] Timeout ao validar ACR" -ForegroundColor Yellow
		Add-ValidationResult -Resource "Container Registry" -Check "Status" -Passed $false -Message "Timeout - nao foi possivel confirmar"
	} elseif ($acr -and $acr.provisioningState -eq "Succeeded") {
		Write-Host "  [OK] ACR ativo: $($acr.loginServer)" -ForegroundColor Green
		Add-ValidationResult -Resource "Container Registry" -Check "Status" -Passed $true -Message "ACR ativo" -Value $acr.loginServer

		if ($acr.adminUserEnabled) {
			Write-Host "  [OK] Admin user habilitado" -ForegroundColor Green
			Add-ValidationResult -Resource "Container Registry" -Check "Admin User" -Passed $true -Message "Admin habilitado"
		} else {
			Write-Host "  [!] Admin user nao habilitado" -ForegroundColor Yellow
			Add-ValidationResult -Resource "Container Registry" -Check "Admin User" -Passed $false -Message "Admin nao habilitado"
		}
	} else {
		Write-Host "  [X] ACR nao esta ativo" -ForegroundColor Red
		Add-ValidationResult -Resource "Container Registry" -Check "Status" -Passed $false -Message "ACR nao ativo"
	}
} catch {
	Write-Host "  [X] Erro ao validar ACR: $_" -ForegroundColor Red
	Add-ValidationResult -Resource "Container Registry" -Check "Validacao" -Passed $false -Message "Erro: $_"
}

# Validar Log Analytics Workspace
Write-Host "`n[4/8] Validando Log Analytics Workspace..." -ForegroundColor Yellow
try {
	$rgName = $ResourceGroupName
	$logWorkspacesRaw = Invoke-AzWithTimeout -AzArguments "monitor log-analytics workspace list --resource-group $rgName --output json"
	$logWorkspaces = @($logWorkspacesRaw)

	if ($null -eq $logWorkspacesRaw) {
		Write-Host "  [!] Timeout ao validar Log Analytics" -ForegroundColor Yellow
		Add-ValidationResult -Resource "Log Analytics" -Check "Existencia" -Passed $false -Message "Timeout - nao foi possivel confirmar"
	} elseif ($logWorkspaces.Count -gt 0) {
		$logWorkspace = $logWorkspaces[0]
		Write-Host "  [OK] Log Analytics Workspace encontrado: $($logWorkspace.name)" -ForegroundColor Green
		Add-ValidationResult -Resource "Log Analytics" -Check "Existencia" -Passed $true -Message "Workspace ativo" -Value $logWorkspace.customerId
	} else {
		Write-Host "  [X] Log Analytics Workspace nao encontrado" -ForegroundColor Red
		Add-ValidationResult -Resource "Log Analytics" -Check "Existencia" -Passed $false -Message "Workspace nao encontrado"
	}
} catch {
	Write-Host "  [X] Erro ao validar Log Analytics: $_" -ForegroundColor Red
	Add-ValidationResult -Resource "Log Analytics" -Check "Validacao" -Passed $false -Message "Erro: $_"
}

# Validar Application Insights
Write-Host "`n[5/8] Validando Application Insights..." -ForegroundColor Yellow
try {
	$rgName = $ResourceGroupName
	$appInsightsRaw = Invoke-AzWithTimeout -AzArguments "monitor app-insights component show --resource-group $rgName --output json"

	if ($null -eq $appInsightsRaw) {
		Write-Host "  [!] Timeout ao validar Application Insights" -ForegroundColor Yellow
		Add-ValidationResult -Resource "Application Insights" -Check "Existencia" -Passed $false -Message "Timeout - nao foi possivel confirmar"
	} else {
		# Response can be a single object or an array — normalize
		if ($appInsightsRaw -is [System.Collections.IEnumerable] -and $appInsightsRaw -isnot [string]) {
			$appInsights = $appInsightsRaw | Select-Object -First 1
		} else {
			$appInsights = $appInsightsRaw
		}
		if ($appInsights -and $appInsights.name) {
		Write-Host "  [OK] Application Insights encontrado: $($appInsights.name)" -ForegroundColor Green
		$instrKey = if ($appInsights.instrumentationKey) { $appInsights.instrumentationKey.Substring(0,8)+"..." } else { "N/A" }
		Add-ValidationResult -Resource "Application Insights" -Check "Existencia" -Passed $true -Message "App Insights ativo" -Value $instrKey
	} else {
		Write-Host "  [X] Application Insights nao encontrado" -ForegroundColor Red
		Add-ValidationResult -Resource "Application Insights" -Check "Existencia" -Passed $false -Message "App Insights nao encontrado"
	}
} catch {
	Write-Host "  [X] Erro ao validar Application Insights: $_" -ForegroundColor Red
	Add-ValidationResult -Resource "Application Insights" -Check "Validacao" -Passed $false -Message "Erro: $_"
}

# Validar Container Apps Environment
Write-Host "`n[6/8] Validando Container Apps Environment..." -ForegroundColor Yellow
try {
	$rgName = $ResourceGroupName
	$caEnvsRaw = Invoke-AzWithTimeout -AzArguments "containerapp env list --resource-group $rgName --output json"
	$caEnvs = @($caEnvsRaw)

	if ($null -eq $caEnvsRaw) {
		Write-Host "  [!] Timeout ao validar Container Apps Environment" -ForegroundColor Yellow
		Add-ValidationResult -Resource "Container Apps Env" -Check "Status" -Passed $false -Message "Timeout - nao foi possivel confirmar"
	} elseif ($caEnvs.Count -gt 0) {
		$caEnv = $caEnvs[0]
		if ($caEnv.properties.provisioningState -eq "Succeeded") {
			Write-Host "  [OK] Container Apps Environment ativo: $($caEnv.name)" -ForegroundColor Green
			Add-ValidationResult -Resource "Container Apps Env" -Check "Status" -Passed $true -Message "Environment ativo"
		} else {
			Write-Host "  [!] Container Apps Environment em provisionamento" -ForegroundColor Yellow
			Add-ValidationResult -Resource "Container Apps Env" -Check "Status" -Passed $false -Message "Ainda em provisionamento"
		}
	} else {
		Write-Host "  [X] Container Apps Environment nao encontrado" -ForegroundColor Red
		Add-ValidationResult -Resource "Container Apps Env" -Check "Existencia" -Passed $false -Message "Environment nao encontrado"
	}
} catch {
	Write-Host "  [X] Erro ao validar Container Apps Environment: $_" -ForegroundColor Red
	Add-ValidationResult -Resource "Container Apps Env" -Check "Validacao" -Passed $false -Message "Erro: $_"
}

# Validar Microsoft Foundry account (AI Foundry)
Write-Host "`n[7/8] Validando Microsoft Foundry account..." -ForegroundColor Yellow
try {
	$aiFoundryName = $outputs.aiFoundryName.value
	$expectedDeployment = $outputs.aiModelDeployment.value
	$rgName = $ResourceGroupName
	$aiFoundry = Invoke-AzWithTimeout -AzArguments "cognitiveservices account show --name $aiFoundryName --resource-group $rgName --output json"

	if ($null -eq $aiFoundry) {
		Write-Host "  [!] Timeout ao validar Microsoft Foundry account" -ForegroundColor Yellow
		Add-ValidationResult -Resource "Microsoft Foundry" -Check "Status" -Passed $false -Message "Timeout - nao foi possivel confirmar"
	} elseif ($aiFoundry -and $aiFoundry.properties.provisioningState -eq "Succeeded") {
		Write-Host "  [OK] Microsoft Foundry account ativo: $($aiFoundry.name)" -ForegroundColor Green
		Add-ValidationResult -Resource "Microsoft Foundry" -Check "Status" -Passed $true -Message "Foundry account ativo" -Value $aiFoundry.properties.endpoint

		# Verificar deployment do modelo
		$deployments = Invoke-AzWithTimeout -AzArguments "cognitiveservices account deployment list --name $aiFoundryName --resource-group $rgName --output json"
		if ($null -eq $deployments) {
			Write-Host "  [!] Timeout ao verificar deployments do modelo" -ForegroundColor Yellow
			Add-ValidationResult -Resource "Model Deployment" -Check "Existencia" -Passed $false -Message "Timeout - nao foi possivel confirmar"
		} else {
			$modelDeploy = $deployments | Where-Object { $_.name -eq $expectedDeployment }
			if ($modelDeploy) {
				Write-Host "  [OK] Deployment '$expectedDeployment' encontrado" -ForegroundColor Green
				Add-ValidationResult -Resource "Model Deployment" -Check "Existencia" -Passed $true -Message "Deployment configurado" -Value $expectedDeployment
			} else {
				Write-Host "  [X] Deployment '$expectedDeployment' nao encontrado" -ForegroundColor Red
				Add-ValidationResult -Resource "Model Deployment" -Check "Existencia" -Passed $false -Message "Deployment '$expectedDeployment' nao encontrado"
			}
		}
	} else {
		Write-Host "  [X] Microsoft Foundry account nao esta ativo ou nao encontrado" -ForegroundColor Red
		Add-ValidationResult -Resource "Microsoft Foundry" -Check "Status" -Passed $false -Message "Foundry account nao ativo"
	}
} catch {
	Write-Host "  [X] Erro ao validar Microsoft Foundry account: $_" -ForegroundColor Red
	Add-ValidationResult -Resource "Microsoft Foundry" -Check "Validacao" -Passed $false -Message "Erro: $_"
}

# Validar Microsoft Foundry project
Write-Host "`n[8/8] Validando Microsoft Foundry project..." -ForegroundColor Yellow
try {
	$aiProjectName = $outputs.aiProjectName.value
	$foundryName = $aiFoundryName
	$rgName = $ResourceGroupName
	$projectResId = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rgName/providers/Microsoft.CognitiveServices/accounts/$foundryName/projects/$aiProjectName"
	$aiProject = Invoke-AzWithTimeout -AzArguments "resource show --ids $projectResId --api-version 2025-06-01 --output json" -TimeoutSeconds 45

	if ($null -eq $aiProject) {
		Write-Host "  [!] Timeout ao validar Microsoft Foundry project" -ForegroundColor Yellow
		Add-ValidationResult -Resource "Microsoft Foundry Project" -Check "Status" -Passed $false -Message "Timeout - nao foi possivel confirmar"
	} elseif ($aiProject) {
		Write-Host "  [OK] Microsoft Foundry project ativo: $aiProjectName" -ForegroundColor Green
		Add-ValidationResult -Resource "Microsoft Foundry Project" -Check "Status" -Passed $true -Message "Project ativo" -Value $aiProjectName
	} else {
		Write-Host "  [X] Microsoft Foundry project nao encontrado" -ForegroundColor Red
		Add-ValidationResult -Resource "Microsoft Foundry Project" -Check "Status" -Passed $false -Message "Project nao encontrado"
	}
} catch {
	Write-Host "  [X] Erro ao validar Microsoft Foundry project: $_" -ForegroundColor Red
	Add-ValidationResult -Resource "Microsoft Foundry Project" -Check "Validacao" -Passed $false -Message "Erro: $_"
}

# Relatorio final
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "         RELATORIO DE VALIDACAO" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passedChecks = ($validationResults | Where-Object { $_.Passed -eq $true }).Count
$totalChecks = $validationResults.Count
if ($totalChecks -gt 0) {
	$successRate = [math]::Round(($passedChecks / $totalChecks) * 100, 2)
} else {
	$successRate = 0
}

Write-Host "Total de verificacoes: $totalChecks" -ForegroundColor White
Write-Host "Verificacoes aprovadas: $passedChecks" -ForegroundColor Green
Write-Host "Verificacoes reprovadas: $($totalChecks - $passedChecks)" -ForegroundColor Red
Write-Host "Taxa de sucesso: $successRate%`n" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Tabela de resultados
$validationResults | Format-Table -Property Resource, Check, Passed, Message -AutoSize

# Salvar relatorio em JSON
$reportPath = "validation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$validationResults | ConvertTo-Json -Depth 10 | Out-File $reportPath
Write-Host "`nRelatorio salvo em: $reportPath" -ForegroundColor Cyan

# Outputs importantes
if ($outputs) {
	Write-Host "`n========================================" -ForegroundColor Cyan
	Write-Host "         INFORMACOES IMPORTANTES" -ForegroundColor Cyan
	Write-Host "========================================`n" -ForegroundColor Cyan
    
	Write-Host "AI Services Endpoint (OpenAI-compatible):" -ForegroundColor Yellow
	Write-Host "  $($outputs.openAIEndpoint.value)`n" -ForegroundColor White
    
	Write-Host "ACR Login Server:" -ForegroundColor Yellow
	Write-Host "  $($outputs.acrLoginServer.value)`n" -ForegroundColor White
    
	if ($outputs.langgraphAgentUrl) {
		Write-Host "LangGraph Agent URL:" -ForegroundColor Yellow
		Write-Host "  https://$($outputs.langgraphAgentUrl.value)`n" -ForegroundColor White
	}
    
	Write-Host "Microsoft Foundry Name:" -ForegroundColor Yellow
	Write-Host "  $($outputs.aiFoundryName.value)`n" -ForegroundColor White

	if ($outputs.aiFoundryEndpoint) {
		Write-Host "Microsoft Foundry Endpoint:" -ForegroundColor Yellow
		Write-Host "  $($outputs.aiFoundryEndpoint.value)`n" -ForegroundColor White
	}
    
	Write-Host "Microsoft Foundry Project Name:" -ForegroundColor Yellow
	Write-Host "  $($outputs.aiProjectName.value)`n" -ForegroundColor White

	if ($outputs.aiProjectEndpoint) {
		Write-Host "Microsoft Foundry Project Endpoint:" -ForegroundColor Yellow
		Write-Host "  $($outputs.aiProjectEndpoint.value)`n" -ForegroundColor White
	}
}

# Status final
if ($successRate -ge 90) {
	Write-Host "`n[OK] VALIDACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
	Write-Host "Todos os recursos principais foram provisionados corretamente.`n" -ForegroundColor Green
	exit 0
} elseif ($successRate -ge 70) {
	Write-Host "`n[!] VALIDACAO CONCLUIDA COM AVISOS" -ForegroundColor Yellow
	Write-Host "A maioria dos recursos foi provisionada, mas alguns itens precisam de atencao.`n" -ForegroundColor Yellow
	exit 0
} else {
	Write-Host "`n[X] VALIDACAO FALHOU" -ForegroundColor Red
	Write-Host "Varios recursos nao foram provisionados corretamente. Revise os erros acima.`n" -ForegroundColor Red
	exit 1
}
