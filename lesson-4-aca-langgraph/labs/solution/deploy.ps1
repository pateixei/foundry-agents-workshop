# deploy.ps1 - Deploy do LangGraph Agent no Azure Container Apps
# Registro como Connected Agent no Microsoft Foundry
#
# Uso: .\deploy.ps1
#
# Pre-requisitos:
#   - Infraestrutura do prereq/ ja deployada (main.bicep)
#   - az login realizado
#
# O que este script faz:
#   1. Obtem outputs do Bicep (ACR, endpoint, model, nomes de recursos)
#   2. Faz build da imagem no ACR (cloud build, --no-logs para Windows)
#   3. Deploy do Container App no ACA Environment existente via Bicep
#   4. Atribui role RBAC a managed identity do ACA:
#      - Cognitive Services OpenAI User no Foundry account
#   5. Imprime URL do agente e instrucoes de registro no Foundry

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Lesson 4 - ACA LangGraph Agent"
Write-Host " (Connected Agent no Foundry)"
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 1. Obter outputs do Bicep (infraestrutura compartilhada)
# -----------------------------------------------------------
Write-Host "[1/5] Obtendo outputs da infraestrutura..." -ForegroundColor Yellow

$RG = "rg-ai-agents-workshop"
$DEPLOYMENT = "main"
$SUBSCRIPTION = (az account show --query id -o tsv 2>$null)
if (-not $SUBSCRIPTION) { Write-Host "ERRO: Execute 'az login' primeiro." -ForegroundColor Red; exit 1 }

$outputs = az deployment group show `
    --resource-group $RG `
    --name $DEPLOYMENT `
    --query "properties.outputs" `
    -o json | ConvertFrom-Json

$ACR_NAME         = $outputs.acrName.value
$ACR_LOGIN        = $outputs.acrLoginServer.value
$PROJECT_ENDPOINT = $outputs.aiProjectEndpoint.value
$MODEL_DEPLOYMENT = $outputs.aiModelDeployment.value
$FOUNDRY_NAME     = $outputs.aiFoundryName.value
$PROJECT_NAME     = $outputs.aiProjectName.value

# Endpoint OpenAI do Foundry
$OPENAI_ENDPOINT = "https://$FOUNDRY_NAME.openai.azure.com/"

Write-Host "  ACR:             $ACR_LOGIN"
Write-Host "  Endpoint:        $PROJECT_ENDPOINT"
Write-Host "  OpenAI Endpoint: $OPENAI_ENDPOINT"
Write-Host "  Model:           $MODEL_DEPLOYMENT"
Write-Host ""

# -----------------------------------------------------------
# 2. Build da imagem no ACR
#    Nota: --no-logs evita UnicodeEncodeError no Windows
# -----------------------------------------------------------
Write-Host "[2/5] Construindo imagem no ACR..." -ForegroundColor Yellow

$AGENT_NAME = "aca-lg-agent"
$IMAGE_TAG = "$($AGENT_NAME):v1"
$IMAGE_FULL = "$ACR_LOGIN/$IMAGE_TAG"

Write-Host "  Imagem: $IMAGE_FULL"

az acr build `
    --registry $ACR_NAME `
    --image $IMAGE_TAG `
    --file Dockerfile `
    . `
    --no-logs

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no build da imagem." -ForegroundColor Red
    exit 1
}

Write-Host "  Build concluido: $IMAGE_FULL"
Write-Host ""

# -----------------------------------------------------------
# 3. Deploy do Container App no ACA Environment existente
#
#    Se o Container App ja existir, remove antes de recriar
#    para evitar conflito de deployment (erro
#    "The content for this response was already consumed").
# -----------------------------------------------------------
Write-Host "[3/5] Deployando Container App no ACA Environment existente..." -ForegroundColor Yellow

# Remover Container App existente (idempotente)
$ErrorActionPreference = "SilentlyContinue"
$existingApp = az containerapp show --name $AGENT_NAME --resource-group $RG --query "name" -o tsv 2>$null
$ErrorActionPreference = "Stop"

if ($existingApp) {
    Write-Host "  Container App '$AGENT_NAME' ja existe. Removendo para recriar..."
    az containerapp delete --name $AGENT_NAME --resource-group $RG --yes 2>$null | Out-Null
    Write-Host "  Removido."
}

Push-Location $PSScriptRoot

$ACA_OUTPUTS = az deployment group create `
    --resource-group $RG `
    --template-file aca.bicep `
    --parameters `
        acrName=$ACR_NAME `
        containerImage=$IMAGE_FULL `
        projectEndpoint=$PROJECT_ENDPOINT `
        modelDeployment=$MODEL_DEPLOYMENT `
        openaiEndpoint=$OPENAI_ENDPOINT `
    --query "properties.outputs" `
    -o json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no deploy do ACA." -ForegroundColor Red
    exit 1
}

$ACA_URL       = $ACA_OUTPUTS.acaUrl.value
$ACA_FQDN      = $ACA_OUTPUTS.acaFqdn.value
$ACA_PRINCIPAL  = $ACA_OUTPUTS.acaPrincipalId.value

Write-Host "  ACA URL:       $ACA_URL"
Write-Host "  ACA Principal: $ACA_PRINCIPAL"
Write-Host ""

# -----------------------------------------------------------
# 4. Atribuir RBAC ao ACA (managed identity)
#
#    O Container App precisa de:
#    - Cognitive Services OpenAI User no Foundry account
#      (para chamar o modelo GPT via Azure OpenAI)
# -----------------------------------------------------------
Write-Host "[4/5] Configurando permissoes RBAC..." -ForegroundColor Yellow

$FOUNDRY_SCOPE = "/subscriptions/$SUBSCRIPTION/resourceGroups/$RG/providers/Microsoft.CognitiveServices/accounts/$FOUNDRY_NAME"

if ($ACA_PRINCIPAL) {
    $ErrorActionPreference = "SilentlyContinue"

    az role assignment create `
        --assignee-object-id $ACA_PRINCIPAL `
        --assignee-principal-type ServicePrincipal `
        --role "Cognitive Services OpenAI User" `
        --scope $FOUNDRY_SCOPE `
        2>$null | Out-Null
    Write-Host "  Cognitive Services OpenAI User atribuido ao Foundry"

    $ErrorActionPreference = "Stop"
} else {
    Write-Host "  AVISO: Nao foi possivel obter o Principal ID do ACA." -ForegroundColor Yellow
}
Write-Host ""

# -----------------------------------------------------------
# 5. Resumo e proximos passos
# -----------------------------------------------------------
Write-Host "======================================" -ForegroundColor Green
Write-Host " Deploy concluido!"
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "  URL do agente:  $ACA_URL" -ForegroundColor Cyan
Write-Host "  Health check:   $ACA_URL/health" -ForegroundColor Cyan
Write-Host "  Chat endpoint:  $ACA_URL/chat" -ForegroundColor Cyan
Write-Host "  Docs (Swagger): $ACA_URL/docs" -ForegroundColor Cyan
Write-Host ""

Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host " Testar o agente (acesso direto)"
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Via chat.py (chamada direta ao ACA)" -ForegroundColor White
Write-Host "  python ../../test/chat.py --lesson 4" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Via curl" -ForegroundColor White
Write-Host "  curl -X POST $ACA_URL/chat -H 'Content-Type: application/json' -d '{""message"":""Qual a cotacao da PETR4?""}'" -ForegroundColor Cyan
Write-Host ""

Write-Host "======================================" -ForegroundColor Magenta
Write-Host " NOTA: ACA vs Hosted Agents" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Este agente roda na SUA infraestrutura (Azure Container Apps)." -ForegroundColor White
Write-Host "Teste-o diretamente pelos endpoints acima (/health, /chat, /docs)." -ForegroundColor White
Write-Host ""
Write-Host "O Foundry Playground NAO suporta agentes externos em ACA." -ForegroundColor Yellow
Write-Host "Para integrar com o Playground, use o modelo 'Hosted Agent'" -ForegroundColor Yellow
Write-Host "(veja Lesson 3), onde o Foundry gerencia a infraestrutura." -ForegroundColor Yellow
Write-Host ""
Write-Host "Voce pode registrar a URL do ACA como 'asset' no portal Foundry" -ForegroundColor White
Write-Host "(Operate > Overview > Register asset), mas isso serve apenas" -ForegroundColor White
Write-Host "como referencia — nao habilita o Playground." -ForegroundColor White
Write-Host ""
Write-Host "======================================" -ForegroundColor Magenta
Write-Host " Dados para referencia:" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  ACA URL:        $ACA_URL" -ForegroundColor Cyan
Write-Host "  ACA FQDN:       $ACA_FQDN" -ForegroundColor Cyan
Write-Host "  Foundry:        $FOUNDRY_NAME" -ForegroundColor Cyan
Write-Host "  Project:        $PROJECT_NAME" -ForegroundColor Cyan
Write-Host "  ACA Principal:  $ACA_PRINCIPAL" -ForegroundColor Cyan
Write-Host ""
