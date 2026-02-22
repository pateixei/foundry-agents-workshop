# Demo 5: A365 SDK Integration — Bot Framework, Adaptive Cards & Observability

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

> **Demo Type**: Instructor-led walkthrough. The instructor live-codes the SDK additions on top of the existing ACA agent from Demo 4, shows the Bot Framework endpoint responding, renders the Adaptive Card output, and verifies traces in Application Insights.

## Overview

Demonstrates adding the **Microsoft Agent 365 SDK** layer to the LangGraph agent already running in ACA: Bot Framework protocol support (`/api/messages`), Adaptive Cards for rich financial data display, OpenTelemetry distributed tracing, and full redeployment — without re-registering the agent in Foundry.

> **Note**: A365 CLI setup, Entra ID app registration, and Agent Blueprint steps are covered in **Demo 6**. This demo focuses exclusively on the SDK code changes.

## Key Concepts

- ✅ Azure Monitor OpenTelemetry — `configure_azure_monitor` + custom spans per tool
- ✅ Bot Framework Activity Protocol — `/api/messages` FastAPI endpoint
- ✅ Adaptive Cards — schema v1.4, `FactSet` for structured financial data
- ✅ ACA rolling update — new image pushed, no Foundry re-registration needed
- ✅ Observability split — App Insights (all calls) vs Foundry Tracing (gateway-routed only)

## Architecture

```
┌────────────────────────────────────────────────────────┐
│ Azure Tenant (Tenant A)                                │
│                                                        │
│  Client / Teams emulator                               │
│       │                                                │
│       ▼  POST /api/messages  (Bot Framework Activity)  │
│  ┌─────────────────────────────────────────────────┐   │
│  │  ACA: aca-lg-agent                              │   │
│  │  ├─> BotFrameworkAdapter                        │   │
│  │  ├─> on_message_activity → LangGraph graph      │   │
│  │  ├─> tools (get_stock_price, get_exchange_rate) │   │
│  │  │     └── OTel spans → Application Insights    │   │
│  │  └─> Adaptive Card response                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                        │
│  Application Insights ←── all calls (direct + gateway)│
│  Foundry Tracing       ←── gateway-routed calls only  │
└────────────────────────────────────────────────────────┘
```

## Prerequisites

- Agent from Demo 4 deployed and running in ACA
- `APPLICATIONINSIGHTS_CONNECTION_STRING` available (from `prereq/` outputs)
- Python 3.11+ and Docker available locally
- Bot Framework Emulator (optional, for local testing)

## Demo Flow

### Phase 1: Add OpenTelemetry (5 minutes)

Show how to wire `configure_azure_monitor` and custom spans in one block:

```python
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

app = FastAPI()

app_insights_cs = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if app_insights_cs:
    configure_azure_monitor(connection_string=app_insights_cs)

FastAPIInstrumentor.instrument_app(app)

tracer = trace.get_tracer(__name__)
```

Instrument a tool function with a custom span — show the `set_attribute` and `record_exception` calls:

```python
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

> **Key point**: `configure_azure_monitor()` must be called **before** `trace.get_tracer()`. FastAPIInstrumentor auto-instruments all HTTP endpoints.

### Phase 2: Add Bot Framework Endpoint (10 minutes)

Show the adapter setup and the `/api/messages` route:

```python
from botbuilder.core import BotFrameworkAdapter, BotFrameworkAdapterSettings, TurnContext
from botbuilder.schema import Activity

settings = BotFrameworkAdapterSettings(
    app_id=os.environ.get("MICROSOFT_APP_ID", ""),
    app_password=os.environ.get("MICROSOFT_APP_PASSWORD", "")
)
adapter = BotFrameworkAdapter(settings)

async def on_message_activity(turn_context: TurnContext):
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
    auth_header = request.headers.get("Authorization", "")
    body = await request.json()
    activity = Activity().deserialize(body)
    await adapter.process_activity(activity, auth_header, on_message_activity)
    return Response(status_code=200)
```

> **Key point**: `MICROSOFT_APP_ID` is intentionally left empty at this stage. The Bot Framework skips auth validation when App ID is empty — correct for this lab. It will be filled after Lab 6 Blueprint registration.

### Phase 3: Create Adaptive Card (5 minutes)

Walk through the card helper — highlight the `FactSet` for structured ticker/price data:

```python
def create_financial_card(text: str, ticker: str = None, price: float = None) -> dict:
    body = [
        {
            "type": "ColumnSet",
            "columns": [{
                "type": "Column", "width": "stretch",
                "items": [{
                    "type": "TextBlock",
                    "text": "💹 Financial Advisor",
                    "weight": "Bolder",
                    "size": "Medium"
                }]
            }]
        },
        {
            "type": "TextBlock",
            "text": text,
            "wrap": True
        }
    ]

    if ticker and price is not None:
        body.append({
            "type": "FactSet",
            "facts": [
                {"title": "Ticker", "value": ticker},
                {"title": "Price",  "value": f"R$ {price:.2f}"}
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

> **Key point**: Schema version must be **1.4 or lower** — that is the maximum supported by Teams. Validate the payload at https://adaptivecards.io/designer before deploying.

### Phase 4: Redeploy to ACA (5 minutes)

Show that updating the container image does NOT require re-registering the agent in Foundry:

```powershell
cd lesson-5-a365-langgraph/solution

# Build, push, and update ACA (handled by deploy.ps1)
.\deploy.ps1

# Set env vars on the running container app
$RG       = "rg-ai-agents-workshop"
$ACA_NAME = "aca-lg-agent"

az containerapp update `
  --name $ACA_NAME --resource-group $RG `
  --set-env-vars `
    "APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>" `
    "MICROSOFT_APP_ID=" `
    "MICROSOFT_APP_PASSWORD="
```

Verify the new revision is serving traffic:

```powershell
$FQDN = az containerapp show `
    --name $ACA_NAME --resource-group $RG `
    --query "properties.configuration.ingress.fqdn" -o tsv

# Health probe
Invoke-RestMethod -Uri "https://$FQDN/health"

# REST chat endpoint (backward compatible)
python ../../../test/chat.py --lesson 5 --endpoint "https://$FQDN"

# Bot Framework Activity
$activity = @{
    type="message"; text="What is the PETR4 stock price?";
    from=@{id="demo-user"}; conversation=@{id="demo-conv"}
    channelId="test"; serviceUrl="https://test.botframework.com"
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://$FQDN/api/messages" `
    -Method Post -Body $activity -ContentType "application/json"
```

Expected: 200 response with an Adaptive Card attachment.

### Phase 5: Verify Observability (5 minutes)

#### Application Insights — Transaction Search

1. Azure Portal → Application Insights resource → **Transaction search**
2. Set time range to **Last 30 minutes**
3. Click a `POST /chat` or `POST /api/messages` entry
4. Click **View all telemetry** → inspect the waterfall
5. Point out custom spans: `get_stock_price`, `get_exchange_rate` with timing

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

#### Foundry Portal — Gateway-routed calls only

> Send a request via the Foundry project endpoint (AI Gateway URL) to see traces here — direct ACA calls appear only in App Insights.

```powershell
python ../../../test/chat.py --lesson 4 --endpoint $aiProjectEndpoint
```

Then: Azure AI Foundry → your project → **Tracing** → click an entry → inspect the span waterfall.

## Bot Framework Activity Flow

```
Test client / Teams emulator
    │
    │  POST /api/messages  {"type":"message","text":"..."}
    ▼
BotFrameworkAdapter.process_activity()
    │  (auth validation skipped when MICROSOFT_APP_ID is empty)
    ▼
on_message_activity(turn_context)
    │
    ├── turn_context.activity.text  → user message
    ├── agent_graph.ainvoke(...)    → LangGraph execution
    │       └── tools fire → OTel spans recorded
    └── send_activity(Adaptive Card)
    │
    ▼
200 OK  (Bot Framework response)
```

## Adaptive Cards — Rendered Example

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "ColumnSet",
      "columns": [{
        "type": "Column", "width": "stretch",
        "items": [{ "type": "TextBlock", "text": "💹 Financial Advisor", "weight": "Bolder", "size": "Medium" }]
      }]
    },
    { "type": "TextBlock", "text": "PETR4 is currently trading at R$ 35.42, up 1.23% today.", "wrap": true },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Ticker", "value": "PETR4" },
        { "title": "Price",  "value": "R$ 35.42" }
      ]
    }
  ]
}
```

## Observability Split — App Insights vs Foundry

| Call Path | App Insights | Foundry Tracing |
|-----------|:------------:|:---------------:|
| Direct to ACA `POST /chat` | ✅ | ❌ |
| Direct to ACA `POST /api/messages` | ✅ | ❌ |
| Via Foundry AI Gateway | ✅ | ✅ |

> Use App Insights for full production observability. Use Foundry Tracing for quick inspection during development when routing through the gateway.

## Troubleshooting

**`/api/messages` returns 401**  
Cause: `MICROSOFT_APP_ID` set but credentials not yet provisioned (Lab 6 needed)  
Fix: Leave `MICROSOFT_APP_ID` empty — Bot Framework skips auth when the App ID is blank.

**Custom spans missing in App Insights**  
Cause: `configure_azure_monitor()` called after `trace.get_tracer()`  
Fix: Call `configure_azure_monitor()` first, then get the tracer.

**Adaptive Card not rendering**  
Cause: Schema version > 1.4 or invalid JSON  
Fix: Validate at https://adaptivecards.io/designer. Use `"version": "1.4"`.

**Foundry Tracing shows no traces**  
Cause: Test calls went directly to ACA, not through the AI Gateway  
Fix: Use the Foundry project endpoint (`$aiProjectEndpoint`) for test requests.

**Telemetry not appearing in App Insights**  
Cause: `APPLICATIONINSIGHTS_CONNECTION_STRING` not set on ACA  
Fix: Run `az containerapp update --set-env-vars` and restart the revision.

## Resources

- [Azure Monitor OpenTelemetry](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [Bot Framework SDK for Python](https://learn.microsoft.com/azure/bot-service/bot-builder-python-quickstart)
- [Adaptive Cards Designer](https://adaptivecards.io/designer/)
- [Azure Container Apps — Update revision](https://learn.microsoft.com/azure/container-apps/revisions)

---

**Demo Level**: Advanced  
**Estimated Time**: 30 minutes  
**Best For**: Showing SDK integration workflow before A365 CLI/Blueprint steps in Demo 6
