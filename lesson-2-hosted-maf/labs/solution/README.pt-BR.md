# Lição 1: Agente de Mercado Financeiro com Microsoft Agent Framework

## Objetivo

Nesta lição, você criará e implantará um agente de IA usando o **Microsoft Agent Framework** (MAF) no Microsoft Foundry. O agente é especializado em mercados financeiros e expõe ferramentas Python para consultar cotações, taxas de câmbio e resumos de mercado.

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
lesson-2-hosted-maf/labs/solution/
  agent.yaml           # Manifesto do agente (nome, runtime, modelo, ferramentas, otel)
  app.py               # Servidor HTTP (agentserver-agentframework)
  Dockerfile           # Imagem do contêiner para implantação
  # create_hosted_agent.py movido para prereq/
  deploy.ps1           # Script de implantação automatizada (az CLI)
  test_agent.py        # Cliente console que testa o agente via backend Foundry
  requirements.txt     # Dependências Python (versionadas)
  .env                 # Variáveis de ambiente (gerado automaticamente pelo deploy)
  src/
    __init__.py
    main.py            # Ponto de entrada: função run(user_input, thread_id)
    agent/
      __init__.py
      finance_agent.py # Classe do agente (AzureAIClient + ferramentas)
  tools/
    __init__.py
    finance_tools.py   # Funções de ferramentas expostas ao agente
```

## Pré-requisitos

1. Infraestrutura provisionada via `prereq/deploy.ps1`
2. Azure CLI (`az`) instalado e autenticado
3. Python 3.10+
4. Docker (para construção da imagem)
5. Agente publicado como Hosted Agent no Foundry (para testes via `test_agent.py`)

## Deploy Rápido

```powershell
cd lesson-1/foundry-agent
.\deploy.ps1
```

O script automaticamente:
1. Obtém outputs da implantação Bicep (endpoint, modelo, ACR)
2. Constrói imagem Docker no ACR
3. Atribui roles RBAC (AcrPull + Cognitive Services OpenAI User)
4. Cria nova versão de hosted agent via `az cognitiveservices agent`
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

### Testar o agente (cliente console -> backend Foundry)

```bash
# Testa o hosted agent no Foundry via Responses API
python test_agent.py

# Opções
python test_agent.py --endpoint <project-endpoint>
python test_agent.py --agent-name <name> --agent-version <version>
```

## Tecnologias

| Componente | Tecnologia |
|-----------|-----------|
| Framework | Microsoft Agent Framework (`agent-framework-azure-ai`) |
| Modelo | gpt-4.1 via Azure OpenAI (Foundry) |
| Servidor HTTP | `azure-ai-agentserver-agentframework` |
| Identidade | Managed Identity (`DefaultAzureCredential`) |
| Observabilidade | OpenTelemetry + Azure Monitor |
| Contêiner | Docker -> Azure Container Registry |
| Hospedagem | Microsoft Foundry Hosted Agent |

## Ferramentas Disponíveis

| Ferramenta | Descrição |
|------|-----------|
| `get_stock_quote(ticker)` | Cotações de ações (PETR4, VALE3, AAPL, MSFT, etc.) |
| `get_exchange_rate(pair)` | Taxa de câmbio (USD/BRL, EUR/BRL, etc.) |
| `get_market_summary(market)` | Resumo de mercado (brazil, usa, europe, global) |

## Observabilidade

O agente exporta traces via OpenTelemetry para o Azure Monitor (Application Insights):

- **Span `agent_run`**: Cada execução do agente com atributos `user_input`, `thread_id`, `response_length`
- **Span `create_finance_agent`**: Criação/inicialização do agente
- **Métricas automáticas**: Latência, erros, throughput via Azure Monitor SDK

Visualize no portal: Application Insights > Transaction Search.
