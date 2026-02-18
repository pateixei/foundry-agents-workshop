# Lesson 5: Microsoft Agent 365 SDK Integration

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Integrate** Azure Monitor / OpenTelemetry for distributed tracing and observability
2. **Implement** Bot Framework Protocol (`/api/messages` endpoint) for native Teams integration
3. **Create** Adaptive Cards for rich, interactive M365 responses
4. **Instrument** tool functions with custom OpenTelemetry spans
5. **Deploy** an enhanced agent with production-grade telemetry
6. **Test** agents via both REST API and Bot Framework Activity format

---

## Navigation

| Resource | Description |
|----------|-------------|
| [📖 Demo Walkthrough](demos/README.md) | Code walkthrough and demo instructions |
| [🔬 Lab Exercise](labs/LAB-STATEMENT.md) | Hands-on lab with tasks and success criteria |
| [📝 Agent Registration](REGISTER.md) | How to register the agent in Foundry Portal (as an assest) |

---

## Overview

This lesson enhances the LangGraph agent from Lesson 4 with Microsoft Agent 365 SDK features for observability, adaptive cards, and native M365 integration.

### Before vs After

| Aspect | Before (Generic FastAPI) | After (A365 SDK) |
|--------|-------------------------|-------------------|
| Endpoint | `/chat` (custom JSON) | `/api/messages` (Bot Framework protocol) |
| Responses | Plain text/JSON | Adaptive Cards (rich UI) |
| Monitoring | Basic logs | OpenTelemetry + Application Insights |
| Context | Custom message parsing | Activity objects with user identity, conversation ID |
| M365 Integration | None | Native Teams/Outlook support |

> **Without A365 SDK**: Your agent is a generic REST API.
> **With A365 SDK**: Your agent speaks M365's language—Activities, Adaptive Cards, telemetry.

---

## Architecture: SDK Enhancement Layer

```
Microsoft Teams / Outlook
    ↓ (Bot Framework Activity)
/api/messages endpoint (A365 SDK)
    ↓
BotFrameworkAdapter
    ↓ (TurnContext with user identity)
LangGraph Agent
    ↓ (instrumented with OpenTelemetry spans)
Azure OpenAI + Tools
    ↓
Adaptive Card Response
    ↓ (sent via TurnContext)
Teams / Outlook (rich UI)

── Telemetry ──────────────►  Application Insights
```

---

## Key Enhancements

### 1. Azure Monitor Observability

Add OpenTelemetry tracing so you can debug agent behavior in production:

```python
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Configure Application Insights
app_insights_cs = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
if app_insights_cs:
    configure_azure_monitor(connection_string=app_insights_cs)

app = FastAPI()
FastAPIInstrumentor.instrument_app(app)  # Auto-trace all endpoints
```

**Instrument tool functions** with custom spans for granular timing:

```python
tracer = trace.get_tracer(__name__)

def get_stock_price(symbol: str) -> dict:
    with tracer.start_as_current_span("get_stock_price") as span:
        span.set_attribute("stock.symbol", symbol)
        price_data = fetch_price(symbol)
        span.set_attribute("stock.price", price_data["price"])
        span.set_status(trace.Status(trace.StatusCode.OK))
        return price_data
```

> In Application Insights, you'll see: How long did `get_stock_price` take? What was the success rate? Where do bottlenecks occur?

### 2. Bot Framework Protocol

Add the native `/api/messages` endpoint that Teams and Outlook use to communicate:

```python
from botbuilder.core import BotFrameworkAdapter, TurnContext
from botbuilder.schema import Activity, ActivityTypes

adapter = BotFrameworkAdapter(settings=BotAdapterSettings(
    app_id=os.getenv("APP_ID"),
    app_password=os.getenv("APP_PASSWORD")
))

@app.post("/api/messages")
async def messages(request: Request):
    body = await request.json()
    activity = Activity().deserialize(body)

    async def on_turn(turn_context: TurnContext):
        if turn_context.activity.type == ActivityTypes.message:
            response = agent.invoke(turn_context.activity.text)
            card = create_adaptive_card(response)
            await turn_context.send_activity(card)

    await adapter.process_activity(activity, on_turn)
    return {"status": "ok"}
```

> **Activity objects** enable Teams to send rich context: user identity, conversation ID, thread history.

### 3. Adaptive Cards

Rich M365-optimized responses with interactive UI elements:

```json
{
  "type": "AdaptiveCard",
  "body": [
    { "type": "TextBlock", "text": "📈 Apple Inc. (AAPL)", "weight": "Bolder", "size": "Medium" },
    { "type": "FactSet", "facts": [
      { "title": "Price", "value": "$178.42" },
      { "title": "Change", "value": "+2.34 (+1.33%)" }
    ]},
    { "type": "ActionSet", "actions": [
      { "type": "Action.Submit", "title": "View Chart" },
      { "type": "Action.Submit", "title": "Get Details" }
    ]}
  ],
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "version": "1.5"
}
```

### 4. Enhanced Tools

All tools instrumented with tracing spans for:
- Performance monitoring per tool call
- Usage analytics (which tools are most used)
- Error tracking with full stack traces

---

## New Dependencies

```txt
# A365 SDK and Observability
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
```

---

## Deployment

```powershell
cd lesson-5-a365-langgraph
./deploy.ps1
```

After deployment, configure Application Insights:
```powershell
# Get connection string
$connectionString = az monitor app-insights component show \
  --resource-group $rgName --app <app-insights-name> \
  --query connectionString -o tsv

# Update ACA environment variable
az containerapp update --name aca-lg-agent --resource-group $rgName \
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString"
```

**LESSON 6** - Update A365 config with new endpoint:
```powershell
cd ../lesson-6-a365-prereq
a365 setup blueprint --skip-infrastructure
```

---

## Testing

### Health Check
```powershell
Invoke-RestMethod "https://<endpoint>/health"
```

### Chat API (backward compatible)
```powershell
$body = @{message = "Qual o preco da PETR4?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/chat" -Method Post -Body $body -ContentType "application/json"
```

### Bot Framework Activity (new M365 protocol)
```powershell
$activity = @{
    type = "message"
    text = "Mostre um resumo do mercado"
    from = @{ id = "user123"; name = "Test User" }
    conversation = @{ id = "conv123" }
    id = "msg123"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

---

## View Telemetry

### Understanding Where Traces Appear

The call path determines **which observability surface** captures the trace:

| Call path | Traces in Foundry portal? | Traces in Application Insights? |
|-----------|--------------------------|----------------------------------|
| **Direct → ACA** (`/chat` or `/api/messages`) | ❌ No | ✅ Yes (via OpenTelemetry) |
| **Via Foundry AI Gateway** (Foundry project endpoint) | ✅ Yes | ✅ Yes (both) |

> **Why?** Foundry only captures telemetry for requests that pass through its AI Gateway (APIM). When you call ACA directly, Foundry never sees the request. Application Insights captures everything because the OpenTelemetry SDK instruments the agent process itself, regardless of how the call arrived.

---

### Viewing Traces in Application Insights

Application Insights captures all calls (direct and gateway-routed), including custom OpenTelemetry spans for individual tool calls.

**Transaction Search** — find a specific request end-to-end:
1. Azure Portal → your Application Insights resource → **Transaction search**
2. Set time range to **Last 30 minutes**
3. Click a `POST /chat` or `POST /api/messages` request
4. Click **View all telemetry** → see the full **End-to-end transaction** waterfall
5. Verify custom spans appear: `get_stock_price`, `get_portfolio`, etc., each with duration

**Performance** — aggregate latency analysis:
1. Application Insights → **Performance**
2. Select operation `POST /chat` or `POST /api/messages`
3. View P50 / P95 / P99 response times and drill into slow samples
4. Click **Drill into samples** → pick a slow trace → see which tool span caused the delay

**Live Metrics** — real-time stream during a live demo:
1. Application Insights → **Live metrics**
2. Keep this open while sending test messages
3. See incoming request rate, failure rate, and server telemetry with ~1 s latency

**KQL query** — custom analysis in Log Analytics:
```kusto
// All agent requests in the last hour with duration
requests
| where timestamp > ago(1h)
| where name in ("POST /chat", "POST /api/messages")
| project timestamp, name, duration, success, resultCode
| order by timestamp desc

// Custom spans for tool calls
dependencies
| where timestamp > ago(1h)
| where type == "InProc"  // OpenTelemetry in-process spans
| project timestamp, name, duration, success
| order by duration desc
```

---

### Viewing Traces in Foundry Portal

Foundry tracing only captures calls routed **through the AI Gateway endpoint** (the Foundry project URL, not the ACA FQDN directly).

1. Azure Portal → Azure AI Foundry → your project → **Tracing** (left nav)
2. You'll see traces for each invocation routed via the gateway
3. Each trace shows: latency, token usage, model calls, and the connected agent hop
4. Click a trace → drill into the **span waterfall**: `gateway → ACA /chat → LangGraph nodes`

> **To generate Foundry traces from your tests**, use the Foundry project endpoint instead of the ACA URL directly:
> ```powershell
> # This goes through AI Gateway → captured in Foundry tracing
> python ../../test/chat.py --lesson 4 --endpoint $aiProjectEndpoint
>
> # This goes direct to ACA → NOT captured in Foundry tracing
> python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>
> ```

---

### Key Metrics to Monitor

| Metric | Where | What to Look For |
|--------|-------|------------------|
| Request count | Application Insights → Requests | Volume of `/chat` and `/api/messages` calls |
| Response time | Application Insights → Performance | P50, P95, P99 latencies |
| Failures | Application Insights → Failures | Failed requests and exceptions with stack traces |
| Tool timing | Transaction Search → custom spans | Per-tool execution duration (`get_stock_price`, etc.) |
| Dependencies | Application Insights → Dependencies | External API calls (stock data providers) |
| Gateway traces | Foundry portal → Tracing | End-to-end span including gateway overhead |
| Token usage | Foundry portal → Tracing | Token count per invocation when routed via gateway |

---

## 🔧 Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Telemetry not appearing | Connection string wrong | Verify `APPLICATIONINSIGHTS_CONNECTION_STRING` env var and restart container |
| `/api/messages` returns 401 | Auth misconfigured | Verify `APP_ID` and `APP_PASSWORD` environment variables match Entra registration |
| Adaptive Cards not rendering | Schema version mismatch | Ensure card uses Adaptive Card schema v1.5 for Teams compatibility |
| Custom spans missing | Tracer not initialized | Verify `configure_azure_monitor()` runs before tracer creation |
| Bot Framework timeout | Agent too slow | Profile tool spans in App Insights; optimize slow tools |

---

## ❓ Frequently Asked Questions

**Q: Do I still need the `/chat` endpoint after adding `/api/messages`?**
A: Yes—keep both. `/chat` is useful for direct testing and non-M365 clients. `/api/messages` is the Bot Framework protocol endpoint for Teams/Outlook.

**Q: What's the difference between Activity and a regular HTTP request?**
A: Activities carry M365 context: user identity, conversation ID, thread history, channel info. Regular HTTP requests are stateless JSON payloads.

**Q: How much does Application Insights cost?**
A: Ingestion-based pricing (~$2.30/GB). For workshop-scale usage, it's negligible. In production, configure sampling to control costs.

**Q: Can I test Bot Framework locally without Teams?**
A: Yes—use the [Bot Framework Emulator](https://github.com/microsoft/BotFramework-Emulator) desktop app to send Activities to your local endpoint.

**Q: Why not use Application permissions instead of Delegated for the Bot?**
A: Delegated permissions act on behalf of the user (User.Read). Application permissions would give the bot unrestricted access. Use least-privilege—delegated is safer.

---

## 🏆 Self-Paced Challenges

1. **Custom Dashboard**: Create an Application Insights workbook that shows agent tool usage, response times, and error rates in a single view
2. **Advanced Adaptive Cards**: Build a multi-step Adaptive Card with Action.Submit that lets users select stocks from a dropdown before querying
3. **Conversation Memory**: Extend the Bot Framework handler to maintain conversation history across multiple turns using TurnContext
4. **Alert Rules**: Configure Application Insights alerts for: error rate >5%, response time >2s, and availability <99%
5. **Multi-Channel**: Test the same `/api/messages` endpoint from Teams, Outlook, and Bot Framework Emulator—document the differences in Activity payloads
6. **Custom Telemetry Events**: Add `tracer.start_as_current_span()` to every tool in your agent and create a dependency map in App Insights

---

## Next Steps

- **Lesson 7**: Publish to M365 Admin Center
- **Lesson 8**: Create agent instances in Teams

---

## References

- [Azure Monitor OpenTelemetry](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-overview)
- [Bot Framework SDK for Python](https://learn.microsoft.com/azure/bot-service/bot-builder-python-quickstart)
- [Adaptive Cards Designer](https://adaptivecards.io/designer/)
- [Application Insights Pricing](https://azure.microsoft.com/pricing/details/monitor/)
