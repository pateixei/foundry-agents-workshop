# Lesson 1 - Agente Declarativo (Prompt-Based)

Cria um agente financeiro **declarativo** no Azure AI Foundry usando o SDK `azure-ai-projects`.

## O que e um agente declarativo?

Agentes declarativos sao definidos via `PromptAgentDefinition` e registrados diretamente no Foundry. Diferente de agentes **hosted** (lessons 2 e 3), nao requerem container Docker ou ACR.

**Vantagens:**
- Instructions, model e tools editaveis no portal do Foundry
- Sem necessidade de build/deploy de container
- Deploy instantaneo

**Limitacoes:**
- Sem custom tools locais (funcoes Python executadas no container)
- Tools limitadas as disponiveis server-side (SharePoint, Bing, Azure Functions via OpenAPI, MCP)

## Estrutura

```
lesson-1-declarative/
  create_agent.py      # Cria o agente no Foundry
  test_agent.py        # Console client para testar o agente
  requirements.txt     # Dependencias Python
  README.md            # Este arquivo
```

## Pre-requisitos

1. Recursos Azure provisionados (ver `prereq/`)
2. Role "Azure AI User" no projeto do Foundry
3. Python 3.10+

## Uso

```bash
# Instalar dependencias
pip install -r requirements.txt

# Criar o agente
python create_agent.py

# Testar o agente
python test_agent.py
```

## Comparativo com Lessons 2 e 3

| Caracteristica | Lesson 1 (Declarativo) | Lesson 2 (Hosted MAF) | Lesson 3 (Hosted LangGraph) |
|---|---|---|---|
| Tipo | Prompt-based | Hosted (container) | Hosted (container) |
| Framework | SDK azure-ai-projects | Microsoft Agent Framework | LangGraph |
| Container | Nao | Sim (Docker/ACR) | Sim (Docker/ACR) |
| Custom tools | Nao (server-side only) | Sim (Python local) | Sim (Python local) |
| Editavel no portal | Sim | Nao | Nao |
| Deploy | Instantaneo | Build + ACR + start | Build + ACR + start |

## Usando Tools do Catalogo do Foundry via SDK

Uma das maiores vantagens do agente declarativo e poder usar **tools do catalogo do Foundry** (as mesmas disponiveis no portal) diretamente via codigo SDK.

### Como funciona?

- **Agente Declarativo** (`PromptAgentDefinition`): roda **server-side** no Foundry. As tools (Bing, Azure AI Search, OpenAPI, Code Interpreter, etc.) sao executadas pelo proprio runtime do Foundry. Voce define as tools no SDK e elas aparecem no portal (e vice-versa).
- **Agente Hosted** (MAF/LangGraph): roda dentro de um **container**. O container gerencia suas proprias tools via codigo Python. O runtime do Foundry apenas encaminha a request para o container — nao injeta tools do portal.

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

# 1. Obter o connection ID do recurso Bing (criado no portal)
bing_connection = project_client.connections.get("nome-da-conexao-bing")

# 2. Criar agente declarativo COM a tool Bing
agent = project_client.agents.create_version(
    agent_name="fin-market-with-bing",
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="Voce e um assistente de mercado financeiro. Use Bing para dados em tempo real.",
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
    description="Agente com Bing Grounding",
)

# 3. Chamar o agente via Responses API
openai_client = project_client.get_openai_client()
response = openai_client.responses.create(
    input="Qual a cotacao do dolar hoje?",
    tool_choice="required",  # forcar uso da tool
    extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
)
print(response.output_text)
```

### Tools disponiveis via SDK (mesmas do portal)

| Tool | Classe no SDK (`azure.ai.projects.models`) |
|------|---------------------------------------------|
| Bing Grounding | `BingGroundingAgentTool` |
| Bing Custom Search | `BingCustomSearchAgentTool` |
| Azure AI Search | `AzureAISearchAgentTool` |
| OpenAPI 3.0 | `OpenApiAgentTool` |
| Code Interpreter | `CodeInterpreterAgentTool` |
| File Search | `FileSearchAgentTool` |
| MCP (preview) | `McpAgentTool` |
| Azure Functions | `AzureFunctionAgentTool` |

### Comparativo: Tools declarativas vs hosted

| | Declarativo (SDK/Portal) | Hosted (MAF/LangGraph) |
|---|---|---|
| Usar tools do catalogo Foundry | **Sim** — via `tools=[]` no `PromptAgentDefinition` | **Nao** — container gerencia suas proprias tools |
| Editavel no portal | **Sim** | **Nao** |
| Tools customizadas Python | **Nao** (so Function Calling com schema) | **Sim** — codigo Python livre |

> **Resumo**: se o objetivo e usar tools do catalogo do Foundry (Bing, AI Search, etc.), o caminho e o **agente declarativo**. Basta adicionar as tools no array `tools` do `PromptAgentDefinition`.

## Referencia

- [Microsoft Foundry quickstart](https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code)
- [Foundry Agent Service overview](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Bing Grounding tools](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/bing-tools)
- [Tools overview](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/overview)
