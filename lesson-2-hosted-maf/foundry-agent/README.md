# Licao 1: Agente de Mercado Financeiro com Microsoft Agent Framework

## Objetivo

Nesta licao, voce criara e fara o deployment de um agente de IA usando o **Microsoft Agent Framework** (MAF) no Microsoft Foundry. O agente e especializado em mercado financeiro e expoe tools Python para consultar cotacoes, cambio e resumos de mercado.

## Arquitetura

```
Foundry Project (ag365-prj001)
  |
  +-- Hosted Agent (fin-market-agent)
        |-- Microsoft Agent Framework (Python)
        |-- Model: gpt-4.1 (Azure OpenAI)
        |-- Tools: get_stock_quote, get_exchange_rate, get_market_summary
        |-- Identity: Managed Identity
        |-- Observability: OpenTelemetry -> Azure Monitor
```

## Estrutura do Projeto

```
lesson-1/foundry-agent/
  agent.yaml           # Manifesto do agente (nome, runtime, model, tools, otel)
  app.py               # HTTP server (agentserver-agentframework)
  Dockerfile           # Container image para deploy
  # create_hosted_agent.py movido para prereq/
  deploy.ps1           # Script de deploy automatizado (az CLI)
  test_agent.py        # Console client que testa o agente via Foundry backend
  requirements.txt     # Dependencias Python (pinned)
  .env                 # Variaveis de ambiente (auto-gerado pelo deploy)
  src/
    __init__.py
    main.py            # Entrypoint: funcao run(user_input, thread_id)
    agent/
      __init__.py
      finance_agent.py # Classe do agente (AzureAIClient + tools)
  tools/
    __init__.py
    finance_tools.py   # Funcoes-ferramenta expostas ao agente
```

## Pre-requisitos

1. Infraestrutura provisionada via `prereq/deploy.ps1`
2. Azure CLI (`az`) instalado e autenticado
3. Python 3.10+
4. Docker (para build da imagem)
5. Agente publicado como Hosted Agent no Foundry (para testes via `test_agent.py`)

## Deploy Rapido

```powershell
cd lesson-1/foundry-agent
.\deploy.ps1
```

O script automaticamente:
1. Obtem outputs do deployment Bicep (endpoint, model, ACR)
2. Faz build da imagem Docker no ACR
3. Atribui roles RBAC (AcrPull + Cognitive Services OpenAI User)
4. Cria nova versao do hosted agent via `az cognitiveservices agent`
5. Inicia o agente
6. Aguarda o agente ficar Running

## Uso Manual

### Configurar ambiente

```bash
pip install -r requirements.txt
```

Edite o `.env`:

```
FOUNDRY_PROJECT_ENDPOINT=https://<foundry>.services.ai.azure.com/api/projects/<project>
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4.1
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=...
```

### Testar o agente (console client -> Foundry backend)

```bash
# Testa o hosted agent no Foundry via Responses API
python test_agent.py

# Opcoes
python test_agent.py --endpoint <project-endpoint>
python test_agent.py --agent-name <nome> --agent-version <versao>
```

## Tecnologias

| Componente | Tecnologia |
|-----------|-----------|
| Framework | Microsoft Agent Framework (`agent-framework-azure-ai`) |
| Modelo | gpt-4.1 via Azure OpenAI (Foundry) |
| HTTP Server | `azure-ai-agentserver-agentframework` |
| Identity | Managed Identity (`DefaultAzureCredential`) |
| Observabilidade | OpenTelemetry + Azure Monitor |
| Container | Docker -> Azure Container Registry |
| Hosting | Microsoft Foundry Hosted Agent |

## Tools Disponiveis

| Tool | Descricao |
|------|-----------|
| `get_stock_quote(ticker)` | Cotacao de acoes (PETR4, VALE3, AAPL, MSFT, etc.) |
| `get_exchange_rate(pair)` | Taxa de cambio (USD/BRL, EUR/BRL, etc.) |
| `get_market_summary(market)` | Resumo do mercado (brasil, eua, europa, global) |

## Observabilidade

O agente exporta traces via OpenTelemetry para o Azure Monitor (Application Insights):

- **Span `agent_run`**: Cada execucao do agente com atributos `user_input`, `thread_id`, `response_length`
- **Span `create_finance_agent`**: Criacao/inicializacao do agente
- **Metricas automaticas**: Latencia, erros, throughput via Azure Monitor SDK

Visualize no portal: Application Insights > Transaction Search.
