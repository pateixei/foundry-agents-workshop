## How to Host a LangGraph Agent on Azure AI Foundry

### Prerequisites in Azure Infrastructure

1. **Azure AI Foundry (account + project)** — Foundry provides the API gateway (Responses API), the Capability Host that manages the container, and model access.

2. **Azure Container Registry (ACR)** — to store your agent's Docker image.

3. **Deployed model** — a model deployment (e.g., `gpt-4.1`) in Foundry, accessible via Azure OpenAI.

4. **Managed Identity with RBAC** — the project identity needs:
   - **AcrPull** on the Container Registry (to pull the image)
   - **Cognitive Services OpenAI User** on the Foundry account (for the container to call the model)

5. **Capability Host** — Foundry resource that manages the container lifecycle (start/stop/routing). Automatically created when registering the agent.

### What Changes in LangGraph Code

Your LangGraph code itself (graph, tools, nodes) **does not change**. The adaptations are only in the integration layer:

#### 1. Single dependency: `azure-ai-agentserver-langgraph`

```
azure-ai-agentserver-langgraph==1.0.0b10
```

This package brings everything: the adapter that exposes the graph as a Responses API, plus LangGraph/LangChain dependencies.

#### 2. `from_langgraph` adapter at entry point

Instead of running the graph manually, you expose it via adapter:

```python
from azure.ai.agentserver.langgraph import from_langgraph

agent = build_agent()       # your compiled StateGraph
adapter = from_langgraph(agent)
adapter.run()                # opens HTTP server on port 8088
```

This transforms the LangGraph graph into a Responses API server that Foundry knows how to call.

#### 3. LLM via `AzureChatOpenAI` with Azure credential

The container uses `DefaultAzureCredential` (managed identity) to authenticate to Azure OpenAI:

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

#### 4. Environment variables consumed by the container

Foundry injects these env vars when starting the container:

| Variable | Description |
|---|---|
| `AZURE_AI_PROJECT_ENDPOINT` | Foundry project endpoint |
| `AZURE_AI_MODEL_DEPLOYMENT_NAME` | Model deployment name |
| `AZURE_OPENAI_ENDPOINT` | Foundry OpenAI endpoint (`https://<account>.openai.azure.com/`) |
| `AZURE_CLIENT_ID` | Managed identity client ID |

#### 5. Required monkey-patch (known bug)

The `azure-ai-agentserver-core` package v1.0.0b10 does not accept the `id` field that Foundry sends in `AgentReference`. You need to patch `_deserialize_agent_reference` to ignore extra fields — as implemented in [main.py](lesson-3-hosted-langgraph/langgraph-agent/main.py#L211-L245).

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

Port **8088** is expected by Foundry for LangGraph agents.

### Deployment Flow

1. **Build the image** in ACR: `az acr build --registry <acr> --image lg-market-agent:v1 .`
2. **Register the agent** via SDK (`create_hosted_agent.py`) or CLI (`az cognitiveservices agent create`), passing the ACR image and env vars.
3. **Start the agent**: `az cognitiveservices agent start --name <name> --agent-version 1`
4. **Test** via Foundry portal (playground) or programmatic client using the Responses API.

### Summary of Differences vs. Standalone LangGraph

| Aspect | Standalone LangGraph | LangGraph on Foundry |
|---|---|---|
| Execution | You run `graph.invoke()` | Adapter `from_langgraph(graph).run()` exposes HTTP |
| LLM Authentication | API key or any method | Managed Identity via `DefaultAzureCredential` |
| System prompt | Passed in code | Passed in code (portal does not allow editing) |
| Port | Any | **8088** (Foundry convention) |
| Extra dependency | None | `azure-ai-agentserver-langgraph` |
| Deploy | Wherever you want | Docker image in ACR → Foundry hosted agent |
