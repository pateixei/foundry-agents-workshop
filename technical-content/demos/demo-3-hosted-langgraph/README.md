# Demo 3: Hosted LangGraph Agent (AWS Migration)

> **Demo Type**: Instructor-led walkthrough. This demo references source code in `lesson-3-hosted-langgraph/langgraph-agent/`. The instructor walks through the code live on screen.

## Overview

Demonstrates migrating an existing **LangGraph agent from AWS Lambda/ECS** to Azure Foundry as a Hosted Agent. Shows how to adapt LangGraph code for Foundry with minimal changes.

## Key Concepts

- ✅ LangGraph StateGraph architecture
- ✅ Azure OpenAI integration with `AzureChatOpenAI`  
- ✅ Foundry adapter pattern (`caphost.json`)
- ✅ Container deployment to Foundry
- ✅ Migration path from AWS to Azure

## Architecture

```
AWS Lambda/ECS → Azure Foundry Hosted Agent
LangGraph Code (95% unchanged) + Adapter Config
```

## Prerequisites

- Azure Foundry project with model
- ACR for container storage
- Docker Desktop
- Existing LangGraph knowledge (recommended)

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
| **AWS Migration** | Easier (code similar) | Requires refactor |

## When to Use LangGraph vs MAF

**Use LangGraph when:**
- Migrating from AWS Lambda with existing LangGraph code
- Need explicit control over agent flow
- Building multi-agent workflows
- Complex state management required

**Use MAF when:**
- Starting new agent from scratch
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

## Migration Checklist (AWS → Azure)

- [x] Replace Bedrock with `AzureChatOpenAI`
- [x] Update environment variables (API keys → Managed Identity)
- [x] Add `caphost.json` for Foundry adapter
- [x] Change container port (Lambda default → 8080)
- [x] Update IAM roles → RBAC roles
- [x] CloudWatch → Application Insights
- [x] ECR → ACR

## Resources

- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [AzureChatOpenAI Reference](https://python.langchain.com/docs/integrations/chat/azure_chat_openai)
- [AWS to Azure Migration Guide](https://learn.microsoft.com/azure/architecture/aws-professional/)

---

**Demo Level**: Intermediate-Advanced  
**Estimated Time**: 25-30 minutes  
**Best For**: Teams migrating from AWS with existing LangGraph agents
