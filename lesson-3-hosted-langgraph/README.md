# Lesson 3 - Hosted Agent with LangGraph

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Navigation

| Resource | Description |
|----------|-------------|
| [📖 Demo Walkthrough](demos/README.md) | Code walkthrough and demo instructions |
| [🔬 Lab Exercise](labs/LAB-STATEMENT.md) | Hands-on lab with tasks and success criteria |
| [📐 Architecture Diagram](media/lesson-3-architecture.png) | Architecture overview |
| [🛠️ Deployment Diagram](media/lesson-3-deployment.png) | Deployment flow |
| [📁 Solution Notes](labs/solution/README.md) | Solution code and deployment details |
| [📚 LangGraph Foundry Guide](langgraph-foundry-guide.md) | Deep-dive on LangGraph + Foundry integration |

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

1. **Deploy** LangGraph agents on Azure Foundry using the adapter pattern
2. **Implement** LangGraph agents with custom tools and graph-based orchestration
3. **Compare** LangGraph and MAF architectures side-by-side
4. **Register** LangGraph agents as Foundry Hosted Agents
5. **Decide** when to use LangGraph vs MAF for specific use cases
6. **Map** LangGraph deployments across different cloud environments

## Why LangGraph on Foundry?

In Lesson 2 you built a hosted agent with MAF. But what if you already have LangGraph agents running elsewhere, or need fine-grained control over orchestration?

**LangGraph is framework-agnostic** — your core graph code (nodes, edges, state) stays the same regardless of where you deploy. Moving to Foundry requires minimal changes: swap the model provider and add a config file.

> Your graph definitions, nodes, edges — **all unchanged**. The adapter pattern handles the platform integration.

### Why Deploy on Foundry Instead of Other Platforms?

- **Unified platform** — Foundry integrates agents with Copilot, Teams, and M365
- **Enterprise governance** — Centralized agent management, RBAC, auditing
- **Cost optimization** — Azure EA agreements, reserved instances
- **Compliance** — Data residency requirements via Azure regions
- **Ecosystem** — Native integration with Azure services (Cosmos DB, Key Vault, etc.)

> Deploying on Foundry isn't just about hosting — it's **strategic positioning** for enterprise AI.

## Architecture

**Traditional LangGraph deployment:**
```
┌──────────────────────────┐
│ Container / Function     │
│  ├─> LangGraph code      │
│  └─> LLM API client      │
└──────────┬───────────────┘
           │ (triggered by)
           ▼
┌──────────────────────────┐
│ API Gateway              │
└──────────────────────────┘
```

**On Azure Foundry:**
```
┌──────────────────────────────────┐
│ Foundry Hosted Agent             │
│  ├─> Container (same LangGraph!) │
│  └─> Azure OpenAI via Foundry    │
└──────────┬───────────────────────┘
           │ (accessed via)
           ▼
┌──────────────────────────────────┐
│ Foundry Responses API            │
└──────────────────────────────────┘
```

The key difference: Foundry hosted agents are **always-on containers** designed for persistent agent workloads. If you've run LangGraph in containers before, deployment to Foundry is straightforward.

## Key Concepts

| Concept | Description |
|---|---|
| **Hosted Agent** | Own container registered in Foundry that exposes the Responses API |
| **LangGraph** | Graph framework for agent orchestration — you define nodes, edges, and conditional routing |
| **Adapter** | `azure-ai-agentserver-langgraph` converts a LangGraph graph into an HTTP server compatible with Foundry |
| **caphost.json** | Configuration file that tells the adapter how to load your graph and expose it to Foundry |
| **Capability Host** | Resource at the Foundry account level that enables hosted agents |
| **Managed Identity** | The container runs with the project's identity (needs RBAC roles) — no API keys in code |

## Lesson Structure

```
lesson-3-hosted-langgraph/
  README.md
  langgraph-foundry-guide.md     # Deep-dive guide
  demos/                          # Demo walkthrough
  labs/                           # Hands-on lab
    solution/
      main.py                     # LangGraph agent definition
      Dockerfile                  # Container (similar to MAF)
      requirements.txt            # Dependencies
      deploy.ps1                  # Deployment script
      caphost.json                # Foundry adapter config
      README.md                   # Solution notes
  media/                          # Architecture diagrams
```

### Key Files Explained

| File | Role |
|---|---|
| `main.py` | LangGraph agent — state definition, tools, graph nodes/edges, compiled app |
| `caphost.json` | The "glue" between LangGraph and Foundry — tells the adapter where your app is |
| `Dockerfile` | Container definition — runs the adapter (not `main.py` directly) |
| `deploy.ps1` | One-click deployment — builds in ACR, registers in Foundry, tests |

> **Simpler than MAF**: No `src/` folders, no agent server abstraction. LangGraph + config file + adapter.

## Step-by-Step Walkthrough

### 1. Understand the LangGraph Agent Code

The agent code is **pure LangGraph** — nothing Foundry-specific except the model provider:

**State definition:**
```python
class AgentState(TypedDict):
    messages: Annotated[list, "conversation history"]
    next_action: str
```

**Tools (plain Python functions):**
```python
def get_stock_price(symbol: str) -> dict:
    """Fetch stock price."""
    prices = {"AAPL": 175.50, "PETR4": 38.20, "VALE3": 65.80}
    return {
        "symbol": symbol.upper(),
        "price": prices.get(symbol.upper(), 0.0),
        "currency": "USD" if not symbol.endswith("3") else "BRL"
    }
```

**Model initialization (the platform-specific part):**
```python
# Azure OpenAI model via Foundry
model = AzureChatOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_version="2024-02-01",
    deployment_name="gpt-4",
    azure_ad_token_provider=get_bearer_token_provider(
        DefaultAzureCredential(),
        "https://cognitiveservices.azure.com/.default"
    )
)
```

> If you've used LangGraph with other providers, this is the only code change — swap `ChatOpenAI` for `AzureChatOpenAI` and use **Managed Identity** (`DefaultAzureCredential`) instead of API keys.

**Graph definition (unchanged LangGraph):**
```python
workflow = StateGraph(AgentState)

workflow.add_node("agent", agent_node)
workflow.add_node("tool_executor", tool_executor_node)

workflow.set_entry_point("agent")
workflow.add_conditional_edges(
    "agent",
    should_continue,
    {"continue": "tool_executor", "end": END}
)
workflow.add_edge("tool_executor", "agent")

app = workflow.compile()
```

### 2. Understand the Foundry Adapter (`caphost.json`)

This config file is the "glue" between LangGraph and Foundry:

```json
{
  "version": "1.0",
  "agent": {
    "name": "financial-advisor-langgraph",
    "description": "Financial market agent built with LangGraph",
    "entry_point": "main:app",
    "port": 8088,
    "protocol": "responses-api"
  },
  "environment": {
    "AZURE_OPENAI_ENDPOINT": "${AZURE_OPENAI_ENDPOINT}",
    "AZURE_OPENAI_API_VERSION": "2024-02-01"
  }
}
```

| Field | Meaning |
|---|---|
| `entry_point` | Points to your compiled graph variable: `file:variable` (i.e., `main.py` → `app`) |
| `port` | Must be **8088** — Foundry's standard for hosted agents |
| `protocol` | `responses-api` — the adapter translates LangGraph to this Foundry protocol |
| `environment` | Variables injected by Foundry at runtime (model endpoint, etc.) |

### 3. Understand the Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .
COPY caphost.json .

EXPOSE 8088

# Entry point: the ADAPTER runs, not main.py directly
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
```

> **Important:** The container runs the **adapter** (`azure.ai.agentserver.langgraph`), not your `main.py` directly. The adapter reads `caphost.json`, loads your compiled `app`, and wraps it in an HTTP server. This is different from MAF, where MAF SDK provides the server.

### 4. Set Up Your Environment

```bash
cd lesson-3-hosted-langgraph/labs/solution

# Install dependencies
pip install -r requirements.txt
```

Key packages:
- `langgraph` — The graph framework
- `langchain-openai` — Azure OpenAI integration
- `azure-identity` — Managed Identity authentication
- `azure-ai-agentserver-langgraph` — **Foundry adapter** (wraps LangGraph in Foundry's Responses API)

> Without `azure-ai-agentserver-langgraph`, Foundry wouldn't know how to communicate with your LangGraph agent.

### 5. (Optional) Test Locally

You can test the graph before deploying:

```python
python -c "
from main import app

state = {'messages': [('user', 'What is AAPL price?')], 'next_action': ''}
result = app.invoke(state)
print(result)
"
```

> LangGraph supports direct invocation — no HTTP server needed for testing. This makes unit testing much simpler compared to MAF.

### 6. Deploy the Agent

```powershell
cd labs/solution
.\deploy.ps1
```

The script builds the container in Azure, registers the hosted agent in Foundry, and tests it. Build takes **8–12 minutes**.

**Expected output:**
```
🔨 Building LangGraph agent container...
✅ Image built: acrworkshopxyz.azurecr.io/finance-agent-lg:latest

📦 Registering Hosted Agent in Foundry...
✅ Agent registered!
   Status: Running ✅

🧪 Testing agent...
Response: The current price of VALE (VALE3) is R$ 65.80 BRL.
🎉 Agent is live and responding!
```

### 7. Test the Agent

```bash
cd labs/solution
python test_agent.py
```

Try these queries:
1. "What's the current price of AAPL?"
2. "Compare PETR4 and VALE3"
3. "Give me a full market summary"

## MAF vs LangGraph: Side-by-Side Comparison

### Tool Definition

| MAF | LangGraph |
|-----|-----------|
| Plain functions in a list: `tools=[fn1, fn2]` | Plain functions registered as graph nodes |
| Docstrings used for tool schema | Docstrings used for tool schema |
| `Annotated` type hints for parameters | Standard type hints |

### Orchestration

| MAF | LangGraph |
|-----|-----------|
| Automatic ReAct loop — framework decides | Explicit graph with conditional edges — **you** decide |
| Less code, less control | More code, full control |
| Best for standard patterns | Best for complex multi-step workflows |

### State Management

| MAF | LangGraph |
|-----|-----------|
| Abstracted — managed internally by MAF | Explicit `TypedDict` — you define every field |
| Less control, simpler | Full control, more code |

### Testing

| MAF | LangGraph |
|-----|-----------|
| Requires agent server for testing | Graph can be invoked directly (no server) |
| Integration testing focused | Unit testing friendly |

### Full Comparison Matrix

| Aspect | MAF | LangGraph |
|--------|-----|-----------|
| **Learning Curve** | Low | Medium |
| **Code Verbosity** | Low (decorators) | Medium (explicit graph) |
| **Orchestration Control** | Low (automatic ReAct) | High (custom routing) |
| **State Management** | Abstracted | Explicit TypedDict |
| **Multi-Agent** | Harder (nested agents) | Natural (graph composition) |
| **Testing** | HTTP-based | Direct invocation |
| **Adoption Effort** | Moderate (new framework) | Low (if you already know LangGraph) |
| **Platform Lock-in** | Azure-native | Framework-agnostic (works everywhere) |
| **Best For** | New projects, simple agents | Complex workflows, existing LangGraph teams |

> **Pick MAF** for greenfield projects with standard patterns. **Pick LangGraph** for complex orchestration or when you already have LangGraph experience. Both are valid — they coexist in the same Foundry project.

## 🧭 Deployment Assessment

Use this checklist to estimate migration effort for your existing LangGraph agents:

| Factor | Low Effort (1–2 days) | Medium (1–2 weeks) | High (1+ month) |
|---|---|---|---|
| **Graph complexity** | 1–3 nodes | 4–10 nodes | 10+ nodes, subgraphs |
| **Model provider** | Already Azure OpenAI | Need to swap provider | Multiple providers |
| **Platform services** | Generic APIs only | Some Azure equivalents needed | Deep platform-specific integrations |
| **State/checkpointing** | Stateless | Need Azure storage backend | Custom checkpointing logic |
| **Workload** | Dev/test | Staging | Production-critical |

**Decision tree:**
```
Should I deploy my LangGraph agent on Foundry?

Does my org use M365/Azure?
    ├─ Yes → Strong strategic value → Assess effort
    │   ├─ Low  → Deploy now
    │   ├─ Med  → POC first, then deploy
    │   └─ High → Phased: run in parallel, validate, switch
    └─ No → Evaluate if enterprise features justify the move
        └─ Consider: Teams delivery, Copilot integration, governance
```

## 🔧 Troubleshooting

| Error / Symptom | Cause | Fix |
|-----------------|-------|-----|
| `Entry point 'main:app' not found` | Variable name mismatch | Verify `app = workflow.compile()` exists in `main.py` and matches `caphost.json` |
| `caphost.json not found` | Not copied in Dockerfile | Add `COPY caphost.json .` to Dockerfile |
| Graph works locally but not in Foundry | Missing adapter or wrong port | Verify Dockerfile CMD uses adapter: `python -m azure.ai.agentserver.langgraph --config caphost.json` |
| Azure OpenAI authentication fails | Managed Identity not configured | Assign "Cognitive Services User" role to the managed identity |
| Port 8088 already in use | Conflicting container | Stop other agents or check for port conflicts |
| Checkpoints not persisting | Using in-memory checkpointer | Switch to persistent storage (Cosmos DB or Table Storage) |
| Agent status stuck on "Deploying" | Container startup failure | Check logs: `az cognitiveservices agent logs --name <agent>` |

### Persistent Checkpointing

If you need state persistence across sessions, replace in-memory storage with Azure Table Storage:

```python
from langgraph.checkpoint.azure import AzureTableCheckpointer

checkpointer = AzureTableCheckpointer(
    connection_string=os.getenv("AZURE_STORAGE_CONNECTION_STRING")
)
app = workflow.compile(checkpointer=checkpointer)
```

## ❓ Frequently Asked Questions

**Q: Do I need to rewrite my LangGraph agent for Foundry?**
A: No. Your graph code (nodes, edges, state) stays the same. You only change the model provider to `AzureChatOpenAI` and add a `caphost.json` config file.

**Q: Can I run the same agent on Foundry and other platforms simultaneously?**
A: Yes. Keep the core graph code shared and swap only the model provider and deployment config per platform.

**Q: What's the difference between the MAF server and the LangGraph adapter?**
A: MAF provides `AgentFrameworkApp` as a built-in HTTP server. LangGraph uses a separate adapter (`azure-ai-agentserver-langgraph`) that wraps your compiled graph. Both expose the same Foundry Responses API on port 8088.

**Q: Can I use LangGraph checkpointing on Foundry?**
A: Yes. Use Azure Table Storage or Cosmos DB as the checkpoint backend instead of in-memory storage.

**Q: When should I choose LangGraph over MAF?**
A: Choose LangGraph when you need fine-grained orchestration control, have complex multi-step workflows, want graph composition for multi-agent patterns, or already have existing LangGraph code.

## 🏆 Self-Paced Challenges

| Challenge | Difficulty | Description |
|---|---|---|
| **Add a custom tool** | ⭐ | Add `get_market_sentiment(symbol)` to the graph and test it |
| **Migrate an existing agent** | ⭐⭐ | Take one of your own LangGraph agents and deploy it on Foundry |
| **Implement checkpointing** | ⭐⭐ | Add Azure Table Storage checkpointer for persistent state |
| **Build same agent in both** | ⭐⭐⭐ | Implement the same financial agent in MAF and LangGraph, compare dev time |
| **Multi-agent graph** | ⭐⭐⭐ | Create a LangGraph with subgraphs that delegate to specialized sub-agents |

## Reference

- [LangGraph documentation](https://langchain-ai.github.io/langgraph/)
- [LangGraph Foundry Guide](langgraph-foundry-guide.md)
- [Azure LangGraph adapter reference](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/hosted-agents)
- [LangGraph checkpointing guide](https://langchain-ai.github.io/langgraph/concepts/persistence/)
- [Capability Host overview](../capability-host.md)
