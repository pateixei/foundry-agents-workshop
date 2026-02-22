# Demo 3: Hosted LangGraph Agent on Azure Foundry

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

> **Demo Type**: Instructor-led walkthrough. This demo references source code in `lesson-3-hosted-langgraph/labs/solution/`. The instructor walks through the code live on screen.

## Overview

Demonstrates deploying a **LangGraph agent as a Hosted Agent** on Azure Foundry. Shows how teams already using LangGraph can bring their existing code to Foundry with minimal changes, leveraging Azure's managed infrastructure and enterprise governance.

## Key Concepts

- ✅ LangGraph StateGraph architecture
- ✅ Azure OpenAI integration with `AzureChatOpenAI`  
- ✅ Foundry adapter pattern (`caphost.json`)
- ✅ Container deployment to Foundry
- ✅ Multi-platform deployment flexibility

## Architecture

```
LangGraph Code (portable) + Adapter Config → Azure Foundry Hosted Agent
```

## Prerequisites

- Azure Foundry project with model
- ACR for container storage
- Docker Desktop
- LangGraph knowledge (recommended)

## Quick Start

```powershell
cd demo-3-hosted-langgraph
.\deploy.ps1
```

## Key Files

- `main.py` - LangGraph agent with StateGraph
- `caphost.json` - Foundry adapter configuration
- `Dockerfile` - Container definition
- `deploy.ps1` - Automated deployment

## Code Sample: LangGraph Agent

```python
from langgraph.graph import StateGraph, END
from langchain_openai import AzureChatOpenAI
from typing import TypedDict, Annotated

class AgentState(TypedDict):
    messages: Annotated[list, "conversation history"]
    next_action: str

# Define tools (same as MAF)
def get_stock_price(symbol: str) -> dict:
    # Implementation...
    pass

# Create Azure OpenAI model
model = AzureChatOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
    azure_deployment="gpt-4",
    temperature=0.7,
)

# Build LangGraph graph
workflow = StateGraph(AgentState)
workflow.add_node("agent", lambda state: agent_node(state, model, tools))
workflow.add_node("tools", lambda state: tool_node(state, tools))
workflow.add_edge("agent", "tools")
workflow.add_edge("tools", "agent")
workflow.set_entry_point("agent")

app = workflow.compile()
```

## caphost.json Configuration

```json
{
  "name": "langgraph-financial-agent",
  "version": "1.0",
  "entry": "main:app",
  "runtime": "python",
  "port": 8080,
  "health_check": "/health"
}
```

## Comparison: LangGraph vs MAF

| Feature | LangGraph (This Demo) | MAF (Demo 2) |
|---------|----------------------|--------------|
| **Framework** | Graph-based | Decorator-based |
| **Orchestration** | Manual (edges, nodes) | Automatic (ReAct) |
| **State Management** | TypedDict | Built-in context |
| **Best For** | Complex workflows | Single agent + tools |
| **Portability** | High (graph-based) | Azure-native |

## When to Use LangGraph vs MAF

**Use LangGraph when:**
- Team already has LangGraph expertise or existing code
- Need explicit control over agent flow
- Building multi-agent workflows
- Complex state management required

**Use MAF when:**
- Starting new agent from scratch on Azure
- Simple tool-calling patterns
- Want Foundry-native integration
- Prefer simplicity over control

## Troubleshooting

**Issue: "caphost.json not found"**  
**Fix**: Ensure file exists in container root and COPY command in Dockerfile includes it

**Issue: "Model authentication failed"**  
**Fix**: Verify `AZURE_OPENAI_ENDPOINT` and Managed Identity has "Cognitive Services User" role

**Issue: "Graph compilation error"**  
**Fix**: Check all nodes have defined edges; entry point must be set

## Deployment Checklist (LangGraph → Foundry)

- [x] Configure `AzureChatOpenAI` as the model provider
- [x] Set up Managed Identity for secure authentication
- [x] Add `caphost.json` for Foundry adapter
- [x] Configure container to expose port 8080
- [x] Set up RBAC roles for Azure OpenAI access
- [x] Enable Application Insights for observability
- [x] Push container image to ACR

## Resources

- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [AzureChatOpenAI Reference](https://python.langchain.com/docs/integrations/chat/azure_chat_openai)
- [Azure AI Foundry Hosted Agents](https://learn.microsoft.com/azure/ai-foundry/concepts/hosted-agents)

---

**Demo Level**: Intermediate-Advanced  
**Estimated Time**: 25-30 minutes  
**Best For**: Teams with LangGraph experience deploying to Azure Foundry
