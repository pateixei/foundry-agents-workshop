# Lesson 3 - Hosted Agent com LangGraph

Nesta licao, criamos um agente hospedado no Azure AI Foundry usando o
framework LangGraph. O agente e especializado em mercado financeiro e
roda como container proprio dentro do Foundry.

Veja detalhes completos em [langgraph-agent/README.md](langgraph-agent/README.md).

## Quick Start

```powershell
cd langgraph-agent
.\deploy.ps1
```

## Teste Rapido

```powershell
cd langgraph-agent
python test_agent.py
```

## Conceitos Chave

- **Hosted Agent**: Container proprio registrado no Foundry que expoe a Responses API
- **LangGraph**: Framework de grafos para orquestracao de agentes com padrao ReAct
- **Adapter**: `azure-ai-agentserver-langgraph` converte um grafo LangGraph em servidor HTTP
- **Capability Host**: Recurso no nivel do Foundry account que habilita hosted agents
- **Managed Identity**: O container roda com a identidade do projeto (precisa de roles RBAC)
