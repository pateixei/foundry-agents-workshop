# Instructional Script: Module 3 - Hosted Agent with LangGraph

---

**Module**: 3 - Hosted Agent with LangGraph  
**Duration**: 120 minutes (Day 2, Hours 3-4: 11:15-13:15)  
**Instructor**: Technical SME + Facilitator  
**Location**: `instructor-guide/MODULE-3-HOSTED-LANGGRAPH-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Learning Objectives

By the end of this module, students will be able to:
1. **Deploy** LangGraph agents on Azure Foundry using the adapter pattern
2. **Implement** LangGraph agents using the Foundry adapter pattern
3. **Compare** LangGraph and MAF architectures side-by-side
4. **Deploy** LangGraph agents as Foundry Hosted Agents
5. **Decide** when to use LangGraph vs MAF for specific use cases
6. **Map** LangGraph deployments across different cloud environments

---

## 📊 Module Overview

| Element | Duration | Method |
|---------|----------|--------|
| **LangGraph on Azure: Multi-Platform Advantage** | 20 min | Presentation (platform capabilities) |
| **LangGraph on Foundry Architecture** | 25 min | Code walkthrough + adapter pattern |
| **Hands-On Deployment** | 45 min | Deploy LangGraph agent to Foundry |
| **MAF vs LangGraph Comparison** | 20 min | Side-by-side code comparison |
| **Deployment Planning Workshop** | 10 min | Decision framework |

---

## 🗣️ Instructional Script (Minute-by-Minute)

### 11:15-11:35 | LangGraph on Azure: Multi-Platform Advantage (20 min)

**Instructional Method**: Presentation with platform comparison

**Opening (2 min)**:
> "You've now deployed a MAF agent. Many of you also have experience with LangGraph. Today we'll deploy LangGraph agents on Azure Foundry—and you'll see how little code changes."
>
> "LangGraph is framework-agnostic—it works across cloud providers and locally. We'll show you how to run your existing LangGraph code on Foundry with minimal adapter changes."

**Content Delivery (15 min)**:

**Slide 1: LangGraph Across Cloud Platforms**

| Component | Other Clouds | Azure Foundry |
|-----------|-------------|---------------|
| **Framework** | LangGraph | LangGraph (same!) |
| **Compute** | Various container services | Foundry Hosted Agent |
| **Model** | Various LLM providers | Azure OpenAI via Foundry |
| **Storage** | Various databases | Azure Cosmos DB or Table Storage |
| **Container** | Various registries | Azure Container Registry (ACR) |
| **Deployment** | Various IaC tools | Bicep or ARM |
| **Monitoring** | Various solutions | Application Insights |

**Say**:
> "Core LangGraph code stays the same. What changes: deployment target and model provider."
>
> "Your graph definitions, nodes, edges—all unchanged. The adapter pattern handles the platform integration."

**Slide 2: Why Deploy LangGraph on Azure Foundry?**

**Ask students**: "What advantages do you see in running LangGraph on Azure Foundry?" (collect responses)

**Instructor provides**:
- ✅ **Unified platform**: Foundry integrates agents with Copilot, Teams, M365
- ✅ **Enterprise governance**: Centralized agent management, RBAC, auditing
- ✅ **Cost optimization**: Azure EA agreements, reserved instances
- ✅ **Compliance**: Data residency requirements (Azure regions)
- ✅ **Ecosystem**: Native integration with Azure services (Cosmos, KeyVault, etc.)

**Say**:
> "Deploying on Foundry isn't just about hosting—it's **strategic positioning** for enterprise AI."

**Slide 3: LangGraph on Foundry vs Other Platforms**

Show before/after architecture:

**Traditional Deployment (other platforms)**:
```
┌──────────────────────┐
│ Container / Function   │
│  ├─> LangGraph code  │
│  └─> LLM API client  │
└─────────┬────────────┘
          │ (triggered by)
          ▼
┌──────────────────────┐
│ API Gateway          │
└──────────────────────┘
```

**After (Azure Foundry)**:
```
┌──────────────────────────────────┐
│ Foundry Hosted Agent             │
│  ├─> Container (same LangGraph)  │
│  └─> Azure OpenAI via Foundry    │
└─────────┬────────────────────────┘
          │ (accessed via)
          ▼
┌──────────────────────────────────┐
│ Foundry Responses API            │
└──────────────────────────────────┘
```

**Say**:
> "Event-driven functions are short-lived. Foundry hosted agents are **always-on containers**—designed for persistent agent workloads."
>
> "If you've run LangGraph in containers before, deployment to Foundry is straightforward: containerization is identical."

**Interactive (3 min)**:
- **Poll**: "How many have LangGraph agents in production?" (count)
- **Ask those with hands up**: "What's your biggest consideration when deploying to a new platform?"
- Common answers: Downtime, cost, testing effort
- **Respond**: "We'll address all three today."

**Transition**:
> "Let's see the actual code changes needed. Spoiler: minimal."

---

### 11:35-12:00 | LangGraph on Foundry Architecture (25 min)

**Instructional Method**: Live code walkthrough

**Setup**:
- Share screen with VS Code
- Open `lesson-3-hosted-langgraph/solution/`
- Split view: File tree + code

#### Section 1: File Structure (5 min)

**Show structure**:
```
solution/
├── main.py                        # LangGraph agent definition
├── Dockerfile                     # Container (similar to MAF)
├── requirements.txt               # Dependencies
├── deploy.ps1                     # Deployment script
├── caphost.json                   # Capability Host config (NEW!)
└── README.md
```

**Say**:
> "Notice: Simpler than MAF. No `src/` folders, no agent server abstraction."
>
> "Key difference: `caphost.json`—Foundry config file that LangGraph needs."

#### Section 2: LangGraph Agent Code (10 min)

**Open**: `main.py`

**Show imports**:
```python
from langgraph.graph import StateGraph, END
from langchain_openai import AzureChatOpenAI
from langchain_core.messages import HumanMessage, AIMessage
from typing import TypedDict, Annotated
```

**Say**:
> "Standard LangGraph imports. Nothing Foundry-specific here."

**Show state definition**:
```python
class AgentState(TypedDict):
    messages: Annotated[list, "conversation history"]
    next_action: str
```

**Show tools**:
```python
def get_stock_price(symbol: str) -> dict:
    """Fetch stock price."""
    # Same implementation as MAF module
    prices = {"AAPL": 175.50, "PETR4": 38.20, "VALE3": 65.80}
    return {
        "symbol": symbol.upper(),
        "price": prices.get(symbol.upper(), 0.0),
        "currency": "USD" if not symbol.endswith("3") else "BRL"
    }

# Additional tools: get_exchange_rate, get_market_sentiment
```

**Say**:
> "Tools are plain functions—same as MAF, but without `@tool` decorator."
>
> "LangGraph doesn't use decorators. Tools are registered explicitly in the graph."

**Show model initialization** (IMPORTANT):
```python
# Azure OpenAI model via Foundry
model = AzureChatOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),  # From Foundry
    api_version="2024-02-01",
    deployment_name="gpt-4",
    azure_ad_token_provider=get_bearer_token_provider(
        DefaultAzureCredential(),
        "https://cognitiveservices.azure.com/.default"
    )
)
```

**Narrate carefully**:
> "This is where the platform-specific part lives. If you've used LangGraph with other model providers, the change looks like this:"
> ```python
> # Other providers (before)
> from langchain_community.chat_models import ChatOpenAI
> model = ChatOpenAI(model="your-model")
> ```
>
> "On Azure, swap to `AzureChatOpenAI` and use Foundry's endpoint."
>
> "Key: **Managed Identity authentication** (`DefaultAzureCredential`)—no API keys in your code!"

**Show graph definition**:
```python
# Define graph
workflow = StateGraph(AgentState)

# Add nodes
workflow.add_node("agent", agent_node)
workflow.add_node("tool_executor", tool_executor_node)

# Add edges
workflow.set_entry_point("agent")
workflow.add_conditional_edges(
    "agent",
    should_continue,  # Function that decides: tools or end?
    {
        "continue": "tool_executor",
        "end": END
    }
)
workflow.add_edge("tool_executor", "agent")

# Compile
app = workflow.compile()
```

**Say**:
> "This is pure LangGraph—no changes needed for Foundry."
>
> "Your existing graph definitions work as-is."

#### Section 3: Foundry Adapter (`caphost.json`) (10 min)

**Open**: `caphost.json`

**Show content**:
```json
{
  "version": "1.0",
  "agent": {
    "name": "financial-advisor-langgraph",
    "description": "Financial market agent built with LangGraph",
    "entry_point": "main:app",
    "port": 8088,
    "protocol": "responses-api"
  },
  "environment": {
    "AZURE_OPENAI_ENDPOINT": "${AZURE_OPENAI_ENDPOINT}",
    "AZURE_OPENAI_API_VERSION": "2024-02-01"
  }
}
```

**Explain each field**:
- **`entry_point`**: "Points to your compiled LangGraph app. Format: `file:variable`"
- **`port`**: "Foundry expects 8088—same as MAF"
- **`protocol`**: "`responses-api`—Foundry's standard. Adapter translates LangGraph to this."
- **`environment`**: "Inject env vars from Foundry (model endpoint, etc.)"

**Say**:
> "This file is the 'glue' between LangGraph and Foundry."
>
> "Other platforms have their own runtime configs. Foundry uses this explicit config approach—gives you full control."

**Interactive (2 min)**:
- **Ask**: "Where does `${AZURE_OPENAI_ENDPOINT}` get resolved?" (answer: Foundry injects at runtime)
- **Ask**: "What if I change port to 8080?" (answer: breaks Foundry routing)

**Transition**:
> "That's all the code changes: model provider + config file. Let's deploy it."

---

### 12:00-12:45 | Hands-On Deployment (45 min)

**Instructional Method**: Guided deployment with checkpoints

**Lab Structure**: Progressive checkpoints

#### Checkpoint 1: Code Review & Customization (10 min)

**Student Task**:
```powershell
cd lesson-3-hosted-langgraph/langgraph-agent

# Open main.py in editor
code main.py
```

**Customization Exercise**:
1. **Change agent name** in `caphost.json`:
   ```json
   "name": "financial-advisor-lg-YOURINITIALS"
   ```

2. **Modify state structure** (optional for advanced):
   ```python
   class AgentState(TypedDict):
       messages: Annotated[list, "conversation history"]
       next_action: str
       user_context: dict  # NEW: Add user preferences
   ```

3. **Review graph structure**:
   - Identify nodes
   - Trace edge flow
   - Understand conditional logic

**Instructor Facilitation**:
- "Don't just copy—understand the graph. Trace a sample request through nodes."
- Walk around (or breakout rooms), answer questions

**Success Criteria**: ✅ Students understand graph flow

---

#### Checkpoint 2: Environment Setup (5 min)

**Verify prerequisites**:
```powershell
# Check Foundry endpoint
echo $env:AZURE_AI_PROJECT_ENDPOINT

# Check ACR access
az acr login --name $env:ACR_NAME
```

**Install LangGraph dependencies**:
```powershell
pip install -r requirements.txt
```

**Expected packages**:
- `langgraph>=0.0.20`
- `langchain-openai>=0.1.0`
- `azure-identity>=1.15.0`
- `azure-ai-agentserver-langgraph>=0.1.0`  # Foundry adapter!

**Say**:
> "The `azure-ai-agentserver-langgraph` package is Microsoft's adapter. It wraps LangGraph in Foundry's Responses API."
>
> "Without this, Foundry wouldn't know how to talk to your LangGraph agent."

**Success Criteria**: ✅ Dependencies installed without errors

---

#### Checkpoint 3: Local Testing (Optional, 10 min)

**Demonstrate** (instructor only, students watch):
```powershell
# Run agent locally (outside Foundry)
python -c "
from main import app
from langgraph.pregel import Pregel

# Create initial state
state = {'messages': [('user', 'What is AAPL price?')], 'next_action': ''}

# Invoke graph
result = app.invoke(state)
print(result)
"
```

**Expected Output**:
```python
{
  'messages': [
    ('user', 'What is AAPL price?'),
    ('assistant', 'The current price of AAPL is $175.50 USD.')
  ],
  'next_action': 'end'
}
```

**Say**:
> "This proves our graph works locally. Now we containerize for Foundry."

---

#### Checkpoint 4: Dockerfile Review (5 min)

**Open**: `Dockerfile`

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY main.py .
COPY caphost.json .

# Expose port
EXPOSE 8088

# Entry point: agentserver adapter
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
```

**Highlight entry point**:
> "Notice: We don't run `main.py` directly. We run the **adapter** (`azure.ai.agentserver.langgraph`)."
>
> "Adapter reads `caphost.json`, loads your `main:app`, and wraps it in HTTP server."
>
> "This is different from MAF, where MAF SDK provides the server. Here, Microsoft provides a LangGraph-specific adapter."

---

#### Checkpoint 5: Execute Deployment (15 min)

**Student Task**:
```powershell
# Execute deployment script
.\deploy.ps1
```

**Expected Output**:
```
🔨 Building LangGraph agent container...
⏳ Build time: ~8-12 minutes

Step 1/7 : FROM python:3.11-slim
Step 2/7 : WORKDIR /app
Step 3/7 : COPY requirements.txt .
Step 4/7 : RUN pip install --no-cache-dir -r requirements.txt
...
✅ Image built: acrworkshopxyz.azurecr.io/finance-agent-lg:latest

📦 Registering Hosted Agent in Foundry...
az cognitiveservices agent create \
  --name financial-advisor-lg-PT \
  --container-image acrworkshopxyz.azurecr.io/finance-agent-lg:latest \
  --capability-host-id <foundry-caphost-id>

✅ Agent registered!
   Status: Deploying
   
⏳ Monitoring deployment (this may take 3-5 minutes)...
   Status: Deploying... (0:30 elapsed)
   Status: Deploying... (1:00 elapsed)
   Status: Running ✅ (1:45 elapsed)

✅ Deployment complete!

🧪 Testing agent...
Invoking: What's the price of VALE3?
Response: The current price of VALE (VALE3) is R$ 65.80 BRL.

🎉 Agent is live and responding!
```

**Instructor Facilitation** (during 10-15 min wait):
- **Activity**: "Compare your LangGraph main.py with yesterday's MAF code. What's similar? Different?"
- **Discussion**: "If you have existing LangGraph agents, what would you need to change?"
- Take questions on LangGraph patterns

**Monitor Progress**:
- "Thumbs up when you see 'Status: Running'"
- "If deployment fails, paste last 20 lines of output in chat"

**Common Errors**:

| Error | Cause | Fix |
|-------|-------|-----|
| "caphost.json not found" | File not copied in Dockerfile | Add `COPY caphost.json .` |
| "Entry point 'main:app' not found" | Wrong variable name | Verify `app = workflow.compile()` exists |
| "Port 8088 already in use" | Conflicting container | Stop other agents or use different port (not recommended) |
| "Azure OpenAI endpoint error" | Missing env var | Verify `AZURE_OPENAI_ENDPOINT` in Foundry settings |

**Success Criteria**: ✅ 85%+ students have agent in Running status

---

### 12:45-13:05 | MAF vs LangGraph Comparison (20 min)

**Instructional Method**: Side-by-side code comparison

**Setup**: Split screen showing MAF (Module 2) and LangGraph (Module 3) code

#### Comparison 1: Tool Definition

**MAF**:
```python
from agent_framework import Agent, tool

class FinanceAgent(Agent):
    @tool()
    def get_stock_price(self, symbol: str) -> dict:
        """Fetch stock price."""
        return get_stock_price(symbol)
```

**LangGraph**:
```python
def get_stock_price(symbol: str) -> dict:
    """Fetch stock price."""
    # Implementation
    return {"symbol": symbol, "price": 175.50}

# Register in graph
workflow.add_node("tool_executor", tool_executor_node)
```

**Discussion**:
- **MAF**: Declarative with decorator
- **LangGraph**: Imperative with explicit node registration
- **Preference**: MAF for simplicity, LangGraph for control

---

#### Comparison 2: Orchestration

**MAF**:
```python
# Automatic ReAct loop
agent = Agent(
    name="finance",
    instructions="You are a financial advisor. Use tools.",
    tools=[get_stock_price, get_exchange_rate]
)
# MAF decides when to call tools
```

**LangGraph**:
```python
# Explicit graph with conditional edges
workflow.add_conditional_edges(
    "agent",
    should_continue,  # Your logic decides routing
    {"continue": "tool_executor", "end": END}
)
```

**Discussion**:
- **MAF**: Framework decides orchestration (opinionated)
- **LangGraph**: You control flow (flexible)
- **Use MAF when**: Standard ReAct pattern sufficient
- **Use LangGraph when**: Complex multi-step workflows, custom routing logic

---

#### Comparison 3: State Management

**MAF**:
```python
# State managed internally by MAF
# Access via agent context
context = self.get_context()
```

**LangGraph**:
```python
# Explicit state definition
class AgentState(TypedDict):
    messages: list
    next_action: str
    # Add any custom fields

# State passed through graph
def agent_node(state: AgentState) -> AgentState:
    # Modify state
    return updated_state
```

**Discussion**:
- **MAF**: Abstracted state (less control, simpler)
- **LangGraph**: Explicit state (full control, more code)
- **Preference**: Depends on complexity requirements

---

#### Comparison 4: Testing

**MAF**:
```python
# Test requires agent server
agent = FinanceAgent()
app = AgentFrameworkApp(agent)
# Test via HTTP or SDK
```

**LangGraph**:
```python
# Test graph directly (no server needed)
app = workflow.compile()
result = app.invoke({"messages": [...], "next_action": ""})
assert result["messages"][-1] == expected
```

**Discussion**:
- **LangGraph**: Easier unit testing (pure functions)
- **MAF**: Integration testing more straightforward

---

#### Comparison Matrix (show slide):

| Aspect | MAF | LangGraph |
|--------|-----|-----------|
| **Learning Curve** | Low | Medium |
| **Code Verbosity** | Low (decorators) | Medium (explicit graph) |
| **Orchestration Control** | Low (automatic ReAct) | High (custom routing) |
| **State Management** | Abstracted | Explicit TypedDict |
| **Multi-Agent** | Harder (nested agents) | Natural (graph composition) |
| **Testing** | HTTP-based | Direct invocation |
| **Adoption Effort** | Moderate (new framework) | Low (existing LangGraph works) |
| **Best For** | New projects, simple agents | Complex workflows, teams with LangGraph experience |

**Interactive (5 min)**:
- **Poll**: "Which framework do you prefer?" (MAF / LangGraph / Depends)
- "For those who said 'Depends'—what's your decision criteria?" (capture)

**Key Takeaway**:
> "Both are valid. MAF is Azure-native and simpler. LangGraph gives you control and works everywhere."
>
> "Pick MAF for greenfield projects with standard patterns. Pick LangGraph for complex orchestration or when you already have LangGraph experience."

---

### 13:05-13:15 | Deployment Planning Workshop (10 min)

**Instructional Method**: Decision framework exercise

**Activity**: LangGraph Deployment Assessment Checklist

**Provide worksheet** (students fill out):

```
My LangGraph Agent Deployment Assessment:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Where does your agent currently run?
   [ ] Cloud container service
   [ ] Serverless function
   [ ] Local/on-prem
   [ ] Other: _____________

2. What model provider do you use?
   [ ] OpenAI API (direct)
   [ ] Azure OpenAI (already on Azure!)
   [ ] Other LLM provider
   [ ] Other: _____________

3. How complex is your graph?
   [ ] Simple (1-3 nodes)
   [ ] Medium (4-10 nodes)
   [ ] Complex (10+ nodes, multiple subgraphs)

4. Do you use LangGraph's checkpointing?
   [ ] Yes (need to choose Azure storage backend)
   [ ] No (stateless agent)

5. Do you have platform-specific integrations?
   [ ] Cloud-specific services (proprietary databases, storage, etc.)
   [ ] Generic APIs (Stripe, Twilio, etc.)
   [ ] None

Deployment Effort Estimate:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Low Effort (1-2 days):
- Simple graph
- OpenAI model already
- No platform-specific services
- Stateless

Medium Effort (1-2 weeks):
- Medium complexity
- Model provider swap needed
- Some platform-specific services (need Azure equivalents)
- Checkpoint storage configuration

High Effort (1+ month):
- Complex multi-agent system
- Deep platform-specific integrations
- Custom checkpointing logic
- Production-critical workload
```

**Instructor leads discussion** (5 min):
- "Who's in Low Effort category?" (count)
- "Who's in High Effort?" (count)
- "For High Effort folks: What's the biggest consideration?"

**Provide Deployment Decision Tree** (handout):
```
Should I deploy my LangGraph agent on Azure Foundry?

Start: I have a LangGraph agent I want on Foundry
    ↓
Does my organization use M365/Azure?
    ├─ Yes → Strong strategic value → Assess deployment effort
    │   ├─ Low → Deploy now
    │   ├─ Medium → POC first, then deploy
    │   └─ High → Phased approach (run in parallel, validate, switch)
    └─ No → Evaluate if enterprise features justify the move
        └─ Consider: Teams delivery, Copilot integration, governance
```

**Wrap-Up**:
> "You can run agents on multiple platforms simultaneously. The goal is choosing the best fit for each use case."
>
> "Use this decision framework to plan your deployment strategy."

---

## 📋 Instructor Checklist

### Before Module 3:
- [ ] All students completed Module 2 (hosted MAF agent working)
- [ ] Slides loaded (comparison matrices, deployment decision tree)
- [ ] VS Code open with both `lesson-2` and `lesson-3` folders (side-by-side)
- [ ] Test LangGraph deployment (verify adapter works)
- [ ] Prepare deployment worksheet (print or digital)

### During Module 3:
- [ ] Confirm students understand MAF vs LangGraph differences
- [ ] Monitor LangGraph deployments (similar timeline to MAF)
- [ ] Capture deployment questions (for FAQ)
- [ ] Track which students have existing LangGraph agents (for follow-up)
- [ ] Validate comparison discussion is balanced (not biased toward one framework)

### After Module 3:
- [ ] Update `7-DELIVERY-LOG.md` with deployment-specific issues
- [ ] Share deployment worksheet results (anonymized aggregate)
- [ ] Collect feedback: Was comparison valuable?
- [ ] Verify all students ready for Module 4 (need working hosted agent)

---

## 🎓 Pedagogical Notes

### Learning Theory Applied:
- **Transfer Learning**: Leverage existing LangGraph knowledge
- **Comparative Analysis**: Side-by-side frameworks builds schema
- **Authentic Task**: Deploying on a new platform is real-world problem students face
- **Self-Assessment**: Deployment worksheet encourages reflection

### Adult Learning Principles:
- **Relevance**: Multi-platform deployment is a valuable professional skill
- **Autonomy**: Students assess their own deployment path
- **Problem-Centered**: Solve "how do I move to Azure?" question
- **Experience-Based**: Use students' existing LangGraph projects as examples

### Cognitive Load Management:
- **Intrinsic**: LangGraph familiar, reduces load
- **Extraneous**: Minimize new concepts (only adapter + endpoint changes)
- **Germane**: Focus on framework differences (transferable schema)

---

## 🔧 Troubleshooting Playbook

### Issue: "Entry point 'main:app' not found"
**Diagnosis**: Variable name mismatch in `caphost.json`  
**Fix**: Verify compiled graph variable name
```python
# In main.py, must have:
app = workflow.compile()  # Variable name must match caphost.json
```

### Issue: Graph Runs Locally But Not in Foundry
**Diagnosis**: Missing adapter or wrong port  
**Fix**: Verify Dockerfile CMD uses adapter
```dockerfile
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
```

### Issue: Azure OpenAI Authentication Fails
**Diagnosis**: Managed Identity not configured  
**Fix**: Verify MI has "Cognitive Services User" role
```powershell
az role assignment create \
  --role "Cognitive Services User" \
  --assignee <managed-identity> \
  --scope <foundry-resource-id>
```

### Issue: Checkpoints Not Persisting
**Diagnosis**: In-memory checkpointer used  
**Fix**: Implement persistent storage (Cosmos DB, Table Storage)
```python
from langgraph.checkpoint.azure import AzureTableCheckpointer

checkpointer = AzureTableCheckpointer(
    connection_string=os.getenv("AZURE_STORAGE_CONNECTION_STRING")
)
app = workflow.compile(checkpointer=checkpointer)
```

---

## 📊 Success Metrics

**Module Completion Indicators**:
- ✅ 85%+ students deploy LangGraph agent successfully
- ✅ 90%+ can articulate one difference between MAF and LangGraph
- ✅ 75%+ complete deployment assessment worksheet
- ✅ 100% understand when to choose each framework

**Learning Evidence**:
- ✅ Students can explain: adapter role in Foundry
- ✅ Students can compare: MAF decorators vs LangGraph nodes
- ✅ Students can assess: deployment effort for their agents

**Engagement Indicators**:
- ✅ 70%+ participate in framework preference poll
- ✅ 5+ questions on deployment strategy
- ✅ 60%+ complete deployment worksheet

---

## 🔄 Continuous Improvement Notes

**For Next Iteration**:
- If timing runs over → Reduce local testing demo
- If comparison underwhelming → Add more code examples
- If deployment planning workshop too fast → Extend with pair discussions
- If students prefer MAF overwhelmingly → Emphasize LangGraph benefits more

**Feedback Collection**:
- Poll: "Was side-by-side comparison helpful?"
- Track: How many plan to deploy LangGraph agents on Azure?
- Capture: What deployment concerns weren't addressed?

**Enhancement Ideas**:
- **Advanced**: Multi-agent LangGraph patterns
- **Case Study**: Real-world multi-platform deployment (anonymized)
- **Workshop**: Build same agent in both frameworks (compare dev time)

---

## 📚 Resources for Students

**Documentation Links**:
- 📘 LangGraph documentation
- 📘 Azure LangGraph adapter reference
- 📘 LangGraph checkpointing guide (Azure storage)
- 🎥 Video: "Deploying LangGraph on Azure Foundry" (12 min)
- 💻 Deployment guide: LangGraph on Azure Foundry

**Self-Paced Practice**:
- **Challenge 1**: Migrate your existing LangGraph agent
- **Challenge 2**: Implement persistent checkpointing
- **Challenge 3**: Build same agent in MAF and LangGraph (compare)

---

**Script Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Reviewed by**: (Pending)  
**Status**: Draft - Awaiting approval
