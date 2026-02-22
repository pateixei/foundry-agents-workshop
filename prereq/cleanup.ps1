# Script de Limpeza - Workshop Agent365
# Este script remove o resource group e todos os recursos filhos
# Purga recursos Cognitive Services (AI Foundry) em soft-delete por padrao

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "main.bicepparam",

    [Parameter(Mandatory=$false)]
    [switch]$NoPurge,

    [Parameter(Mandatory=$false)]
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

# Banner
Write-Host "`n========================================" -ForegroundColor Red
Write-Host "   CLEANUP WORKSHOP AGENT365" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Red

# Ler ResourceGroupName do arquivo de parametros, se nao foi informado
if (-not $ResourceGroupName -and $ParametersFile -and (Test-Path $ParametersFile)) {
    $rgMatch = Select-String -Path $ParametersFile -Pattern "param\s+resourceGroupName\s*=\s*'([^']+)'" | Select-Object -First 1
    if ($rgMatch) {
        $ResourceGroupName = $rgMatch.Matches.Groups[1].Value
        Write-Host "  [i] ResourceGroupName lido do arquivo de parametros: $ResourceGroupName" -ForegroundColor Cyan
    }
}

if (-not $ResourceGroupName) {
    Write-Host "  [X] ResourceGroupName e obrigatorio (use -ResourceGroupName ou defina em $ParametersFile)" -ForegroundColor Red
    exit 1
}

# Verificar se o Resource Group existe
Write-Host "[1/3] Verificando Resource Group..." -ForegroundColor Yellow
try {
    $rg = az group show --name $ResourceGroupName --output json 2>$null | ConvertFrom-Json
    if (-not $rg) {
        Write-Host "  [i] Resource Group '$ResourceGroupName' nao encontrado. Nada para limpar." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "  [OK] Resource Group '$ResourceGroupName' encontrado em: $($rg.location)" -ForegroundColor Green
    $rgLocation = $rg.location
} catch {
    Write-Host "  [i] Resource Group '$ResourceGroupName' nao encontrado. Nada para limpar." -ForegroundColor Yellow
    exit 0
}

# Listar recursos no grupo
Write-Host "`n[2/3] Recursos no grupo '$ResourceGroupName':" -ForegroundColor Yellow
az resource list --resource-group $ResourceGroupName --query "[].{Name:name, Type:type}" --output table 2>$null

# Coletar nomes de contas Cognitive Services para purge
$csAccounts = @()
if (-not $NoPurge) {
    $csJson = az resource list --resource-group $ResourceGroupName `
        --query "[?type=='Microsoft.CognitiveServices/accounts'].name" `
        --output json 2>$null
    if ($csJson) {
        $csAccounts = $csJson | ConvertFrom-Json
    }
}

# Confirmacao
Write-Host ""
Write-Host "ATENCAO: Isso ira excluir permanentemente o resource group '$ResourceGroupName' e TODOS os seus recursos." -ForegroundColor Red
if (-not $NoPurge -and $csAccounts.Count -gt 0) {
    Write-Host "As seguintes contas Cognitive Services tambem serao PURGADAS (irrecuperavel):" -ForegroundColor Red
    foreach ($acct in $csAccounts) {
        Write-Host "  - $acct" -ForegroundColor Red
    }
}
Write-Host ""

if (-not $Yes) {
    $answer = Read-Host "Tem certeza que deseja continuar? (yes/no)"
    if ($answer -ne "yes") {
        Write-Host "Limpeza cancelada." -ForegroundColor Yellow
        exit 0
    }
}

# Excluir Resource Group
Write-Host "`n[3/3] Excluindo Resource Group '$ResourceGroupName'..." -ForegroundColor Yellow
Write-Host "      (Isso pode levar alguns minutos)" -ForegroundColor Cyan
az group delete --name $ResourceGroupName --yes 2>$null
Write-Host "  [OK] Resource Group '$ResourceGroupName' excluido" -ForegroundColor Green

# Purgar Cognitive Services (soft-delete)
if (-not $NoPurge -and $csAccounts.Count -gt 0) {
    Write-Host "`nPurgando contas Cognitive Services em soft-delete..." -ForegroundColor Yellow
    foreach ($acct in $csAccounts) {
        Write-Host "  [i] Purgando '$acct' em '$rgLocation'..." -ForegroundColor Cyan
        try {
            az cognitiveservices account purge --name $acct --resource-group $ResourceGroupName --location $rgLocation 2>$null
            Write-Host "  [OK] '$acct' purgado" -ForegroundColor Green
        } catch {
            Write-Host "  [!] Nao foi possivel purgar '$acct' (pode ja ter sido purgado ou nao estar em soft-delete)" -ForegroundColor Yellow
        }
    }
} elseif ($NoPurge) {
    Write-Host "`nPurge de Cognitive Services ignorado (remova -NoPurge para habilitar)" -ForegroundColor Yellow
}

# Finalizar
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   LIMPEZA CONCLUIDA" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

if ($NoPurge) {
    Write-Host "Nota: Recursos Cognitive Services podem permanecer em estado soft-delete por 48 horas." -ForegroundColor Yellow
    Write-Host "Para purga-los, re-execute sem -NoPurge" -ForegroundColor Yellow
}
