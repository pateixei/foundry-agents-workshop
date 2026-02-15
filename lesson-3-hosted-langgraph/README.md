# Lesson 3 - Hosted Agent with LangGraph

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

In this lesson, we create a hosted agent in Azure AI Foundry using the
LangGraph framework. The agent specializes in financial markets and
runs as its own container within Foundry.

See complete details in [solution/README.md](solution/README.md).

## Quick Start

```powershell
cd solution
.\deploy.ps1
```

## Quick Test

```powershell
cd solution
python test_agent.py
```

## Key Concepts

- **Hosted Agent**: Own container registered in Foundry that exposes the Responses API
- **LangGraph**: Graph framework for agent orchestration with ReAct pattern
- **Adapter**: `azure-ai-agentserver-langgraph` converts a LangGraph graph into an HTTP server
- **Capability Host**: Resource at the Foundry account level that enables hosted agents
- **Managed Identity**: The container runs with the project's identity (needs RBAC roles)
