# deploy.ps1 - Deploy do Hosted Agent MAF no Azure AI Foundry
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
Write-Host " Lesson 1 - MAF Hosted Agent"
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 1. Obter outputs do Bicep (infraestrutura compartilhada)
# -----------------------------------------------------------
Write-Host "[1/6] Obtendo outputs da infraestrutura..." -ForegroundColor Yellow

$RG = "rg-ai-agents-workshop"
$DEPLOYMENT = "main"
$SUBSCRIPTION = (az account show --query id -o tsv)
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

$AGENT_NAME = "fin-market-agent"

# Determinar proxima versao verificando versoes existentes
$ErrorActionPreference = "SilentlyContinue"
$existingVersions = az cognitiveservices agent list-versions `
    --account-name $FOUNDRY_NAME `
    --project-name $PROJECT_NAME `
    --name $AGENT_NAME 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
$ErrorActionPreference = "Stop"

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

Push-Location $PSScriptRoot
$ErrorActionPreference = "SilentlyContinue"
az acr build `
    --registry $ACR_NAME `
    --image $IMAGE_TAG `
    --file Dockerfile `
    . `
    --no-logs
$acr_exit = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($acr_exit -ne 0) {
    Pop-Location
    Write-Host "ERRO: Falha no build da imagem." -ForegroundColor Red
    exit 1
}
Pop-Location

Write-Host "  Build concluido: $IMAGE_FULL"
Write-Host ""

# -----------------------------------------------------------
# 3. Atribuir RBAC ao projeto (managed identity)
#
#    Roles necessarias:
#    - AcrPull no ACR (para baixar a imagem do container)
#    - Cognitive Services OpenAI User no Foundry account
#      (para o container chamar o modelo GPT)
# -----------------------------------------------------------
Write-Host "[3/6] Configurando permissoes RBAC..." -ForegroundColor Yellow

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

    # Azure AI User no Foundry account
    # Inclui Microsoft.CognitiveServices/* (wildcard) que cobre
    # AIServices/agents/write - necessario porque o MAF internamente
    # chama project_client.agents.create_version() ao receber requests.
    az role assignment create `
        --assignee-object-id $PROJECT_PRINCIPAL `
        --assignee-principal-type ServicePrincipal `
        --role "Azure AI User" `
        --scope $FOUNDRY_SCOPE `
        2>$null | Out-Null
    Write-Host "  Azure AI User atribuido ao Foundry"
    $ErrorActionPreference = "Stop"
} else {
    Write-Host "  AVISO: Nao foi possivel obter o Principal ID do projeto." -ForegroundColor Yellow
    Write-Host "  Verifique se o projeto tem Managed Identity habilitada." -ForegroundColor Yellow
}
Write-Host ""

# -----------------------------------------------------------
# 4. Criar nova versao do hosted agent
#
#    HOSTED_AGENT_VERSION deve ser a versao REAL do agente.
#    O MAF usa esse valor para construir o agent reference
#    que envia ao Foundry Responses API internamente:
#      extra_body = {"agent": {"name": ..., "version": HOSTED_AGENT_VERSION}}
#    Se o valor nao corresponder a uma versao existente, o
#    Foundry retorna 404 "Agent ... with version ... not found".
#
#    Usamos $NEXT_VERSION (calculado no passo 2) como valor
#    do env var. O servico normalmente atribui essa mesma
#    versao. Verificamos apos a criacao e alertamos se diferir.
# -----------------------------------------------------------
Write-Host "[4/6] Criando hosted agent..." -ForegroundColor Yellow

$ErrorActionPreference = "SilentlyContinue"
$envVars = @(
    "FOUNDRY_PROJECT_ENDPOINT=$PROJECT_ENDPOINT",
    "FOUNDRY_MODEL_DEPLOYMENT_NAME=$MODEL_DEPLOYMENT",
    "AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT",
    "HOSTED_AGENT_VERSION=$NEXT_VERSION"
)

$createResult = az cognitiveservices agent create `
    --account-name $FOUNDRY_NAME `
    --project-name $PROJECT_NAME `
    --name $AGENT_NAME `
    --image $IMAGE_FULL `
    --cpu 1 --memory 2Gi `
    --protocol responses --protocol-version v1 `
    --env @envVars `
    --no-start `
    -o json
$agent_exit = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($agent_exit -ne 0) {
    Write-Host "ERRO: Falha ao criar hosted agent." -ForegroundColor Red
    exit 1
}

# Extrair versao real atribuida pelo servico
$createJson = $createResult | ConvertFrom-Json
$ACTUAL_VERSION = $createJson.version
Write-Host "  Versao atribuida pelo servico: $ACTUAL_VERSION"

if ($ACTUAL_VERSION -ne "$NEXT_VERSION") {
    Write-Host "  AVISO: Versao atribuida ($ACTUAL_VERSION) difere da esperada ($NEXT_VERSION)!" -ForegroundColor Red
    Write-Host "  O container tera HOSTED_AGENT_VERSION=$NEXT_VERSION mas a versao real e $ACTUAL_VERSION." -ForegroundColor Red
    Write-Host "  Isso causara erro 404 no MAF. Delete e recrie com versoes limpas." -ForegroundColor Red
    exit 1
}

Write-Host "  Agente $AGENT_NAME v$ACTUAL_VERSION criado (HOSTED_AGENT_VERSION=$NEXT_VERSION)"

# Usar a versao real para o start
$NEXT_VERSION = $ACTUAL_VERSION
Write-Host ""

# -----------------------------------------------------------
# 5. Iniciar o agente
# -----------------------------------------------------------
Write-Host "[5/6] Iniciando agente v$NEXT_VERSION..." -ForegroundColor Yellow

$ErrorActionPreference = "SilentlyContinue"
az cognitiveservices agent start `
    --account-name $FOUNDRY_NAME `
    --project-name $PROJECT_NAME `
    --name $AGENT_NAME `
    --agent-version $NEXT_VERSION
$start_exit = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($start_exit -ne 0) {
    Write-Host "ERRO: Falha ao iniciar o agente." -ForegroundColor Red
    exit 1
}

Write-Host "  Aguardando agente ficar Running (pode levar ~2 min)..."
$maxWait = 180
$elapsed = 0
while ($elapsed -lt $maxWait) {
    Start-Sleep -Seconds 15
    $elapsed += 15

    $ErrorActionPreference = "SilentlyContinue"
    $statusResult = az cognitiveservices agent status `
        --account-name $FOUNDRY_NAME `
        --project-name $PROJECT_NAME `
        --name $AGENT_NAME `
        --agent-version $NEXT_VERSION `
        -o json 2>$null
    $ErrorActionPreference = "Stop"

    if ($statusResult) {
        $statusJson = $statusResult | ConvertFrom-Json -ErrorAction SilentlyContinue
        $containerStatus = $statusJson.status
        if ($containerStatus -eq "Running") {
            Write-Host "  Agente Running!" -ForegroundColor Green
            break
        }
        Write-Host "  Aguardando... ($($elapsed)s) status=$containerStatus"
    } else {
        Write-Host "  Aguardando... ($($elapsed)s)"
    }
}
Write-Host ""

# -----------------------------------------------------------
# 6. Informacoes finais
# -----------------------------------------------------------
Write-Host "[6/6] Deploy concluido!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para testar manualmente:" -ForegroundColor Cyan
Write-Host "  python ../../test/chat.py --lesson 2"
Write-Host ""
Write-Host "Ou via REST:" -ForegroundColor Cyan
Write-Host "  Endpoint: $PROJECT_ENDPOINT"
Write-Host "  Agent:    $AGENT_NAME v$NEXT_VERSION"
Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host " Deploy concluido!"
Write-Host "======================================" -ForegroundColor Green
