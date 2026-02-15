# Lab 2: Build Custom Tools with Microsoft Agent Framework

## Objective

Implement custom Python tools for a hosted agent using Microsoft Agent Framework (MAF). The agent will execute real business logic: call external APIs, process data, and perform calculations—capabilities not possible with declarative agents.

## Scenario

Your financial services team needs an agent that can:
- Query live stock prices from an API
- Calculate currency conversions with historical data
- Analyze portfolio performance metrics
- Access internal database for customer portfolios (simulated)

This requires **custom Python code execution**, so you'll build a **Hosted Agent with MAF**.

## Learning Outcomes

- Implement custom Python tools for MAF agents
- Containerize MAF applications with Docker
- Deploy containers to Azure Container Registry (ACR)
- Register hosted agents in Foundry via Azure CLI
- Debug agents using container logs and Application Insights
- Understand MAF architecture and tool calling patterns

## Prerequisites

- [x] Lab 1 completed (declarative agent understanding)
- [x] Docker Desktop installed and running
- [x] Azure CLI 2.57+ with `az cognitiveservices agent` commands
- [x] ACR created and accessible
- [x] Application Insights connection string

## Tasks

### Task 1: Implement Custom Tools (25 minutes)

Navigate to `starter/tools/` and implement three financial tools:

**1.1 - `get_stock_quote(ticker: str) -> dict`**

Requirements:
- Accept ticker symbol (e.g., "PETR4", "AAPL")
- Return JSON with: symbol, price, currency, change_percent
- For workshop: simulate data (in production, call real API)

**Hints**:
- Use `Annotated[str, "description"]` for type hints
- Return structured dict (MAF converts to JSON for LLM)
- Include error handling for invalid tickers

**1.2 - `calculate_portfolio_value(holdings: list[dict]) -> dict`**

Requirements:
- Accept list of holdings: `[{"ticker": "PETR4", "quantity": 100}, ...]`
- Calculate total value using `get_stock_quote` for each ticker
- Return: total_value, by_symbol breakdown, total_gain_percent

**1.3 - `get_market_sentiment(market: str) -> dict`**

Requirements:
- Accept market name: "brazil", "usa", "europe"
- Return structured summary: indices, sentiment, trend
- Include narrative text suitable for agent response

**Success Criteria**:
- ✅ All three functions implemented with type hints
- ✅ Functions return structured data (dicts)
- ✅ Error handling for invalid inputs
- ✅ Docstrings explain purpose and parameters

### Task 2: Create MAF Agent (20 minutes)

Open `starter/src/agent/finance_agent.py` and complete:

**2.1 - Import required MAF modules**
```python
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential
```

**2.2 - Define system prompt**

Create a comprehensive system prompt that:
- Defines agent role (financial advisor)
- Explains tool capabilities
- Sets response format and tone
- Includes disclaimers

**2.3 - Implement `create_finance_agent()` function**

```python
async def create_finance_agent():
    """Creates and returns MAF finance agent."""
    project_endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    model_deployment = os.environ["FOUNDRY_MODEL_DEPLOYMENT_NAME"]
    credential = DefaultAzureCredential()
    
    # TODO: Import tools from tools.finance_tools
    # TODO: Create AzureAIClient with tools
    # TODO: Return client and credential
```

**Hints**:
- Pass tools list to `AzureAIClient(tools=[...])`
- Include `agent_version` from environment for hosted agent compatibility
- Use `DefaultAzureCredential` for Managed Identity auth

**Success Criteria**:
- ✅ Agent creation function is async
- ✅ Tools are properly registered
- ✅ Environment variables used correctly
- ✅ Credentials managed properly

### Task 3: Implement Entry Point (10 minutes)

Open `starter/src/main.py` and implement:

```python
async def run(user_input: str, thread_id: Optional[str] = None) -> str:
    """Main entry point called by agent server."""
    # TODO: Create agent
    # TODO: Handle thread (new or existing)
    # TODO: Process user input
    # TODO: Return response
```

Requirements:
- Accept `user_input` (string) and optional `thread_id`
- Create new thread if `thread_id` is None
- Stream agent responses
- Handle errors gracefully

**Success Criteria**:
- ✅ Function accepts and processes user input
- ✅ Thread management works correctly
- ✅ Responses are streamed and concatenated
- ✅ Credentials are closed properly (async context manager)

### Task 4: Configure Observability (10 minutes)

Add OpenTelemetry integration:

```python
from azure.monitor.opentelemetry import configure_azure_monitor
connection_string = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if connection_string:
    configure_azure_monitor(connection_string=connection_string)
```

Requirements:
- Configure before any agent operations
- Use environment variable for connection string
- Add spans for agent invocations and tool calls

**Success Criteria**:
- ✅ Application Insights configured
- ✅ Telemetry captured for agent operations

### Task 5: Build and Deploy Container (20 minutes)

**5.1 - Review Dockerfile**

Ensure `starter/Dockerfile` is configured:
- Base image: `python:3.11-slim`
- Working directory: `/app`
- Expose port: `8088`
- CMD: Run agentserver with MAF adapter

**5.2 - Build container**

```powershell
docker build -t fin-market-maf:v1 .
```

**5.3 - Push to ACR**

```powershell
az acr login --name YOUR-ACR
docker tag fin-market-maf:v1 YOUR-ACR.azurecr.io/fin-market-maf:v1
docker push YOUR-ACR.azurecr.io/fin-market-maf:v1
```

**5.4 - Deploy to Foundry**

```powershell
az cognitiveservices agent create \
  --name fin-market-maf \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-FOUNDRY-PROJECT \
  --image "YOUR-ACR.azurecr.io/fin-market-maf:v1" \
  --env "FOUNDRY_PROJECT_ENDPOINT=..." \
       "FOUNDRY_MODEL_DEPLOYMENT_NAME=..." \
       "APPLICATIONINSIGHTS_CONNECTION_STRING=..." \
       "HOSTED_AGENT_VERSION=1"

az cognitiveservices agent start \
  --name fin-market-maf \
  --agent-version 1 \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-FOUNDRY-PROJECT
```

**Success Criteria**:
- ✅ Container built without errors
- ✅ Image pushed to ACR successfully
- ✅ Hosted agent created in Foundry
- ✅ Agent status shows "Running"

### Task 6: Test Custom Tools (15 minutes)

**6.1 - Test individual tools**

```powershell
python test_tools.py
```

Verify outputs for:
- Single stock quote
- Portfolio calculation with multiple holdings
- Market sentiment for different regions

**6.2 - Test end-to-end agent**

```powershell
python test_agent.py
```

Test questions:
1. "Qual é o preço da PETR4?"
2. "Calcule o valor de um portfólio com 100 PETR4 e 50 VALE3"
3. "Como está o sentimento do mercado brasileiro hoje?"

**Expected Behavior**:
- Agent calls appropriate tools automatically
- Tool responses are incorporated into natural language answers
- Multiple tool calls are chained when needed (e.g., portfolio calculation calls get_stock_quote for each ticker)

**Success Criteria**:
- ✅ Agent invokes correct tools for each question
- ✅ Tool outputs are processed correctly
- ✅ Responses are coherent and accurate
- ✅ Disclaimers are included

### Task 7: Debug with Logs and Telemetry (10 minutes)

**7.1 - View container logs**

```powershell
az cognitiveservices agent logs show \
  --name fin-market-maf \
  --agent-version 1 \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-FOUNDRY-PROJECT \
  --tail 50
```

Look for:
- Agent server startup confirmation
- Tool registration messages
- Request/response traces

**7.2 - Check Application Insights**

1. Navigate to Azure Portal → Application Insights
2. Go to **Transaction Search**
3. Filter last 30 minutes
4. Inspect:
   - `agent_run` spans
   - Tool execution spans
   - Model request spans

**Success Criteria**:
- ✅ Logs show successful agent startup
- ✅ Tool registrations confirmed
- ✅ Telemetry visible in Application Insights
- ✅ Performance metrics available

## Deliverables

- [x] Three custom tools implemented and tested
- [x] MAF agent configured and working
- [x] Container built and deployed to ACR
- [x] Hosted agent running in Foundry
- [x] End-to-end tests passing
- [x] Telemetry configured and visible

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **Tool Implementation** | 30 pts | All three tools functional with proper type hints |
| **MAF Agent Setup** | 20 pts | Agent configured correctly with tools |
| **Deployment** | 20 pts | Container built and deployed to Foundry |
| **Testing** | 15 pts | End-to-end tests demonstrate tool calling |
| **Observability** | 10 pts | Logs and telemetry configured |
| **Code Quality** | 5 pts | Clean, documented, error handling |

**Total**: 100 points

## Troubleshooting

### "Docker build failed: pip install error"
- Ensure `requirements.txt` has correct package versions
- Check network connectivity for PyPI access

### "ACR authorization failed"
- Run `az acr login --name YOUR-ACR`
- Verify you have AcrPush role

### "Hosted agent creation failed: agent already exists"
- Stop existing agent first
- Wait for "Deleted" status before re-creating
- Or use different agent name/version

### "Tool not found by agent"
- Verify tools are passed to `AzureAIClient(tools=[...])`
- Check function names match (case-sensitive)
- Ensure functions have docstrings (used by LLM for tool discovery)

### "No telemetry in Application Insights"
- Wait 2-3 minutes for propagation
- Verify connection string is correct
- Check logs for OpenTelemetry configuration messages

## Time Estimate

- Task 1: 25 minutes
- Task 2: 20 minutes
- Task 3: 10 minutes
- Task 4: 10 minutes
- Task 5: 20 minutes
- Task 6: 15 minutes
- Task 7: 10 minutes
- **Total**: 110 minutes

## Next Steps

- **Lab 3**: Migrate LangGraph agent from AWS to Azure
- Compare MAF vs LangGraph architectures
- Understand when to use each framework

---

**Difficulty**: Intermediate  
**Prerequisites**: Python, Docker basics, Lab 1 completed  
**Estimated Time**: 110 minutes
