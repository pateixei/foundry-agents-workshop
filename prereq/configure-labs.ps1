# configure-labs.ps1 - Configura endpoints em cada labs/solution apos deploy dos recursos
#
# Este script le os outputs do deployment Bicep (prereq/) e atualiza
# automaticamente os arquivos de configuracao (.env, deploy.ps1, aca.bicep)
# e os defaults nos arquivos Python em cada pasta labs/solution/
# com os endpoints corretos.
#
# Uso:
#   pwsh ./configure-labs.ps1
#   pwsh ./configure-labs.ps1 -ResourceGroupName "meu-rg" -DeploymentName "main"
#
# Pre-requisitos:
#   - Infraestrutura do prereq/ ja deployada (main.bicep)
#   - az login realizado

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$false)]
    [string]$DeploymentName = "main",

    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "main.bicepparam"
)

$ErrorActionPreference = "Stop"

# ─── Banner ──────────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   CONFIGURE LABS - AGENT365 WORKSHOP"   -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ─── Resolve script root and workspace root ──────────────────
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }
# prereq/ is where this script lives; workspace root is one level up
$WorkspaceRoot = Split-Path $ScriptDir -Parent

Write-Host "Workspace: $WorkspaceRoot" -ForegroundColor White
Write-Host ""

# ─── Read ResourceGroupName from parameters file if not provided ──
$ParamsPath = Join-Path $ScriptDir $ParametersFile
if (-not $ResourceGroupName -and (Test-Path $ParamsPath)) {
    $rgMatch = Select-String -Path $ParamsPath -Pattern "param\s+resourceGroupName\s*=\s*'([^']+)'" | Select-Object -First 1
    if ($rgMatch) {
        $ResourceGroupName = $rgMatch.Matches.Groups[1].Value
        Write-Host "  [i] Resource Group from parameters file: $ResourceGroupName" -ForegroundColor Cyan
    }
}

if (-not $ResourceGroupName) {
    Write-Host "  [X] ResourceGroupName is required. Use -ResourceGroupName or set it in $ParametersFile" -ForegroundColor Red
    exit 1
}

# ─── [1/3] Get deployment outputs ───────────────────────────
Write-Host "[1/4] Reading deployment outputs..." -ForegroundColor Yellow

$outputsJson = az deployment group show `
    --resource-group $ResourceGroupName `
    --name $DeploymentName `
    --query "properties.outputs" `
    -o json 2>$null

if ($LASTEXITCODE -ne 0 -or -not $outputsJson) {
    Write-Host "  [X] Could not read deployment outputs. Is the deployment '$DeploymentName' in RG '$ResourceGroupName' complete?" -ForegroundColor Red
    exit 1
}

$outputs = $outputsJson | ConvertFrom-Json

# Extract values
$acrName              = $outputs.acrName.value
$acrLoginServer       = $outputs.acrLoginServer.value
$aiFoundryName        = $outputs.aiFoundryName.value
$aiFoundryEndpoint    = $outputs.aiFoundryEndpoint.value
$aiProjectName        = $outputs.aiProjectName.value
$aiProjectEndpoint    = $outputs.aiProjectEndpoint.value
$aiModelDeployment    = $outputs.aiModelDeployment.value
$containerAppsEnvName = $outputs.containerAppsEnvName.value
$appInsightsKey       = $outputs.appInsightsInstrumentationKey.value

# Derived
$openaiEndpoint = "https://$aiFoundryName.openai.azure.com/"

# Get App Insights connection string (not in Bicep outputs, query directly)
$appInsightsConnStr = ""
try {
    $appInsightsConnStr = az monitor app-insights component show `
        --resource-group $ResourceGroupName `
        --query "[0].connectionString" -o tsv 2>$null
} catch { }

Write-Host "  ACR:             $acrLoginServer"
Write-Host "  Foundry:         $aiFoundryName"
Write-Host "  Project:         $aiProjectName"
Write-Host "  Project Endpoint:$aiProjectEndpoint"
Write-Host "  OpenAI Endpoint: $openaiEndpoint"
Write-Host "  Model:           $aiModelDeployment"
Write-Host "  ACA Env:         $containerAppsEnvName"
Write-Host "  AppInsights:     $(if ($appInsightsConnStr) { $appInsightsConnStr.Substring(0,40) + '...' } else { 'N/A' })"
Write-Host ""

# ─── Helper function ─────────────────────────────────────────
function Update-FileContent {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Replacement,
        [string]$Description
    )
    if (-not (Test-Path $FilePath)) { return $false }
    $content = Get-Content $FilePath -Raw
    if ($content -match [regex]::Escape($Pattern)) {
        # Exact match not found as-is, try regex
    }
    $newContent = $content -replace $Pattern, $Replacement
    if ($newContent -ne $content) {
        Set-Content -Path $FilePath -Value $newContent -NoNewline
        Write-Host "    [OK] $Description" -ForegroundColor Green
        return $true
    }
    return $false
}

# ─── [2/3] Configure lab solutions ──────────────────────────
Write-Host "[2/4] Configuring lab solutions..." -ForegroundColor Yellow

$updatedFiles = 0

# --- Lesson 1: .env file ---
Write-Host "`n  Lesson 1 - Declarative Agent" -ForegroundColor White
$lesson1Dir = Join-Path $WorkspaceRoot "lesson-1-declarative" "labs" "solution"
if (Test-Path $lesson1Dir) {
    $envFile = Join-Path $lesson1Dir ".env"
    $envContent = @"
PROJECT_ENDPOINT=$aiProjectEndpoint
MODEL_DEPLOYMENT_NAME=$aiModelDeployment
"@
    Set-Content -Path $envFile -Value $envContent -NoNewline
    Write-Host "    [OK] .env updated with project endpoint and model" -ForegroundColor Green
    $updatedFiles++

    # Also update .env.example
    $envExFile = Join-Path $lesson1Dir ".env.example"
    if (Test-Path $envExFile) {
        Set-Content -Path $envExFile -Value $envContent -NoNewline
        Write-Host "    [OK] .env.example updated" -ForegroundColor Green
        $updatedFiles++
    }

    # Update Python files - DEFAULT_ENDPOINT placeholder
    foreach ($pyFile in @("create_agent.py", "test_agent.py")) {
        $pyPath = Join-Path $lesson1Dir $pyFile
        if (Test-Path $pyPath) {
            $pyContent = Get-Content $pyPath -Raw
            $pyNew = $pyContent -replace '(os\.environ\.get\(\s*"PROJECT_ENDPOINT",\s*\n?\s*)"https://[^"]*"', "`$1`"$aiProjectEndpoint`""
            if ($pyNew -ne $pyContent) {
                Set-Content -Path $pyPath -Value $pyNew -NoNewline
                Write-Host "    [OK] $pyFile - PROJECT_ENDPOINT default updated" -ForegroundColor Green
                $updatedFiles++
            }
        }
    }
}

# --- Lesson 1 labs/solution/ Python files (additional) ---
# Note: labs/solution/ .env and Python files are already handled in the main loop above.
# This section is kept as a placeholder for any additional lesson-1 specific config.

# --- Lesson 1 demos/ Python files ---
$lesson1DemoDir = Join-Path $WorkspaceRoot "lesson-1-declarative" "demos"
if (Test-Path $lesson1DemoDir) {
    # Create/update .env
    $envDemo1 = Join-Path $lesson1DemoDir ".env"
    Set-Content -Path $envDemo1 -Value $envContent -NoNewline
    Write-Host "    [OK] demos/.env updated" -ForegroundColor Green
    $updatedFiles++

    foreach ($pyFile in @("create_agent.py", "test_agent.py")) {
        $pyPath = Join-Path $lesson1DemoDir $pyFile
        if (Test-Path $pyPath) {
            $pyContent = Get-Content $pyPath -Raw
            $pyNew = $pyContent -replace '(os\.environ\.get\(\s*"PROJECT_ENDPOINT",\s*\n?\s*)"https://[^"]*"', "`$1`"$aiProjectEndpoint`""
            if ($pyNew -ne $pyContent) {
                Set-Content -Path $pyPath -Value $pyNew -NoNewline
                Write-Host "    [OK] demos/$pyFile - PROJECT_ENDPOINT default updated" -ForegroundColor Green
                $updatedFiles++
            }
        }
    }
}

# --- Lesson 2: Hosted MAF (deploy.ps1 needs RG) ---
Write-Host "`n  Lesson 2 - Hosted MAF Agent" -ForegroundColor White
$lesson2Dir = Join-Path $WorkspaceRoot "lesson-2-hosted-maf" "labs" "solution"
if (Test-Path $lesson2Dir) {
    $deploy2 = Join-Path $lesson2Dir "deploy.ps1"
    if (Test-Path $deploy2) {
        $d2Content = Get-Content $deploy2 -Raw
        $d2New = $d2Content -replace '\$RG\s*=\s*"[^"]*"', "`$RG = `"$ResourceGroupName`""
        if ($d2New -ne $d2Content) {
            Set-Content -Path $deploy2 -Value $d2New -NoNewline
            Write-Host "    [OK] deploy.ps1 - resource group updated to '$ResourceGroupName'" -ForegroundColor Green
            $updatedFiles++
        } else {
            Write-Host "    [i] deploy.ps1 - resource group already correct" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "    [i] No labs/solution/ directory found" -ForegroundColor Cyan
}

# --- Lesson 3: Hosted LangGraph (deploy.ps1 needs RG) ---
Write-Host "`n  Lesson 3 - Hosted LangGraph" -ForegroundColor White
$lesson3Dir = Join-Path $WorkspaceRoot "lesson-3-hosted-langgraph" "labs" "solution"
if (Test-Path $lesson3Dir) {
    $deploy3 = Join-Path $lesson3Dir "deploy.ps1"
    if (Test-Path $deploy3) {
        $d3Content = Get-Content $deploy3 -Raw
        $d3New = $d3Content -replace '\$RG\s*=\s*"[^"]*"', "`$RG = `"$ResourceGroupName`""
        if ($d3New -ne $d3Content) {
            Set-Content -Path $deploy3 -Value $d3New -NoNewline
            Write-Host "    [OK] deploy.ps1 - resource group updated to '$ResourceGroupName'" -ForegroundColor Green
            $updatedFiles++
        } else {
            Write-Host "    [i] deploy.ps1 - resource group already correct" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "    [i] No labs/solution/ directory found" -ForegroundColor Cyan
}

# --- Lesson 4: ACA LangGraph ---
Write-Host "`n  Lesson 4 - ACA LangGraph" -ForegroundColor White
$lesson4Dir = Join-Path $WorkspaceRoot "lesson-4-aca-langgraph" "labs" "solution"
if (Test-Path $lesson4Dir) {
    # Update deploy.ps1 - resource group
    $deploy4 = Join-Path $lesson4Dir "deploy.ps1"
    if (Test-Path $deploy4) {
        $d4Content = Get-Content $deploy4 -Raw
        $d4New = $d4Content -replace '\$RG\s*=\s*"[^"]*"', "`$RG = `"$ResourceGroupName`""
        if ($d4New -ne $d4Content) {
            Set-Content -Path $deploy4 -Value $d4New -NoNewline
            Write-Host "    [OK] deploy.ps1 - resource group updated to '$ResourceGroupName'" -ForegroundColor Green
            $updatedFiles++
        }
    }

    # Update aca.bicep - ACA environment name
    $bicep4 = Join-Path $lesson4Dir "aca.bicep"
    if (Test-Path $bicep4) {
        $b4Content = Get-Content $bicep4 -Raw
        $b4New = $b4Content -replace "param acaEnvironmentName string = '[^']*'", "param acaEnvironmentName string = '$containerAppsEnvName'"
        if ($b4New -ne $b4Content) {
            Set-Content -Path $bicep4 -Value $b4New -NoNewline
            Write-Host "    [OK] aca.bicep - ACA environment name updated to '$containerAppsEnvName'" -ForegroundColor Green
            $updatedFiles++
        }
    }
}

# --- Lesson 6: A365 SDK ---
Write-Host "`n  Lesson 6 - A365 SDK Agent" -ForegroundColor White
$lesson6Dir = Join-Path $WorkspaceRoot "lesson-6-a365-langgraph" "labs" "solution"
if (Test-Path $lesson6Dir) {
    # Update aca.bicep - ACA environment name
    $bicep6 = Join-Path $lesson6Dir "aca.bicep"
    if (Test-Path $bicep6) {
        $b6Content = Get-Content $bicep6 -Raw
        $b6New = $b6Content -replace "param acaEnvironmentName string = '[^']*'", "param acaEnvironmentName string = '$containerAppsEnvName'"
        if ($b6New -ne $b6Content) {
            Set-Content -Path $bicep6 -Value $b6New -NoNewline
            Write-Host "    [OK] aca.bicep - ACA environment name updated to '$containerAppsEnvName'" -ForegroundColor Green
            $updatedFiles++
        }
    }

    # Check if deploy.ps1 exists
    $deploy6 = Join-Path $lesson6Dir "deploy.ps1"
    if (Test-Path $deploy6) {
        $d6Content = Get-Content $deploy6 -Raw
        $d6New = $d6Content -replace '\$RG\s*=\s*"[^"]*"', "`$RG = `"$ResourceGroupName`""
        if ($d6New -ne $d6Content) {
            Set-Content -Path $deploy6 -Value $d6New -NoNewline
            Write-Host "    [OK] deploy.ps1 - resource group updated to '$ResourceGroupName'" -ForegroundColor Green
            $updatedFiles++
        }
    }
}

# ─── [3/4] Also update labs/solution/ deploy scripts ───
Write-Host "`n[3/4] Updating labs/solution/ deploy scripts..." -ForegroundColor Yellow

$solutionDirs = @(
    (Join-Path $WorkspaceRoot "lesson-2-hosted-maf" "labs" "solution"),
    (Join-Path $WorkspaceRoot "lesson-3-hosted-langgraph" "labs" "solution"),
    (Join-Path $WorkspaceRoot "lesson-4-aca-langgraph" "labs" "solution"),
    (Join-Path $WorkspaceRoot "lesson-6-a365-langgraph" "labs" "solution")
)

foreach ($solDir in $solutionDirs) {
    $lessonName = (Split-Path (Split-Path $solDir -Parent) -Leaf)
    if (-not (Test-Path $solDir)) { continue }

    $deployFile = Join-Path $solDir "deploy.ps1"
    if (Test-Path $deployFile) {
        $dContent = Get-Content $deployFile -Raw
        $dNew = $dContent -replace '\$RG\s*=\s*"[^"]*"', "`$RG = `"$ResourceGroupName`""
        if ($dNew -ne $dContent) {
            Set-Content -Path $deployFile -Value $dNew -NoNewline
            Write-Host "  [OK] $lessonName/labs/solution/deploy.ps1 - RG updated" -ForegroundColor Green
            $updatedFiles++
        }
    }

    $bicepFile = Join-Path $solDir "aca.bicep"
    if (Test-Path $bicepFile) {
        $bContent = Get-Content $bicepFile -Raw
        $bNew = $bContent -replace "param acaEnvironmentName string = '[^']*'", "param acaEnvironmentName string = '$containerAppsEnvName'"
        if ($bNew -ne $bContent) {
            Set-Content -Path $bicepFile -Value $bNew -NoNewline
            Write-Host "  [OK] $lessonName/labs/solution/aca.bicep - ACA env updated" -ForegroundColor Green
            $updatedFiles++
        }
    }
}

# ─── [4/4] Update test/ Python files ────────────────────────
Write-Host "`n[4/4] Updating test/ Python files..." -ForegroundColor Yellow

$chatPy = Join-Path $WorkspaceRoot "test" "chat.py"
if (Test-Path $chatPy) {
    $chatContent = Get-Content $chatPy -Raw
    $chatNew = $chatContent -replace '(os\.environ\.get\(\s*"RESOURCE_GROUP",\s*)"[^"]*"', "`$1`"$ResourceGroupName`""
    if ($chatNew -ne $chatContent) {
        Set-Content -Path $chatPy -Value $chatNew -NoNewline
        Write-Host "  [OK] test/chat.py - RESOURCE_GROUP default updated to '$ResourceGroupName'" -ForegroundColor Green
        $updatedFiles++
    }
}

# ─── Summary ─────────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   CONFIGURATION COMPLETE"                -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "  Files updated: $updatedFiles" -ForegroundColor White
Write-Host ""
Write-Host "  Resource Group:     $ResourceGroupName" -ForegroundColor Cyan
Write-Host "  Project Endpoint:   $aiProjectEndpoint" -ForegroundColor Cyan
Write-Host "  OpenAI Endpoint:    $openaiEndpoint" -ForegroundColor Cyan
Write-Host "  Model Deployment:   $aiModelDeployment" -ForegroundColor Cyan
Write-Host "  ACR:                $acrLoginServer" -ForegroundColor Cyan
Write-Host "  ACA Environment:    $containerAppsEnvName" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Navigate to each lesson and run the lab" -ForegroundColor White
Write-Host "    2. Lesson 1: cd lesson-1-declarative/labs/solution && python create_agent.py" -ForegroundColor White
Write-Host "    3. Lesson 2: cd lesson-2-hosted-maf/labs/solution && ./deploy.ps1" -ForegroundColor White
Write-Host "    4. Lesson 3: cd lesson-3-hosted-langgraph/labs/solution && ./deploy.ps1" -ForegroundColor White
Write-Host "    5. Lesson 4: cd lesson-4-aca-langgraph/labs/solution && ./deploy.ps1" -ForegroundColor White
Write-Host "    6. Lesson 6: cd lesson-6-a365-langgraph/labs/solution && ./deploy.ps1" -ForegroundColor White
Write-Host ""
