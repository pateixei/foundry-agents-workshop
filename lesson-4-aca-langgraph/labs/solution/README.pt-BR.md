# Lição 4 - Agente LangGraph no Azure Container Apps (Connected Agent)

> 🇺🇸 **[Read in English](README.md)**

Nesta lição, implantamos um agente LangGraph no **Azure Container Apps (ACA)** —
infraestrutura gerenciada pelo usuário — e o registramos como um **Connected Agent**
no Control Plane do Microsoft Foundry para governança e monitoramento.

## Arquitetura

```
User
  |
  v
Foundry AI Gateway (APIM)  <-- proxy, governance, telemetry
  |
  v
Azure Container Apps
  +-- FastAPI Server (port 8080)
       +-- LangGraph Agent (ReAct)
            +-- get_stock_price()
            +-- get_market_summary()
            +-- get_exchange_rate()
            |
            v
       Azure OpenAI (gpt-4.1)
```

Diferente das lições 2-3 (hosted agents), o contêiner roda no ACA e não na
infraestrutura do Foundry. O Control Plane do Foundry atua como proxy e
camada de governança via AI Gateway (Azure API Management).

## Tools Disponíveis

| Tool | Descrição |
|---|---|
| `get_stock_price` | Consulta preços de ações (PETR4, VALE3, AAPL, etc.) |
| `get_market_summary` | Resumo dos principais índices (Ibovespa, S&P 500, etc.) |
| `get_exchange_rate` | Taxas de câmbio (USD/BRL, EUR/BRL, BTC/USD, etc.) |

> **Nota:** As tools utilizam dados simulados para fins educacionais.

## Estrutura de Arquivos

```
lesson-4-aca-langgraph/labs/solution/
  main.py              # LangGraph Agent + FastAPI server
  requirements.txt     # Python dependencies
  Dockerfile           # Container image (port 8080)
  aca.bicep            # ACA infrastructure (Bicep)
  deploy.ps1           # Complete deployment script
  README.md            # This file
```

## Como Funciona

### Diferenças em Relação aos Hosted Agents (Lições 2-3)

| Aspecto | Hosted Agent | Connected Agent (ACA) |
|---|---|---|
| Infraestrutura | Foundry Capability Host | Azure Container Apps |
| Servidor HTTP | `azure-ai-agentserver-*` (porta 8088) | FastAPI + uvicorn (porta 8080) |
| Registro | `az cognitiveservices agent create` | Portal do Foundry (Control Plane) |
| Proxy | API de Responses nativa | AI Gateway (APIM) |
| Escalabilidade | Gerenciado pelo Foundry | ACA (réplicas mín/máx) |
| Managed Identity | MI do projeto Foundry | MI do Container App |
| Monitoramento | Logs do Foundry | Logs do ACA + telemetria do Foundry |

### Servidor FastAPI

O agente expõe uma API REST simples via FastAPI:

```python
from fastapi import FastAPI

app = FastAPI()

@app.post("/chat")
def chat(req: ChatRequest):
    result = agent.invoke({"messages": [HumanMessage(content=req.message)]})
    return ChatResponse(response=result)

@app.get("/health")
async def health():
    return {"status": "ok"}
```

Endpoints:
- `POST /chat` - Envia mensagem, retorna resposta do agente
- `GET /health` - Health check para probes do ACA
- `GET /docs` - Swagger UI (documentação interativa da API)

## Pré-requisitos

- Infraestrutura da pasta `prereq/` já implantada
- Azure CLI (`az login` completado)
- Python 3.12+

## Passo a Passo da Implantação

### 1. Construir Imagem no ACR

```powershell
az acr build --registry <ACR_NAME> --image aca-lg-agent:v1 --file Dockerfile . --no-logs
```

### 2. Implantar ACA via Bicep

```powershell
az deployment group create `
    --resource-group rg-ag365sdk `
    --template-file aca.bicep `
    --parameters `
        logAnalyticsName=log-ai001 `
        acrName=acr123 `
        containerImage=acr123.azurecr.io/aca-lg-agent:v1 `
        projectEndpoint=https://ai-foundry001.services.ai.azure.com/api/projects/ag365-prj001 `
        modelDeployment=gpt-4.1 `
        openaiEndpoint=https://ai-foundry001.openai.azure.com/
```

Saídas:
- `acaUrl` - URL pública do agente (https://<app>.<region>.azurecontainerapps.io)
- `acaPrincipalId` - Principal ID da managed identity do ACA

### 3. Permissões RBAC

O Container App precisa de acesso ao modelo no Foundry:

| Role | Escopo | Motivo |
|---|---|---|
| **Cognitive Services OpenAI User** | AI Foundry Account | Para o contêiner chamar o modelo GPT |

```powershell
az role assignment create `
    --assignee-object-id <ACA_PRINCIPAL_ID> `
    --assignee-principal-type ServicePrincipal `
    --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>"
```

> **Nota:** Diferente dos hosted agents, o ACA NÃO precisa de AcrPull porque
> as credenciais de admin do ACR são injetadas via secrets no Bicep.

### 4. Registrar no Control Plane do Foundry

O registro como Connected Agent é feito no **portal do Foundry (novo)**:

1. Acesse [ai.azure.com](https://ai.azure.com) (toggle "Foundry new" habilitado)
2. **Operate** > **Admin console** > verifique que o **AI Gateway** está configurado
3. **Operate** > **Overview** > **Register agent**
4. Preencha:
   - **Agent URL**: `https://<aca-fqdn>` (URL do ACA)
   - **Protocol**: HTTP
   - **Project**: ag365-prj001
   - **Agent name**: aca-lg-agent
5. Salve. O Foundry gera uma **proxy URL** (via AI Gateway/APIM)
6. Copie a proxy URL em: **Assets** > selecione o agente > **Agent URL**

Após o registro, o Foundry:
- Cria uma proxy URL: `https://apim-<foundry>.azure-api.net/aca-lg-agent/`
- Roteia requisições através do AI Gateway
- Coleta telemetria e métricas
- Permite bloquear/desbloquear o agente centralmente

> **Importante:** O Foundry atua como proxy transparente. A autenticação
> do endpoint original é mantida — se o ACA é público, o proxy também é.

### 5. Testar o agente

```powershell
# Direct call to ACA
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the PETR4 quote?"}'

# Via Foundry proxy (after registration)
curl -X POST https://apim-<foundry>.azure-api.net/aca-lg-agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Give me a market summary"}'
```

## Implantação Automatizada

```powershell
cd lesson-4-aca-langgraph/aca-agent
.\deploy.ps1
```

O script executa todos os passos acima (exceto o registro no portal,
que está documentado nas instruções impressas ao final).

## Resolução de Problemas

| Erro | Causa | Solução |
|---|---|---|
| Contêiner em CrashLoopBackOff | MI sem permissão OpenAI | Atribuir Cognitive Services OpenAI User |
| 401 ao chamar /chat | Ingress não é externo | Verificar `ingress.external: true` no Bicep |
| Timeout na resposta | Modelo não acessível | Verificar AZURE_OPENAI_ENDPOINT e RBAC |
| Health check falhando | Contêiner não iniciou | Checar logs: `az containerapp logs show` |
| Foundry não mostra agente | AI Gateway não configurado | Configurar AI Gateway no Admin console |

## Logs do Contêiner

```powershell
# Real-time logs
az containerapp logs show `
    --resource-group rg-ag365sdk `
    --name aca-lg-agent `
    --follow

# System logs (probes, scaling)
az containerapp logs show `
    --resource-group rg-ag365sdk `
    --name aca-lg-agent `
    --type system
```
