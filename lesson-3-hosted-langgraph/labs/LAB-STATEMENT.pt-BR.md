# Lab 3: Implantar Agente LangGraph como Hosted Agent no Azure Foundry

## Objetivo

Implantar um **agente LangGraph como Hosted Agent (Agente Hospedado)** no Azure Foundry, demonstrando como equipes com expertise em LangGraph podem aproveitar a infraestrutura gerenciada do Azure com alterações mínimas de código.

## Cenário

Sua equipe possui um agente financeiro baseado em LangGraph. O negócio quer:
- Implantar no Azure Foundry para gerenciamento corporativo
- Aproveitar Managed Identity (Identidade Gerenciada) para autenticação segura
- Integrar com o ecossistema M365 (Teams, Outlook)
- Manter os padrões de código LangGraph existentes

Sua tarefa: Empacotar o agente LangGraph para a plataforma Hosted Agent do Foundry.

## Objetivos de Aprendizagem

- Implantar agentes LangGraph como Hosted Agents no Azure Foundry
- Configurar Azure OpenAI como provedor de modelo
- Configurar adaptador Foundry para LangGraph (`caphost.json`)
- Implantar agentes LangGraph como Foundry Hosted Agents
- Comparar arquiteturas LangGraph vs MAF
- Tomar decisões informadas de seleção de framework

## Pré-requisitos

- [x] Lab 2 completado (entendimento do MAF)
- [x] Conhecimento de LangGraph (recomendado mas não obrigatório)
- [x] Entendimento de implantações baseadas em contêiner
- [x] Docker e acesso ao ACR
- [x] Recurso Azure OpenAI implantado

## Tarefas

### Tarefa 1: Revisar Arquitetura do Agente LangGraph (10 minutos)

**Estude a estrutura do agente LangGraph fornecido**:

```
starter/langgraph-agent/
├── main.py                 # FastAPI + LangGraph entry point
├── financial_graph.py      # LangGraph StateGraph definition
├── tools.py                # Tool functions (same as MAF)
└── requirements.txt        # Python dependencies
```

**Componentes-chave para identificar**:
- Definição do StateGraph do LangGraph e roteamento de nodes
- Padrão de registro de funções de tools
- Configuração do provedor de modelo
- Entry point do servidor HTTP

**Perguntas para responder**:
1. Como o grafo do agente é estruturado (nodes e edges)?
2. Onde acontece a autenticação do modelo?
3. Como as tools são registradas no LangGraph?
4. Qual é o modelo de execução (síncrono vs assíncrono)?

**Critérios de Sucesso**:
- ✅ Entender o padrão StateGraph do LangGraph
- ✅ Identificar a configuração do modelo
- ✅ Reconhecer o modelo de implantação baseado em contêiner

### Tarefa 2: Criar Agente LangGraph para Azure (30 minutos)

Navegue até `starter/azure-agent/` e implemente:

**2.1 - Definir Estado do Agente**

```python
from typing import TypedDict, Annotated
from langchain_core.messages import BaseMessage

class FinancialAgentState(TypedDict):
    """State object for financial agent."""
    messages: Annotated[list[BaseMessage], "Conversation history"]
    current_tool: Annotated[str, "Currently executing tool"]
    tool_result: Annotated[dict, "Result from last tool call"]
```

**2.2 - Implementar Node de Tools**

```python
def tool_node(state: FinancialAgentState) -> FinancialAgentState:
    """Executes tool based on agent's decision."""
    # TODO: Extract tool name from last message
    # TODO: Call appropriate tool function
    # TODO: Update state with result
    return state
```

**2.3 - Implementar Node do Agente**

```python
from langchain_openai import AzureChatOpenAI

async def agent_node(state: FinancialAgentState, model: AzureChatOpenAI) -> FinancialAgentState:
    """LLM processes conversation and decides next action."""
    # TODO: Format messages for LLM
    # TODO: Call Azure OpenAI via model
    # TODO: Determine if tool call needed
    # TODO: Update state
    return state
```

**2.4 - Construir StateGraph**

```python
from langgraph.graph import StateGraph, END

def create_financial_graph() -> StateGraph:
    """Builds LangGraph workflow for financial agent."""
    workflow = StateGraph(FinancialAgentState)
    
    # TODO: Add nodes (agent, tools)
    # TODO: Define edges (agent -> tools, tools -> agent, agent -> END)
    # TODO: Set entry point
    # TODO: Compile graph
    
    return workflow.compile()
```

**2.5 - Configurar Azure OpenAI como Provedor de Modelo**

```python
from langchain_openai import AzureChatOpenAI
model = AzureChatOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
    azure_deployment="gpt-4",
    temperature=0.7,
)
```

**Critérios de Sucesso**:
- ✅ Objeto de estado corretamente tipado
- ✅ Node de tools executa tools baseado no estado
- ✅ Node do agente processa respostas do LLM
- ✅ Grafo compilado sem erros
- ✅ Azure OpenAI configurado como provedor de modelo

### Tarefa 3: Configurar Adaptador Foundry (15 minutos)

**3.1 - Criar `caphost.json`**

```json
{
  "name": "langgraph-financial-agent",
  "version": "1.0",
  "entry":  "main:app",
  "runtime": "python",
  "port": 8080,
  "health_check": "/health",
  "environment": {
    "AZURE_OPENAI_ENDPOINT": "${AZURE_OPENAI_ENDPOINT}",
    "AZURE_OPENAI_DEPLOYMENT": "${AZURE_OPENAI_DEPLOYMENT}",
    "AZURE_CLIENT_ID": "${MANAGED_IDENTITY_CLIENT_ID}"
  }
}
```

**Propósito**: Indica ao Foundry como invocar seu agente LangGraph
- `entry`: Módulo e callable para invocar
- `port`: Porta do servidor HTTP (LangGraph usa 8080, MAF usa 8088)
- `health_check`: Endpoint para monitoramento de saúde

**3.2 - Implementar Wrapper HTTP**

Crie `main.py`:
```python
from fastapi import FastAPI, Request
from financial_graph import create_financial_graph

app = FastAPI()
graph = create_financial_graph()

@app.post("/invoke")
async def invoke_agent(request: Request):
    """Foundry calls this endpoint to invoke agent."""
    body = await request.json()
    user_message = body.get("message")
    
    # Run LangGraph
    result = await graph.ainvoke({
        "messages": [user_message],
        "current_tool": None,
        "tool_result": {}
    })
    
    return {"response": result["messages"][-1].content}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

**Critérios de Sucesso**:
- ✅ `caphost.json` configurado corretamente
- ✅ Endpoints HTTP implementados (FastAPI)
- ✅ Invocação do grafo funciona de forma assíncrona

### Tarefa 4: Criar Dockerfile (10 minutos)

Crie o Dockerfile para implantação no Azure Foundry:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Pontos-Chave**:
- Imagem base: Python slim (leve)
- Porta: 8080 para compatibilidade com Foundry
- CMD: Servidor web uvicorn para FastAPI
- Diretório de trabalho: `/app`

**Critérios de Sucesso**:
- ✅ Build do Dockerfile realizado com sucesso
- ✅ Contêiner expõe a porta correta
- ✅ uvicorn inicia corretamente

### Tarefa 5: Implantar no Azure Foundry (20 minutos)

**5.1 - Fazer build e push do contêiner**

```powershell
docker build -t langgraph-financial-agent:v1 .
az acr login --name YOUR-ACR
docker tag langgraph-financial-agent:v1 YOUR-ACR.azurecr.io/langgraph- financial-agent:v1
docker push YOUR-ACR.azurecr.io/langgraph-financial-agent:v1
```

**5.2 - Criar Hosted Agent**

```powershell
az cognitiveservices agent create \
  --name langgraph-financial-agent \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-PROJECT \
  --image "YOUR-ACR.azurecr.io/langgraph-financial-agent:v1" \
  --env "AZURE_OPENAI_ENDPOINT=..." \
       "AZURE_OPENAI_DEPLOYMENT=gpt-4" \
       "HOSTED_AGENT_VERSION=1"
```

**5.3 - Iniciar agente**

```powershell
az cognitiveservices agent start \
  --name langgraph-financial-agent \
  --agent-version 1 \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-PROJECT
```

**Critérios de Sucesso**:
- ✅ Contêiner implantado no ACR
- ✅ Hosted Agent criado no Foundry
- ✅ Status do agente mostra "Running"

### Tarefa 6: Testar e Comparar (15 minutos)

**6.1 - Testar agente implantado**

```powershell
python test_agent.py
```

Teste as mesmas perguntas:
1. "What's the PETR4 stock price?"
2. "Calculate portfolio value: 100 PETR4, 50 VALE3"
3. "Give me Brazil market summary"

**6.2 - Comparar com agente MAF (Lab 2)**

| Funcionalidade | LangGraph (Este Lab) | MAF (Lab 2) |
|---------|---------------------|-------------|
| **Linhas de Código** | ~150 linhas | ~80 linhas |
| **Complexidade** | Maior (orquestração explícita) | Menor (automática) |
| **Controle** | Controle total sobre o fluxo | Gerenciado pelo framework |
| **Gerenciamento de Estado** | Manual (TypedDict) | Integrado |
| **Chamada de Tools** | Roteamento manual de nodes | Padrão ReAct automático |
| **Portabilidade** | Alta (grafo independente de plataforma) | Nativo Azure |

**6.3 - Matriz de Decisão**

Quando você escolheria LangGraph ao invés de MAF?
- [x] Equipe possui expertise ou código existente em LangGraph
- [x] Necessita de controle explícito sobre o fluxo do agente
- [x] Workflows complexos de múltiplas etapas
- [x] Requisitos de gerenciamento de estado personalizado

Quando você escolheria MAF ao invés de LangGraph?
- [x] Novo desenvolvimento de agente do zero no Azure
- [x] Padrões simples de chamada de tools
- [x] Quer desenvolvimento mais rápido (menos boilerplate)
- [x] Prefere convenções de framework sobre controle

**Critérios de Sucesso**:
- ✅ Agente funcional e produz respostas corretas
- ✅ Desempenho comparável
- ✅ Entendimento claro dos trade-offs entre frameworks

## Entregáveis

- [x] Agente LangGraph configurado com Azure OpenAI
- [x] `caphost.json` configurado
- [x] Dockerfile para implantação Azure
- [x] Agente implantado e executando no Foundry
- [x] Documento de comparação: LangGraph vs MAF
- [x] Checklist de implantação completado

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|-----------|--------|-------------|
| **Estratégia de Implantação** | 15 pts | Identificou componentes e necessidades de configuração |
| **Implementação LangGraph** | 30 pts | State, nodes, edges configurados corretamente |
| **Integração Azure OpenAI** | 20 pts | Azure OpenAI configurado como provedor de modelo |
| **Implantação** | 20 pts | Contêiner construído e agente executando |
| **Testes** | 10 pts | Agente produz respostas corretas |
| **Análise Comparativa** | 5 pts | Avaliação criteriosa LangGraph vs MAF |

**Total**: 100 pontos

## Resolução de Problemas

### "Graph compilation error: node not found"
- Verifique se todos os nodes referenciados em edges foram adicionados ao grafo
- Confira se os nomes dos nodes correspondem exatamente (sensível a maiúsculas/minúsculas)

### "Azure OpenAI 401 Unauthorized"
- Certifique-se de que a Managed Identity possui a role "Cognitive Services User"
- Verifique se `AZURE_OPENAI_ENDPOINT` está correto

### "caphost.json not found during deployment"
- O arquivo deve estar no diretório raiz do contêiner
- Certifique-se de que o comando COPY do Dockerfile o inclui

### "Tool execution fails in graph"
- Verifique se as funções de tools estão importadas corretamente
- Confirme se os nomes das tools correspondem à saída de function call do LLM

## Estimativa de Tempo

- Tarefa 1: 10 minutos
- Tarefa 2: 30 minutos
- Tarefa 3: 15 minutos
- Tarefa 4: 10 minutos
- Tarefa 5: 20 minutos
- Tarefa 6: 15 minutos
- **Total**: 100 minutos

## Próximos Passos

- **Lab 4**: Implantar no Azure Container Apps para controle de infraestrutura
- Entender o padrão Connected Agent (Agente Conectado)
- Aprender Bicep IaC para implantação Azure

---

**Dificuldade**: Intermediário-Avançado  
**Pré-requisitos**: Labs 1-2, conhecimento básico de LangGraph  
**Tempo Estimado**: 100 minutos
