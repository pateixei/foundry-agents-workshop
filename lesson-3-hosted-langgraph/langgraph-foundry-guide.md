## Como hospedar um agente LangGraph no Azure AI Foundry

### Pré-requisitos na infraestrutura Azure

1. **Azure AI Foundry (account + project)** — o Foundry fornece o gateway de API (Responses API), o Capability Host que gerencia o container, e o acesso ao modelo.

2. **Azure Container Registry (ACR)** — para armazenar a imagem Docker do seu agente.

3. **Modelo deployado** — um deployment de modelo (ex: `gpt-4.1`) no Foundry, acessível via Azure OpenAI.

4. **Managed Identity com RBAC** — a identidade do projeto precisa de:
   - **AcrPull** no Container Registry (para puxar a imagem)
   - **Cognitive Services OpenAI User** no Foundry account (para o container chamar o modelo)

5. **Capability Host** — recurso do Foundry que gerencia o ciclo de vida do container (start/stop/routing). Criado automaticamente ao registrar o agente.

### O que muda no código LangGraph

Seu código LangGraph em si (grafo, tools, nodes) **não muda**. As adaptações são apenas na camada de integração:

#### 1. Dependência única: `azure-ai-agentserver-langgraph`

```
azure-ai-agentserver-langgraph==1.0.0b10
```

Este pacote traz tudo: o adapter que expõe o grafo como Responses API, mais as dependências do LangGraph/LangChain.

#### 2. Adapter `from_langgraph` no entry point

Em vez de rodar o grafo manualmente, você o expõe via adapter:

```python
from azure.ai.agentserver.langgraph import from_langgraph

agent = build_agent()       # seu StateGraph compilado
adapter = from_langgraph(agent)
adapter.run()                # abre servidor HTTP na porta 8088
```

Isso transforma o grafo LangGraph num servidor Responses API que o Foundry sabe chamar.

#### 3. LLM via `init_chat_model` com credencial Azure

O container usa `DefaultAzureCredential` (managed identity) para autenticar no Azure OpenAI:

```python
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from langchain.chat_models import init_chat_model

credential = DefaultAzureCredential()
token_provider = get_bearer_token_provider(credential, "https://cognitiveservices.azure.com/.default")

llm = init_chat_model(
    "azure_openai:gpt-4.1",
    azure_ad_token_provider=token_provider,
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_version="2025-01-01-preview",
)
```

#### 4. Variáveis de ambiente consumidas pelo container

O Foundry injeta estas env vars ao iniciar o container:

| Variável | Descrição |
|---|---|
| `AZURE_AI_PROJECT_ENDPOINT` | Endpoint do projeto Foundry |
| `AZURE_AI_MODEL_DEPLOYMENT_NAME` | Nome do deployment do modelo |
| `AZURE_OPENAI_ENDPOINT` | Endpoint OpenAI do Foundry (`https://<account>.openai.azure.com/`) |
| `AZURE_CLIENT_ID` | Client ID da managed identity |

#### 5. Monkey-patch obrigatório (bug conhecida)

O pacote `azure-ai-agentserver-core` v1.0.0b10 não aceita o campo `id` que o Foundry envia no `AgentReference`. É necessário fazer patch no `_deserialize_agent_reference` para ignorar campos extras — conforme implementado em [main.py](lesson-3-hosted-langgraph/langgraph-agent/main.py#L211-L245).

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

A porta **8088** é a esperada pelo Foundry para agentes LangGraph.

### Fluxo de deploy

1. **Build da imagem** no ACR: `az acr build --registry <acr> --image lg-market-agent:v1 .`
2. **Registrar o agente** via SDK (`create_hosted_agent.py`) ou CLI (`az cognitiveservices agent create`), passando a imagem ACR e as env vars.
3. **Iniciar o agente**: `az cognitiveservices agent start --name <name> --agent-version 1`
4. **Testar** via Foundry portal (playground) ou via cliente programático usando a Responses API.

### Resumo das diferenças vs. LangGraph standalone

| Aspecto | LangGraph standalone | LangGraph no Foundry |
|---|---|---|
| Execução | Você roda `graph.invoke()` | Adapter `from_langgraph(graph).run()` expõe HTTP |
| Autenticação LLM | API key ou qualquer método | Managed Identity via `DefaultAzureCredential` |
| System prompt | Passado no código | Passado no código (portal não permite editar) |
| Porta | Qualquer | **8088** (convenção Foundry) |
| Dependência extra | Nenhuma | `azure-ai-agentserver-langgraph` |
| Deploy | Onde quiser | Imagem Docker no ACR → Foundry hosted agent |
