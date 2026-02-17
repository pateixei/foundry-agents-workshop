# deploy.ps1 - Deploy do Hosted Agent MAF no Azure AI Foundry
# Uso: .\deploy.ps1
#
# Pre-requisitos:
#   - Infraestrutura do prereq/ ja deployada (main.bicep)
#     Isso inclui: ACR, Foundry account/project, Capability Host e Storage Account
#   - az login realizado
#   - Python 3.10+ com azure-ai-projects e azure-identity instalados
#     (pip install azure-ai-projects azure-identity)
#
# O que este script faz:
#   1. Obtem outputs do Bicep (ACR, endpoint, model, nomes de recursos)
#      e verifica se o Capability Host esta provisionado
#   2. Faz build da imagem no ACR (cloud build, --no-logs para Windows)
#   3. Atribui roles RBAC a managed identity do projeto:
#      - AcrPull no Container Registry
#      - Cognitive Services OpenAI User no Foundry account
#   4. Registra o hosted agent via Python SDK (azure-ai-projects)
#      O servico auto-provisiona o container apos criacao
#   5. Aguarda o agente ficar Running e executa teste rapido

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Lesson 2 - MAF Hosted Agent"
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

# Endpoint OpenAI do Foundry (para o container chamar o modelo)
$OPENAI_ENDPOINT = "https://$FOUNDRY_NAME.openai.azure.com/"

Write-Host "  ACR:             $ACR_LOGIN"
Write-Host "  Endpoint:        $PROJECT_ENDPOINT"
Write-Host "  OpenAI Endpoint: $OPENAI_ENDPOINT"
Write-Host "  Model:           $MODEL_DEPLOYMENT"
Write-Host "  Foundry:         $FOUNDRY_NAME"
Write-Host "  Project:         $PROJECT_NAME"

# Verificar se o Capability Host esta provisionado (necessario para hosted agents)
$ErrorActionPreference = "SilentlyContinue"
$capHostStatus = az rest --method GET `
    --uri "https://management.azure.com/subscriptions/$SUBSCRIPTION/resourceGroups/$RG/providers/Microsoft.CognitiveServices/accounts/$FOUNDRY_NAME/capabilityHosts/default?api-version=2025-04-01-preview" `
    --query "properties.provisioningState" `
    -o tsv 2>$null
$ErrorActionPreference = "Stop"

if ($capHostStatus -eq "Succeeded") {
    Write-Host "  Capability Host: OK" -ForegroundColor Green
} else {
    Write-Host "  ERRO: Capability Host nao encontrado ou nao provisionado (status=$capHostStatus)." -ForegroundColor Red
    Write-Host "  Execute 'prereq/deploy.ps1' primeiro para provisionar a infraestrutura completa." -ForegroundColor Red
    Write-Host "  O Capability Host e obrigatorio para hosted agents (lessons 2 e 3)." -ForegroundColor Red
    exit 1
}
Write-Host ""

# -----------------------------------------------------------
# 2. Build da imagem no ACR
#    Nota: --no-logs evita UnicodeEncodeError (colorama/cp1252)
#    no PowerShell 5.1 no Windows.
# -----------------------------------------------------------
Write-Host "[2/5] Construindo imagem no ACR..." -ForegroundColor Yellow

$AGENT_NAME = "fin-market-agent"
$IMAGE_TAG = "$($AGENT_NAME):v1"
$IMAGE_FULL = "$ACR_LOGIN/$IMAGE_TAG"

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
Write-Host "[3/5] Configurando permissoes RBAC..." -ForegroundColor Yellow

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
# 4. Registrar hosted agent via Python SDK
#
#    Usa azure-ai-projects para criar o hosted agent.
#    O servico auto-provisiona o container apos a criacao --
#    nao e necessario um "start" separado.
#
#    Se o agente ja existir com containers ativos, o script
#    reutiliza a versao existente (idempotente).
#    Nota: create_version() NAO auto-provisiona containers.
#    Apenas agents.create() dispara o provisionamento.
#
#    Env vars injetadas no container:
#    - FOUNDRY_PROJECT_ENDPOINT: endpoint do projeto Foundry
#    - FOUNDRY_MODEL_DEPLOYMENT_NAME: nome do deployment GPT
#    - AZURE_OPENAI_ENDPOINT: endpoint OpenAI do Foundry
# -----------------------------------------------------------
Write-Host "[4/5] Registrando hosted agent via Python SDK..." -ForegroundColor Yellow

$createAgentPy = @"
import json, sys
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    ImageBasedHostedAgentDefinition,
    ProtocolVersionRecord,
)
from azure.identity import DefaultAzureCredential

endpoint      = '$PROJECT_ENDPOINT'
acr_image     = '$IMAGE_FULL'
model         = '$MODEL_DEPLOYMENT'
openai_ep     = '$OPENAI_ENDPOINT'
agent_name    = '$AGENT_NAME'

cred = DefaultAzureCredential()
client = AIProjectClient(endpoint=endpoint, credential=cred)

# --- Verifica se o agente ja existe ---
agent_exists = False
try:
    existing = client.agents.get(agent_name)
    agent_exists = True
    # Obter versao do agente existente
    latest = existing.as_dict().get('versions', {}).get('latest', {})
    version = latest.get('version', '1')
except Exception:
    pass

if agent_exists:
    print(f'  Agente {agent_name} ja existe (v{version}).')
    print(f'  Reutilizando versao existente (idempotente).')
    print(f'  Para redeployar com codigo novo, delete o agente no portal')
    print(f'  do Foundry e execute novamente.')
else:
    # Criar agente pela primeira vez (auto-provisiona container)
    print(f'  Criando hosted agent {agent_name}...')
    print(f'    Imagem: {acr_image}')
    print(f'    Model:  {model}')

    definition = ImageBasedHostedAgentDefinition(
        image=acr_image,
        container_protocol_versions=[
            ProtocolVersionRecord(protocol='responses', version='v1')
        ],
        cpu='1',
        memory='2Gi',
        environment_variables={
            'FOUNDRY_PROJECT_ENDPOINT': endpoint,
            'FOUNDRY_MODEL_DEPLOYMENT_NAME': model,
            'AZURE_OPENAI_ENDPOINT': openai_ep,
        },
    )

    agent = client.agents.create(
        name=agent_name,
        definition=definition,
        description='Agente de mercado financeiro - hosted MAF agent',
    )

    version = getattr(agent, 'version', None)
    if not version:
        latest = agent.as_dict().get('versions', {}).get('latest', {})
        version = latest.get('version', '1')
    print(f'  Agente criado! Versao: {version}')

# --- Resultado em JSON para o PowerShell ---
print('AGENT_RESULT:' + json.dumps({'name': agent_name, 'version': str(version)}))
"@

$agentOutput = python3 -c $createAgentPy 2>&1
$agent_exit = $LASTEXITCODE

# Exibir output do Python
foreach ($line in $agentOutput) {
    if ($line -notmatch '^AGENT_RESULT:') {
        Write-Host $line
    }
}

if ($agent_exit -ne 0) {
    Write-Host "ERRO: Falha ao criar hosted agent via Python SDK." -ForegroundColor Red
    Write-Host "  Verifique se azure-ai-projects e azure-identity estao instalados:" -ForegroundColor Red
    Write-Host "  pip install azure-ai-projects azure-identity" -ForegroundColor Red
    exit 1
}

# Extrair resultado JSON
$resultLine = ($agentOutput | Where-Object { $_ -match '^AGENT_RESULT:' }) -replace '^AGENT_RESULT:',''
if ($resultLine) {
    $agentResult = $resultLine | ConvertFrom-Json
    $NEXT_VERSION = $agentResult.version
} else {
    $NEXT_VERSION = "1"
}

Write-Host "  Agente $AGENT_NAME v$NEXT_VERSION registrado" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------
# 5. Aguardar provisionamento e testar
#
#    O servico auto-provisiona o container apos agents.create().
#    Verificamos chamando o agente via Responses API ate
#    obter uma resposta valida (indica que o container esta
#    Running e aceitando requests).
# -----------------------------------------------------------
Write-Host "[5/5] Aguardando agente ficar pronto (ate ~3 min)..." -ForegroundColor Yellow

$maxWait = 180
$elapsed = 0
$agentReady = $false

while ($elapsed -lt $maxWait) {
    Start-Sleep -Seconds 15
    $elapsed += 15

    $testResult = python3 -c @"
import sys
try:
    from azure.ai.projects import AIProjectClient
    from azure.identity import DefaultAzureCredential
    c = AIProjectClient(endpoint='$PROJECT_ENDPOINT', credential=DefaultAzureCredential())
    openai = c.get_openai_client()
    r = openai.responses.create(
        extra_body={'agent': {'name': '$AGENT_NAME', 'version': '$NEXT_VERSION', 'type': 'agent_reference'}},
        input='ping',
    )
    if r.output_text:
        print('READY')
    else:
        print('WAITING')
except Exception as e:
    msg = str(e)
    if 'not running' in msg.lower() or 'not found' in msg.lower():
        print('WAITING')
    else:
        print(f'ERROR:{msg}')
"@ 2>$null

    if ($testResult -eq "READY") {
        $agentReady = $true
        Write-Host "  Agente Running!" -ForegroundColor Green
        break
    }
    elseif ($testResult -match '^ERROR:') {
        $errMsg = $testResult -replace '^ERROR:',''
        Write-Host "  Aguardando... ($($elapsed)s) erro=$errMsg" -ForegroundColor Yellow
    }
    else {
        Write-Host "  Aguardando... ($($elapsed)s) container provisionando..."
    }
}

if (-not $agentReady) {
    Write-Host "  Timeout aguardando agente. Verifique o portal do Foundry." -ForegroundColor Yellow
    Write-Host "  O agente foi criado mas pode demorar mais para provisionar." -ForegroundColor Yellow
}
Write-Host ""

# -----------------------------------------------------------
# Informacoes finais
# -----------------------------------------------------------
Write-Host "Deploy concluido!" -ForegroundColor Yellow
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
