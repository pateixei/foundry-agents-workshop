# Lesson 4 - LangGraph Agent no Azure Container Apps (Connected Agent)

Nesta licao, deployamos um agente LangGraph em **Azure Container Apps (ACA)** -
infraestrutura gerenciada pelo usuario - e o registramos como **Connected Agent**
no Microsoft Foundry Control Plane para governanca e monitoramento.

## Arquitetura

```
Usuario
  |
  v
Foundry AI Gateway (APIM)  <-- proxy, governanca, telemetria
  |
  v
Azure Container Apps
  +-- FastAPI Server (porta 8080)
       +-- LangGraph Agent (ReAct)
            +-- get_stock_price()
            +-- get_market_summary()
            +-- get_exchange_rate()
            |
            v
       Azure OpenAI (gpt-4.1)
```

Diferente das licoes 2-3 (hosted agents), o container roda em ACA e nao na
infraestrutura do Foundry. O Foundry Control Plane atua como proxy e camada
de governanca via AI Gateway (Azure API Management).

## Ferramentas Disponiveis

| Ferramenta | Descricao |
|---|---|
| `get_stock_price` | Consulta preco de acoes (PETR4, VALE3, AAPL, etc.) |
| `get_market_summary` | Resumo dos principais indices (Ibovespa, S&P 500, etc.) |
| `get_exchange_rate` | Taxa de cambio (USD/BRL, EUR/BRL, BTC/USD, etc.) |

> **Nota:** As ferramentas usam dados simulados para fins didaticos.

## Estrutura de Arquivos

```
lesson-4-aca-langgraph/aca-agent/
  main.py              # Agente LangGraph + FastAPI server
  requirements.txt     # Dependencias Python
  Dockerfile           # Container image (porta 8080)
  aca.bicep            # Infraestrutura ACA (Bicep)
  deploy.ps1           # Script de deploy completo
  README.md            # Este arquivo
```

## Como Funciona

### Diferente dos Hosted Agents (Licoes 2-3)

| Aspecto | Hosted Agent | Connected Agent (ACA) |
|---|---|---|
| Infraestrutura | Foundry Capability Host | Azure Container Apps |
| Servidor HTTP | `azure-ai-agentserver-*` (porta 8088) | FastAPI + uvicorn (porta 8080) |
| Registro | `az cognitiveservices agent create` | Foundry portal (Control Plane) |
| Proxy | Responses API nativa | AI Gateway (APIM) |
| Scaling | Foundry managed | ACA (min/max replicas) |
| Managed Identity | MI do projeto Foundry | MI do Container App |
| Monitoramento | Logs do Foundry | ACA logs + Foundry telemetria |

### Servidor FastAPI

O agente expoe uma API REST simples via FastAPI:

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
- `GET /docs` - Swagger UI (documentacao interativa da API)

## Pre-requisitos

- Infraestrutura da pasta `prereq/` ja deployada
- Azure CLI (`az login` realizado)
- Python 3.12+

## Deploy Passo a Passo

### 1. Build da Imagem no ACR

```powershell
az acr build --registry <ACR_NAME> --image aca-lg-agent:v1 --file Dockerfile . --no-logs
```

### 2. Deploy do ACA via Bicep

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

Saidas:
- `acaUrl` - URL publica do agente (https://<app>.<region>.azurecontainerapps.io)
- `acaPrincipalId` - Principal ID da managed identity do ACA

### 3. Permissoes RBAC

O Container App precisa de acesso ao modelo no Foundry:

| Role | Scope | Motivo |
|---|---|---|
| **Cognitive Services OpenAI User** | AI Foundry Account | Para o container chamar o modelo GPT |

```powershell
az role assignment create `
    --assignee-object-id <ACA_PRINCIPAL_ID> `
    --assignee-principal-type ServicePrincipal `
    --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>"
```

> **Nota:** Diferente dos hosted agents, o ACA NAO precisa de AcrPull porque
> as credenciais admin do ACR sao injetadas via Bicep secrets.

### 4. Registrar no Foundry Control Plane

O registro como Connected Agent e feito no **portal do Foundry (new)**:

1. Acesse [ai.azure.com](https://ai.azure.com) (toggle "Foundry new" ativado)
2. **Operate** > **Admin console** > verifique que **AI Gateway** esta configurado
3. **Operate** > **Overview** > **Register agent**
4. Preencha:
   - **Agent URL**: `https://<aca-fqdn>` (URL do ACA)
   - **Protocol**: HTTP
   - **Project**: ag365-prj001
   - **Agent name**: aca-lg-agent
5. Salve. O Foundry gera uma **URL proxy** (via AI Gateway/APIM)
6. Copie a URL proxy em: **Assets** > selecione o agente > **Agent URL**

Apos o registro, o Foundry:
- Cria uma URL proxy: `https://apim-<foundry>.azure-api.net/aca-lg-agent/`
- Roteia requisicoes atraves do AI Gateway
- Coleta telemetria e metricas
- Permite bloquear/desbloquear o agente centralmente

> **Importante:** O Foundry atua como proxy transparente. A autenticacao
> original do endpoint se mantem - se o ACA for publico, o proxy tambem e.

### 5. Testar o agente

```powershell
# Chamada direta ao ACA
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Qual a cotacao da PETR4?"}'

# Via Foundry proxy (apos registro)
curl -X POST https://apim-<foundry>.azure-api.net/aca-lg-agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Me de um resumo do mercado"}'
```

## Deploy Automatizado

```powershell
cd lesson-4-aca-langgraph/aca-agent
.\deploy.ps1
```

O script executa todos os passos acima (exceto o registro no portal,
que e documentado nas instrucoes impressas ao final).

## Troubleshooting

| Erro | Causa | Solucao |
|---|---|---|
| Container em CrashLoopBackOff | MI sem permissao no OpenAI | Atribuir Cognitive Services OpenAI User |
| 401 ao chamar /chat | Ingress nao e externo | Verificar `ingress.external: true` no Bicep |
| Timeout na resposta | Modelo nao acessivel | Verificar AZURE_OPENAI_ENDPOINT e RBAC |
| Health check falhando | Container não iniciou | Verificar logs: `az containerapp logs show` |
| Foundry nao mostra agente | AI Gateway nao configurado | Configurar AI Gateway no Admin console |

## Logs do Container

```powershell
# Logs em tempo real
az containerapp logs show `
    --resource-group rg-ag365sdk `
    --name aca-lg-agent `
    --follow

# Logs do sistema (probes, scaling)
az containerapp logs show `
    --resource-group rg-ag365sdk `
    --name aca-lg-agent `
    --type system
```
