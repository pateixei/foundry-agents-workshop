# Demo 2: Hosted Agent com MAF e Tools Personalizadas

## Visão Geral

Esta demo apresenta um **Hosted Agent (Agente Hospedado)** utilizando o **Microsoft Agent Framework (MAF)** com tools Python personalizadas. Diferente dos agentes declarativos (Demo 1), agentes hospedados executam em seu próprio contêiner e podem executar qualquer código Python como tools.

## O Que Esta Demo Demonstra

- ✅ Criação de tools Python personalizadas usando MAF
- ✅ Build e containerização de aplicações MAF
- ✅ Implantação de imagens de contêiner no Azure Container Registry (ACR)
- ✅ Registro de agentes hospedados no Foundry via Azure CLI
- ✅ Debug de agentes usando logs de contêiner e Application Insights
- ✅ Integração de OpenTelemetry para observabilidade

## Arquitetura

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

## Pré-requisitos

1. **Recursos Azure**:
   - Projeto Foundry com modelo implantado
   - Azure Container Registry (ACR)
   - Application Insights para telemetria

2. **Ferramentas Locais**:
   - Docker Desktop instalado e em execução
   - Azure CLI (`az`) versão 2.57+
   - Python 3.10+

3. **Permissões**:
   - Permissão de push no ACR (role AcrPush)
   - Permissão de implantação de agente no Foundry

## Estrutura de Arquivos

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

## Como Executar

### Passo 1: Configurar Ambiente

Crie o arquivo `.env`:
```bash
FOUNDRY_PROJECT_ENDPOINT=https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4.1
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=...;IngestionEndpoint=...
HOSTED_AGENT_VERSION=1
```

### Passo 2: Build e Deploy

Execute o script de implantação automatizada:
```powershell
.\deploy.ps1
```

O script irá:
1. ✅ Fazer build da imagem Docker
2. ✅ Tagar a imagem com o nome do ACR
3. ✅ Fazer push da imagem para o ACR
4. ✅ Criar/atualizar o agente hospedado no Foundry
5. ✅ Iniciar o contêiner do agente
6. ✅ Exibir status e logs do agente

**Saída Esperada**:
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

### Passo 3: Testar o Agente

```powershell
python test_agent.py
```

**Exemplo de Interação**:
```
🤖 Financial Advisor Agent (Hosted MAF)

You: Qual e o preco da PETR4?

Agent: 🔍 Consultando cotacao...
PETR4 (Petrobras PN): R$ 35,42 | Variacao: +1.23% (alta)

Esta informacao e simulada para fins educativos e nao constitui 
recomendacao de investimento.
```

## Implementação das Tools Personalizadas

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

**Pontos-Chave**:
- Funções usam type hints com `Annotated` para descrições de parâmetros
- O MAF converte automaticamente estes em esquemas de tools para o LLM
- Não é necessário decorator `@tool()` — o MAF descobre tools via registro de funções

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

**Pontos-Chave**:
- `AzureAIClient` é a classe principal do MAF para construir agentes
- Tools são registradas passando referências de funções
- Managed Identity (Identidade Gerenciada) (`DefaultAzureCredential`) autentica no Foundry
- `HOSTED_AGENT_VERSION` previne conflitos na criação do agente

## Entendendo Hosted Agents vs Declarativos

| Funcionalidade | Declarativo (Demo 1) | Hosted Agent com MAF (Esta Demo) |
|---------|---------------------|------------------------|
| **Tools** | Apenas catálogo Foundry | Qualquer código Python |
| **Implantação** | Chamada SDK | Build de contêiner + deploy |
| **Modificação** | Portal (instantâneo) | Alteração de código + reimplantação |
| **Infraestrutura** | Nenhuma (serverless) | Contêiner necessário |
| **Controle** | Limitado | Controle total |
| **Caso de Uso** | Protótipos | Produção com lógica personalizada |
| **Acesso a Banco de Dados** | ❌ Não | ✅ Sim (via Python) |
| **Chamadas de API** | ❌ Não | ✅ Sim (via Python) |

## Observabilidade com Application Insights

O agente integra OpenTelemetry para observabilidade completa:

```python
# In src/main.py
from azure.monitor.opentelemetry import configure_azure_monitor

connection_string = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if connection_string:
    configure_azure_monitor(connection_string=connection_string)
```

**Visualizar Telemetria**:
1. Portal Azure → Application Insights
2. Transaction Search → Filtrar pelos últimos 30 minutos
3. Visualize traces para:
   - Invocações do agente
   - Chamadas de tools
   - Requisições ao modelo
   - Tempos de resposta

## Resolução de Problemas

### Problema: "Cannot connect to Docker daemon"
**Causa**: Docker Desktop não está em execução  
**Solução**:
```powershell
# Windows: Start Docker Desktop from Start Menu
# Verify:
docker ps
```

### Problema: "ACR push failed: unauthorized"
**Causa**: Não autenticado no ACR  
**Solução**:
```powershell
az acr login --name acr123
```

### Problema: "Hosted agent creation failed: agent already exists"
**Causa**: Agente com mesmo nome/versão já existe  
**Solução**:
```powershell
# Stop and delete existing agent first
az cognitiveservices agent stop --name fin-market-maf --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
# Wait 60 seconds for status to become "Deleted"
az cognitiveservices agent status --name fin-market-maf --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
# Then delete
az cognitiveservices agent delete --name fin-market-maf --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```

### Problema: "Container fails to start: 400 ID cannot be null"
**Causa**: Problema conhecido do MAF com roteamento de referência do agente  
**Solução**: Consulte context.md para workarounds com monkey-patch ou use a versão mais recente do MAF com correções

### Problema: "No logs showing in Application Insights"
**Causa**: Atraso na propagação de telemetria (2-3 minutos)  
**Solução**: Aguarde 3-5 minutos após a primeira requisição, então atualize o portal

## Explicação do Script de Deploy

O script `deploy.ps1` automatiza toda a implantação:

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

## Próximos Passos

- **Demo 3**: Hosted Agent com LangGraph para workflows complexos
- **Demo 4**: Deploy em ACA para controle de infraestrutura
- **Demo 5**: SDK Agent 365 para integração com M365

## Recursos Adicionais

- [Documentação Microsoft Agent Framework](https://learn.microsoft.com/azure/ai-foundry/agent-framework/)
- [Referência da API AzureAIClient](https://learn.microsoft.com/python/api/agent-framework/)
- [Arquitetura de Hosted Agents](https://learn.microsoft.com/azure/ai-foundry/concepts/hosted-agents)

---

**Nível da Demo**: Intermediário  
**Tempo Estimado**: 30-40 minutos  
**Pré-requisitos**: Docker, ACR, projeto Foundry com modelo
