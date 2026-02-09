# deploy.ps1 - Deploy do Hosted Agent LangGraph no Azure AI Foundry
# Uso: .\deploy.ps1
#
# Pre-requisitos:
#   - Infraestrutura do prereq/ ja deployada (main.bicep)
#   - az login realizado
#   - az extension add --name cognitiveservices --upgrade
#
# O que este script faz:
#   1. Obtem outputs do Bicep (ACR, endpoint, model, nomes de recursos)
#   2. Faz build da imagem no ACR (cloud build, --no-logs para Windows)
#   3. Atribui roles RBAC a managed identity do projeto:
#      - AcrPull no Container Registry
#      - Cognitive Services OpenAI User no Foundry account
#   4. Cria nova versao do hosted agent via az cognitiveservices agent create
#   5. Inicia o agente via az cognitiveservices agent start
#   6. Aguarda o agente ficar Running e executa teste

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Lesson 2 - LangGraph Hosted Agent"
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 1. Obter outputs do Bicep (infraestrutura compartilhada)
# -----------------------------------------------------------
Write-Host "[1/6] Obtendo outputs da infraestrutura..." -ForegroundColor Yellow

$RG = "rg-ag365sdk"
$DEPLOYMENT = "main"
$SUBSCRIPTION = (az account show --query id -o tsv)
if (-not $SUBSCRIPTION) { Write-Host "ERRO: Execute 'az login' primeiro." -ForegroundColor Red; exit 1 }

$outputs = az deployment group show `
    --resource-group $RG `
    --name $DEPLOYMENT `
    --query "properties.outputs" `
    -o json | ConvertFrom-Json

$ACR_NAME        = $outputs.acrName.value
$ACR_LOGIN       = $outputs.acrLoginServer.value
$PROJECT_ENDPOINT = $outputs.aiProjectEndpoint.value
$MODEL_DEPLOYMENT = $outputs.aiModelDeployment.value
$FOUNDRY_NAME    = $outputs.aiFoundryName.value
$PROJECT_NAME    = $outputs.aiProjectName.value

# Endpoint OpenAI do Foundry (para o container chamar o modelo)
$OPENAI_ENDPOINT = "https://$FOUNDRY_NAME.openai.azure.com/"

Write-Host "  ACR:             $ACR_LOGIN"
Write-Host "  Endpoint:        $PROJECT_ENDPOINT"
Write-Host "  OpenAI Endpoint: $OPENAI_ENDPOINT"
Write-Host "  Model:           $MODEL_DEPLOYMENT"
Write-Host "  Foundry:         $FOUNDRY_NAME"
Write-Host "  Project:         $PROJECT_NAME"
Write-Host ""

# -----------------------------------------------------------
# 2. Build da imagem no ACR
#    Nota: --no-logs evita UnicodeEncodeError (colorama/cp1252)
#    no PowerShell 5.1 no Windows.
# -----------------------------------------------------------
Write-Host "[2/6] Construindo imagem no ACR..." -ForegroundColor Yellow

$AGENT_NAME = "lg-market-agent"

# Determinar proxima versao verificando versoes existentes
$existingVersions = az cognitiveservices agent list-versions `
    --account-name $FOUNDRY_NAME `
    --project-name $PROJECT_NAME `
    --name $AGENT_NAME 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($existingVersions -and $existingVersions.data) {
    $maxVer = ($existingVersions.data | ForEach-Object { [int]$_.version } | Measure-Object -Maximum).Maximum
    $NEXT_VERSION = $maxVer + 1
} else {
    $NEXT_VERSION = 1
}

$IMAGE_TAG = "$($AGENT_NAME):v$NEXT_VERSION"
$IMAGE_FULL = "$ACR_LOGIN/$IMAGE_TAG"

Write-Host "  Versao: $NEXT_VERSION"
Write-Host "  Imagem: $IMAGE_TAG"

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
# 3. Atribuir RBAC ao projeto (managed identity)
#
#    Roles necessarias:
#    - AcrPull no ACR (para baixar a imagem do container)
#    - Cognitive Services OpenAI User no Foundry account
#      (para o container chamar o modelo GPT)
#
#    NOTA: O resource type do projeto Foundry e
#    Microsoft.CognitiveServices/accounts/projects
#    (NAO MachineLearningServices/workspaces).
# -----------------------------------------------------------
Write-Host "[3/6] Configurando permissoes RBAC..." -ForegroundColor Yellow

# Obter principal ID do AI Project (managed identity)
$PROJECT_RESOURCE_ID = "/subscriptions/$SUBSCRIPTION/resourceGroups/$RG/providers/Microsoft.CognitiveServices/accounts/$FOUNDRY_NAME/projects/$PROJECT_NAME"
$PROJECT_PRINCIPAL = az resource show `
    --ids $PROJECT_RESOURCE_ID `
    --query "identity.principalId" `
    -o tsv

$ACR_ID = az acr show --name $ACR_NAME --query "id" -o tsv
$FOUNDRY_SCOPE = "/subscriptions/$SUBSCRIPTION/resourceGroups/$RG/providers/Microsoft.CognitiveServices/accounts/$FOUNDRY_NAME"

if ($PROJECT_PRINCIPAL) {
    Write-Host "  Project Principal ID: $PROJECT_PRINCIPAL"

    # AcrPull no ACR
    $ErrorActionPreference = "SilentlyContinue"
    az role assignment create `
        --assignee-object-id $PROJECT_PRINCIPAL `
        --assignee-principal-type ServicePrincipal `
        --role "AcrPull" `
        --scope $ACR_ID `
        2>$null | Out-Null
    Write-Host "  AcrPull atribuido ao ACR"

    # Cognitive Services OpenAI User no Foundry account
    az role assignment create `
        --assignee-object-id $PROJECT_PRINCIPAL `
        --assignee-principal-type ServicePrincipal `
        --role "Cognitive Services OpenAI User" `
        --scope $FOUNDRY_SCOPE `
        2>$null | Out-Null
    Write-Host "  Cognitive Services OpenAI User atribuido ao Foundry"
    $ErrorActionPreference = "Stop"
} else {
    Write-Host "  AVISO: Nao foi possivel obter o Principal ID do projeto." -ForegroundColor Yellow
    Write-Host "  Verifique se o projeto tem Managed Identity habilitada." -ForegroundColor Yellow
}
Write-Host ""

# -----------------------------------------------------------
# 4. Criar nova versao do hosted agent
# -----------------------------------------------------------
Write-Host "[4/6] Criando hosted agent v$NEXT_VERSION..." -ForegroundColor Yellow

az cognitiveservices agent create `
    --account-name $FOUNDRY_NAME `
    --project-name $PROJECT_NAME `
    --name $AGENT_NAME `
    --image $IMAGE_FULL `
    --cpu 1 --memory 2Gi `
    --protocol responses --protocol-version v1 `
    --env AZURE_AI_PROJECT_ENDPOINT=$PROJECT_ENDPOINT `
         AZURE_AI_MODEL_DEPLOYMENT_NAME=$MODEL_DEPLOYMENT `
         AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT `
    --no-start

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar hosted agent." -ForegroundColor Red
    exit 1
}

Write-Host "  Agente $AGENT_NAME v$NEXT_VERSION criado"
Write-Host ""

# -----------------------------------------------------------
# 5. Iniciar o agente
# -----------------------------------------------------------
Write-Host "[5/6] Iniciando agente v$NEXT_VERSION..." -ForegroundColor Yellow

az cognitiveservices agent start `
    --account-name $FOUNDRY_NAME `
    --project-name $PROJECT_NAME `
    --name $AGENT_NAME `
    --agent-version $NEXT_VERSION

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao iniciar o agente." -ForegroundColor Red
    exit 1
}

Write-Host "  Aguardando agente ficar Running (pode levar ~2 min)..."
$maxWait = 180
$elapsed = 0
while ($elapsed -lt $maxWait) {
    Start-Sleep -Seconds 15
    $elapsed += 15

    # Verificar se ja esta Running tentando iniciar novamente
    $startResult = az cognitiveservices agent start `
        --account-name $FOUNDRY_NAME `
        --project-name $PROJECT_NAME `
        --name $AGENT_NAME `
        --agent-version $NEXT_VERSION 2>&1

    if ($startResult -match "Running") {
        Write-Host "  Agente Running!" -ForegroundColor Green
        break
    }
    Write-Host "  Aguardando... ($($elapsed)s)"
}
Write-Host ""

# -----------------------------------------------------------
# 6. Teste rapido
# -----------------------------------------------------------
Write-Host "[6/6] Testando o agente..." -ForegroundColor Yellow

# Aguardar propagacao do RBAC (caso primeira execucao)
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Para testar manualmente:" -ForegroundColor Cyan
Write-Host "  python ../../test/chat.py --lesson 3"
Write-Host ""
Write-Host "Ou via REST:" -ForegroundColor Cyan
Write-Host "  Endpoint: $PROJECT_ENDPOINT"
Write-Host "  Agent:    $AGENT_NAME v$NEXT_VERSION"
Write-Host ""
Write-Host "Deploy concluido com sucesso!" -ForegroundColor Green
Write-Host ""

Write-Host "======================================" -ForegroundColor Green
Write-Host " Deploy concluido!"
Write-Host "======================================" -ForegroundColor Green
