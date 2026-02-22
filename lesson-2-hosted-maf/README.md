# Lesson 2: Deploying an AI Agent on Microsoft Foundry

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Navigation

| Resource | Description |
|----------|-------------|
| [📖 Demo Walkthrough](demos/README.md) | Code walkthrough and demo instructions |
| [🔬 Lab Exercise](labs/LAB-STATEMENT.md) | Hands-on lab with tasks and success criteria |
| [📐 Architecture Diagram](media/lesson-2-architecture.png) | Architecture overview |
| [🛠️ Deployment Diagram](media/lesson-2-deployment.png) | Deployment flow |
| [📁 Solution Notes](labs/solution/README.md) | Solution code and deployment details |

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

1. **Implement** custom Python tools using Microsoft Agent Framework
2. **Build** and containerize a MAF agent application
3. **Deploy** a containerized agent to Azure Container Registry (ACR)
4. **Register** the agent as a Hosted Agent in Foundry
5. **Debug** agents using container logs, telemetry, and tracing
6. **Compare** MAF architecture with declarative and LangGraph patterns
7. **Explain** when to use hosted vs declarative agents

## Why Hosted Agents?

In Lesson 1 you built a **declarative** agent — serverless, no custom code, instantly deployed. But what if your agent needs to:

- Query your company's SQL database?
- Call an external API (Bloomberg, Salesforce)?
- Process files or run complex calculations?
- Execute arbitrary Python logic?

**Declarative agents can't do that.** They're limited to tools available in the Foundry catalog. Hosted agents break free from those limitations — you run **any Python code** as tools inside your own container.

> Think of it this way: declarative agents are like serverless functions that **orchestrate**. Hosted agents are like containers with full **business logic** inside.

## Architecture

```
┌─────────────────────────────────────┐
│ Your Code (Python + MAF)            │
│   ├─> Agent definition              │
│   └─> Custom tools (plain functions)│
└───────────┬─────────────────────────┘
            │ (containerized)
            ▼
┌─────────────────────────────────────┐
│ Docker Container in ACR             │
│   ├─> HTTP Server (port 8088)       │
│   └─> Runs with Managed Identity    │
└───────────┬─────────────────────────┘
            │ (registered in)
            ▼
┌─────────────────────────────────────┐
│ Foundry Capability Host             │
│   ├─> Routes requests to container  │
│   └─> Collects telemetry            │
└─────────────────────────────────────┘
```

Your agent runs inside its own container within Foundry's infrastructure — called the **Capability Host**. You write Python functions, register them as tools, containerize everything, push to ACR, and Foundry runs it. Requests flow through Foundry's routing layer to your container and responses come back through the same path.

## What is Microsoft Agent Framework (MAF)?

MAF is Microsoft's framework for building agents within Foundry. If you're familiar with LangGraph, here's how they compare:

| Concept | LangGraph | MAF |
|---------|-----------|-----|
| **Framework** | Graph-based orchestration | Function-based agent |
| **Agent Definition** | `StateGraph` + nodes | `AzureAIClient` + tool list |
| **Tools** | Functions in graph nodes | Plain Python functions passed as list |
| **State** | `TypedDict` state object | Agent context |
| **Orchestration** | Explicit edges/routing | Automatic tool calling (ReAct loop) |
| **Best For** | Complex multi-agent workflows | Single agent with multiple tools |

> **Key insight**: MAF simplifies agent patterns. LangGraph gives you fine control over orchestration — you define the graph. MAF does orchestration automatically using the ReAct pattern. Both run in containers, both support custom tools. MAF is integrated with Foundry out of the box, but it's also platform-agnostic — you can host MAF agents anywhere.

## Agent

**Financial Market Agent** — Python agent with Microsoft Agent Framework published as a Hosted Agent in Foundry.

Features:
- Developed in Python with Microsoft Agent Framework (`agent-framework-azure-ai`)
- Uses the gpt-4.1 model provisioned via Microsoft Foundry
- Exposes 3 tools: stock quotes, exchange rates, market summary
- Hosted Agent in Foundry with Managed Identity
- OpenTelemetry integrated with Azure Monitor
- HTTP Server via `azure-ai-agentserver-agentframework`

## Lesson Structure

```
lesson-2-hosted-maf/
  README.md
  demos/                 # Demo walkthrough
  labs/                  # Hands-on lab
    solution/
      agent.yaml           # Agent manifest
      app.py               # HTTP server
      deploy.ps1           # Automated deployment script
      Dockerfile           # Container image
      requirements.txt     # Dependencies
      src/
        main.py            # Entrypoint run()
        agent/
          finance_agent.py # MAF agent
      tools/
        finance_tools.py   # Agent tools
  media/                 # Architecture diagrams
```

### Key Files Explained

| File | Role |
|---|---|
| `tools/finance_tools.py` | Business logic — stock APIs, calculations. **Pure Python**, no framework dependency |
| `src/agent/finance_agent.py` | Agent definition — registers tools with MAF, sets instructions and model |
| `app.py` | HTTP server wrapper — MAF's `AgentFrameworkApp` serves the Responses API on port 8088 |
| `Dockerfile` | Containerization — standard Python image, exposes port 8088 |
| `deploy.ps1` | One-click deployment — builds in ACR, registers in Foundry, tests |

## Prerequisites
- `../prereq/` folder executed to provision Azure infrastructure
- Azure CLI (`az`) installed and authenticated
- Python 3.10+ with pip

## Step-by-Step Walkthrough

### 1. Understand How Tools Work in MAF

In MAF, tools are **plain Python functions** passed as a list to the agent. No special decorators needed — MAF auto-generates JSON schemas from your type hints and docstrings.

```python
# tools/finance_tools.py — plain Python functions
from typing import Annotated

def get_stock_quote(ticker: Annotated[str, "Stock ticker code"]) -> str:
    """Returns the current price of a stock."""
    # ... your business logic here ...

def get_exchange_rate(pair: Annotated[str, "Currency pair"]) -> str:
    """Returns the current exchange rate."""
    # ... implementation ...

def get_market_summary() -> str:
    """Returns a summary of major market indices."""
    # ... implementation ...
```

```python
# src/agent/finance_agent.py — register tools as a simple list
from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary

TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]

async def create_finance_agent():
    client = AzureAIClient.from_async_credential(credential, project_endpoint)
    agent = await client.agents.create_agent(
        model=model_deployment, instructions=SYSTEM_PROMPT, tools=TOOLS
    )
    return agent
```

**Key principles for writing good tools:**

| Principle | Why it matters |
|---|---|
| **Docstrings are mandatory** | The LLM reads them to decide when to call your tool |
| **Use `Annotated` type hints** | MAF generates JSON schemas from these for the LLM |
| **Single responsibility** | One tool = one clear purpose |
| **Return useful errors** | Don't crash — return `{"error": "message"}` instead |
| **Keep execution fast** | Tools should run in <5 seconds; use `async` for slow I/O |

### 2. Understand the HTTP Server

MAF provides `AgentFrameworkApp` which wraps your agent in an HTTP server implementing Foundry's Responses API automatically — you don't write HTTP handlers.

```python
# app.py
from azure.ai.agentserver.agentframework import AgentFrameworkApp

app = AgentFrameworkApp(agent)
# Runs on port 8088 — Foundry's standard for hosted agents
```

> Port **8088** is required by Foundry. Don't change it.

### 3. Set Up Your Environment

```bash
# Navigate to lesson folder
cd lesson-2-hosted-maf/labs/solution

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# .\venv\Scripts\activate  # Windows PowerShell

# Install dependencies
pip install -r requirements.txt
```

### 4. Deploy the Agent

The deployment script automates everything:

```powershell
cd lesson-2-hosted-maf/labs/solution
.\deploy.ps1
```

The script performs 5 steps:
1. **Loads** your infrastructure config from the prereq deployment
2. **Builds** the container image **in Azure** (no local Docker needed!)
3. **Registers** the container as a hosted agent in Foundry
4. **Monitors** until the agent is running
5. **Tests** the agent with a sample query

**Expected output:**
```
🔨 Building container image in ACR...
⏳ This may take 8-12 minutes...
✅ Successfully tagged finance-agent-maf:latest

📦 Registering hosted agent in Foundry...
✅ Agent registered: financial-advisor-maf
   Status: Running
   Container: acrworkshopxyz.azurecr.io/finance-agent-maf:latest
```

> The build takes **8–12 minutes**. This is normal — the container is being built in Azure's cloud, not locally.

### 5. Verify in the Portal

After deployment:

1. Open [portal.azure.com](https://portal.azure.com) → **AI Foundry** → Your project
2. Navigate to **Agents** → Find "financial-advisor-maf"
3. Check: Container image, status, endpoint, tools list

> **Important difference from Lesson 1:** You **cannot** edit instructions in the portal for hosted agents — they're baked into the container. To change behavior: update code → rebuild container → redeploy.

### 6. Test the Agent

```bash
python test_agent.py
```

**Expected interaction:**
```
🤖 Financial Advisor MAF Agent

You: What's the current price of AAPL?

Agent: Let me fetch that for you.
[Calling tool: get_stock_price(symbol="AAPL")]
[Tool result: {"symbol": "AAPL", "price": 175.50, "currency": "USD"}]

The current price of Apple (AAPL) is $175.50 USD.
```

Try these queries to test all tools:
1. "Compare AAPL and PETR4 prices"
2. "What's the market sentiment for VALE3?"
3. "Give me an overall market summary"

Notice how the agent **decides which tools to call** automatically — this is the ReAct pattern in action.

## 🔧 Debugging & Troubleshooting

### Reading Container Logs

```bash
# View logs
az cognitiveservices agent logs --name financial-advisor-maf

# Real-time tailing
az cognitiveservices agent logs --name financial-advisor-maf --follow

# Filter for errors
az cognitiveservices agent logs --name financial-advisor-maf | grep "ERROR"
```

**Example log output:**
```
2026-02-14 09:25:10 INFO  Starting agent server on port 8088
2026-02-14 09:26:30 INFO  Request received: /v1/chat/completions
2026-02-14 09:26:31 DEBUG Tool call: get_stock_price(symbol="AAPL")
2026-02-14 09:26:31 DEBUG Tool result: {"symbol": "AAPL", "price": 175.50}
2026-02-14 09:26:32 INFO  Response sent: 200 OK
```

### Common Errors

| Error / Symptom | Cause | Fix |
|-----------------|-------|-----|
| Agent status stuck on **"Deploying"** for >20 min | Container not responding on port 8088 | Check logs for startup errors; verify `EXPOSE 8088` in Dockerfile |
| Agent says "I don't have access to data" instead of calling tool | Tool not in TOOLS list, or missing docstring | Verify function is in `TOOLS = [...]` and has docstring + type hints |
| **"requirements.txt not found"** during build | Dockerfile path mismatch | Ensure `requirements.txt` exists at the expected path |
| **Import error** in container | Missing `__init__.py` files | Ensure all packages have `__init__.py` |
| **"Unauthorized"** when calling Foundry | Managed Identity missing RBAC | Assign "Cognitive Services User" role to the managed identity |
| Container build fails with auth error | ACR not accessible | Run `az acr login --name <acr>` |
| Tool returns error to user | Unhandled exception in tool | Wrap tool logic in try/except, return `{"error": "..."}` |

### Debugging: Agent Doesn't Call Your Tool

Step-by-step diagnosis:

1. **Check the TOOLS list** — is your function registered?
   ```python
   TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]
   # ← Is your function here?
   ```

2. **Check docstring** — without it, the LLM doesn't know what the tool does

3. **Check instructions** — do they mention using tools?
   ```python
   instructions="Use available tools to fetch real-time data. Always call tools instead of making up data."
   ```

4. **Check logs** — look for `Tool call:` entries. If absent, the LLM chose not to use the tool

### Performance Tips

If your agent is slow:

- **Profile tool execution** — add timing to identify bottleneck tools
- **Use async tools** — `asyncio.gather()` for parallel API calls
- **Cache results** — stock prices valid for 1 minute don't need re-fetching
- **Return more data per call** — reduces LLM round-trips

## 🧭 Pattern Decision Framework

```
Need custom Python tools (DB, APIs, file processing)?
    ├─ Yes → Hosted (MAF or LangGraph)
    └─ No → Is data in Azure (AI Search, Cosmos, Blob)?
        ├─ Yes, and Foundry catalog has the tool → Declarative ✅
        └─ No, or need external API → Hosted ✅
```

### Real-World Scenarios

| Scenario | Pattern | Reasoning |
|---|---|---|
| HR Policy Chatbot using Azure AI Search | **Declarative** | Foundry catalog tool, no custom logic |
| Sales CRM Agent querying Salesforce API | **Hosted (MAF)** | Custom API calls required |
| Financial Report Generator with SQL + Excel | **Hosted (MAF)** | DB access + file generation |
| Document Summarizer with Code Interpreter | **Declarative** | Code Interpreter is a Foundry tool |
| Multi-step approval: inventory + Slack + Jira | **Hosted** | Multiple custom integrations |

> **Rule of thumb:** If you need 2+ external APIs → probably Hosted. If Foundry catalog has the tools → Declarative is faster.

## Comparison: Declarative vs Hosted MAF

| Aspect | Declarative (Lesson 1) | Hosted MAF (Lesson 2) |
|--------|------------------------|-----------------------|
| **Complexity** | Low | Medium |
| **Deploy Time** | <10 seconds | 10–15 minutes |
| **Custom Tools** | No | Yes (any Python code) |
| **Portal Editable** | Yes | No (rebuild container) |
| **Cost** | Pay per token only | Tokens + ~$20–40/mo container |
| **Scaling** | Serverless (auto) | Auto-scaled containers |
| **Control** | Low | High |
| **Debugging** | Portal + API logs | Container logs + telemetry |
| **Best For** | Prototypes, simple Q&A | Production, custom integrations |

> **Strategy:** Start declarative for quick wins. Migrate to hosted when you need custom tools. That's the journey from Lesson 1 → Lesson 2.

## ❓ Frequently Asked Questions

**Q: Can I mix declarative and hosted agents in the same project?**
A: Yes! Use declarative for simple tasks and hosted for complex ones. They coexist in the same Foundry project.

**Q: How do I version my hosted agents?**
A: Tag container images (e.g., `finance-agent-maf:v1.2.0`). Register specific tags in Foundry for rollback capability.

**Q: What's the container cost?**
A: ~$20–40/month for an always-on container (Basic tier). Scales with number of replicas.

**Q: Can hosted agents call other agents?**
A: Yes, via SDK. You can create orchestration patterns where one agent delegates to others.

**Q: Do I need Docker installed locally?**
A: No. The `deploy.ps1` script uses `az acr build` which builds the container **in Azure's cloud**. No local Docker required.

## 🏆 Self-Paced Challenges

| Challenge | Difficulty | Description |
|---|---|---|
| **Add error handling** | ⭐ | Wrap all tools in try/except and return meaningful error messages |
| **Add a new tool** | ⭐⭐ | Implement `get_market_sentiment(symbol)` returning sentiment, confidence, and summary |
| **Implement async tools** | ⭐⭐ | Convert `get_stock_quote` to async with `asyncio` for parallel API calls |
| **Add structured logging** | ⭐⭐ | Use JSON-formatted logs for easier parsing in Application Insights |
| **Version tagging** | ⭐⭐⭐ | Modify `deploy.ps1` to tag images with semver and register specific versions |
| **Multi-agent call** | ⭐⭐⭐ | Create a second agent and have the first one delegate subtasks via SDK |

## Reference

- [Microsoft Agent Framework documentation](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Foundry Hosted Agents guide](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/hosted-agents)
- [Azure Container Registry build](https://learn.microsoft.com/azure/container-registry/container-registry-tutorial-quick-task)
- [Capability Host overview](../capability-host.md)
