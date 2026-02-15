# Lesson 1 - Declarative Agent (Prompt-Based)

Creates a **declarative** financial agent in Azure AI Foundry using the `azure-ai-agents` SDK.

## What is a declarative agent?

Declarative agents are defined via `PromptAgentDefinition` and registered directly in Foundry. Unlike **hosted** agents (lessons 2 and 3), they don't require Docker containers or ACR.

**Advantages:**
- Instructions, model, and tools editable in the Foundry portal
- No need for container build/deploy
- Instant deployment

**Limitations:**
- No local custom tools (Python functions executed in container)
- Tools limited to server-side available ones (SharePoint, Bing, Azure Functions via OpenAPI, MCP)

## Structure

```
lesson-1-declarative/
  create_agent.py      # Creates the agent in Foundry
  test_agent.py        # Console client to test the agent
  requirements.txt     # Python dependencies
  README.md            # This file
```

## Prerequisites

1. Azure resources provisioned (see `prereq/`)
2. "Azure AI User" role on the Foundry project
3. Python 3.10+

## Usage

```bash
# Install dependencies
pip install -r requirements.txt

# Create the agent
python create_agent.py

# Test the agent
python test_agent.py
```

## Comparison with Lessons 2 and 3

| Feature | Lesson 1 (Declarative) | Lesson 2 (Hosted MAF) | Lesson 3 (Hosted LangGraph) |
|---|---|---|---|
| Type | Prompt-based | Hosted (container) | Hosted (container) |
| Framework | SDK azure-ai-agents | Microsoft Agent Framework | LangGraph |
| Container | No | Yes (Docker/ACR) | Yes (Docker/ACR) |
| Custom tools | No (server-side only) | Yes (local Python) | Yes (local Python) |
| Editable in portal | Yes | No | No |
| Deploy | Instant | Build + ACR + start | Build + ACR + start |

## Using Foundry Catalog Tools via SDK

One of the biggest advantages of the declarative agent is the ability to use **tools from the Foundry catalog** (the same ones available in the portal) directly via SDK code.

### How does it work?

- **Declarative Agent** (`PromptAgentDefinition`): runs **server-side** in Foundry. The tools (Bing, Azure AI Search, OpenAPI, Code Interpreter, etc.) are executed by Foundry's own runtime. You define the tools in the SDK and they appear in the portal (and vice versa).
- **Hosted Agent** (MAF/LangGraph): runs inside a **container**. The container manages its own tools via Python code. Foundry's runtime only forwards the request to the container — it doesn't inject tools from the portal.

### Example: agent with Bing Grounding Search

```python
import os
from azure.identity import DefaultAzureCredential
from azure.ai.agents import AgentsClient
from azure.ai.agents.models import (
    PromptAgentDefinition,
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
    BingGroundingSearchConfiguration,
)

credential = DefaultAzureCredential()
project_client = AgentsClient(
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

| Tool | SDK Class (`azure.ai.agents.models`) |
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

## Reference

- [Microsoft Foundry quickstart](https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code)
- [Foundry Agent Service overview](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Bing Grounding tools](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/bing-tools)
- [Tools overview](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/overview)
