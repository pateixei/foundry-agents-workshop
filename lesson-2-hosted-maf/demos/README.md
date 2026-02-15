# Demo 2: Hosted MAF Agent with Custom Tools

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Overview

This demo showcases a **Hosted Agent** using **Microsoft Agent Framework (MAF)** with custom Python tools. Unlike declarative agents (Demo 1), hosted agents run in your own container and can execute any Python code as tools.

## What This Demonstrates

- ✅ Creating custom Python tools using MAF
- ✅ Building and containerizing MAF agent applications
- ✅ Deploying container images to Azure Container Registry (ACR)
- ✅ Registering hosted agents in Foundry via Azure CLI
- ✅ Debugging agents using container logs and Application Insights
- ✅ Integrating OpenTelemetry for observability

## Architecture

```
┌──────────────────────────────────────────┐
│ Your Code (Python + MAF)                 │
│  ├─> finance_agent.py (Agent definition) │
│  └─> finance_tools.py (Custom tools)     │
└────────────┬─────────────────────────────┘
             │ (containerized)
             ▼
┌──────────────────────────────────────────┐
│ Docker Container in ACR                  │
│  ├─> HTTP Server (port 8088)             │
│  └─> Runs with Managed Identity          │
└────────────┬─────────────────────────────┘
             │ (registered in)
             ▼
┌──────────────────────────────────────────┐
│ Foundry Capability Host                  │
│  ├─> Routes requests to container        │
│  └─> Collects telemetry                  │
└──────────────────────────────────────────┘
```

## Prerequisites

1. **Azure Resources**:
   - Foundry project with model deployed
   - Azure Container Registry (ACR)
   - Application Insights for telemetry

2. **Local Tools**:
   - Docker Desktop installed and running
   - Azure CLI (`az`) with version 2.57+
   - Python 3.10+

3. **Permissions**:
   - ACR Push permission (AcrPush role)
   - Foundry agent deployment permission

## File Structure

```
demo-2-hosted-maf/
├── README.md                    # This file
├── src/
│   ├── main.py                  # Entry point (run function)
│   └── agent/
│       └── finance_agent.py     # MAF agent definition
├── tools/
│   └── finance_tools.py         # Custom tool implementations
├── app.py                       # HTTP server wrapper
├── Dockerfile                   # Container definition
├── requirements.txt             # Python dependencies
├── deploy.ps1                   # Automated deployment script
└── .env.example                 # Environment template
```

## How to Run

### Step 1: Configure Environment

Create `.env` file:
```bash
FOUNDRY_PROJECT_ENDPOINT=https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4.1
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=...;IngestionEndpoint=...
HOSTED_AGENT_VERSION=1
```

### Step 2: Build and Deploy

Run the automated deployment script:
```powershell
.\deploy.ps1
```

The script will:
1. ✅ Build Docker image
2. ✅ Tag image with ACR name
3. ✅ Push image to ACR
4. ✅ Create/update hosted agent in Foundry
5. ✅ Start the agent container
6. ✅ Display agent status and logs

**Expected Output**:
```
🐳 Building Docker image...
✅ Image built successfully

🚀 Pushing to ACR...
✅ Image pushed: acr123.azurecr.io/fin-market-maf:v1

📦 Creating hosted agent in Foundry...
✅ Hosted agent created: fin-market-maf

▶️  Starting agent deployment...
✅ Agent started successfully

📊 Agent Status:
  Name: fin-market-maf
  Version: 1
  Status: Running
  Image: acr123.azurecr.io/fin-market-maf:v1

📋 Recent logs:
  [INFO] Agent server started on port 8088
  [INFO] Tools registered: get_stock_quote, get_exchange_rate, get_market_summary
```

### Step 3: Test the Agent

```powershell
python test_agent.py
```

**Example Interaction**:
```
🤖 Financial Advisor Agent (Hosted MAF)

You: Qual e o preco da PETR4?

Agent: 🔍 Consultando cotacao...
PETR4 (Petrobras PN): R$ 35,42 | Variacao: +1.23% (alta)

Esta informacao e simulada para fins educativos e nao constitui 
recomendacao de investimento.
```

## Custom Tools Implementation

### tools/finance_tools.py

```python
from typing import Annotated
from random import uniform

def get_stock_quote(
    ticker: Annotated[str, "Codigo da acao, ex: PETR4, VALE3, ITUB4"],
) -> str:
    """Retorna a cotacao atual de uma acao."""
    # In production, this would call a real API (B3, Yahoo Finance, etc.)
    prices = {
        "PETR4": ("Petrobras PN", uniform(28.0, 42.0), "BRL"),
        "VALE3": ("Vale ON", uniform(55.0, 80.0), "BRL"),
        "ITUB4": ("Itau Unibanco PN", uniform(25.0, 38.0), "BRL"),
    }
    
    ticker_upper = ticker.upper().strip()
    if ticker_upper in prices:
        name, price, currency = prices[ticker_upper]
        change = uniform(-3.0, 3.0)
        symbol = "R$" if currency == "BRL" else "$"
        direction = "alta" if change > 0 else "queda"
        return (
            f"{ticker_upper} ({name}): {symbol} {price:.2f} | "
            f"Variacao: {change:+.2f}% ({direction})"
        )
    
    return f"Ticker '{ticker_upper}' nao encontrado."


def get_exchange_rate(
    pair: Annotated[str, "Par de moedas, ex: USD/BRL, EUR/BRL"],
) -> str:
    """Retorna a taxa de cambio atual para um par de moedas."""
    rates = {
        "USD/BRL": uniform(4.80, 5.50),
        "EUR/BRL": uniform(5.20, 6.10),
    }
    
    pair_upper = pair.upper().replace(" ", "")
    if pair_upper in rates:
        rate = rates[pair_upper]
        change = uniform(-1.5, 1.5)
        return f"{pair_upper}: {rate:.4f} | Variacao: {change:+.2f}%"
    
    return f"Par '{pair_upper}' nao encontrado."


def get_market_summary(
    market: Annotated[str, "Mercado: brasil, eua, europa"],
) -> str:
    """Retorna um resumo do mercado financeiro selecionado."""
    market_lower = market.lower().strip()
    
    if market_lower in ("brasil", "br"):
        ibov = uniform(115000, 135000)
        ibov_change = uniform(-2.0, 2.0)
        return (
            f"Mercado Brasileiro:\n"
            f"  Ibovespa: {ibov:,.0f} pts ({ibov_change:+.2f}%)\n"
            f"  Taxa Selic: 13.75% a.a.\n"
        )
    
    if market_lower in ("eua", "us"):
        sp500 = uniform(4800, 5500)
        sp_change = uniform(-1.5, 1.5)
        return (
            f"Mercado Norte-Americano:\n"
            f"  S&P 500: {sp500:,.0f} pts ({sp_change:+.2f}%)\n"
        )
    
    return f"Mercado '{market}' nao reconhecido."
```

**Key Points**:
- Functions use type hints with `Annotated` for parameter descriptions
- MAF automatically converts these to tool schemas for the LLM
- No `@tool()` decorator needed -- MAF discovers tools via function registration

### src/agent/finance_agent.py

```python
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential
from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary

TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]

async def create_finance_agent():
    """Creates and returns the MAF finance agent."""
    credential = DefaultAzureCredential()
    
    # When running as hosted agent, agent version already exists in Foundry
    # Passing agent_version prevents MAF from trying to create a conflicting agent
    agent_version = os.environ.get("HOSTED_AGENT_VERSION")
    
    # AzureAIClient automatically handles tool registration and LLM interaction
    client = AzureAIClient(
        endpoint=os.environ["FOUNDRY_PROJECT_ENDPOINT"],
        model=os.environ["FOUNDRY_MODEL_DEPLOYMENT_NAME"],
        credential=credential,
        tools=TOOLS,  # Register custom tools
        agent_version=agent_version,
    )
    
    return client, credential
```

**Key Points**:
- `AzureAIClient` is the core MAF class for building agents
- Tools are registered by passing function references
- Managed Identity (`DefaultAzureCredential`) authenticates to Foundry
- `HOSTED_AGENT_VERSION` prevents agent creation conflicts

## Understanding Hosted Agents vs Declarative

| Feature | Declarative (Demo 1) | Hosted MAF (This Demo) |
|---------|---------------------|------------------------|
| **Tools** | Foundry catalog only | Any Python code |
| **Deployment** | SDK call | Container build + deploy |
| **Modification** | Portal (instant) | Code change + redeploy |
| **Infrastructure** | None (serverless) | Container required |
| **Control** | Limited | Full control |
| **Use Case** | Prototypes | Production with custom logic |
| **Database Access** | ❌ No | ✅ Yes (via Python) |
| **API Calls** | ❌ No | ✅ Yes (via Python) |

## Observability with Application Insights

The agent integrates OpenTelemetry for full observability:

```python
# In src/main.py
from azure.monitor.opentelemetry import configure_azure_monitor

connection_string = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if connection_string:
    configure_azure_monitor(connection_string=connection_string)
```

**View Telemetry**:
1. Azure Portal → Application Insights
2. Transaction Search → Filter by last 30 minutes
3. See traces for:
   - Agent invocations
   - Tool calls
   - Model requests
   - Response times

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"
**Cause**: Docker Desktop not running  
**Fix**:
```powershell
# Windows: Start Docker Desktop from Start Menu
# Verify:
docker ps
```

### Issue: "ACR push failed: unauthorized"
**Cause**: Not logged into ACR  
**Fix**:
```powershell
az acr login --name acr123
```

### Issue: "Hosted agent creation failed: agent already exists"
**Cause**: Agent with same name/version exists  
**Fix**:
```powershell
# Stop and delete existing agent first
az cognitiveservices agent stop --name fin-market-maf --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
# Wait 60 seconds for status to become "Deleted"
az cognitiveservices agent status --name fin-market-maf --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
# Then delete
az cognitiveservices agent delete --name fin-market-maf --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```

### Issue: "Container fails to start: 400 ID cannot be null"
**Cause**: Known MAF issue with agent reference routing  
**Fix**: See context.md for monkey-patch workarounds or use latest MAF version with fixes

### Issue: "No logs showing in Application Insights"
**Cause**: Telemetry propagation delay (2-3 minutes)  
**Fix**: Wait 3-5 minutes after first request, then refresh portal

## Deployment Script Walkthrough

The `deploy.ps1` script automates the full deployment:

```powershell
# 1. Read environment variables
$ACR_NAME = "acr123"
$AGENT_NAME = "fin-market-maf"
$IMAGE_TAG = "v1"

# 2. Build Docker image
docker build -t $AGENT_NAME:$IMAGE_TAG .

# 3. Tag for ACR
docker tag $AGENT_NAME:$IMAGE_TAG $ACR_NAME.azurecr.io/$AGENT_NAME:$IMAGE_TAG

# 4. Push to ACR
az acr login --name $ACR_NAME
docker push $ACR_NAME.azurecr.io/$AGENT_NAME:$IMAGE_TAG

# 5. Create/update hosted agent
az cognitiveservices agent create `
  --name $AGENT_NAME `
  --account-name ai-foundry001 `
  --project-name ag365-prj001 `
  --image "$ACR_NAME.azurecr.io/$AGENT_NAME:$IMAGE_TAG" `
  --env "FOUNDRY_PROJECT_ENDPOINT=$FOUNDRY_ENDPOINT" `
       "FOUNDRY_MODEL_DEPLOYMENT_NAME=$MODEL_NAME" `
       "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS" `
       "HOSTED_AGENT_VERSION=1"

# 6. Start the agent
az cognitiveservices agent start `
  --name $AGENT_NAME `
  --agent-version 1 `
  --account-name ai-foundry001 `
  --project-name ag365-prj001

# 7. Check status
az cognitiveservices agent status --name $AGENT_NAME --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001

# 8. View logs
az cognitiveservices agent logs show --name $AGENT_NAME --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001 --tail 50
```

## Next Steps

- **Demo 3**: LangGraph hosted agent for migrating AWS workloads
- **Demo 4**: ACA deployment for infrastructure control
- **Demo 5**: Agent 365 SDK for M365 integration

## Additional Resources

- [Microsoft Agent Framework Docs](https://learn.microsoft.com/azure/ai-foundry/agent-framework/)
- [AzureAIClient API Reference](https://learn.microsoft.com/python/api/agent-framework/)
- [Hosted Agent Architecture](https://learn.microsoft.com/azure/ai-foundry/concepts/hosted-agents)

---

**Demo Level**: Intermediate  
**Estimated Time**: 30-40 minutes  
**Prerequisites**: Docker, ACR, Foundry project with model
