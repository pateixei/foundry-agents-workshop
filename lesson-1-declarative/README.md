# Lesson 1 - Declarative Agent (Prompt-Based)

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Navigation

| Resource | Description |
|----------|-------------|
| [📖 Demo Walkthrough](demos/README.md) | Code walkthrough, expected output, and troubleshooting |
| [🔬 Lab Exercise](labs/LAB-STATEMENT.md) | Hands-on lab with tasks and success criteria |
| [📐 Architecture Diagram](media/lesson-1-architecture.png) | Architecture overview |
| [🛠️ Deployment Diagram](media/lesson-1-deployment.png) | Deployment flow |

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

1. **Create** a declarative agent using the `PromptAgentDefinition` SDK
2. **Configure** agent instructions, tools, and model selection
3. **Test** the agent in the Foundry portal playground
4. **Modify** agent configuration in the portal without redeployment
5. **Explain** when to use declarative vs hosted patterns
6. **Compare** declarative agents to other agent hosting patterns

## What is a Declarative Agent?

A declarative agent is a **"serverless agent"** — you define it via `PromptAgentDefinition` and register it directly in Foundry. Foundry handles model calls, function execution, and scaling on its behalf. You don't build containers or manage infrastructure.

Think of it as a **serverless function that orchestrates AI**: your code only **defines** the agent, but the agent **runs** in Foundry's backend.

```
┌─────────────────────────────────────────────┐
│ Your Code (create_agent.py)                 │
│   └─> PromptAgentDefinition (SDK)           │
└─────────────────┬───────────────────────────┘
                  │
                  ▼ (register agent)
┌─────────────────────────────────────────────┐
│ Azure AI Foundry (Backend)                  │
│   ├─> Agent Runtime (serverless)            │
│   ├─> Model (GPT-4)                         │
│   └─> Tools (Bing, Code Interpreter, etc.)  │
└─────────────────┬───────────────────────────┘
                  │
                  ▼ (invoke via API)
┌─────────────────────────────────────────────┐
│ Client Application (chat interface)         │
└─────────────────────────────────────────────┘
```

Unlike **hosted** agents (lessons 2 and 3), declarative agents don't require Docker containers or ACR.

### Advantages & Limitations

| Advantage ✅ | Limitation ⚠️ |
|-------------|---------------|
| No container build/deploy needed | No custom Python tools (local functions) |
| Instructions, model, and tools editable in the portal | Tools limited to Foundry catalog |
| Instant deployment (<10 seconds) | Less control over execution flow |
| Foundry manages scaling automatically | complex multi-step workflows requires **Foundry Workflows** |
| Great for prototypes and rapid iteration | |

> **Quick rule of thumb:** If your agent needs Bing search, Azure AI Search, or Code Interpreter — declarative is perfect. You'll hit limits when you would like to create agents in custom code using Microsoft Agent Framework or other 3rd party framework (such as LangGraph) — that's when you go hosted (lessons 2 & 3).

## Structure

```
lesson-1-declarative/
  README.md              # This file (theory + navigation)
  demos/                 # Demo walkthrough
    create_agent.py      # Demo: creates the agent
    test_agent.py        # Demo: tests the agent
    README.md            # Code walkthrough & troubleshooting
  labs/                  # Hands-on lab
    LAB-STATEMENT.md     # Lab exercise statement
    starter/             # Starter code (TODOs)
    solution/            # Reference solution
  media/                 # Architecture diagrams
```

## Prerequisites

1. Azure resources provisioned (see `prereq/`)
2. "Azure AI User" role on the Foundry project
3. Python 3.10+

## Step-by-Step Walkthrough

### 1. Set Up Your Environment

```bash
# Navigate to lesson folder
cd lesson-1-declarative

# Create virtual environment
python -m venv venv

# Activate (Linux/Mac)
source venv/bin/activate

# Activate (Windows PowerShell)
# .\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

**Verify installation:**
```bash
python -c "import azure.ai.projects; print('✅ SDK installed')"
```

### 2. Configure Environment Variables

Get your endpoint from the deployment outputs (see `prereq/`):

```bash
# Linux/Mac
export AZURE_AI_PROJECT_ENDPOINT="https://<your-foundry-account>.cognitiveservices.azure.com"

# Windows PowerShell
# $env:AZURE_AI_PROJECT_ENDPOINT="https://<your-foundry-account>.cognitiveservices.azure.com"
```

> **Pro tip:** Create a `.env` file in the lesson directory and use `python-dotenv`:
> ```env
> AZURE_AI_PROJECT_ENDPOINT=https://<your-foundry-account>.cognitiveservices.azure.com
> ```

### 3. Understand the Code

The key SDK components:

```python
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential
```

- **`DefaultAzureCredential`** — Authentication chain: tries CLI credentials → managed identity → environment variables
- **`AIProjectClient`** — Main client for Azure AI Foundry; provides access to agents, connections, and the OpenAI-compatible endpoint
- **`PromptAgentDefinition`** — The core of declarative agents. Define instructions, model, and tools here
- **`agent_name`** — Unique identifier within your Foundry project
- **`instructions`** — System prompt: the "personality" of your agent (injected on every request)

### 4. Create and Test the Agent

```bash
# Create the agent
python create_agent.py

# Test the agent
python test_agent.py
```

**Expected output:**
```
🔄 Creating declarative agent...
✅ Agent created successfully!
   Name: financial-advisor
   ID: asst_AbC123XyZ
   Version: 1
   Model: gpt-4
   Status: active
```

> In about 3 seconds you've deployed an AI agent. No Docker, no container registry — just one SDK call. Contrast this with a traditional deployment where you'd build a container, configure triggers, and set up IAM policies.

### 5. Explore in the Foundry Portal

After creating the agent, verify it in the portal:

1. Open [portal.azure.com](https://portal.azure.com)
2. Navigate to **AI Foundry** → Your project
3. Left menu → **Agents** → Find your agent
4. Click **Playground** to test interactively

**Try these portal experiments** (no code required):

| Experiment | What to do | What you'll learn |
|---|---|---|
| **Edit instructions** | Add a line: *"Always respond in Portuguese when discussing Brazilian markets."* → Save | Instant prompt updates without redeployment |
| **Swap model** | Change `gpt-4` → `gpt-4-turbo` → Save → Test again | Cost/latency tradeoffs in seconds |
| **Version rollback** | Go to Versions tab → Set Version 1 as active | Built-in immutable versioning and rollback |

> These experiments show the core advantage of declarative agents: **three changes, zero container builds**. Your product manager can tweak prompts without engineering support.

## 🧭 Pattern Decision Framework

Use this decision tree to choose the right agent pattern:

```
START: I need an AI agent
           │
           ▼
     Does it need custom Python tools?
     (API calls, DB queries, file processing)
           │
      Yes ─┤── No
      │    │      │
      ▼    │      ▼
   Hosted  │  Does it need complex multi-step workflows?
           │      │
           │ Yes ─┤── No
           │  │   │      │
           │  ▼   │      ▼
           │ Hosted│   Declarative ✅
```

### Test Your Intuition

| Scenario | Answer | Why |
|---|---|---|
| Agent queries company SQL database, then analyzes data | **Hosted** | Requires custom DB connection tool |
| Agent helps employees find docs via Azure AI Search | **Declarative** ✅ | Azure AI Search is a built-in Foundry tool |
| Agent books meetings via calendar API and sends emails | **Hosted** | Calendar/email APIs require custom tools |
| Agent answers HR questions from PDF documents (RAG) | **Declarative** ✅ | If using Azure AI Search for retrieval |
| Agent fetches live stock prices from Bloomberg API and stores in PostgreSQL | **Hosted** | Bloomberg API + PostgreSQL = custom tools |

## Comparison with Lessons 2 and 3

| Feature | Lesson 1 (Declarative) | Lesson 2 (Hosted MAF) | Lesson 3 (Hosted LangGraph) |
|---|---|---|---|
| Type | Prompt-based | Hosted (container) | Hosted (container) |
| Framework | SDK azure-ai-projects | Microsoft Agent Framework | LangGraph |
| Container | No | Yes (Docker/ACR) | Yes (Docker/ACR) |
| Custom tools | No (server-side only) | Yes (local Python) | Yes (local Python) |
| Editable in portal | Yes | No | No |
| Deploy time | <10 seconds | ~5 minutes (container build) | ~5 minutes (container build) |
| Cost model | Pay per token (no compute) | Container compute + tokens | Container compute + tokens |
| Maintenance | Low (managed) | Medium (update containers) | Medium (update containers) |
| Best for | Fast Prototyping, Simple Workflows | Production, complex logic | Production, Existing LangGraph expertise |

> **Strategy:** Start with declarative. Migrate to hosted when you hit limitations. That's the journey from Lesson 1 → Lessons 2 & 3.

## Using Foundry Catalog Tools via SDK

One of the biggest advantages of the declarative agent is the ability to use **tools from the Foundry catalog** (the same ones available in the portal) directly via SDK code.

### How does it work?

- **Declarative Agent** (`PromptAgentDefinition`): runs **server-side** in Foundry. The tools (Bing, Azure AI Search, OpenAPI, Code Interpreter, etc.) are executed by Foundry's own runtime. You define the tools in the SDK and they appear in the portal (and vice versa).
- **Hosted Agent** (MAF/LangGraph): runs inside a **container**. The container manages its own tools via Python code. Foundry's runtime only forwards the request to the container — ***it doesn't inject tools from the portal***.

### Example: agent with Bing Grounding Search

```python
import os
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    PromptAgentDefinition,
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
    BingGroundingSearchConfiguration,
)

credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"],
    credential=credential,
)

# 1. Get the connection ID of the Bing resource (created in the portal)
bing_connection = project_client.connections.get("bing-connection-name")

# 2. Create declarative agent WITH the Bing tool
agent = project_client.agents.create_version(
    agent_name="fin-market-with-bing",
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="You are a financial market assistant. Use Bing for real-time data.",
        tools=[
            BingGroundingAgentTool(
                bing_grounding=BingGroundingSearchToolParameters(
                    search_configurations=[
                        BingGroundingSearchConfiguration(
                            project_connection_id=bing_connection.id
                        )
                    ]
                )
            )
        ],
    ),
    description="Agent with Bing Grounding",
)

# 3. Call the agent via Responses API
openai_client = project_client.get_openai_client()
response = openai_client.responses.create(
    input="What is the dollar exchange rate today?",
    tool_choice="required",  # force tool use
    extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
)
print(response.output_text)
```

### Tools available via SDK (same as the portal)

| Tool | SDK Class (`azure.ai.projects.models`) |
|------|---------------------------------------------|
| Bing Grounding | `BingGroundingAgentTool` |
| Bing Custom Search | `BingCustomSearchAgentTool` |
| Azure AI Search | `AzureAISearchAgentTool` |
| OpenAPI 3.0 | `OpenApiAgentTool` |
| Code Interpreter | `CodeInterpreterAgentTool` |
| File Search | `FileSearchAgentTool` |
| MCP (preview) | `McpAgentTool` |
| Azure Functions | `AzureFunctionAgentTool` |

### Comparison: Declarative tools vs hosted

| | Declarative (SDK/Portal) | Hosted (MAF/LangGraph) |
|---|---|---|
| Use tools from Foundry catalog | **Yes** — via `tools=[]` in `PromptAgentDefinition` | **No** — container manages its own tools |
| Editable in portal | **Yes** | **No** |
| Custom Python tools | **No** (only Function Calling with schema) | **Yes** — free Python code |

> **Summary**: if the goal is to use tools from the Foundry catalog (Bing, AI Search, etc.), the path is the **declarative agent**. Just add the tools to the `tools` array in `PromptAgentDefinition`.

## 🔧 Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Authentication failed` | Azure CLI not logged in or expired token | Run `az login` then `az account show` |
| `Endpoint not found` | Wrong environment variable | Verify `AZURE_AI_PROJECT_ENDPOINT` matches your Foundry project |
| `Agent name already exists` | Name collision in shared project | Add unique suffix: `agent_name=f"financial-advisor-{your_initials}"` |
| `Insufficient permissions` | Missing RBAC role | Verify you have "Azure AI User" or "Cognitive Services User" role |
| `python not found` | Not in PATH | Try `python3` or `py -m venv venv` |
| Playground doesn't respond | Model quota exhausted | Check Azure Service Health; try `gpt-35-turbo` as a fallback |
| Agent not visible in portal | Browser cache or wrong project | Hard refresh (Ctrl+F5); verify endpoint matches portal project |

> **Environment conflicts?** Delete and recreate your venv:
> ```bash
> deactivate
> rm -rf venv
> python -m venv venv
> source venv/bin/activate
> pip install -r requirements.txt
> ```

## ❓ Frequently Asked Questions

**Q: Can I use both declarative and hosted agents in the same project?**
A: Yes! Mix and match based on requirements. Each pattern suits different use cases.

**Q: How do I version control declarative agents?**
A: Export agent configuration via SDK, commit to Git, and recreate via CI/CD. Foundry also maintains immutable versions internally.

**Q: What's the cost model?**
A: Pay per token (model usage only). No container compute costs — unlike hosted agents.

**Q: Can I use models other than OpenAI?**
A: Yes. Foundry supports Azure OpenAI, Meta Llama, Mistral, and others. Configure the model in the portal or via SDK.

**Q: What happens when I edit an agent in the portal?**
A: Each edit creates a new immutable version. You can rollback to any previous version with one click.

## 🏆 Self-Paced Challenges

After completing the lab, try these to deepen your understanding:

| Challenge | Difficulty | Description |
|---|---|---|
| **Add Bing Grounding** | ⭐ | Add `BingGroundingAgentTool` to your agent and ask real-time questions |
| **Add Code Interpreter** | ⭐ | Enable `CodeInterpreterAgentTool` and ask the agent to generate charts |
| **Multi-language prompts** | ⭐⭐ | Modify instructions so the agent auto-detects user language and responds accordingly |
| **Export & version control** | ⭐⭐ | Export your agent config via SDK and commit it to a Git repo |
| **Multi-agent comparison** | ⭐⭐⭐ | Create two agents with different temperatures (0.2 vs 0.9) and compare response styles |

## Reference

- [Microsoft Foundry quickstart](https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code)
- [Foundry Agent Service overview](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Bing Grounding tools](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/bing-tools)
- [Tools overview](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/overview)
- [PromptAgentDefinition SDK reference](https://learn.microsoft.com/python/api/azure-ai-agents/)
- [Model selection guide](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/model-region-support)
