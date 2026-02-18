# Lab 5: A365 SDK Integration — Bot Framework, Adaptive Cards & Observability

> 🇧🇷 **[Leia em Português (pt-BR)](LAB-STATEMENT.pt-BR.md)**

## Objective

Enhance the LangGraph agent (from Lab 4) with the **Microsoft Agent 365 SDK**: add Bot Framework messaging support, Adaptive Cards for rich financial data display, and Azure Monitor / OpenTelemetry observability — then redeploy to ACA.

## Scenario

Your financial advisor agent is running in ACA and registered in Foundry. The business now requires:
- Bot Framework `/api/messages` endpoint so the agent can talk to Microsoft Teams and Outlook
- Adaptive Cards for professionally formatted financial responses
- Distributed tracing via Application Insights for production observability

> **Note**: A365 CLI setup, Entra ID app registration, and Agent Blueprint steps are covered in **Lab 6**. This lab focuses exclusively on the SDK and code changes.

## Learning Outcomes

- Implement the Bot Framework Activity Protocol (`/api/messages` endpoint)
- Create Adaptive Cards for financial data visualization
- Integrate Azure Monitor OpenTelemetry for distributed tracing
- Instrument individual tool functions with custom spans
- Redeploy an updated container image to ACA (no re-registration needed)
- Observe traces in Application Insights and Foundry portal

## Prerequisites

- [x] Lab 4 completed (ACA-deployed agent running and registered in Foundry)
- [x] Application Insights resource provisioned (created in `prereq/`)
- [x] `APPLICATIONINSIGHTS_CONNECTION_STRING` available (from `prereq/` outputs)
- [x] Python 3.11+ and Docker available locally

## Tasks

### Task 1: Add OpenTelemetry Observability (20 minutes)

**1.1 - Update `requirements.txt`**

Add the following to `starter/requirements.txt`:
```txt
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
```

**1.2 - Configure Azure Monitor in `main.py`**

```python
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

app = FastAPI()

# Configure Application Insights telemetry
app_insights_cs = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if app_insights_cs:
    configure_azure_monitor(connection_string=app_insights_cs)

FastAPIInstrumentor.instrument_app(app)  # Auto-trace all HTTP endpoints
```

**1.3 - Instrument tool functions with custom spans**

```python
tracer = trace.get_tracer(__name__)

async def get_stock_price(ticker: str) -> dict:
    with tracer.start_as_current_span("get_stock_price") as span:
        span.set_attribute("ticker", ticker)
        try:
            result = await _fetch_stock_data(ticker)
            span.set_attribute("price", result["price"])
            span.set_status(trace.Status(trace.StatusCode.OK))
            return result
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            raise
```

Apply the same pattern to each LangGraph tool (`get_exchange_rate`, `get_market_summary`, etc.).

**Success Criteria**:
- ✅ `configure_azure_monitor()` called at startup
- ✅ FastAPI endpoints auto-instrumented
- ✅ Each tool function wrapped in a custom span
- ✅ Span attributes include relevant context (ticker, amount, etc.)

---

### Task 2: Implement Bot Framework `/api/messages` Endpoint (30 minutes)

**2.1 - Add Bot Framework dependencies to `requirements.txt`**

```txt
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
botframework-connector>=4.16.0
```

**2.2 - Implement the endpoint in `starter/main.py`**

```python
from fastapi import FastAPI, Request, Response
from botbuilder.core import BotFrameworkAdapter, BotFrameworkAdapterSettings, TurnContext
from botbuilder.schema import Activity

# Bot Framework Adapter — APP_ID comes from the Agent Blueprint (Lab 6)
settings = BotFrameworkAdapterSettings(
    app_id=os.environ.get("MICROSOFT_APP_ID", ""),
    app_password=os.environ.get("MICROSOFT_APP_PASSWORD", "")
)
adapter = BotFrameworkAdapter(settings)

async def on_message_activity(turn_context: TurnContext):
    """Process an incoming Bot Framework Activity with the LangGraph agent."""
    user_message = turn_context.activity.text

    result = await agent_graph.ainvoke({
        "messages": [user_message],
        "current_tool": None,
        "tool_result": {}
    })

    response_text = result["messages"][-1].content
    card = create_financial_card(response_text)

    await turn_context.send_activity(
        Activity(type="message", attachments=[card])
    )

@app.post("/api/messages")
async def handle_messages(request: Request):
    """Bot Framework messaging endpoint — receives Activities from M365."""
    auth_header = request.headers.get("Authorization", "")
    body = await request.json()
    activity = Activity().deserialize(body)
    await adapter.process_activity(activity, auth_header, on_message_activity)
    return Response(status_code=200)
```

**2.3 - Test the endpoint locally**

```powershell
# Simulate a Bot Framework Activity
$activity = @{
    type         = "message"
    text         = "What is the PETR4 stock price?"
    from         = @{ id = "user-test"; name = "Test User" }
    conversation = @{ id = "conv-test" }
    channelId    = "test"
    serviceUrl   = "https://test.botframework.com"
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "http://localhost:8080/api/messages" `
    -Method Post `
    -Body $activity `
    -ContentType "application/json"
```

> **Expected**: A 200 response with an Adaptive Card attachment.

**Success Criteria**:
- ✅ `/api/messages` accepts POST requests
- ✅ Bot Framework activities processed correctly
- ✅ Response contains an Adaptive Card attachment
- ✅ `/chat` endpoint still works (backward compatibility)

---

### Task 3: Create Adaptive Cards for Financial Data (20 minutes)

**3.1 - Implement the card helper in `starter/main.py`**

```python
def create_financial_card(text: str, ticker: str = None, price: float = None) -> dict:
    """Creates an Adaptive Card for financial responses."""
    body = [
        {
            "type": "ColumnSet",
            "columns": [
                {
                    "type": "Column", "width": "stretch",
                    "items": [{
                        "type": "TextBlock",
                        "text": "💹 Financial Advisor",
                        "weight": "Bolder",
                        "size": "Medium"
                    }]
                }
            ]
        },
        {
            "type": "TextBlock",
            "text": text,
            "wrap": True
        }
    ]

    # Add structured price row if data is available
    if ticker and price is not None:
        body.append({
            "type": "FactSet",
            "facts": [
                {"title": "Ticker", "value": ticker},
                {"title": "Price", "value": f"R$ {price:.2f}"}
            ]
        })

    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.4",
            "body": body
        }
    }
```

**3.2 - Validate card schema**

Before deploying, validate your card at [https://adaptivecards.io/designer](https://adaptivecards.io/designer):
- Schema version must be **1.4 or lower** (Teams maximum)
- All referenced properties must be valid for the selected version

**Success Criteria**:
- ✅ Adaptive Card renders textual response
- ✅ Optional `FactSet` included for structured ticker/price data
- ✅ Card schema validated (version ≤ 1.4)
- ✅ Card used in `on_message_activity` handler

---

### Task 4: Redeploy to ACA (20 minutes)

> **Key point**: Updating the container image does NOT require re-registering the agent in Foundry. The registered endpoint URL stays the same — Foundry automatically serves the new code.

**4.1 - Run the deploy script**

```powershell
cd lesson-5-a365-langgraph/labs/solution

.\deploy.ps1
```

The deploy script:
1. Builds the new container image with Bot Framework + OpenTelemetry
2. Pushes to ACR
3. Updates the ACA app to the new image revision
4. Sets `APPLICATIONINSIGHTS_CONNECTION_STRING` as a secret/env var

**4.2 - Set environment variables on ACA**

```powershell
$RG       = "rg-ai-agents-workshop"
$ACA_NAME = "aca-lg-agent"

az containerapp update `
  --name $ACA_NAME `
  --resource-group $RG `
  --set-env-vars `
    "APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>" `
    "MICROSOFT_APP_ID=" `
    "MICROSOFT_APP_PASSWORD="
```

> `MICROSOFT_APP_ID` / `MICROSOFT_APP_PASSWORD` are left empty for now — they will be filled in Lab 6 after the Agent Blueprint is registered.

**4.3 - Verify the deployment**

```powershell
$FQDN = az containerapp show `
    --name $ACA_NAME --resource-group $RG `
    --query "properties.configuration.ingress.fqdn" -o tsv

# Health check
Invoke-RestMethod -Uri "https://$FQDN/health"

# REST chat endpoint
python ../../../test/chat.py --lesson 5 --endpoint "https://$FQDN"

# Bot Framework endpoint
$activity = @{
    type="message"; text="Market summary for IBOV";
    from=@{id="u1"}; conversation=@{id="c1"}
    channelId="test"; serviceUrl="https://test.botframework.com"
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://$FQDN/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

**Success Criteria**:
- ✅ Container redeployed with no downtime
- ✅ `/health` returns `{ "status": "ok" }`
- ✅ `/chat` endpoint responds correctly
- ✅ `/api/messages` accepts Bot Framework activities
- ✅ No re-registration needed in Foundry

---

### Task 5: Verify Observability (20 minutes)

#### Application Insights (all calls — direct and gateway-routed)

**Transaction Search** (individual request end-to-end):
1. Azure Portal → your Application Insights resource → **Transaction search**
2. Set time range to **Last 30 minutes**
3. Click a `POST /chat` or `POST /api/messages` entry
4. Click **View all telemetry** → inspect the **End-to-end transaction** waterfall
5. Verify custom spans appear: `get_stock_price`, `get_exchange_rate`, etc., each with timing

**Performance** (aggregate latency):
1. Application Insights → **Performance**
2. Select operation `POST /chat`
3. View P50 / P95 / P99 latencies
4. Click **Drill into samples** → select a slow trace → identify which tool span caused the delay

**Live Metrics** (real-time — useful during live demos):
1. Application Insights → **Live metrics**
2. Keep open while sending test messages; see requests, failures, and server telemetry with ~1 s latency

**KQL queries** in Log Analytics:
```kusto
// All agent requests in the last hour
requests
| where timestamp > ago(1h)
| where name in ("POST /chat", "POST /api/messages")
| project timestamp, name, duration, success, resultCode
| order by timestamp desc

// Custom tool spans
dependencies
| where timestamp > ago(1h)
| where type == "InProc"
| project timestamp, name, duration, success
| order by duration desc
```

#### Foundry Portal (gateway-routed calls only)

> Foundry tracing only captures calls routed through the **AI Gateway endpoint** (the Foundry project URL), not direct-to-ACA calls.

1. Azure Portal → Azure AI Foundry → your project → **Tracing** (left nav)
2. Send a request via the Foundry project endpoint:
   ```powershell
   python ../../../test/chat.py --lesson 4 --endpoint $aiProjectEndpoint
   ```
3. Click the trace entry → see the span waterfall: `gateway → ACA /chat → LangGraph nodes`
4. Observe token usage and latency per hop

**Success Criteria**:
- ✅ Application Insights shows requests for both `/chat` and `/api/messages`
- ✅ Custom tool spans visible in Transaction Search
- ✅ Foundry Tracing shows traces for gateway-routed calls
- ✅ P95 latency identified under Performance

---

## Deliverables

- [x] OpenTelemetry observability integrated (`configure_azure_monitor`, custom spans)
- [x] Bot Framework `/api/messages` endpoint implemented
- [x] Adaptive Cards created and validated
- [x] Agent redeployed to ACA (no re-registration)
- [x] Traces visible in Application Insights
- [x] Traces visible in Foundry portal (via gateway path)

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **OpenTelemetry Setup** | 20 pts | `configure_azure_monitor` + custom tool spans |
| **Bot Framework Endpoint** | 30 pts | `/api/messages` functional, activities processed |
| **Adaptive Cards** | 20 pts | Card implemented, schema valid, renders correctly |
| **ACA Redeployment** | 20 pts | New image deployed, health checks pass |
| **Observability Verified** | 10 pts | Traces confirmed in App Insights and Foundry |

**Total**: 100 points

## Troubleshooting

### Telemetry not appearing in Application Insights
- **Cause**: Connection string not set or wrong
- **Fix**: Verify `APPLICATIONINSIGHTS_CONNECTION_STRING` env var on ACA. Restart the container revision after setting it.

### `/api/messages` returns 401
- **Cause**: `MICROSOFT_APP_ID` set but credentials not yet configured (Lab 6 is needed first)
- **Fix**: Leave `MICROSOFT_APP_ID` empty for now — Bot Framework skips auth validation when App ID is empty, which is acceptable for testing.

### Adaptive Card not rendering
- **Cause**: Invalid schema or version > 1.4
- **Fix**: Validate at [https://adaptivecards.io/designer](https://adaptivecards.io/designer). Ensure `"version": "1.4"`.

### Custom spans missing in App Insights
- **Cause**: `configure_azure_monitor()` called after tracer creation
- **Fix**: Call `configure_azure_monitor()` before any `trace.get_tracer()` call.

### Foundry Tracing shows no traces
- **Cause**: Test calls went directly to ACA, not through AI Gateway
- **Fix**: Use the Foundry project endpoint (`$aiProjectEndpoint`) instead of the ACA FQDN.

## Time Estimate

- Task 1: 20 minutes
- Task 2: 30 minutes
- Task 3: 20 minutes
- Task 4: 20 minutes
- Task 5: 20 minutes
- **Total**: ~110 minutes

## Next Steps

- **Lab 6**: Register the agent in Microsoft Entra ID, configure A365 CLI, and set up the Agent Blueprint so the `/api/messages` endpoint is wired into Microsoft Teams.

---

**Difficulty**: Advanced  
**Prerequisites**: Lab 4, Application Insights connection string  
**Estimated Time**: ~110 minutes
