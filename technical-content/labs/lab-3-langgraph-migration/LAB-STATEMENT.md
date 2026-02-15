# Lab 3: Migrate LangGraph Agent from AWS to Azure

## Objective

Migrate an existing **LangGraph agent from AWS Lambda/ECS** to Azure Foundry as a Hosted Agent, demonstrating the AWS-to-Azure migration path with minimal code changes.

## Scenario

Your team has a LangGraph-based financial agent running in AWS Lambda. The business wants to:
- Consolidate infrastructure in Azure
- Leverage Microsoft Foundry for unified agent management
- Integrate with M365 ecosystem (Teams, Outlook)
- Maintain existing LangGraph code patterns

Your task: Lift-and-shift the agent to Azure with minimal refactoring.

## Learning Outcomes

- Migrate LangGraph agents from AWS to Azure
- Adapt AWS model APIs (Bedrock) to Azure OpenAI
- Configure Foundry adapter for LangGraph (`caphost.json`)
- Deploy LangGraph agents as Foundry Hosted Agents
- Compare LangGraph vs MAF architectures
- Make informed framework selection decisions

## Prerequisites

- [x] Lab 2 completed (MAF understanding)
- [x] LangGraph knowledge (recommended but not required)
- [x] Understanding of AWS Lambda or ECS containers
- [x] Docker and ACR access
- [x] Azure OpenAI resource deployed

## Tasks

### Task 1: Review AWS Agent Architecture (10 minutes)

**Study the provided AWS Lambda LangGraph agent**:

```
starter/aws-agent/
├── lambda_function.py      # AWS Lambda handler
├── financial_graph.py      # LangGraph StateGraph definition
├── tools.py                # Tool functions (same as MAF)
└── requirements.txt        # AWS dependencies
```

**Key AWS components to identify**:
- Lambda handler function signature
- Bedrock API client usage
- Event-driven invocation model
- IAM role-based authentication

**Questions to answer**:
1. How is the agent invoked in AWS?
2. Where does authentication happen?
3. How are tools registered in LangGraph?
4. What's the execution model (synchronous vs async)?

**Success Criteria**:
- ✅ Understand Lambda handler pattern
- ✅ Identify Bedrock API usage
- ✅ Recognize differences from always-on container model

### Task 2: Create Azure LangGraph Agent (30 minutes)

Navigate to `starter/azure-agent/` and implement:

**2.1 - Define Agent State**

```python
from typing import TypedDict, Annotated
from langchain_core.messages import BaseMessage

class FinancialAgentState(TypedDict):
    """State object for financial agent."""
    messages: Annotated[list[BaseMessage], "Conversation history"]
    current_tool: Annotated[str, "Currently executing tool"]
    tool_result: Annotated[dict, "Result from last tool call"]
```

**2.2 - Implement Tool Node**

```python
def tool_node(state: FinancialAgentState) -> FinancialAgentState:
    """Executes tool based on agent's decision."""
    # TODO: Extract tool name from last message
    # TODO: Call appropriate tool function
    # TODO: Update state with result
    return state
```

**2.3 - Implement Agent Node**

```python
from langchain_openai import AzureChatOpenAI

async def agent_node(state: FinancialAgentState, model: AzureChatOpenAI) -> FinancialAgentState:
    """LLM processes conversation and decides next action."""
    # TODO: Format messages for LLM
    # TODO: Call Azure OpenAI via model
    # TODO: Determine if tool call needed
    # TODO: Update state
    return state
```

**2.4 - Build StateGraph**

```python
from langgraph.graph import StateGraph, END

def create_financial_graph() -> StateGraph:
    """Builds LangGraph workflow for financial agent."""
    workflow = StateGraph(FinancialAgentState)
    
    # TODO: Add nodes (agent, tools)
    # TODO: Define edges (agent -> tools, tools -> agent, agent -> END)
    # TODO: Set entry point
    # TODO: Compile graph
    
    return workflow.compile()
```

**2.5 - Replace Bedrock with Azure OpenAI**

**BEFORE (AWS Bedrock)**:
```python
from langchain_community.chat_models import BedrockChat
model = BedrockChat(
    model_id="anthropic.claude-3-sonnet",
    region_name="us-east-1",
)
```

**AFTER (Azure OpenAI)**:
```python
from langchain_openai import AzureChatOpenAI
model = AzureChatOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
    azure_deployment="gpt-4",
    temperature=0.7,
)
```

**Success Criteria**:
- ✅ State object properly typed
- ✅ Tool node executes tools based on state
- ✅ Agent node processes LLM responses
- ✅ Graph compiled without errors
- ✅ Azure OpenAI replaces Bedrock successfully

### Task 3: Configure Foundry Adapter (15 minutes)

**3.1 - Create `caphost.json`**

```json
{
  "name": "langgraph-financial-agent",
  "version": "1.0",
  "entry":  "main:app",
  "runtime": "python",
  "port": 8080,
  "health_check": "/health",
  "environment": {
    "AZURE_OPENAI_ENDPOINT": "${AZURE_OPENAI_ENDPOINT}",
    "AZURE_OPENAI_DEPLOYMENT": "${AZURE_OPENAI_DEPLOYMENT}",
    "AZURE_CLIENT_ID": "${MANAGED_IDENTITY_CLIENT_ID}"
  }
}
```

**Purpose**: Tells Foundry how to invoke your LangGraph agent
- `entry`: Module and callable to invoke
- `port`: HTTP server port (LangGraph uses 8080, MAF uses 8088)
- `health_check`: Endpoint for health monitoring

**3.2 - Implement HTTP Wrapper**

Create `main.py`:
```python
from fastapi import FastAPI, Request
from financial_graph import create_financial_graph

app = FastAPI()
graph = create_financial_graph()

@app.post("/invoke")
async def invoke_agent(request: Request):
    """Foundry calls this endpoint to invoke agent."""
    body = await request.json()
    user_message = body.get("message")
    
    # Run LangGraph
    result = await graph.ainvoke({
        "messages": [user_message],
        "current_tool": None,
        "tool_result": {}
    })
    
    return {"response": result["messages"][-1].content}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

**Success Criteria**:
- ✅ `caphost.json` configured correctly
- ✅ HTTP endpoints implemented (FastAPI)
- ✅ Graph invocation works asynchronously

### Task 4: Update Dockerfile (10 minutes)

Adapt Dockerfile from AWS to Azure:

**BEFORE (AWS ECS)**:
```dockerfile
FROM public.ecr.aws/lambda/python:3.11
WORKDIR /var/task
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["lambda_function.handler"]
```

**AFTER (Azure Foundry)**:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Key Changes**:
- Base image: Lambda runtime → Python slim
- Port: Expose 8080 for HTTP server
- CMD: Lambda handler → uvicorn web server
- Working directory: `/var/task` → `/app`

**Success Criteria**:
- ✅ Dockerfile builds successfully
- ✅ Container exposes correct port
- ✅ uvicorn starts correctly

### Task 5: Deploy to Azure Foundry (20 minutes)

**5.1 - Build and push container**

```powershell
docker build -t langgraph-financial-agent:v1 .
az acr login --name YOUR-ACR
docker tag langgraph-financial-agent:v1 YOUR-ACR.azurecr.io/langgraph- financial-agent:v1
docker push YOUR-ACR.azurecr.io/langgraph-financial-agent:v1
```

**5.2 - Create Hosted Agent**

```powershell
az cognitiveservices agent create \
  --name langgraph-financial-agent \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-PROJECT \
  --image "YOUR-ACR.azurecr.io/langgraph-financial-agent:v1" \
  --env "AZURE_OPENAI_ENDPOINT=..." \
       "AZURE_OPENAI_DEPLOYMENT=gpt-4" \
       "HOSTED_AGENT_VERSION=1"
```

**5.3 - Start agent**

```powershell
az cognitiveservices agent start \
  --name langgraph-financial-agent \
  --agent-version 1 \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-PROJECT
```

**Success Criteria**:
- ✅ Container deployed to ACR
- ✅ Hosted agent created in Foundry
- ✅ Agent status shows "Running"

### Task 6: Test and Compare (15 minutes)

**6.1 - Test migrated agent**

```powershell
python test_agent.py
```

Test same questions as in AWS:
1. "What's the PETR4 stock price?"
2. "Calculate portfolio value: 100 PETR4, 50 VALE3"
3. "Give me Brazil market summary"

**6.2 - Compare with MAF agent (Lab 2)**

| Feature | LangGraph (This Lab) | MAF (Lab 2) |
|---------|---------------------|-------------|
| **Code Lines** | ~150 lines | ~80 lines |
| **Complexity** | Higher (explicit orchestration) | Lower (automatic) |
| **Control** | Full control over flow | Framework-managed |
| **State Management** | Manual (TypedDict) | Built-in |
| **Tool Calling** | Manual node routing | Automatic ReAct pattern |
| **Migration Ease** | Easier (from LangGraph) | Requires refactor |

**6.3 - Decision Matrix**

When would you choose LangGraph over MAF?
- [x] Migrating existing LangGraph code from AWS
- [x] Need explicit control over agent flow
- [x] Complex multi-step workflows
- [x] Custom state management requirements

When would you choose MAF over LangGraph?
- [x] New agent development from scratch
- [x] Simple tool-calling patterns
- [x] Want faster development (less boilerplate)
- [x] Prefer framework conventions over control

**Success Criteria**:
- ✅ Agent functional and produces correct answers
- ✅ Performance comparable to AWS version
- ✅ Clear understanding of framework trade-offs

## Deliverables

- [x] Migrated LangGraph agent (Azure OpenAI)
- [x] `caphost.json` configured
- [x] Dockerfile adapted for Azure
- [x] Agent deployed and running in Foundry
- [x] Comparison document: LangGraph vs MAF
- [x] Migration checklist completed

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **Migration Strategy** | 15 pts | Identified AWS components to change |
| **LangGraph Implementation** | 30 pts | State, nodes, edges correctly configured |
| **Azure OpenAI Integration** | 20 pts | Bedrock replaced with Azure OpenAI |
| **Deployment** | 20 pts | Container built and agent running |
| **Testing** | 10 pts | Agent produces correct answers |
| **Comparison Analysis** | 5 pts | Thoughtful LangGraph vs MAF evaluation |

**Total**: 100 points

## Troubleshooting

### "Graph compilation error: node not found"
- Verify all nodes referenced in edges are added to graph
- Check node names match exactly (case-sensitive)

### "Azure OpenAI 401 Unauthorized"
- Ensure Managed Identity has "Cognitive Services User" role
- Verify `AZURE_OPENAI_ENDPOINT` is correct

### "caphost.json not found during deployment"
- File must be in container root directory
- Ensure Dockerfile COPY command includes it

### "Tool execution fails in graph"
- Check tool functions are imported correctly
- Verify tool names match LLM's function call output

## Time Estimate

- Task 1: 10 minutes
- Task 2: 30 minutes
- Task 3: 15 minutes
- Task 4: 10 minutes
- Task 5: 20 minutes
- Task 6: 15 minutes
- **Total**: 100 minutes

## Next Steps

- **Lab 4**: Deploy to Azure Container Apps for infrastructure control
- Understand Connected Agent pattern
- Learn Bicep IaC for Azure deployment

---

**Difficulty**: Intermediate-Advanced  
**Prerequisites**: Labs 1-2, basic LangGraph/AWS knowledge  
**Estimated Time**: 100 minutes
