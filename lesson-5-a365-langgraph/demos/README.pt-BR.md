# Demo 5: Integração A365 SDK — Bot Framework, Adaptive Cards & Observabilidade

> 🇺🇸 **[Read in English](README.md)**

> **Tipo de Demo**: Demonstração guiada pelo instrutor. O instrutor adiciona ao vivo as camadas de SDK no agente ACA existente do Demo 4, mostra o endpoint Bot Framework respondendo, renderiza o Adaptive Card e verifica os traces no Application Insights.

## Visão Geral

Demonstra a adição da camada do **Microsoft Agent 365 SDK** ao agente LangGraph já rodando no ACA: suporte ao protocolo Bot Framework (`/api/messages`), Adaptive Cards para exibição rica de dados financeiros, rastreamento distribuído com OpenTelemetry e reimplantação completa — sem re-registrar o agente no Foundry.

> **Nota**: A configuração do A365 CLI, o registro do app no Entra ID e os passos do Agent Blueprint estão cobertos no **Demo 6**. Este demo foca exclusivamente nas mudanças de código do SDK.

## Conceitos-Chave

- ✅ Azure Monitor OpenTelemetry — `configure_azure_monitor` + spans customizados por tool
- ✅ Bot Framework Activity Protocol — endpoint `/api/messages` no FastAPI
- ✅ Adaptive Cards — schema v1.4, `FactSet` para dados financeiros estruturados
- ✅ Atualização rolling no ACA — nova imagem implantada, sem re-registro no Foundry
- ✅ Split de observabilidade — App Insights (todas as chamadas) vs Foundry Tracing (apenas via gateway)

## Arquitetura

```
┌────────────────────────────────────────────────────────┐
│ Azure Tenant (Tenant A)                                │
│                                                        │
│  Cliente / Teams emulator                              │
│       │                                                │
│       ▼  POST /api/messages  (Bot Framework Activity)  │
│  ┌─────────────────────────────────────────────────┐   │
│  │  ACA: aca-lg-agent                              │   │
│  │  ├─> BotFrameworkAdapter                        │   │
│  │  ├─> on_message_activity → grafo LangGraph      │   │
│  │  ├─> tools (get_stock_price, get_exchange_rate) │   │
│  │  │     └── spans OTel → Application Insights    │   │
│  │  └─> resposta Adaptive Card                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                        │
│  Application Insights ←── todas as chamadas            │
│  Foundry Tracing       ←── apenas chamadas via gateway │
└────────────────────────────────────────────────────────┘
```

## Pré-requisitos

- Agente do Demo 4 implantado e rodando no ACA
- `APPLICATIONINSIGHTS_CONNECTION_STRING` disponível (dos outputs de `prereq/`)
- Python 3.11+ e Docker disponíveis localmente
- Bot Framework Emulator (opcional, para testes locais)

## Fluxo da Demo

### Fase 1: Adicionar OpenTelemetry (5 minutos)

Mostre como conectar `configure_azure_monitor` e os spans customizados em um bloco:

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

Instrumente uma função de tool com um span customizado — destaque as chamadas `set_attribute` e `record_exception`:

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

> **Ponto-chave**: `configure_azure_monitor()` deve ser chamado **antes** de `trace.get_tracer()`. FastAPIInstrumentor auto-instrumenta todos os endpoints HTTP.

### Fase 2: Adicionar Endpoint Bot Framework (10 minutos)

Mostre a configuração do adapter e a rota `/api/messages`:

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

> **Ponto-chave**: `MICROSOFT_APP_ID` é intencionalmente deixado vazio nesta fase. O Bot Framework pula a validação de auth quando o App ID está vazio — correto para este lab. Será preenchido após o registro do Blueprint no Lab 6.

### Fase 3: Criar Adaptive Card (5 minutos)

Percorra o helper do card — destaque o `FactSet` para dados estruturados de ticker/preço:

```python
def create_financial_card(text: str, ticker: str = None, price: float = None) -> dict:
    body = [
        {
            "type": "ColumnSet",
            "columns": [{
                "type": "Column", "width": "stretch",
                "items": [{
                    "type": "TextBlock",
                    "text": "💹 Consultor Financeiro",
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
                {"title": "Preço",  "value": f"R$ {price:.2f}"}
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

> **Ponto-chave**: A versão do schema deve ser **1.4 ou inferior** — esse é o máximo suportado pelo Teams. Valide o payload em https://adaptivecards.io/designer antes de implantar.

### Fase 4: Reimplantar no ACA (5 minutos)

Mostre que atualizar a imagem do container NÃO requer re-registrar o agente no Foundry:

```powershell
cd lesson-5-a365-langgraph/solution

# Build, push e atualização do ACA (gerenciados pelo deploy.ps1)
.\deploy.ps1

# Definir variáveis de ambiente no container app
$RG       = "rg-ai-agents-workshop"
$ACA_NAME = "aca-lg-agent"

az containerapp update `
  --name $ACA_NAME --resource-group $RG `
  --set-env-vars `
    "APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>" `
    "MICROSOFT_APP_ID=" `
    "MICROSOFT_APP_PASSWORD="
```

Verifique que a nova revisão está servindo tráfego:

```powershell
$FQDN = az containerapp show `
    --name $ACA_NAME --resource-group $RG `
    --query "properties.configuration.ingress.fqdn" -o tsv

# Health probe
Invoke-RestMethod -Uri "https://$FQDN/health"

# Endpoint REST de chat (compatibilidade retroativa)
python ../../../test/chat.py --lesson 5 --endpoint "https://$FQDN"

# Bot Framework Activity
$activity = @{
    type="message"; text="Qual é o preço da PETR4?";
    from=@{id="demo-user"}; conversation=@{id="demo-conv"}
    channelId="test"; serviceUrl="https://test.botframework.com"
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://$FQDN/api/messages" `
    -Method Post -Body $activity -ContentType "application/json"
```

Esperado: resposta 200 com um Adaptive Card como attachment.

### Fase 5: Verificar Observabilidade (5 minutos)

#### Application Insights — Transaction Search

1. Portal Azure → recurso Application Insights → **Transaction search**
2. Defina o intervalo de tempo para **Últimos 30 minutos**
3. Clique em uma entrada `POST /chat` ou `POST /api/messages`
4. Clique em **View all telemetry** → inspecione o waterfall
5. Destaque spans customizados: `get_stock_price`, `get_exchange_rate` com timing

```kusto
// Todas as requisições do agente na última hora
requests
| where timestamp > ago(1h)
| where name in ("POST /chat", "POST /api/messages")
| project timestamp, name, duration, success, resultCode
| order by timestamp desc

// Spans customizados de tools
dependencies
| where timestamp > ago(1h)
| where type == "InProc"
| project timestamp, name, duration, success
| order by duration desc
```

#### Portal do Foundry — Apenas chamadas via gateway

> Envie uma requisição via endpoint do projeto Foundry (URL do AI Gateway) para ver traces aqui — chamadas diretas ao ACA aparecem apenas no App Insights.

```powershell
python ../../../test/chat.py --lesson 4 --endpoint $aiProjectEndpoint
```

Depois: Azure AI Foundry → seu projeto → **Tracing** → clique em uma entrada → inspecione o waterfall de spans.

## Fluxo de Activity do Bot Framework

```
Cliente de teste / Teams emulator
    │
    │  POST /api/messages  {"type":"message","text":"..."}
    ▼
BotFrameworkAdapter.process_activity()
    │  (validação de auth pulada quando MICROSOFT_APP_ID está vazio)
    ▼
on_message_activity(turn_context)
    │
    ├── turn_context.activity.text  → mensagem do usuário
    ├── agent_graph.ainvoke(...)    → execução do LangGraph
    │       └── tools disparam → spans OTel registrados
    └── send_activity(Adaptive Card)
    │
    ▼
200 OK  (resposta Bot Framework)
```

## Adaptive Cards — Exemplo Renderizado

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
        "items": [{ "type": "TextBlock", "text": "💹 Consultor Financeiro", "weight": "Bolder", "size": "Medium" }]
      }]
    },
    { "type": "TextBlock", "text": "PETR4 está sendo negociada a R$ 35,42 hoje, alta de 1,23%.", "wrap": true },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Ticker", "value": "PETR4" },
        { "title": "Preço",  "value": "R$ 35,42" }
      ]
    }
  ]
}
```

## Split de Observabilidade — App Insights vs Foundry

| Caminho da Chamada | App Insights | Foundry Tracing |
|--------------------|:------------:|:---------------:|
| Direto ao ACA `POST /chat` | ✅ | ❌ |
| Direto ao ACA `POST /api/messages` | ✅ | ❌ |
| Via Foundry AI Gateway | ✅ | ✅ |

> Use o App Insights para observabilidade completa em produção. Use o Foundry Tracing para inspeção rápida durante o desenvolvimento ao rotear pelo gateway.

## Resolução de Problemas

**`/api/messages` retorna 401**  
Causa: `MICROSOFT_APP_ID` definido mas credenciais ainda não provisionadas (Lab 6 necessário)  
Solução: Deixe `MICROSOFT_APP_ID` vazio — o Bot Framework pula a auth quando o App ID está em branco.

**Spans customizados ausentes no App Insights**  
Causa: `configure_azure_monitor()` chamado após `trace.get_tracer()`  
Solução: Chame `configure_azure_monitor()` primeiro, depois obtenha o tracer.

**Adaptive Card não renderiza**  
Causa: Versão do schema > 1.4 ou JSON inválido  
Solução: Valide em https://adaptivecards.io/designer. Use `"version": "1.4"`.

**Foundry Tracing não mostra traces**  
Causa: Chamadas de teste foram diretamente ao ACA, não pelo AI Gateway  
Solução: Use o endpoint do projeto Foundry (`$aiProjectEndpoint`) para as requisições de teste.

**Telemetria não aparece no App Insights**  
Causa: `APPLICATIONINSIGHTS_CONNECTION_STRING` não definido no ACA  
Solução: Execute `az containerapp update --set-env-vars` e reinicie a revisão.

## Recursos

- [Azure Monitor OpenTelemetry](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable)
- [SDK do Bot Framework para Python](https://learn.microsoft.com/azure/bot-service/bot-builder-python-quickstart)
- [Designer de Adaptive Cards](https://adaptivecards.io/designer/)
- [Azure Container Apps — Atualizar revisão](https://learn.microsoft.com/azure/container-apps/revisions)

---

**Nível da Demo**: Avançado  
**Tempo Estimado**: 30 minutos  
**Melhor Para**: Demonstrar o fluxo de integração do SDK antes dos passos de A365 CLI/Blueprint no Demo 6
