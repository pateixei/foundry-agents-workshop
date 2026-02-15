## Como Hospedar um Agente LangGraph no Azure AI Foundry

### Pré-requisitos de Infraestrutura Azure

1. **Azure AI Foundry (account + projeto)** — O Foundry fornece o API gateway (Responses API), o Capability Host que gerencia o contêiner e acesso ao modelo.

2. **Azure Container Registry (ACR)** — para armazenar a imagem Docker do seu agente.

3. **Modelo implantado** — uma implantação de modelo (ex., `gpt-4.1`) no Foundry, acessível via Azure OpenAI.

4. **Managed Identity com RBAC** — a identidade do projeto precisa de:
   - **AcrPull** no Container Registry (para puxar a imagem)
   - **Cognitive Services OpenAI User** na conta Foundry (para o contêiner chamar o modelo)

5. **Capability Host** — recurso Foundry que gerencia o ciclo de vida do contêiner (start/stop/roteamento). Criado automaticamente ao registrar o agente.

### O Que Muda no Código LangGraph

Seu código LangGraph em si (grafo, ferramentas, nós) **não muda**. As adaptações são apenas na camada de integração:

#### 1. Dependência única: `azure-ai-agentserver-langgraph`

```
azure-ai-agentserver-langgraph==1.0.0b10
```

Este pacote traz tudo: o adaptador que expõe o grafo como Responses API, mais dependências LangGraph/LangChain.

#### 2. Adaptador `from_langgraph` no ponto de entrada

Em vez de executar o grafo manualmente, você o expõe via adaptador:

```python
from azure.ai.agentserver.langgraph import from_langgraph

agent = build_agent()       # seu StateGraph compilado
adapter = from_langgraph(agent)
adapter.run()                # abre servidor HTTP na porta 8088
```

Isso transforma o grafo LangGraph em um servidor Responses API que o Foundry sabe chamar.

#### 3. LLM via `AzureChatOpenAI` com credencial Azure

O contêiner usa `DefaultAzureCredential` (managed identity) para autenticar no Azure OpenAI:

```python
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from langchain_openai import AzureChatOpenAI

credential = DefaultAzureCredential()
token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")

llm = AzureChatOpenAI(
    azure_deployment=os.getenv("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-4o-mini"),
    azure_ad_token_provider=token_provider,
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_version="2025-01-01-preview",
)
```

#### 4. Variáveis de ambiente consumidas pelo contêiner

O Foundry injeta essas variáveis de ambiente ao iniciar o contêiner:

| Variável | Descrição |
|---|---|
| `AZURE_AI_PROJECT_ENDPOINT` | Endpoint do projeto Foundry |
| `AZURE_AI_MODEL_DEPLOYMENT_NAME` | Nome da implantação do modelo |
| `AZURE_OPENAI_ENDPOINT` | Endpoint OpenAI do Foundry (`https://<account>.openai.azure.com/`) |
| `AZURE_CLIENT_ID` | Client ID da managed identity |

#### 5. Monkey-patch necessário (bug conhecido)

O pacote `azure-ai-agentserver-core` v1.0.0b10 não aceita o campo `id` que o Foundry envia em `AgentReference`. Você precisa fazer patch em `_deserialize_agent_reference` para ignorar campos extras — como implementado em [main.py](solution/main.py#L211-L245).

#### 6. Dockerfile

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . ./user_agent/
EXPOSE 8088
CMD ["python", "user_agent/main.py"]
```

A porta **8088** é esperada pelo Foundry para agentes LangGraph.

### Fluxo de Implantação

1. **Construir a imagem** no ACR: `az acr build --registry <acr> --image lg-market-agent:v1 .`
2. **Registrar o agente** via SDK (`create_hosted_agent.py`) ou CLI (`az cognitiveservices agent create`), passando a imagem ACR e variáveis de ambiente.
3. **Iniciar o agente**: `az cognitiveservices agent start --name <name> --agent-version 1`
4. **Testar** via portal Foundry (playground) ou cliente programático usando a Responses API.

### Resumo das Diferenças vs. LangGraph Standalone

| Aspecto | LangGraph Standalone | LangGraph no Foundry |
|---|---|---|
| Execução | Você executa `graph.invoke()` | Adaptador `from_langgraph(graph).run()` expõe HTTP |
| Autenticação LLM | Chave API ou qualquer método | Managed Identity via `DefaultAzureCredential` |
| System prompt | Passado no código | Passado no código (portal não permite edição) |
| Porta | Qualquer | **8088** (convenção Foundry) |
| Dependência extra | Nenhuma | `azure-ai-agentserver-langgraph` |
| Deploy | Onde você quiser | Imagem Docker no ACR → Foundry hosted agent |
