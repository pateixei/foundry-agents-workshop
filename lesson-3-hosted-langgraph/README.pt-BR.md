# Lição 3 - Agente Hospedado com LangGraph

Nesta lição, criamos um agente hospedado no Azure AI Foundry usando o
framework LangGraph. O agente é especializado em mercados financeiros e
roda como seu próprio contêiner dentro do Foundry.

Veja detalhes completos em [langgraph-agent/README.md](../lesson-3-hosted-langgraph/langgraph-agent/README.md).

## Início Rápido

```powershell
cd langgraph-agent
.\deploy.ps1
```

## Teste Rápido

```powershell
cd langgraph-agent
python test_agent.py
```

## Conceitos Principais

- **Hosted Agent**: Contêiner próprio registrado no Foundry que expõe a Responses API
- **LangGraph**: Framework de grafos para orquestração de agentes com padrão ReAct
- **Adaptador**: `azure-ai-agentserver-langgraph` converte um grafo LangGraph em servidor HTTP
- **Capability Host**: Recurso no nível do Foundry account que habilita agentes hospedados
- **Managed Identity**: O contêiner roda com a identidade do projeto (necessita roles RBAC)
