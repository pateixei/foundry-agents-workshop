# Lição 1 - Agente Declarativo (Baseado em Prompt)

Cria um agente financeiro **declarativo** no Azure AI Foundry usando o SDK `azure-ai-projects` (nova experiência Foundry).

## O que é um agente declarativo?

Agentes declarativos são definidos via `PromptAgentDefinition` e registrados diretamente no Foundry. Diferente dos agentes **hospedados** (lições 2 e 3), eles não requerem contêineres Docker ou ACR.

**Vantagens:**
- Instruções, modelo e ferramentas editáveis no portal do Foundry
- Não necessita construção/implantação de contêiner
- Implantação instantânea

**Limitações:**
- Sem ferramentas customizadas locais (funções Python executadas no contêiner)
- Ferramentas limitadas às disponíveis no servidor (SharePoint, Bing, Azure Functions via OpenAPI, MCP)

## Estrutura

```
lesson-1-declarative/
  create_agent.py      # Cria o agente no Foundry
  test_agent.py        # Cliente console para testar o agente
  requirements.txt     # Dependências Python
  README.md            # Este arquivo
```

## Pré-requisitos

1. Recursos Azure provisionados (veja `prereq/`)
2. Role "Azure AI User" no projeto Foundry
3. Python 3.10+

## Uso

```bash
# Instalar dependências
pip install -r requirements.txt

# Criar o agente
python create_agent.py

# Testar o agente
python test_agent.py
```

## Comparação com as Lições 2 e 3

| Recurso | Lição 1 (Declarativo) | Lição 2 (MAF Hospedado) | Lição 3 (LangGraph Hospedado) |
|---|---|---|---|
| Tipo | Baseado em prompt | Hospedado (contêiner) | Hospedado (contêiner) |
| Framework | SDK azure-ai-projects | Microsoft Agent Framework | LangGraph |
| Contêiner | Não | Sim (Docker/ACR) | Sim (Docker/ACR) |
| Ferramentas customizadas | Não (apenas server-side) | Sim (Python local) | Sim (Python local) |
| Editável no portal | Sim | Não | Não |
| Deploy | Instantâneo | Build + ACR + start | Build + ACR + start |

## Usando Ferramentas do Catálogo Foundry via SDK

Uma das maiores vantagens do agente declarativo é a capacidade de usar **ferramentas do catálogo do Foundry** (as mesmas disponíveis no portal) diretamente via código SDK.

### Como funciona?

- **Agente Declarativo** (`PromptAgentDefinition`): roda **server-side** no Foundry. As ferramentas (Bing, Azure AI Search, OpenAPI, Code Interpreter, etc.) são executadas pelo próprio runtime do Foundry. Você define as ferramentas no SDK e elas aparecem no portal (e vice-versa).
- **Agente Hospedado** (MAF/LangGraph): roda dentro de um **contêiner**. O contêiner gerencia suas próprias ferramentas via código Python. O runtime do Foundry apenas encaminha a requisição para o contêiner — não injeta ferramentas do portal.

### Exemplo: agente com Bing Grounding Search

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

### Ferramentas disponíveis via SDK (mesmas do portal)

| Ferramenta | Classe SDK (`azure.ai.projects.models`) |
|------|---------------------------------------------|
| Bing Grounding | `BingGroundingAgentTool` |
| Bing Custom Search | `BingCustomSearchAgentTool` |
| Azure AI Search | `AzureAISearchAgentTool` |
| OpenAPI 3.0 | `OpenApiAgentTool` |
| Code Interpreter | `CodeInterpreterAgentTool` |
| File Search | `FileSearchAgentTool` |
| MCP (preview) | `McpAgentTool` |
| Azure Functions | `AzureFunctionAgentTool` |

### Comparação: Ferramentas declarativas vs hospedadas

| | Declarativo (SDK/Portal) | Hospedado (MAF/LangGraph) |
|---|---|---|
| Usar ferramentas do catálogo Foundry | **Sim** — via `tools=[]` em `PromptAgentDefinition` | **Não** — contêiner gerencia suas próprias ferramentas |
| Editável no portal | **Sim** | **Não** |
| Ferramentas Python customizadas | **Não** (apenas Function Calling com schema) | **Sim** — código Python livre |

> **Resumo**: se o objetivo é usar ferramentas do catálogo do Foundry (Bing, AI Search, etc.), o caminho é o **agente declarativo**. Basta adicionar as ferramentas ao array `tools` em `PromptAgentDefinition`.

## Referência

- [Quickstart do Microsoft Foundry](https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code)
- [Visão geral do Foundry Agent Service](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Ferramentas Bing Grounding](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/bing-tools)
- [Visão geral de ferramentas](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/overview)
