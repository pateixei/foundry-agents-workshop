# Demo 1: Declarative Agent Pattern

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Overview

This demo showcases creating a **declarative (prompt-based) financial advisor agent** in Azure AI Foundry using the `azure-ai-projects` SDK (new Foundry experience). Declarative agents are the simplest pattern—they run server-side in Foundry without requiring custom containers.

## What This Demonstrates

- ✅ Creating agents with `PromptAgentDefinition`
- ✅ Configuring system prompts and model selection
- ✅ Registering agents in Foundry for instant availability
- ✅ Testing agents programmatically via SDK
- ✅ Modifying agent parameters in Foundry Portal (no redeployment needed)
- ✅ Understanding when to use declarative vs hosted patterns

## Architecture

```
┌─────────────────────────────────┐
│ Your Code (create_agent.py)    │
│   └─> PromptAgentDefinition     │
└────────────┬────────────────────┘
             │ (registers agent)
             ▼
┌─────────────────────────────────┐
│ Azure AI Foundry (Backend)      │
│   ├─> Agent Runtime (serverless)│
│   ├─> Model (GPT-4)             │
│   └─> Tools (optional catalog)  │
└────────────┬────────────────────┘
             │ (accessed via SDK)
             ▼
┌─────────────────────────────────┐
│ Client Application              │
│   (test_agent.py - console)     │
└─────────────────────────────────┘
```

## Prerequisites

1. **Azure Resources Deployed**:
   - Azure AI Foundry project created
   - GPT-4 model deployed in Foundry
   - Azure CLI logged in: `az login`

2. **Environment Variables**:
   - `PROJECT_ENDPOINT` - Foundry project endpoint URL
   - `MODEL_DEPLOYMENT_NAME` - Model deployment name (e.g., `gpt-4.1`)

3. **Python Environment**:
   - Python 3.10 or higher
   - Dependencies installed: `pip install -r requirements.txt`

4. **Azure Permissions**:
   - "Azure AI User" role on the Foundry project

## How to Run

### Step 1: Set Environment Variables

Create a `.env` file:
```bash
PROJECT_ENDPOINT=https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
MODEL_DEPLOYMENT_NAME=gpt-4.1
```

Or set in PowerShell:
```powershell
$env:PROJECT_ENDPOINT="https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT"
$env:MODEL_DEPLOYMENT_NAME="gpt-4.1"
```

### Step 2: Create the Agent

```powershell
python create_agent.py
```

**Expected Output**:
```
Endpoint: https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
Agente:   fin-market-declarative
Modelo:   gpt-4.1

Agente criado com sucesso!
  Nome:    fin-market-declarative
  Versao:  1
  ID:      fin-market-declarative:1
  
O agente esta visivel e editavel no portal do Foundry.
Acesse: https://ai.azure.com/ para editar instructions, model, etc.
```

### Step 3: Test the Agent

```powershell
python test_agent.py
```

**Example Interaction**:
```
🤖 Financial Advisor Agent (Declarative)
Type 'quit' to exit

You: Qual é a cotação da PETR4?

Agent: Petrobras PN (PETR4) não possui cotação em tempo real disponível. 
Para informações atualizadas, recomendo consultar sites de notícias financeiras 
como InfoMoney, Valor Econômico, ou dados diretamente da B3.

Esta informação é apenas para fins educativos e não constitui recomendação de investimento.

────────────────────────────────

You: quit
```

### Step 4: Modify Agent in Portal (Optional)

1. Navigate to [Azure AI Foundry Portal](https://ai.azure.com/)
2. Select your project
3. Go to **Agents** → **fin-market-declarative**
4. Click **Edit**
5. Modify the system prompt (e.g., change tone, add capabilities)
6. Click **Save**
7. Test again with `test_agent.py` — changes are immediate!

## File Structure

```
demo-1-declarative-agent/
├── README.md                  # This file
├── create_agent.py            # Agent creation script
├── test_agent.py              # Console test client
├── requirements.txt           # Python dependencies
├── .env.example               # Environment template
└── architecture-diagram.png   # Visual architecture
```

## Code Walkthrough

### create_agent.py

```python
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential

# Authenticate using Azure CLI credentials
credential = DefaultAzureCredential()

# Connect to Foundry project
project_client = AIProjectClient(
    endpoint=os.environ["PROJECT_ENDPOINT"],
    credential=credential,
)

# Define the agent
agent = project_client.agents.create_version(
    agent_name="fin-market-declarative",
    definition=PromptAgentDefinition(
        model="gpt-4.1",  # Use deployed model name
        instructions="""
You are a financial market advisor specializing in Brazilian and international markets.

## Your Objective
Help investors with stock information, exchange rates, and market trends.

## Guidelines
- Always respond in Brazilian Portuguese
- Explain you don't have real-time data
- Include disclaimer: "This information is for educational purposes only"
- Be objective and direct
        """,
    ),
)

print(f"✅ Agent created: {agent.name} (version {agent.version})")
```

**Key Points**:
- `PromptAgentDefinition`: The declarative agent type
- `instructions`: System prompt defining agent behavior
- `model`: References the Foundry model deployment
- No tools specified initially (can add later in Portal)

### test_agent.py

```python
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=os.environ["PROJECT_ENDPOINT"],
    credential=credential,
)

# Get OpenAI client from the project
openai_client = project_client.get_openai_client()

# Create a conversation for multi-turn chat
conversation = openai_client.conversations.create()

# Chat loop
while True:
    user_input = input("You: ")
    if user_input.lower() == "quit":
        break
    
    # Send message via Responses API with agent_reference
    response = openai_client.responses.create(
        conversation=conversation.id,
        extra_body={
            "agent": {
                "name": "fin-market-declarative",
                "type": "agent_reference",
            }
        },
        input=user_input,
    )

    print(response.output_text)
    print("\n" + "─" * 40 + "\n")
```

**Key Points**:
- `get_openai_client()`: Gets an OpenAI-compatible client from the project
- `conversations.create()`: Creates a multi-turn conversation context
- `responses.create()`: Sends messages via the Responses API using `agent_reference`
- Conversation persists across multiple messages (conversation memory)

## Understanding Declarative Agents

### Advantages ✅
- **Instant deployment**: No container build or ACR push required
- **Portal editable**: Modify instructions, tools, and model without code changes
- **Zero infrastructure**: Foundry manages all execution resources
- **Fast iteration**: Test prompt changes in seconds, not minutes
- **Automatic scaling**: Foundry handles traffic spikes

### Limitations ⚠️
- **No custom Python code**: Tools are limited to Foundry's catalog
- **Server-side only**: Can't execute local business logic
- **Limited integrations**: No direct database access or custom APIs
- **Foundry-dependent**: Execution tied to Foundry availability

### When to Use Declarative Agents

**✅ USE WHEN**:
- Rapid prototyping and POCs
- Prompt engineering and testing
- Agents need only Foundry catalog tools (Bing, Azure AI Search, Code Interpreter)
- No custom business logic required
- Fast iterations are priority

**❌ AVOID WHEN**:
- Need custom Python tools (database queries, API calls)
- Require local file processing or complex calculations
- Need complete control over execution environment
- Custom authentication or authorization logic needed

## Adding Foundry Catalog Tools

To add tools like Bing Search or Code Interpreter:

```python
from azure.ai.projects.models import (
    PromptAgentDefinition,
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
)

# Get Bing connection from Foundry
bing_connection = project_client.connections.get("bing-connection-name")

# Create agent with Bing tool
agent = project_client.agents.create_version(
    agent_name="fin-market-with-bing",
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="You are a financial advisor. Use Bing for real-time data.",
        tools=[
            BingGroundingAgentTool(
                bing_grounding=BingGroundingSearchToolParameters(
                    search_configurations=[{
                        "project_connection_id": bing_connection.id
                    }]
                )
            )
        ],
    ),
)
```

**Available Foundry Tools**:
- **Bing Grounding Search**: Web search with grounding
- **Azure AI Search**: Vector and keyword search over your data
- **Code Interpreter**: Execute Python code in sandbox
- **OpenAPI Tools**: Call external APIs via OpenAPI specs
- **Microsoft Fabric**: Query data in Fabric lakehouses

## Comparison: Declarative vs Hosted Agents

| Feature | Declarative (This Demo) | Hosted (Demo 2-3) |
|---------|------------------------|-------------------|
| Deployment | SDK call only | Container build + ACR push |
| Custom Tools | Catalog only | Any Python code |
| Modification | Portal (instant) | Code + redeploy |
| Infrastructure | None (Foundry) | Container required |
| Iteration Speed | Seconds | Minutes (rebuild) |
| Flexibility | Low | High |
| Use Case | Prototyping | Production |

## Troubleshooting

### Issue: "Authentication failed"
**Cause**: Azure CLI not logged in or wrong tenant  
**Fix**:
```powershell
az login
az account show  # Verify correct subscription
```

### Issue: "Model deployment not found"
**Cause**: Model name doesn't match Foundry deployment  
**Fix**:
1. Go to Foundry Portal → Models
2. Copy the exact deployment name (case-sensitive)
3. Update `MODEL_DEPLOYMENT_NAME` environment variable

### Issue: "Access denied to Foundry project"
**Cause**: Missing "Azure AI User" role  
**Fix**:
1. Portal → Foundry Project → Access Control (IAM)
2. Add role assignment: "Azure AI User"
3. Assign to your user account
4. Wait 2-3 minutes for propagation

### Issue: Agent returns generic responses (no domain knowledge)
**Cause**: System prompt is too vague  
**Fix**: Enhance `instructions` with:
- Specific domain knowledge
- Response format guidelines
- Example outputs
- Constraints and disclaimers

### Issue: "Agent version already exists"
**Cause**: Rerunning `create_agent.py` with same name  
**Fix**: Each run of `create_version()` creates a new version (v1, v2, etc.). If you want to start fresh, delete the agent in the Foundry Portal or use a different `agent_name`:
```python
# Option 1: Use a different name
agent_name="fin-market-declarative-v2"

# Option 2: Delete the agent in the Foundry Portal and recreate
```

## Next Steps

After mastering declarative agents, proceed to:
- **Demo 2**: Hosted MAF Agent with custom Python tools
- **Demo 3**: Hosted LangGraph Agent for complex workflows
- **Demo 4**: ACA Deployment for infrastructure control
- **Demo 5**: Agent 365 SDK for M365 integration

## Additional Resources

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Prompt Engineering Guide](https://learn.microsoft.com/azure/ai-services/openai/concepts/prompt-engineering)
- [PromptAgentDefinition API Reference](https://learn.microsoft.com/python/api/azure-ai-projects/)
- [Foundry Tools Catalog](https://learn.microsoft.com/azure/ai-studio/how-to/tools-catalog)

---

**Demo Level**: Beginner  
**Estimated Time**: 15-20 minutes  
**Prerequisites**: Azure resources deployed, Python environment ready
