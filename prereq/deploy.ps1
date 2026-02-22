# Script de Deployment - Workshop Agent365
# Este script provisiona toda a infraestrutura necessaria no Azure

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$DeploymentName = "main",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "main.bicepparam",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Banner
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT WORKSHOP AGENT365" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verificar se Azure CLI esta instalado
Write-Host "[1/9] Verificando Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    if ($azVersion) {
        Write-Host "  [OK] Azure CLI versao $($azVersion.'azure-cli') encontrado" -ForegroundColor Green
    } else {
        Write-Host "  [X] Azure CLI nao encontrado" -ForegroundColor Red
        Write-Host "`nInstale o Azure CLI: https://aka.ms/InstallAzureCLI`n" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  [X] Erro ao verificar Azure CLI" -ForegroundColor Red
    Write-Host "`nInstale o Azure CLI: https://aka.ms/InstallAzureCLI`n" -ForegroundColor Yellow
    exit 1
}

# Verificar se esta logado no Azure
Write-Host "`n[2/9] Verificando autenticacao no Azure..." -ForegroundColor Yellow
try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
    if ($account) {
        Write-Host "  [OK] Autenticado como: $($account.user.name)" -ForegroundColor Green
        Write-Host "  -> Subscription ativa: $($account.name) ($($account.id))" -ForegroundColor Cyan
        
        # Se subscription ID foi fornecida, trocar para ela
        if ($SubscriptionId -and $account.id -ne $SubscriptionId) {
            Write-Host "  -> Trocando para subscription: $SubscriptionId" -ForegroundColor Cyan
            az account set --subscription $SubscriptionId
            $account = az account show --output json | ConvertFrom-Json
            Write-Host "  [OK] Subscription alterada para: $($account.name)" -ForegroundColor Green
        } elseif (-not $SubscriptionId) {
            $SubscriptionId = $account.id
        }
    } else {
        Write-Host "  [X] Nao autenticado no Azure" -ForegroundColor Red
        Write-Host "`nExecute: az login`n" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  [X] Erro ao verificar autenticacao" -ForegroundColor Red
    Write-Host "`nExecute: az login`n" -ForegroundColor Yellow
    exit 1
}

# Verificar extensoes necessarias do Azure CLI
Write-Host "`n[3/9] Verificando extensoes do Azure CLI..." -ForegroundColor Yellow
$requiredExtensions = @('containerapp', 'ml', 'application-insights')

foreach ($ext in $requiredExtensions) {
    $extensionList = az extension list --output json 2>$null
    if ($extensionList) {
        $installed = $extensionList | ConvertFrom-Json | Where-Object { $_.name -eq $ext }
    } else {
        $installed = $null
    }
    
    if ($installed) {
        Write-Host "  [OK] Extensao '$ext' instalada" -ForegroundColor Green
    } else {
        Write-Host "  [!] Extensao '$ext' nao encontrada. Instalando..." -ForegroundColor Yellow
        az extension add --name $ext --only-show-errors 2>$null
        Write-Host "  [OK] Extensao '$ext' instalada" -ForegroundColor Green
    }
}

# Instalar modulos PowerShell do Microsoft Graph (necessarios para Lessons 5-6: A365)
Write-Host "`n[4/9] Verificando modulos PowerShell do Microsoft Graph..." -ForegroundColor Yellow
$requiredModules = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.Applications')

foreach ($mod in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $mod 2>$null | Select-Object -First 1
    if ($installed) {
        Write-Host "  [OK] Modulo '$mod' v$($installed.Version) instalado" -ForegroundColor Green
    } else {
        Write-Host "  [!] Modulo '$mod' nao encontrado. Instalando..." -ForegroundColor Yellow
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber -Repository PSGallery 2>$null
        if ($?) {
            Write-Host "  [OK] Modulo '$mod' instalado" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Falha ao instalar '$mod'. Instale manualmente: Install-Module $mod -Scope CurrentUser" -ForegroundColor Yellow
        }
    }
}

# Ler ResourceGroupName do arquivo de parametros, se nao foi informado
if (-not $ResourceGroupName -and $ParametersFile -and (Test-Path $ParametersFile)) {
    $rgMatch = Select-String -Path $ParametersFile -Pattern "param\s+resourceGroupName\s*=\s*'([^']+)'" | Select-Object -First 1
    if ($rgMatch) {
        $ResourceGroupName = $rgMatch.Matches[0].Groups[1].Value
        Write-Host "  [i] ResourceGroupName lido do arquivo de parametros: $ResourceGroupName" -ForegroundColor Cyan
    }
}
if (-not $ResourceGroupName) {
    $ResourceGroupName = "rg-agent365-workshop"
    Write-Host "  [i] Usando ResourceGroupName padrao: $ResourceGroupName" -ForegroundColor Cyan
}

# Verificar se o arquivo de parametros existe
Write-Host "`n[5/9] Verificando arquivos de deployment..." -ForegroundColor Yellow
$templateFile = "main.bicep"

if (-not (Test-Path $templateFile)) {
    Write-Host "  [X] Arquivo $templateFile nao encontrado" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Template encontrado: $templateFile" -ForegroundColor Green

if (-not (Test-Path $ParametersFile)) {
    Write-Host "  [!] Arquivo de parametros $ParametersFile nao encontrado" -ForegroundColor Yellow
    Write-Host "  -> Deployment sera feito sem arquivo de parametros" -ForegroundColor Cyan
    $useParamsFile = $false
} else {
    Write-Host "  [OK] Parametros encontrados: $ParametersFile" -ForegroundColor Green
    $useParamsFile = $true
}

# Criar ou verificar Resource Group
Write-Host "`n[6/9] Verificando Resource Group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "true") {
    Write-Host "  [OK] Resource Group '$ResourceGroupName' ja existe" -ForegroundColor Green
} else {
    Write-Host "  -> Criando Resource Group '$ResourceGroupName' em $Location..." -ForegroundColor Cyan
    az group create --name $ResourceGroupName --location $Location --output none
    Write-Host "  [OK] Resource Group criado" -ForegroundColor Green
}

# Validar template Bicep
Write-Host "`n[7/9] Validando template Bicep..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
try {
    if ($useParamsFile) {
        az deployment group validate `
            --resource-group $ResourceGroupName `
            --template-file $templateFile `
            --parameters $ParametersFile `
            --output json 2>$null | Out-Null
    } else {
        az deployment group validate `
            --resource-group $ResourceGroupName `
            --template-file $templateFile `
            --output json 2>$null | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Template Bicep validado com sucesso" -ForegroundColor Green
    } else {
        Write-Host "  [X] Erro na validacao do template (exit code: $LASTEXITCODE)" -ForegroundColor Red
        # Re-run to show the error output
        if ($useParamsFile) {
            az deployment group validate `
                --resource-group $ResourceGroupName `
                --template-file $templateFile `
                --parameters $ParametersFile `
                --output json
        } else {
            az deployment group validate `
                --resource-group $ResourceGroupName `
                --template-file $templateFile `
                --output json
        }
        exit 1
    }
} catch {
    Write-Host "  [X] Erro ao validar template: $_" -ForegroundColor Red
    exit 1
}
$ErrorActionPreference = "Stop"

# Executar deployment
Write-Host "`n[8/9] Iniciando deployment..." -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "  -> Modo WhatIf ativado - simulando deployment..." -ForegroundColor Cyan
    try {
        if ($useParamsFile) {
            az deployment group what-if `
                --resource-group $ResourceGroupName `
                --template-file $templateFile `
                --parameters $ParametersFile `
                --name $DeploymentName
        } else {
            az deployment group what-if `
                --resource-group $ResourceGroupName `
                --template-file $templateFile `
                --name $DeploymentName
        }
        Write-Host "`n  [i] Deployment simulado. Use sem o parametro -WhatIf para executar." -ForegroundColor Cyan
        exit 0
    } catch {
        Write-Host "  [X] Erro na simulacao: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  -> Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "  -> Location: $Location" -ForegroundColor Cyan
Write-Host "  -> Deployment Name: $DeploymentName" -ForegroundColor Cyan
Write-Host "`n  [!] Aguarde... Este processo pode levar 10-15 minutos.`n" -ForegroundColor Yellow

$startTime = Get-Date

try {
    if ($useParamsFile) {
        az deployment group create `
            --resource-group $ResourceGroupName `
            --template-file $templateFile `
            --parameters $ParametersFile `
            --name $DeploymentName `
            --verbose
    } else {
        az deployment group create `
            --resource-group $ResourceGroupName `
            --template-file $templateFile `
            --name $DeploymentName `
            --verbose
    }
    
    if ($LASTEXITCODE -eq 0) {
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host "`n  [OK] Deployment concluido com sucesso!" -ForegroundColor Green
        Write-Host "  -> Tempo decorrido: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan
    } else {
        Write-Host "`n  [X] Deployment falhou" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "`n  [X] Erro durante o deployment: $_" -ForegroundColor Red
    exit 1
}

# Obter outputs do deployment
Write-Host "`n[9/9] Obtendo outputs do deployment..." -ForegroundColor Yellow
try {
    $deployment = az deployment group show `
        --resource-group $ResourceGroupName `
        --name $DeploymentName `
        --output json | ConvertFrom-Json
    
    if ($deployment.properties.outputs) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "         DEPLOYMENT OUTPUTS" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        $outputs = $deployment.properties.outputs
        
        foreach ($key in $outputs.PSObject.Properties.Name | Sort-Object) {
            $value = $outputs.$key.value
            Write-Host "$key`:" -ForegroundColor Yellow -NoNewline
            Write-Host " $value" -ForegroundColor White
        }
        
        # Salvar outputs em arquivo
        $outputsPath = "deployment-outputs-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $outputs | ConvertTo-Json -Depth 10 | Out-File $outputsPath
        Write-Host "`nOutputs salvos em: $outputsPath" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  [!] Nao foi possivel obter outputs: $_" -ForegroundColor Yellow
}

# Executar validacao
if (-not $SkipValidation) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "         VALIDANDO DEPLOYMENT" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    if (Test-Path ".\validate-deployment.ps1") {
        Write-Host "Executando script de validacao...`n" -ForegroundColor Cyan
        & ".\validate-deployment.ps1" -ResourceGroupName $ResourceGroupName -DeploymentName $DeploymentName
    } else {
        Write-Host "  [!] Script de validacao nao encontrado" -ForegroundColor Yellow
        Write-Host "  -> Execute manualmente: .\validate-deployment.ps1 -ResourceGroupName $ResourceGroupName`n" -ForegroundColor Cyan
    }
} else {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Validacao ignorada (parametro -SkipValidation usado)" -ForegroundColor Yellow
    Write-Host "Execute manualmente: .\validate-deployment.ps1 -ResourceGroupName $ResourceGroupName" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# Resumo final
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   DEPLOYMENT CONCLUIDO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "1. Revise os outputs do deployment acima" -ForegroundColor White
Write-Host "2. Implemente os agentes (lesson-1/langgraph-agent e lesson-1/agent-framework-agent)" -ForegroundColor White
Write-Host "3. Faca o build e deploy das imagens Docker" -ForegroundColor White
Write-Host "4. Teste os agentes usando os endpoints fornecidos`n" -ForegroundColor White
