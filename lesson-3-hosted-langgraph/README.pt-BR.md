# Lição 3 - Agente Hospedado com LangGraph

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-3-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-3-deployment.png) | Fluxo de implantação |
| [📁 Notas da Solução](labs/solution/README.pt-BR.md) | Código da solução e detalhes de deployment |
| [📚 Guia LangGraph + Foundry](langgraph-foundry-guide.pt-BR.md) | Deep-dive na integração LangGraph + Foundry |

Nesta lição, criamos um agente hospedado no Azure AI Foundry usando o
framework LangGraph. O agente é especializado em mercados financeiros e
roda como seu próprio contêiner dentro do Foundry.

Veja detalhes completos em [labs/solution/README.pt-BR.md](labs/solution/README.pt-BR.md).

## Início Rápido

```powershell
cd labs/solution
.\deploy.ps1
```

## Teste Rápido

```powershell
cd solution
python test_agent.py
```

## Conceitos Principais

- **Hosted Agent**: Contêiner próprio registrado no Foundry que expõe a Responses API
- **LangGraph**: Framework de grafos para orquestração de agentes com padrão ReAct
- **Adaptador**: `azure-ai-agentserver-langgraph` converte um grafo LangGraph em servidor HTTP
- **Capability Host**: Recurso no nível do Foundry account que habilita agentes hospedados
- **Managed Identity**: O contêiner roda com a identidade do projeto (necessita roles RBAC)
