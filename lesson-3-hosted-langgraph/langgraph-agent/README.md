# Lesson 2 - Hosted Agent with LangGraph in Azure AI Foundry

In this lesson, we create a **hosted agent** in Azure AI Foundry
using the **LangGraph** framework from LangChain.

## Architecture

The agent follows the **ReAct** pattern (Reason + Act):

1. The LLM receives the user's message
2. Decides if it needs to call a tool or respond directly
3. If it called a tool, executes and returns the result to the LLM
4. The cycle repeats until the LLM produces a final response

```
START -> llm_call -> [tool_calls?] -> environment -> llm_call -> ... -> END
```

## Available Tools

| Tool | Description |
|---|---|
| `get_stock_price` | Query stock prices (PETR4, VALE3, AAPL, etc.) |
| `get_market_summary` | Summary of major indices (Ibovespa, S&P 500, etc.) |
| `get_exchange_rate` | Exchange rate (USD/BRL, EUR/BRL, BTC/USD, etc.) |

> **Note:** The tools use simulated data for educational purposes.

## File Structure

```
lesson-2/langgraph-agent/
  main.py                  # LangGraph agent + hosted agent server
  # create_hosted_agent.py moved to prereq/
  test_agent.py            # Test script for running agent
  deploy.ps1               # Complete deployment script (CLI)
  requirements.txt         # Python dependencies
  Dockerfile               # Container for hosted agent
  README.md                # This file
```

## How the Hosted Agent Works

The `azure-ai-agentserver-langgraph` package provides the adapter that:

1. Receives a compiled LangGraph graph
2. Exposes the **Responses API** on port 8088
3. Foundry routes client calls to the container

```python
from azure.ai.agentserver.langgraph import from_langgraph
agent = build_agent()          # Compiled StateGraph
adapter = from_langgraph(agent)
adapter.run()                  # Starts server on port 8088
```

## Prerequisites

- Infrastructure from the `prereq/` folder already deployed
- Azure CLI with `cognitiveservices` extension (`az extension add --name cognitiveservices --upgrade`)
- Python 3.12+
- `az login` completed

## Step-by-Step Deployment

The `deploy.ps1` script automates the steps below, but if you need to do it
manually or understand what happens, follow the sequence:

### 1. Capability Host (once per account)

Hosted agents require a **Capability Host** at the account level.
If not yet created, run:

```powershell
az rest --method put `
    --url "https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY_NAME>/capabilityHosts/accountcaphost?api-version=2025-04-01-preview" `
    --body '{\"properties\":{\"capabilityHostKind\":\"Agents\",\"enablePublicHostingEnvironment\":true}}'
```

### 2. Build Image in ACR

```powershell
cd lesson-2/langgraph-agent
az acr build --registry <ACR_NAME> --image lg-market-agent:v1 --file Dockerfile . --no-logs
```

> **Windows Note:** Use `--no-logs` to avoid `UnicodeEncodeError` caused by
> colorama/cp1252 when displaying ACR build logs in PowerShell 5.1.

### 3. RBAC Permissions (project managed identity)

The Foundry project has a managed identity that needs two roles:

| Role | Scope | Reason |
|---|---|---|
| **AcrPull** | Container Registry | To pull the container image |
| **Cognitive Services OpenAI User** | AI Foundry Account | For the container to call the GPT model |

```powershell
# Get the project principal ID
$PRINCIPAL = az resource show `
    --ids "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>/projects/<PROJECT>" `
    --query "identity.principalId" -o tsv

# AcrPull on ACR
az role assignment create --assignee $PRINCIPAL --role "AcrPull" `
    --scope $(az acr show --name <ACR> --query id -o tsv)

# OpenAI User on Foundry account
az role assignment create --assignee $PRINCIPAL --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>"
```

> **Important:** The Foundry project resource type is
> `Microsoft.CognitiveServices/accounts/projects` (NOT `MachineLearningServices`).

### 4. Create and start the agent

```powershell
# Create version (without starting)
az cognitiveservices agent create `
    --account-name <FOUNDRY> --project-name <PROJECT> `
    --name lg-market-agent `
    --image <ACR>.azurecr.io/lg-market-agent:v1 `
    --cpu 1 --memory 2Gi `
    --protocol responses --protocol-version v1 `
    --env AZURE_AI_PROJECT_ENDPOINT=<PROJECT_ENDPOINT> `
         AZURE_AI_MODEL_DEPLOYMENT_NAME=<MODEL> `
         AZURE_OPENAI_ENDPOINT=https://<FOUNDRY>.openai.azure.com/ `
    --no-start

# Start the agent
az cognitiveservices agent start `
    --account-name <FOUNDRY> --project-name <PROJECT> `
    --name lg-market-agent --agent-version 1
```

The agent lifecycle is: `Stopped -> Starting -> Started (Running)`.
Wait ~2 minutes for the status to change to Running.

### 5. Test the agent

```powershell
python test_agent.py
```

## Automated Deployment

```powershell
cd lesson-2/langgraph-agent
.\deploy.ps1
```

## Agent Invocation (Technical Details)

Hosted agents are invoked via **Responses API** with an `agent` field
in the body that identifies the agent and version.

### Using the `azure-ai-projects` SDK

```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

endpoint = "https://<foundry>.services.ai.azure.com/api/projects/<project>"

with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=endpoint, credential=credential) as client,
    client.get_openai_client() as oai,
):
    response = oai.responses.create(
        input=[{"role": "user", "content": "What's the price of PETR4?"}],
        extra_body={
            "agent": {
                "id": "lg-market-agent",
                "name": "lg-market-agent",
                "version": "3",
                "type": "agent_reference",
            }
        },
    )
    print(response.output_text)
```

### Using REST directly

```python
import requests
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
token = credential.get_token("https://ai.azure.com/.default").token

url = "https://<foundry>.services.ai.azure.com/api/projects/<project>/openai/responses?api-version=2025-11-15-preview"
body = {
    "input": [{"role": "user", "content": "What's the price of PETR4?"}],
    "agent": {
        "id": "lg-market-agent",
        "name": "lg-market-agent",
        "version": "3",
        "type": "agent_reference",
    },
}
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

r = requests.post(url, headers=headers, json=body, timeout=120)
# Extract response text
for item in r.json().get("output", []):
    if item.get("type") == "message":
        for c in item.get("content", []):
            if c.get("type") == "output_text":
                print(c["text"])
```

## Known Workarounds and Bugs

### 1. AgentReference without `id` field (SDK)

The `azure-ai-projects==2.0.0b3` SDK's `AgentReference` doesn't include the `id` field,
but the Foundry service requires this field. Workaround: manually build the dict
with `id`, `name`, `version`, and `type` (see examples above).

### 2. AgentReference in container (agentserver-core)

The Foundry service sends an `id` field when routing requests to the container, but
`azure-ai-agentserver-core==1.0.0b10` rejects unknown fields in
`AgentReference`. The `main.py` includes a monkey-patch in
`_patch_agent_reference()` to handle this.

### 3. `init_chat_model` requires `azure_endpoint` and `api_version`

When using `init_chat_model("azure_openai:...")` with LangChain, the
`azure_endpoint` and `api_version` parameters are mandatory. The container receives the
endpoint via the `AZURE_OPENAI_ENDPOINT` environment variable.

### 4. `az acr build` UnicodeEncodeError on Windows

`az acr build` fails with `UnicodeEncodeError: 'charmap' codec` in
PowerShell 5.1 due to colorama. Use `--no-logs` to work around:

```powershell
az acr build --registry <ACR> --image <TAG> --file Dockerfile . --no-logs
```

### 5. Token audience for invocation

- Endpoint `*.services.ai.azure.com` (project): audience `https://ai.azure.com/.default`
- Endpoint `*.openai.azure.com` (OpenAI): audience `https://cognitiveservices.azure.com/.default`

The `AIProjectClient` SDK's `client.get_openai_client()` already configures this
automatically (api-version `2025-11-15-preview`).

## Difference from Lesson 1

| Aspect | Lesson 1 | Lesson 2 |
|---|---|---|
| Type | Prompt-based agent | Hosted agent (container) |
| Framework | Direct SDK (`azure-ai-agents`) | LangGraph + adapter |
| Execution | Serverless in Foundry | Own container in Foundry |
| Tools | Code Interpreter (built-in) | Custom tools (Python) |
| Complexity | Simple | Medium |

## SDK Versions Used

| Package | Version |
|---|---|
| `azure-ai-agentserver-langgraph` | 1.0.0b10 |
| `azure-ai-agentserver-core` | 1.0.0b10 (dependency) |
| `azure-ai-projects` | 2.0.0b3 (local client) |
| `azure-ai-agents` | 1.2.0b5 (dependency) |
| `langchain` / `langgraph` | Installed by agentserver |
