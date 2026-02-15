# Lesson 4 - LangGraph Agent on Azure Container Apps (Connected Agent)

In this lesson, we deploy a LangGraph agent on **Azure Container Apps (ACA)** -
user-managed infrastructure - and register it as a **Connected Agent**
in the Microsoft Foundry Control Plane for governance and monitoring.

## Architecture

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

Unlike lessons 2-3 (hosted agents), the container runs on ACA and not on
Foundry infrastructure. The Foundry Control Plane acts as a proxy and
governance layer via AI Gateway (Azure API Management).

## Available Tools

| Tool | Description |
|---|---|
| `get_stock_price` | Query stock prices (PETR4, VALE3, AAPL, etc.) |
| `get_market_summary` | Summary of major indices (Ibovespa, S&P 500, etc.) |
| `get_exchange_rate` | Exchange rates (USD/BRL, EUR/BRL, BTC/USD, etc.) |

> **Note:** The tools use simulated data for educational purposes.

## File Structure

```
lesson-4-aca-langgraph/solution/
  main.py              # LangGraph Agent + FastAPI server
  requirements.txt     # Python dependencies
  Dockerfile           # Container image (port 8080)
  aca.bicep            # ACA infrastructure (Bicep)
  deploy.ps1           # Complete deployment script
  README.md            # This file
```

## How It Works

### Different from Hosted Agents (Lessons 2-3)

| Aspect | Hosted Agent | Connected Agent (ACA) |
|---|---|---|
| Infrastructure | Foundry Capability Host | Azure Container Apps |
| HTTP Server | `azure-ai-agentserver-*` (port 8088) | FastAPI + uvicorn (port 8080) |
| Registration | `az cognitiveservices agent create` | Foundry portal (Control Plane) |
| Proxy | Native Responses API | AI Gateway (APIM) |
| Scaling | Foundry managed | ACA (min/max replicas) |
| Managed Identity | Foundry project MI | Container App MI |
| Monitoring | Foundry logs | ACA logs + Foundry telemetry |

### FastAPI Server

The agent exposes a simple REST API via FastAPI:

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
- `POST /chat` - Send message, return agent response
- `GET /health` - Health check for ACA probes
- `GET /docs` - Swagger UI (interactive API documentation)

## Prerequisites

- Infrastructure from `prereq/` folder already deployed
- Azure CLI (`az login` completed)
- Python 3.12+

## Step-by-Step Deployment

### 1. Build Image in ACR

```powershell
az acr build --registry <ACR_NAME> --image aca-lg-agent:v1 --file Dockerfile . --no-logs
```

### 2. Deploy ACA via Bicep

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

Outputs:
- `acaUrl` - Public URL of the agent (https://<app>.<region>.azurecontainerapps.io)
- `acaPrincipalId` - Principal ID of the ACA managed identity

### 3. RBAC Permissions

The Container App needs access to the model in Foundry:

| Role | Scope | Reason |
|---|---|---|
| **Cognitive Services OpenAI User** | AI Foundry Account | For the container to call the GPT model |

```powershell
az role assignment create `
    --assignee-object-id <ACA_PRINCIPAL_ID> `
    --assignee-principal-type ServicePrincipal `
    --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>"
```

> **Note:** Unlike hosted agents, ACA does NOT need AcrPull because
> ACR admin credentials are injected via Bicep secrets.

### 4. Register in Foundry Control Plane

Registration as a Connected Agent is done in the **Foundry portal (new)**:

1. Access [ai.azure.com](https://ai.azure.com) (toggle "Foundry new" enabled)
2. **Operate** > **Admin console** > verify that **AI Gateway** is configured
3. **Operate** > **Overview** > **Register agent**
4. Fill in:
   - **Agent URL**: `https://<aca-fqdn>` (ACA URL)
   - **Protocol**: HTTP
   - **Project**: ag365-prj001
   - **Agent name**: aca-lg-agent
5. Save. Foundry generates a **proxy URL** (via AI Gateway/APIM)
6. Copy the proxy URL in: **Assets** > select the agent > **Agent URL**

After registration, Foundry:
- Creates a proxy URL: `https://apim-<foundry>.azure-api.net/aca-lg-agent/`
- Routes requests through the AI Gateway
- Collects telemetry and metrics
- Allows centrally blocking/unblocking the agent

> **Important:** Foundry acts as a transparent proxy. The original
> endpoint authentication is maintained - if ACA is public, the proxy is too.

### 5. Test the agent

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

## Automated Deployment

```powershell
cd lesson-4-aca-langgraph/aca-agent
.\deploy.ps1
```

The script executes all the above steps (except portal registration,
which is documented in the instructions printed at the end).

## Troubleshooting

| Error | Cause | Solution |
|---|---|---|
| Container in CrashLoopBackOff | MI without OpenAI permission | Assign Cognitive Services OpenAI User |
| 401 when calling /chat | Ingress is not external | Verify `ingress.external: true` in Bicep |
| Timeout in response | Model not accessible | Verify AZURE_OPENAI_ENDPOINT and RBAC |
| Health check failing | Container did not start | Check logs: `az containerapp logs show` |
| Foundry does not show agent | AI Gateway not configured | Configure AI Gateway in Admin console |

## Container Logs

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
