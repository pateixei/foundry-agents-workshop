# Lição 5: Integração com o SDK do Microsoft Agent 365

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Integrar** Azure Monitor / OpenTelemetry para rastreamento distribuído e observabilidade
2. **Implementar** o protocolo Bot Framework (endpoint `/api/messages`) para integração nativa com o Teams
3. **Criar** Adaptive Cards para respostas ricas e interativas no M365
4. **Instrumentar** funções de ferramentas com spans personalizados do OpenTelemetry
5. **Implantar** um agente aprimorado com telemetria de nível de produção
6. **Testar** agentes via API REST e formato de Activity do Bot Framework

---

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📝 Registro do Agente](REGISTER.pt-BR.md) | Como registrar o agente A365 |

---

## Visão Geral

Esta lição aprimora o agente LangGraph da Lição 4 com recursos do SDK do Microsoft Agent 365 para observabilidade, adaptive cards e integração nativa com o M365.

### Antes vs Depois

| Aspecto | Antes (FastAPI Genérico) | Depois (A365 SDK) |
|---------|--------------------------|---------------------|
| Endpoint | `/chat` (JSON customizado) | `/api/messages` (protocolo Bot Framework) |
| Respostas | Texto simples/JSON | Adaptive Cards (UI rica) |
| Monitoramento | Logs básicos | OpenTelemetry + Application Insights |
| Contexto | Parsing customizado de mensagens | Objetos Activity com identidade do usuário, ID de conversa |
| Integração M365 | Nenhuma | Suporte nativo a Teams/Outlook |

> **Sem o A365 SDK**: Seu agente é uma API REST genérica.
> **Com o A365 SDK**: Seu agente fala a linguagem do M365 — Activities, Adaptive Cards, telemetria.

---

## Arquitetura: Camada de Aprimoramento do SDK

```
Microsoft Teams / Outlook
    ↓ (Bot Framework Activity)
/api/messages endpoint (A365 SDK)
    ↓
BotFrameworkAdapter
    ↓ (TurnContext com identidade do usuário)
LangGraph Agent
    ↓ (instrumentado com spans OpenTelemetry)
Azure OpenAI + Tools
    ↓
Adaptive Card Response
    ↓ (enviado via TurnContext)
Teams / Outlook (UI rica)

── Telemetria ──────────────►  Application Insights
```

---

## Melhorias Principais

### 1. Observabilidade com Azure Monitor

Adicione rastreamento OpenTelemetry para depurar o comportamento do agente em produção:

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

**Instrumente funções de ferramentas** com spans personalizados para medição granular:

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

> No Application Insights, você verá: Quanto tempo levou `get_stock_price`? Qual foi a taxa de sucesso? Onde estão os gargalos?

### 2. Protocolo Bot Framework

Adicione o endpoint nativo `/api/messages` que o Teams e o Outlook usam para se comunicar:

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

> **Objetos Activity** permitem que o Teams envie contexto rico: identidade do usuário, ID de conversa, histórico do thread.

### 3. Adaptive Cards

Respostas ricas otimizadas para o M365 com elementos de UI interativos:

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

### 4. Ferramentas Aprimoradas

Todas as ferramentas instrumentadas com spans de rastreamento para:
- Monitoramento de desempenho por chamada de ferramenta
- Análise de uso (quais ferramentas são mais utilizadas)
- Rastreamento de erros com stack traces completos

---

## Novas Dependências

```txt
# A365 SDK e Observabilidade
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
```

---

## Implantação

```powershell
cd lesson-5-a365-langgraph
./deploy.ps1
```

Após a implantação, configure o Application Insights:
```powershell
# Get connection string
$connectionString = az monitor app-insights component show \
  --resource-group $rgName --app <app-insights-name> \
  --query connectionString -o tsv

# Update ACA environment variable
az containerapp update --name aca-lg-agent --resource-group $rgName \
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString"
```

Atualize a configuração do A365 com o novo endpoint:
```powershell
cd ../lesson-5-a365-prereq
a365 setup blueprint --skip-infrastructure
```

---

## Testes

### Verificação de Saúde
```powershell
Invoke-RestMethod "https://<endpoint>/health"
```

### API de Chat (compatível com versão anterior)
```powershell
$body = @{message = "Qual o preco da PETR4?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/chat" -Method Post -Body $body -ContentType "application/json"
```

### Bot Framework Activity (novo protocolo M365)
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

## Visualizar Telemetria

1. Portal do Azure → Application Insights → **Pesquisa de Transações**
2. Encontre requisições recentes (últimos 5 minutos)
3. Clique para ver a visualização **Transação ponta a ponta**
4. Verifique spans personalizados: `get_stock_price` visível com medição de tempo

### Métricas Principais para Monitorar

| Métrica | Onde | O que Observar |
|---------|------|----------------|
| Contagem de requisições | Application Insights → Requests | Volume de chamadas a `/api/messages` |
| Tempo de resposta | Application Insights → Performance | Latências P50, P95, P99 |
| Falhas | Application Insights → Failures | Requisições com falha e exceções |
| Tempo das ferramentas | Transaction Search → Custom spans | Duração de execução por ferramenta |
| Dependências | Application Insights → Dependencies | Chamadas a APIs externas (dados de ações) |

---

## 🔧 Solução de Problemas

| Problema | Causa | Solução |
|----------|-------|---------|
| Telemetria não aparece | Connection string incorreta | Verifique a variável de ambiente `APPLICATIONINSIGHTS_CONNECTION_STRING` e reinicie o container |
| `/api/messages` retorna 401 | Autenticação mal configurada | Verifique se as variáveis de ambiente `APP_ID` e `APP_PASSWORD` correspondem ao registro do Entra |
| Adaptive Cards não renderizam | Incompatibilidade de versão do schema | Verifique se o card usa Adaptive Card schema v1.5 para compatibilidade com o Teams |
| Spans personalizados ausentes | Tracer não inicializado | Verifique se `configure_azure_monitor()` executa antes da criação do tracer |
| Timeout no Bot Framework | Agente muito lento | Analise os spans das ferramentas no App Insights; otimize ferramentas lentas |

---

## ❓ Perguntas Frequentes

**P: Ainda preciso do endpoint `/chat` após adicionar `/api/messages`?**
R: Sim — mantenha ambos. `/chat` é útil para testes diretos e clientes que não são M365. `/api/messages` é o endpoint do protocolo Bot Framework para Teams/Outlook.

**P: Qual a diferença entre um Activity e uma requisição HTTP comum?**
R: Activities carregam contexto M365: identidade do usuário, ID de conversa, histórico do thread, informações do canal. Requisições HTTP comuns são payloads JSON sem estado.

**P: Quanto custa o Application Insights?**
R: Preço baseado em ingestão (~$2,30/GB). Para uso em escala de workshop, é insignificante. Em produção, configure amostragem para controlar custos.

**P: Posso testar o Bot Framework localmente sem o Teams?**
R: Sim — use o aplicativo desktop [Bot Framework Emulator](https://github.com/microsoft/BotFramework-Emulator) para enviar Activities ao seu endpoint local.

**P: Por que não usar permissões de Aplicativo em vez de Delegadas para o Bot?**
R: Permissões delegadas atuam em nome do usuário (User.Read). Permissões de aplicativo dariam ao bot acesso irrestrito. Use o menor privilégio — delegadas são mais seguras.

---

## 🏆 Desafios Autoguiados

1. **Dashboard Personalizado**: Crie um workbook do Application Insights que mostre uso de ferramentas do agente, tempos de resposta e taxas de erro em uma única visualização
2. **Adaptive Cards Avançados**: Construa um Adaptive Card multi-etapas com Action.Submit que permita aos usuários selecionar ações de um dropdown antes de consultar
3. **Memória de Conversa**: Estenda o handler do Bot Framework para manter o histórico de conversa em múltiplos turnos usando TurnContext
4. **Regras de Alerta**: Configure alertas do Application Insights para: taxa de erro >5%, tempo de resposta >2s e disponibilidade <99%
5. **Multi-Canal**: Teste o mesmo endpoint `/api/messages` a partir do Teams, Outlook e Bot Framework Emulator — documente as diferenças nos payloads de Activity
6. **Eventos de Telemetria Personalizados**: Adicione `tracer.start_as_current_span()` a cada ferramenta do seu agente e crie um mapa de dependências no App Insights

---

## Próximos Passos

- **Lição 7**: Publicar no M365 Admin Center
- **Lição 8**: Criar instâncias de agente no Teams

---

## Referências

- [Azure Monitor OpenTelemetry](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-overview)
- [Bot Framework SDK para Python](https://learn.microsoft.com/azure/bot-service/bot-builder-python-quickstart)
- [Adaptive Cards Designer](https://adaptivecards.io/designer/)
- [Preços do Application Insights](https://azure.microsoft.com/pricing/details/monitor/)
