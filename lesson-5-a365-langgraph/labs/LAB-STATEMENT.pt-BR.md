# Lab 5: Integração A365 SDK — Bot Framework, Adaptive Cards & Observabilidade

> 🇺🇸 **[Read in English](LAB-STATEMENT.md)**

## Objetivo

Aprimorar o agente LangGraph (do Lab 4) com o **Microsoft Agent 365 SDK**: adicionar suporte ao protocolo Bot Framework, Adaptive Cards para exibição rica de dados financeiros e observabilidade via Azure Monitor / OpenTelemetry — em seguida, reimplantar no ACA.

## Cenário

Seu agente de consultoria financeira está rodando no ACA e registrado no Foundry. O negócio agora requer:
- Endpoint Bot Framework `/api/messages` para que o agente se comunique com Microsoft Teams e Outlook
- Adaptive Cards para respostas financeiras com formatação profissional
- Rastreamento distribuído via Application Insights para observabilidade em produção

> **Nota**: A configuração do A365 CLI, o registro do app no Entra ID e os passos do Agent Blueprint estão cobertos no **Lab 6**. Este lab foca exclusivamente nas mudanças de SDK e código.

## Objetivos de Aprendizagem

- Implementar o Bot Framework Activity Protocol (endpoint `/api/messages`)
- Criar Adaptive Cards para visualização de dados financeiros
- Integrar Azure Monitor OpenTelemetry para rastreamento distribuído
- Instrumentar funções de tools individuais com spans customizados
- Reimplantar uma imagem de container atualizada no ACA (sem necessidade de re-registro)
- Observar traces no Application Insights e no portal do Foundry

## Pré-requisitos

- [x] Lab 4 concluído (agente ACA rodando e registrado no Foundry)
- [x] Recurso Application Insights provisionado (criado em `prereq/`)
- [x] `APPLICATIONINSIGHTS_CONNECTION_STRING` disponível (dos outputs de `prereq/`)
- [x] Python 3.11+ e Docker disponíveis localmente

## Tarefas

### Tarefa 1: Adicionar Observabilidade com OpenTelemetry (20 minutos)

**1.1 - Atualizar `requirements.txt`**

Adicione ao `starter/requirements.txt`:
```txt
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
```

**1.2 - Configurar Azure Monitor no `main.py`**

```python
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

app = FastAPI()

# Configurar telemetria do Application Insights
app_insights_cs = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if app_insights_cs:
    configure_azure_monitor(connection_string=app_insights_cs)

FastAPIInstrumentor.instrument_app(app)  # Auto-instrumentar todos os endpoints HTTP
```

**1.3 - Instrumentar funções de tools com spans customizados**

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

Aplique o mesmo padrão em cada tool do LangGraph (`get_exchange_rate`, `get_market_summary`, etc.).

**Critérios de Sucesso**:
- ✅ `configure_azure_monitor()` chamado na inicialização
- ✅ Endpoints FastAPI auto-instrumentados
- ✅ Cada função de tool envolvida em um span customizado
- ✅ Atributos do span incluem contexto relevante (ticker, valor, etc.)

---

### Tarefa 2: Implementar Endpoint Bot Framework `/api/messages` (30 minutos)

**2.1 - Adicionar dependências do Bot Framework ao `requirements.txt`**

```txt
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
botframework-connector>=4.16.0
```

**2.2 - Implementar o endpoint em `starter/main.py`**

```python
from fastapi import FastAPI, Request, Response
from botbuilder.core import BotFrameworkAdapter, BotFrameworkAdapterSettings, TurnContext
from botbuilder.schema import Activity

# Bot Framework Adapter — APP_ID virá do Agent Blueprint (Lab 6)
settings = BotFrameworkAdapterSettings(
    app_id=os.environ.get("MICROSOFT_APP_ID", ""),
    app_password=os.environ.get("MICROSOFT_APP_PASSWORD", "")
)
adapter = BotFrameworkAdapter(settings)

async def on_message_activity(turn_context: TurnContext):
    """Processa um Bot Framework Activity com o agente LangGraph."""
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
    """Endpoint de mensagens do Bot Framework — recebe Activities do M365."""
    auth_header = request.headers.get("Authorization", "")
    body = await request.json()
    activity = Activity().deserialize(body)
    await adapter.process_activity(activity, auth_header, on_message_activity)
    return Response(status_code=200)
```

**2.3 - Testar o endpoint localmente**

```powershell
# Simular um Bot Framework Activity
$activity = @{
    type         = "message"
    text         = "Qual é o preço da PETR4?"
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

> **Esperado**: Resposta 200 com um Adaptive Card como attachment.

**Critérios de Sucesso**:
- ✅ `/api/messages` aceita requisições POST
- ✅ Activities do Bot Framework processadas corretamente
- ✅ Resposta contém um Adaptive Card como attachment
- ✅ Endpoint `/chat` ainda funciona (compatibilidade retroativa)

---

### Tarefa 3: Criar Adaptive Cards para Dados Financeiros (20 minutos)

**3.1 - Implementar o helper de card em `starter/main.py`**

```python
def create_financial_card(text: str, ticker: str = None, price: float = None) -> dict:
    """Cria um Adaptive Card para respostas financeiras."""
    body = [
        {
            "type": "ColumnSet",
            "columns": [
                {
                    "type": "Column", "width": "stretch",
                    "items": [{
                        "type": "TextBlock",
                        "text": "💹 Consultor Financeiro",
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

    # Adicionar linha de preço estruturado se dados disponíveis
    if ticker and price is not None:
        body.append({
            "type": "FactSet",
            "facts": [
                {"title": "Ticker", "value": ticker},
                {"title": "Preço", "value": f"R$ {price:.2f}"}
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

**3.2 - Validar o schema do card**

Antes de implantar, valide seu card em [https://adaptivecards.io/designer](https://adaptivecards.io/designer):
- Versão do schema deve ser **1.4 ou inferior** (máximo do Teams)
- Todas as propriedades referenciadas devem ser válidas para a versão selecionada

**Critérios de Sucesso**:
- ✅ Adaptive Card renderiza a resposta textual
- ✅ `FactSet` opcional incluído para dados estruturados de ticker/preço
- ✅ Schema do card validado (versão ≤ 1.4)
- ✅ Card usado no handler `on_message_activity`

---

### Tarefa 4: Reimplantar no ACA (20 minutos)

> **Ponto chave**: Atualizar a imagem do container NÃO requer re-registrar o agente no Foundry. A URL do endpoint registrado permanece a mesma — o Foundry automaticamente serve o novo código.

**4.1 - Executar o script de deploy**

```powershell
cd lesson-5-a365-langgraph/labs/solution

.\deploy.ps1
```

O script de deploy:
1. Constrói a nova imagem de container com Bot Framework + OpenTelemetry
2. Faz push para o ACR
3. Atualiza o app ACA para a nova revisão da imagem
4. Configura `APPLICATIONINSIGHTS_CONNECTION_STRING` como variável de ambiente

**4.2 - Definir variáveis de ambiente no ACA**

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

> `MICROSOFT_APP_ID` / `MICROSOFT_APP_PASSWORD` ficam vazios por enquanto — serão preenchidos no Lab 6 após o Agent Blueprint ser registrado.

**4.3 - Verificar a implantação**

```powershell
$FQDN = az containerapp show `
    --name $ACA_NAME --resource-group $RG `
    --query "properties.configuration.ingress.fqdn" -o tsv

# Health check
Invoke-RestMethod -Uri "https://$FQDN/health"

# Endpoint REST de chat
python ../../../test/chat.py --lesson 5 --endpoint "https://$FQDN"

# Endpoint Bot Framework
$activity = @{
    type="message"; text="Resumo de mercado do IBOV";
    from=@{id="u1"}; conversation=@{id="c1"}
    channelId="test"; serviceUrl="https://test.botframework.com"
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://$FQDN/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

**Critérios de Sucesso**:
- ✅ Container reimplantado sem downtime
- ✅ `/health` retorna `{ "status": "ok" }`
- ✅ Endpoint `/chat` responde corretamente
- ✅ `/api/messages` aceita Bot Framework activities
- ✅ Nenhum re-registro necessário no Foundry

---

### Tarefa 5: Verificar Observabilidade (20 minutos)

#### Application Insights (todas as chamadas — diretas e via gateway)

**Transaction Search** (requisição individual end-to-end):
1. Portal Azure → seu recurso Application Insights → **Transaction search**
2. Defina o intervalo de tempo para **Últimos 30 minutos**
3. Clique em uma entrada `POST /chat` ou `POST /api/messages`
4. Clique em **View all telemetry** → inspecione o waterfall **End-to-end transaction**
5. Verifique se spans customizados aparecem: `get_stock_price`, `get_exchange_rate`, etc., cada um com timing

**Performance** (latência agregada):
1. Application Insights → **Performance**
2. Selecione a operação `POST /chat`
3. Visualize latências P50 / P95 / P99
4. Clique em **Drill into samples** → selecione um trace lento → identifique qual span de tool causou o atraso

**Live Metrics** (tempo real — útil durante demos ao vivo):
1. Application Insights → **Live metrics**
2. Mantenha aberto enquanto envia mensagens de teste; veja requisições, falhas e telemetria do servidor com ~1 s de latência

**Queries KQL** no Log Analytics:
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

#### Portal do Foundry (apenas chamadas via gateway)

> O Foundry só captura traces de chamadas roteadas pelo **endpoint do AI Gateway** (URL do projeto Foundry), não de chamadas diretas ao ACA.

1. Portal Azure → Azure AI Foundry → seu projeto → **Tracing** (menu esquerdo)
2. Envie uma requisição via endpoint do projeto Foundry:
   ```powershell
   python ../../../test/chat.py --lesson 4 --endpoint $aiProjectEndpoint
   ```
3. Clique na entrada de trace → veja o waterfall de spans: `gateway → ACA /chat → nós LangGraph`
4. Observe uso de tokens e latência por hop

**Critérios de Sucesso**:
- ✅ Application Insights mostra requisições para `/chat` e `/api/messages`
- ✅ Spans customizados de tools visíveis no Transaction Search
- ✅ Foundry Tracing mostra traces para chamadas roteadas via gateway
- ✅ Latência P95 identificada em Performance

---

## Entregáveis

- [x] Observabilidade OpenTelemetry integrada (`configure_azure_monitor`, spans customizados)
- [x] Endpoint Bot Framework `/api/messages` implementado
- [x] Adaptive Cards criados e validados
- [x] Agente reimplantado no ACA (sem re-registro)
- [x] Traces visíveis no Application Insights
- [x] Traces visíveis no portal do Foundry (via caminho gateway)

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|-----------|--------|-------------|
| **Setup OpenTelemetry** | 20 pts | `configure_azure_monitor` + spans customizados de tools |
| **Endpoint Bot Framework** | 30 pts | `/api/messages` funcional, activities processadas |
| **Adaptive Cards** | 20 pts | Card implementado, schema válido, renderiza corretamente |
| **Reimplantação no ACA** | 20 pts | Nova imagem implantada, health checks funcionando |
| **Observabilidade Verificada** | 10 pts | Traces confirmados no App Insights e Foundry |

**Total**: 100 pontos

## Resolução de Problemas

### Telemetria não aparece no Application Insights
- **Causa**: Connection string não definida ou incorreta
- **Solução**: Verifique a variável de ambiente `APPLICATIONINSIGHTS_CONNECTION_STRING` no ACA. Reinicie a revisão do container após defini-la.

### `/api/messages` retorna 401
- **Causa**: `MICROSOFT_APP_ID` definido mas credenciais ainda não configuradas (Lab 6 é necessário primeiro)
- **Solução**: Deixe `MICROSOFT_APP_ID` vazio por enquanto — o Bot Framework pula a validação de auth quando App ID está vazio, o que é aceitável para testes.

### Adaptive Card não renderiza
- **Causa**: Schema inválido ou versão > 1.4
- **Solução**: Valide em [https://adaptivecards.io/designer](https://adaptivecards.io/designer). Certifique-se de usar `"version": "1.4"`.

### Spans customizados ausentes no App Insights
- **Causa**: `configure_azure_monitor()` chamado após criação do tracer
- **Solução**: Chame `configure_azure_monitor()` antes de qualquer chamada a `trace.get_tracer()`.

### Foundry Tracing não mostra traces
- **Causa**: Chamadas de teste foram diretamente ao ACA, não pelo AI Gateway
- **Solução**: Use o endpoint do projeto Foundry (`$aiProjectEndpoint`) em vez do FQDN do ACA.

## Estimativa de Tempo

- Tarefa 1: 20 minutos
- Tarefa 2: 30 minutos
- Tarefa 3: 20 minutos
- Tarefa 4: 20 minutos
- Tarefa 5: 20 minutos
- **Total**: ~110 minutos

## Próximos Passos

- **Lab 6**: Registrar o agente no Microsoft Entra ID, configurar o A365 CLI e configurar o Agent Blueprint para que o endpoint `/api/messages` seja integrado ao Microsoft Teams.

---

**Dificuldade**: Avançado  
**Pré-requisitos**: Lab 4, connection string do Application Insights  
**Tempo Estimado**: ~110 minutos
