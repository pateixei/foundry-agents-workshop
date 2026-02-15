# Instructional Script: Module 2 - Hosted Agent with Microsoft Agent Framework

---

**Module**: 2 - Hosted Agent with MAF  
**Duration**: 180 minutes (Day 1 Hours 3-4: 03:30-05:30, Day 2 Hours 1-2: 09:00-11:00)  
**Instructor**: Technical SME + Facilitator  
**Location**: `instructor-guide/MODULE-2-HOSTED-MAF-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Learning Objectives

By the end of this module, students will be able to:
1. **Implement** custom Python tools using Microsoft Agent Framework decorators
2. **Build** and containerize a MAF agent application
3. **Deploy** containerized agent to Azure Container Registry (ACR)
4. **Register** agent as Hosted Agent in Foundry
5. **Debug** agents using container logs, telemetry, and tracing
6. **Compare** MAF architecture with LangGraph patterns
7. **Explain** when to use hosted vs declarative agents

---

## 📊 Module Overview (4 Hours Split Across 2 Days)

### Day 1 - Part 1 (2 hours: 03:30-05:30)
| Element | Duration | Method |
|---------|----------|--------|
| **MAF Conceptual Model** | 30 min | Presentation + comparison with LangGraph |
| **MAF Code Architecture** | 30 min | Live code walkthrough |
| **Custom Tools Deep Dive** | 30 min | Implementation patterns |
| **Initial Deployment Lab** | 30 min | Start container build |

### Day 2 - Part 2 (2 hours: 09:00-11:00)
| Element | Duration | Method |
|---------|----------|--------|
| **Deployment Completion** | 20 min | Monitor, troubleshoot, test |
| **Hosted Agent Registration** | 30 min | CLI commands + portal verification |
| **Testing & Debugging** | 40 min | Test agent, review logs, tracing |
| **Pattern Comparison** | 20 min | MAF vs Declarative decision matrix |
| **Q&A + Transition** | 10 min | Discussion |

---

## 🗣️ Day 1 - Part 1: Instructional Script

### 03:30-04:00 | MAF Conceptual Model (30 min)

**Instructional Method**: Presentation with framework comparison

**Opening (2 min)**:
> "Yesterday you deployed a declarative agent—serverless, no custom code. Today we break free from those limitations. You'll build **custom tools** in Python and run them in your own container."
>
> "This is Microsoft Agent Framework—MAF for short. Think of it as Microsoft's answer to LangGraph, built specifically for Foundry."

**Content Delivery (20 min)**:

**Slide 1: The Limitation We're Solving**

Show example:
```
Student Question: "Can my declarative agent query my company's SQL database?"
Answer: ❌ No - declarative agents can't execute custom Python code. You can connect to company's SQL Databases indirectly by using tools available in Foundry Portal (such as calling an API or using a connection to Microsoft Fabric)

Solution: ✅ Hosted Agent with MAF - run ANY Python code as tools.
```

**Say**:
> "Declarative is great for fast adoption. But sometimes your company needs custom logic: database queries, API calls, file processing, complex calculations. That's where hosted agents shine."

**Slide 2: Hosted Agent Architecture**

Display diagram:
```
┌─────────────────────────────────────┐
│ Your Code (Python + MAF)            │
│   ├─> Agent definition              │
│   └─> Custom tools (plain functions) │
└───────────┬─────────────────────────┘
            │ (containerized)
            ▼
┌─────────────────────────────────────┐
│ Docker Container in ACR             │
│   ├─> HTTP Server (port 8088)       │
│   └─> Runs with Managed Identity    │
└───────────┬─────────────────────────┘
            │ (registered in)
            ▼
┌─────────────────────────────────────┐
│ Foundry Capability Host             │
│   ├─> Routes requests to container  │
│   └─> Collects telemetry            │
└─────────────────────────────────────┘
```

**Narrate**:
> "Your agent runs in its own container within Foundry's infrastructure—called the **Capability Host**."
>
> "You write Python functions and register them as tools. We containerize everything, push to ACR, and Foundry runs it."
>
> "Requests flow through Foundry's routing layer to your container. Responses come back through the same path."

**Slide 3: MAF for LangGraph Developers**

Show comparison table:

| Concept | LangGraph | MAF |
|---------|-----------|-----|
| **Framework** | Graph-based orchestration | Function-based agent |
| **Agent Definition** | `StateGraph` + nodes | `AzureAIClient` + tool list |
| **Tools** | Functions in graph nodes | Plain Python functions passed as list |
| **State** | `TypedDict` state object | Agent context |
| **Orchestration** | Explicit edges/routing | Automatic tool calling |
| **Execution** | Graph traversal | ReAct loop (built-in) |
| **Best For** | Complex workflows, multiple agents | Single agent with multiple tools, Complex workflows, multiple agents |

**Say**:
> "LangGraph devs: you're not learning a totally new paradigm. MAF simplifies agent patterns you already know."
>
> "LangGraph gives you control over orchestration—you define the graph. MAF does orchestration automatically using ReAct pattern."
>
> "Both run in containers. Both support custom tools. Key difference: **MAF is integrated with Foundry out of the box**. It's also worth mentioning that MAF is platform-agnostic—you can host MAF-based agents anywhere (e.g., any container platform you prefer)"

**Interactive Activity (5 min)**:
- **Poll**: "Who's built agents with LangGraph before?" (count responses)
- **Ask those who raised hands**: "What's the hardest part of LangGraph?" 
- Common answers: State management, edge routing complexity
- **Response**: "MAF abstracts those complexities. You'll see in code."

**Slide 4: When to Use MAF vs Declarative**

Decision tree:

```
Need custom Python tools?
    ├─ Yes → MAF (this module)
    └─ No → Declarative (Module 1)

Need multi-agent orchestration?
    ├─ Yes → Consider LangGraph (Module 3) or multi-MAF
    └─ No → MAF

Need existing LangGraph code?
    ├─ Yes → LangGraph (Module 3 - leverage existing skills)
    └─ No → MAF (simpler patterns)
```

**Transition (3 min)**:
> "Enough theory. Let's see actual MAF code. You'll notice how elegant it is."

---

### 04:00-04:30 | MAF Code Architecture (30 min)

**Instructional Method**: Live code walkthrough

**Setup**:
- Share screen with VS Code
- Open `lesson-2-hosted-maf/solution/`
- Split view: File tree (left) + code editor (right)

#### Section 1: File Structure Overview (5 min)

**Show directory tree**:
```
solution/
├── src/
│   ├── agent/
│   │   └── finance_agent.py    # ⭐ MAF agent definition
│   └── main.py                 # Entry point
├── tools/
│   └── finance_tools.py        # Tool implementations
├── app.py                      # HTTP server wrapper
├── Dockerfile                  # Container definition
├── deploy.ps1                  # Automation script
├── requirements.txt            # Dependencies
└── agent.yaml                  # Agent manifest
```

**Say**:
> "Clean separation of concerns:"
> - `finance_agent.py` - Agent logic with MAF decorators
> - `finance_tools.py` - Business logic (stock API, calculations)
> - `app.py` - HTTP server (provided by MAF SDK)
> - `Dockerfile` - Containerization
> - `deploy.ps1` - One-click deployment

#### Section 2: Tool Implementation (10 min)

**Open**: `tools/finance_tools.py`

**Show function**:
```python
def get_stock_price(symbol: str) -> dict:
    """
    Fetch current stock price for given symbol.
    
    Args:
        symbol: Stock ticker (e.g., "AAPL", "PETR4")
    
    Returns:
        dict with keys: symbol, price, currency, timestamp
    """
    # Simulate API call (in production: call real API)
    prices = {
        "AAPL": 175.50,
        "PETR4": 38.20,
        "VALE3": 65.80
    }
    
    return {
        "symbol": symbol.upper(),
        "price": prices.get(symbol.upper(), 0.0),
        "currency": "USD" if not symbol.endswith("3") else "BRL",
        "timestamp": datetime.now().isoformat()
    }
```

**Narrate**:
> "This is a pure Python function. Nothing agent-specific yet."
>
> "Good practice: separate business logic from agent framework. Makes testing easier."
>
> "Docstring is critical—MAF uses it to generate tool descriptions for the LLM."

#### Section 3: MAF Agent with Tool Registration (10 min)

**Open**: `src/agent/finance_agent.py`

**Show imports**:
```python
from agent_framework import Agent, tool
from ...tools.finance_tools import get_stock_price, get_exchange_rate
```

**Show agent definition**:
```python
class FinanceAgent(Agent):
    """Financial market assistant specializing in stock analysis."""
    
    def __init__(self):
        super().__init__(
            name="financial-advisor-maf",
            instructions="""
                You are a financial market advisor.
                Help users analyze stocks and make informed decisions.
                Always cite data sources and include risk disclaimers.
            """,
            model="gpt-4"
        )
```

**Say**:
> "Inherit from `Agent` base class. Define name, instructions (system prompt), model."
>
> "Notice: same concepts as declarative agent, but in Python code instead of SDK call."

**Show tool registration** (most important):
```python
# tools/finance_tools.py — plain Python functions (no decorator needed)
def get_stock_quote(ticker: Annotated[str, "Codigo da acao"]) -> str:
    """Retorna a cotacao atual de uma acao."""
    # ... implementation ...

def get_exchange_rate(pair: Annotated[str, "Par de moedas"]) -> str:
    """Retorna a taxa de cambio atual."""
    # ... implementation ...

def get_market_summary() -> str:
    """Retorna um resumo dos principais indices."""
    # ... implementation ...
```

```python
# finance_agent.py — register tools as a simple list
from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary

TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]

async def create_finance_agent():
    client = AzureAIClient.from_async_credential(credential, project_endpoint)
    agent = await client.agents.create_agent(
        model=model_deployment, instructions=SYSTEM_PROMPT, tools=TOOLS
    )
    return agent
```

**Narrate key points**:
- **Plain functions as tools**: "In MAF, tools are plain Python functions passed as a list to `create_agent()`. No decorators needed. The `@tool` decorator is a LangChain/LangGraph pattern we'll cover in Module 3."
- **Docstrings**: "LLM sees this description when deciding which tool to call."
- **Type hints with `Annotated`**: "Critical for tool schemas. MAF auto-generates JSON schema from these."
- **Separation of concerns**: "`tools/finance_tools.py` contains the logic; `finance_agent.py` registers them."

**Interactive Check (2 min)**:
- **Ask**: "What happens if a function has no docstring?" (answer: LLM won't know what the tool does)
- **Ask**: "Why separate `finance_tools.py` from `finance_agent.py`?" (answer: testability, separation of concerns)

#### Section 4: HTTP Server & Entry Point (5 min)

**Open**: `app.py`

**Show code**:
```python
from azure.ai.agentserver.agentframework import AgentFrameworkApp
from src.agent.finance_agent import FinanceAgent

# Create agent instance
agent = FinanceAgent()

# Wrap in HTTP server
app = AgentFrameworkApp(agent)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8088)
```

**Say**:
> "MAF provides `AgentFrameworkApp`—wraps your agent in an HTTP server."
>
> "Port 8088 is Foundry's standard for hosted agents. Don't change it."
>
> "This server implements Foundry's **Responses API** automatically. You don't write HTTP handlers—MAF does it."

**Show**: `src/main.py`

```python
def run():
    """Entry point for container."""
    from .agent.finance_agent import FinanceAgent
    from azure.ai.agentserver.agentframework import AgentFrameworkApp
    import uvicorn
    
    agent = FinanceAgent()
    app = AgentFrameworkApp(agent)
    uvicorn.run(app, host="0.0.0.0", port=8088)
```

**Say**:
> "This is what Dockerfile calls. Simple: instantiate agent, wrap in app, run server."

**Transition**:
> "That's the code architecture. Clean, testable, extensible. Now let's build custom tools hands-on."

---

### 04:30-05:00 | Custom Tools Deep Dive (30 min)

**Instructional Method**: Guided code modification

**Objective**: Students add a NEW custom tool to the agent

#### Activity Setup (5 min)

**Instructor Action**: Display challenge

**Challenge**:
> "Add a new tool: `get_market_sentiment(symbol: str) -> dict`
>
> This tool should return sentiment analysis of recent news for a stock.
> - Input: Stock symbol (e.g., "AAPL")
> - Output: dict with keys: `symbol`, `sentiment` (positive/negative/neutral), `confidence` (0-1), `summary`

**Expected Implementation** (show on screen):
```python
# In tools/finance_tools.py

def get_market_sentiment(symbol: str) -> dict:
    """Analyze market sentiment for a stock based on recent news."""
    # Simulated sentiment (in production: call news API + sentiment model)
    sentiments = {
        "AAPL": {"sentiment": "positive", "confidence": 0.85, "summary": "Strong earnings report"},
        "PETR4": {"sentiment": "neutral", "confidence": 0.60, "summary": "Mixed oil price signals"},
        "VALE3": {"sentiment": "negative", "confidence": 0.75, "summary": "Commodity price decline"}
    }
    
    default = {"sentiment": "neutral", "confidence": 0.5, "summary": "No recent news"}
    result = sentiments.get(symbol.upper(), default)
    result["symbol"] = symbol.upper()
    
    return result
```

**Student Task** (20 min):

1. **Add function to `tools/finance_tools.py`** (5 min)
2. **Register tool in `src/agent/finance_agent.py`** (5 min):
   ```python
   # Add import
   from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary, get_market_sentiment

   # Add to tools list
   TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary, get_market_sentiment]
   ```
3. **Test locally** (10 min):
   ```powershell
   # Install dependencies
   pip install -r requirements.txt
   
   # Run local test
   python -c "
   from src.agent.finance_agent import FinanceAgent
   agent = FinanceAgent()
   result = agent.get_market_sentiment('AAPL')
   print(result)
   "
   ```

**Instructor Facilitation**:
- Walk through each step on screen first
- Share code snippets in chat
- Monitor progress: "Thumbs up when your tool runs locally"
- Troubleshoot common errors:
  - Import errors → verify file structure
  - Type hint issues → show correct syntax
  - Decorator forgotten → agent doesn't see tool

**Success Criteria**: ✅ Students' new tool returns sentiment data locally

#### Discussion: Tool Design Patterns (5 min)

**Interactive**:
- **Ask**: "What makes a good agent tool?"

**Capture answers, then provide principles**:
1. **Single Responsibility**: One tool = one clear purpose
2. **Type Safety**: Always use type hints (enables schema generation)
3. **Descriptive Docstrings**: LLM reads these—be specific
4. **Error Handling**: Return useful errors, don't crash
5. **Idempotency**: Same input → same output (when possible)
6. **Fast Execution**: Tools should run in <5 seconds

**Say**:
> "Your tools become the agent's 'senses and actions'. Design them as carefully as you'd design an API."

---

### 05:00-05:30 | Initial Deployment Lab (30 min)

**Instructional Method**: Automated deployment (script-driven)

**Objective**: Start container build process (completes Day 2)

#### Checkpoint 1: Dockerfile Review (5 min)

**Open**: `Dockerfile`

**Show key lines**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ src/
COPY tools/ tools/
COPY app.py .

# Expose port
EXPOSE 8088

# Entry point
CMD ["python", "-m", "src.main"]
```

**Narrate**:
> "Standard Python Dockerfile. Base image: Python 3.11."
>
> "Port 8088 is Foundry's protocol. Must match your server config."
>
> "Entrypoint: runs `src.main.run()` which starts uvicorn server."

**Interactive (2 min)**:
- **Ask**: "Who's written Dockerfiles before?" (gauge experience)
- "This is production-ready. No changes needed for workshop."

#### Checkpoint 2: Deploy Script Walkthrough (5 min)

**Open**: `deploy.ps1`

**Show steps** (annotate on screen):
```powershell
# 1. Load environment variables
$env:ACR_NAME = (Get-Content ..\..\prereq\setup-output.txt | Where-Object {$_ -match "AZURE_CONTAINER_REGISTRY"}).Split("=")[1]

# 2. Build image in ACR (cloud build - no local Docker needed!)
az acr build `
  --registry $env:ACR_NAME `
  --image finance-agent-maf:latest `
  --file Dockerfile `
  .

# 3. Create/update hosted agent
az cognitiveservices agent create `
  --name financial-advisor-maf `
  --container-image "$env:ACR_NAME.azurecr.io/finance-agent-maf:latest" `
  --resource-group $env:AZURE_RESOURCE_GROUP `
  --kind HostedAgent

# 4. Monitor deployment status
az cognitiveservices agent status --name financial-advisor-maf

# 5. Test agent
python test_agent.py
```

**Say**:
> "This script automates 5 steps:"
> 1. "Loads your infrastructure config from Module 0"
> 2. "Builds container **in Azure** (no local Docker build!)"
> 3. "Registers container as hosted agent in Foundry"
> 4. "Monitors until agent is running"
> 5. "Tests agent with sample query"
>
> "Build takes 8-12 minutes. We'll start it now, complete tomorrow."

#### Checkpoint 3: Execute Deployment (20 min)

**Student Task**:
```powershell
cd lesson-2-hosted-maf/foundry-agent

# Execute deployment
.\deploy.ps1
```

**Expected Output** (show on screen):
```
🔨 Building container image in ACR...
⏳ This may take 8-12 minutes...

Step 1/8 : FROM python:3.11-slim
Step 2/8 : WORKDIR /app
Step 3/8 : COPY requirements.txt .
Step 4/8 : RUN pip install --no-cache-dir -r requirements.txt
...
Step 8/8 : CMD ["python", "-m", "src.main"]
✅ Successfully tagged finance-agent-maf:latest

📦 Registering hosted agent in Foundry...
✅ Agent registered: financial-advisor-maf
   Status: Deploying
   Container: acrworkshopxyz.azurecr.io/finance-agent-maf:latest
   
⏳ Monitoring deployment status...
```

**Instructor Facilitation** (during 10-15 min build):
- "While building, let's discuss hosted vs declarative trade-offs"
- Show slide: Cost comparison (containers always-on vs serverless)
- **Activity**: "Sketch your production agent architecture—what tools would you need?"
- Take questions on deployment process

**Monitor Progress**:
- "If build fails immediately, paste error in chat"
- Common issues: ACR authentication, network timeout
- "Most will still be building when class ends—that's expected"

**Wrap for Day 1** (last 5 min):
**Say**:
> "We've started deployments. They'll complete overnight."
>
> "Tomorrow morning (Day 2), we'll:"
> - Verify deployments succeeded
> - Test agents in Foundry portal
> - Debug using container logs
> - Compare patterns (MAF vs declarative)
>
> "Homework: Review MAF documentation (optional links in chat)."
>
> "See you tomorrow! Day 1 complete—great work."

---

## 🗣️ Day 2 - Part 2: Instructional Script

### 09:00-09:20 | Deployment Completion (20 min)

**Instructional Method**: Verification + troubleshooting

**Opening (2 min)**:
> "Good morning! Yesterday we started container builds. Let's verify they completed successfully."

#### Check Deployment Status (10 min)

**Instructor demonstrates**:
```powershell
cd lesson-2-hosted-maf/foundry-agent

# Check agent status
az cognitiveservices agent status `
  --name financial-advisor-maf `
  --resource-group $env:AZURE_RESOURCE_GROUP
```

**Expected Output**:
```json
{
  "name": "financial-advisor-maf",
  "status": "Running",
  "containerImage": "acrworkshopxyz.azurecr.io/finance-agent-maf:latest",
  "endpoint": "https://foundry-xyz.cognitiveservices.azure.com/agents/financial-advisor-maf",
  "lastUpdated": "2026-02-14T08:45:00Z"
}
```

**Say**:
> "Status: **Running** means success. Foundry is routing requests to your container."

**Student Task**:
- Everyone runs status check
- "Thumbs up in chat if status = Running"

**Troubleshooting** (if some show "Failed" or "Deploying"):

| Status | Meaning | Action |
|--------|---------|--------|
| **Deploying** | Still starting | Wait 2 more minutes, check again |
| **Running** | ✅ Success | Proceed to testing |
| **Failed** | ❌ Error | Check logs: `az cognitiveservices agent logs` |
| **Not Found** | Not registered | Re-run `.\deploy.ps1` |

**For Failed deployments**:
```powershell
# View error logs
az cognitiveservices agent logs --name financial-advisor-maf | Select -Last 50

# Common errors:
# - "Port 8088 not responding" → Check Dockerfile EXPOSE
# - "Import error" → Missing dependency in requirements.txt
# - "Authentication failed" → Managed Identity issue
```

**Instructor Support**:
- Help individuals in breakout rooms if needed
- "If still broken after 5 min, use instructor backup agent"

**Success Criteria**: ✅ 85%+ students have Running status

---

### 09:20-09:50 | Hosted Agent Registration & Testing (30 min)

**Instructional Method**: Hands-on testing with validation

#### Portal Verification (10 min)

**Instructor demonstrates**:
1. Open Foundry portal (portal.azure.com → AI Foundry)
2. Navigate to Agents section
3. Find "financial-advisor-maf"
4. Click to see details
5. Show: Container image, status, endpoint, tools list

**Say**:
> "Unlike declarative agents, you CAN'T edit instructions in portal—they're baked in the container."
>
> "To change behavior: update code, rebuild container, redeploy."

**Interactive**:
- Have students navigate to their agent in portal
- "Screenshot your agent's Tools section—shows your 3 custom tools"
- Share screenshots in chat

#### Test Agent via SDK (15 min)

**Instructor demonstrates**:
```powershell
# Run test client
python test_agent.py
```

**Expected Interaction**:
```
🤖 Financial Advisor MAF Agent

You: What's the current price of AAPL?

Agent: Let me fetch that for you.
[Calling tool: get_stock_price(symbol="AAPL")]
[Tool result: {"symbol": "AAPL", "price": 175.50, "currency": "USD"}]

The current price of Apple (AAPL) is $175.50 USD.

You: What's the market sentiment?

Agent: I'll check the sentiment analysis.
[Calling tool: get_market_sentiment(symbol="AAPL")]
[Tool result: {"symbol": "AAPL", "sentiment": "positive", "confidence": 0.85, "summary": "Strong earnings report"}]

Apple (AAPL) has **positive** market sentiment (85% confidence) based on a strong earnings report.
```

**Narrate**:
> "Notice: You see tool calls inline. This is MAF's transparency—helps debugging."
>
> "Agent decided which tools to call. You didn't specify—ReAct pattern in action."

**Student Task**:
- Run `python test_agent.py`
- Test these queries:
  1. "Compare AAPL and PETR4 prices"
  2. "What's the sentiment for VALE3?"
  3. "Calculate portfolio value: 10 AAPL, 50 PETR4"
- Document which tools were called for each query

**Engagement**:
- "Who got different results than expected?" (discuss why)
- "Did anyone's agent NOT call tools?" (troubleshoot reasoning)

#### Container Logs Review (5 min)

**Instructor demonstrates**:
```powershell
# View real-time logs
az cognitiveservices agent logs --name financial-advisor-maf --follow
```

**Show log output**:
```
2026-02-14 09:25:10 INFO     Starting agent server on port 8088
2026-02-14 09:25:15 INFO     Agent initialized: financial-advisor-maf
2026-02-14 09:26:30 INFO     Request received: /v1/chat/completions
2026-02-14 09:26:31 DEBUG    Tool call: get_stock_price(symbol="AAPL")
2026-02-14 09:26:31 DEBUG    Tool result: {"symbol": "AAPL", "price": 175.50}
2026-02-14 09:26:32 INFO     Response sent: 200 OK
```

**Say**:
> "Logs are your best debugging tool. See requests, tool calls, errors."
>
> "Use `--follow` for real-time tailing. Use filters for errors: `| Select-String 'ERROR'`"

**Success Criteria**: ✅ All students successfully tested agent with 3 queries

---

### 09:50-10:30 | Testing & Debugging Deep Dive (40 min)

**Instructional Method**: Interactive debugging scenarios

#### Scenario 1: Agent Doesn't Call Tool (15 min)

**Setup**: Instructor demonstrates common issue

**Problem**:
> "Agent responds with: 'I don't have access to real-time stock data' instead of calling `get_stock_price` tool."

**Debugging Process** (show step-by-step):

1. **Check tool registration**:
   ```python
   # In finance_agent.py - verify decorator is present
   # Verify function is in the TOOLS list
   TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]
   # ← Is your new tool included here?
   ```

2. **Check tool schema**:
   ```powershell
   # List available tools via API
   curl https://foundry-xyz.../agents/financial-advisor-maf/tools
   ```
   
   **Expected**: JSON list with `get_stock_price` definition

3. **Check instructions**:
   ```python
   # Agent instructions should mention using tools
   instructions="""
   You are a financial advisor.
   Use available tools to fetch real-time data.  # ← Important!
   Always call tools instead of making up data.
   """
   ```

4. **Check LLM reasoning** (logs):
   - Look for: "Tool call: get_stock_price" in logs
   - If absent: LLM didn't decide to use tool
   - Fix: Improve instruction prompts

**Interactive Activity**:
- **Give students broken agent code** (missing function from TOOLS list or missing docstring)
- "Fix it and redeploy"
- Time: 10 minutes

#### Scenario 2: Tool Returns Error (10 min)

**Setup**: Introduce intentional error in tool

**Modify** `tools/finance_tools.py`:
```python
def get_stock_price(symbol: str) -> dict:
    # Simulate API failure
    raise ValueError(f"API error: Invalid symbol {symbol}")
```

**Redeploy** (quick cycle):
```powershell
az acr build --registry ... --image finance-agent-maf:error-test
```

**Test**: Agent should handle error gracefully

**Expected Agent Behavior**:
```
Agent: I encountered an error fetching the stock price: "API error: Invalid symbol XYZ". 
Please verify the ticker symbol is correct.
```

**Debugging Tips**:
- Logs show full stack trace
- MAF wraps tool exceptions, returns error to LLM
- LLM sees error message, can retry or inform user

**Best Practice**: Return user-friendly errors from tools
```python
try:
    price = api.get_price(symbol)
    return {"symbol": symbol, "price": price}
except APIException as e:
    return {"error": f"Could not fetch price: {str(e)}"}
```

#### Scenario 3: Performance Optimization (10 min)

**Question for class**:
> "Your agent takes 30 seconds to respond. How do you debug?"

**Instructor-led analysis**:

1. **Check logs for timing**:
   ```
   2026-02-14 10:05:00 INFO     Request received
   2026-02-14 10:05:28 INFO     Tool call: calculate_portfolio_value
   2026-02-14 10:05:30 INFO     Response sent
   ```
   → Tool took 28 seconds!

2. **Profile tool execution**:
   ```python
   import time
   
   def calculate_portfolio_value(holdings: list[dict]) -> float:
       """Calculate total portfolio value."""
       start = time.time()
       # ... logic ...
       duration = time.time() - start
       print(f"Tool execution: {duration:.2f}s")
       return result
   ```

3. **Optimize**:
   - Parallelize API calls (use `asyncio.gather`)
   - Cache results (e.g., stock prices valid for 1 minute)
   - Reduce LLM round-trips (return more data per tool call)

**Show optimized code**:
```python
import asyncio

async def calculate_portfolio_value(holdings: list[dict]) -> float:
    """Async version with parallel tool calls."""
    tasks = [get_stock_price(h["symbol"]) for h in holdings]
    prices = await asyncio.gather(*tasks)  # Parallel execution
    
    total = sum(p["price"] * h["quantity"] for p, h in zip(prices, holdings))
    return total
```

**Key Takeaway**:
> "Async tools can dramatically improve performance. MAF supports both sync and async."

#### Discussion: Debugging Strategies (5 min)

**Instructor leads brainstorm**:
- What debugging tools exist?
  - Container logs (`az ... logs`)
  - Application Insights (telemetry)
  - Local testing (run agent outside container)
  - Unit tests for tools (test functions directly)

**Best Practices**:
1. **Test tools independently** before deploying agent
2. **Use structured logging** (JSON logs easier to parse)
3. **Set up alerts** (Application Insights for errors)
4. **Version your containers** (tag images for rollback)

---

### 10:30-10:50 | Pattern Comparison (20 min)

**Instructional Method**: Decision framework workshop

**Slide: Declarative vs Hosted Comparison Matrix**

| Aspect | Declarative (Module 1) | Hosted MAF (Module 2) |
|--------|------------------------|-----------------------|
| **Complexity** | Low | Medium |
| **Deploy Time** | <10 seconds | 10-15 minutes |
| **Custom Tools** | ❌ No | ✅ Yes (Python code) |
| **Portal Editable** | ✅ Yes | ❌ No (rebuild required) |
| **Cost** | $0.10/1K tokens | $0.10/1K tokens + $20-40/mo container |
| **Scaling** | Serverless (auto) | Auto-scaled containers |
| **Control** | Low | High |
| **Debugging** | Portal + API logs | Container logs + telemetry |
| **Use Cases** | Prototypes, simple Q&A | Production, custom integrations |

**Interactive Activity** (10 min):

**Present 5 scenarios, class votes: Declarative or Hosted?**

1. **HR Policy Chatbot**
   - Answers FAQs from internal docs
   - Uses Azure AI Search (Foundry catalog tool)
   - **Vote**: Declarative ✅ (no custom logic needed)

2. **Sales CRM Agent**
   - Queries Salesforce API
   - Creates opportunities
   - Updates contact records
   - **Vote**: Hosted ✅ (custom Salesforce tools)

3. **Financial Report Generator**
   - Connects to SQL database
   - Runs complex queries
   - Generates Excel reports
   - **Vote**: Hosted ✅ (DB access + file generation)

4. **Document Summarizer**
   - Summarizes uploaded PDFs
   - Uses Code Interpreter (Foundry tool)
   - **Vote**: Declarative ✅ (IF using Foundry tools)

5. **Multi-Step Approval Workflow**
   - Checks inventory system
   - Sends Slack notifications
   - Updates Jira tickets
   - **Vote**: Hosted ✅ (multiple custom integrations)

**Discuss Results**:
- "Pattern: If you need 2+ external APIs → probably Hosted"
- "Pattern: If Foundry catalog has the tools → Declarative is faster"

**Decision Tree** (provide as handout):
```
Start: I need an agent
    ↓
Is data in Azure (AI Search, Cosmos, Blob)?
    ├─ Yes → Can use Foundry tools?
    │   ├─ Yes → Declarative ✅
    │   └─ No → Hosted
    └─ No → External API/database?
        └─ Yes → Hosted ✅
```

---

### 10:50-11:00 | Q&A + Transition (10 min)

**Format**: Open discussion

**Key Questions to Address**:

1. **Q**: "Can I mix declarative and hosted agents in one project?"
   - **A**: Yes! Use declarative for simple tasks, hosted for complex ones.

2. **Q**: "How do I version my hosted agents?"
   - **A**: Tag container images (`finance-agent-maf:v1.2.0`). Register specific tags in Foundry.

3. **Q**: "What's the container cost?"
   - **A**: ~$20-40/month for always-on container (Basic tier). Scales with replicas.

4. **Q**: "Can hosted agents call other agents?"
   - **A**: Yes via SDK. Create orchestration patterns (tomorrow's advanced topic).

**Preview Module 3**:
**Say**:
> "Next: **Hosted Agent with LangGraph**. You'll:"
> - Migrate existing LangGraph agents to Foundry
> - Compare MAF vs LangGraph architecture
> - Decide which framework fits your use case
> - See how different agent hosting patterns compare
>
> "Many of you have LangGraph experience. Module 3 shows you how to bring that expertise to Foundry."

**Transition**:
> "Break for 15 minutes. Then we tackle LangGraph on Foundry."

---

## 📋 Instructor Checklist

### Before Module 2 (Day 1):
- [ ] All students completed Module 1 (declarative agent working)
- [ ] Docker Desktop running on all machines (verify in Module 0)
- [ ] VS Code open with `lesson-2-hosted-maf/solution/`
- [ ] Slides loaded (MAF concepts, comparison matrix, decision tree)
- [ ] ACR accessible (test with `az acr login`)
- [ ] Backup hosted agent deployed (for students with build failures)

### During Module 2 (Day 1):
- [ ] Confirm students understand MAF vs declarative differences
- [ ] Monitor container builds (expect 10-15 min each)
- [ ] Capture build errors (for troubleshooting guide updates)
- [ ] Track which students' builds complete before Day 1 ends
- [ ] Post async support info (for overnight build monitoring)

### Before Module 2 (Day 2):
- [ ] Check overnight build statuses (identify failures)
- [ ] Prepare troubleshooting scenarios (have broken code ready)
- [ ] Load container logs in portal (for demonstration)
- [ ] Test instructor backup agent (for failed deployments)

### During Module 2 (Day 2):
- [ ] Verify 85%+ students have Running agents
- [ ] Confirm all tested agents with 3+ queries
- [ ] Collect feedback on debugging difficulty
- [ ] Note timing: Was 40 min debugging enough?
- [ ] Identify students needing LangGraph vs MAF guidance

### After Module 2:
- [ ] Update `7-DELIVERY-LOG.md` with issues encountered
- [ ] Document common errors (build failures, tool registration issues)
- [ ] Capture student questions (FAQ)
- [ ] Verify all students ready for Module 3 (need working hosted agent)
- [ ] Share comparison matrix and decision tree as handout

---

## 🎓 Pedagogical Notes

### Learning Theory Applied:
- **Constructivism**: Build custom tools from scratch (not just consume)
- **Experiential Learning**: Deploy real containers, debug real errors
- **Comparative Learning**: Constant reference to LangGraph (leverage prior knowledge)
- **Problem-Based Learning**: Debugging scenarios simulate production issues

### Adult Learning Principles:
- **Autonomy**: Choose which tools to implement (customization)
- **Relevance**: Financial domain relatable; patterns transferable
- **Problem-Solving**: Real debugging, not perfect demos
- **Immediate Application**: Tools usable in production

### Cognitive Load Management:
- **Day 1**: Conceptual understanding + start async task (low load)
- **Day 2**: Hands-on debugging + optimization (higher load, but rested)
- **Chunking**: One concept per 30-min block
- **Scaffolding**: Start with instructor code, then modify incrementally

### Bloom's Taxonomy Progression:
- **Understand**: Explain MAF architecture (Day 1)
- **Apply**: Implement custom tool (Day 1)
- **Analyze**: Debug agent failures (Day 2)
- **Evaluate**: Choose pattern for scenarios (Day 2)
- **Create**: Design production agent (Day 2 discussion)

---

## 🔧 Troubleshooting Playbook

### Issue: Container Build Fails with "requirements.txt not found"
**Diagnosis**: Dockerfile COPY path incorrect  
**Fix**: Verify file structure matches Dockerfile expectations
```dockerfile
COPY requirements.txt .  # Must exist at repo root
```

### Issue: Agent Status Stuck on "Deploying" for >20 Minutes
**Diagnosis**: Container not responding on port 8088  
**Fix**: Check logs for server startup errors
```powershell
az cognitiveservices agent logs --name financial-advisor-maf | Select-String "error"
```
Common causes: wrong port, missing dependency, syntax error in code

### Issue: Tool Not Appearing in Agent
**Diagnosis**: Function missing from TOOLS list, or missing docstring  
**Fix**: Verify function is in TOOLS list and has proper docstring + type hints
```python
# ✅ Correct — function in TOOLS list with docstring
def my_tool(param: str) -> dict:
    """Description of what this tool does."""
    return {}

TOOLS = [my_tool]  # ← registered here

# ❌ Wrong (not in TOOLS list, or missing docstring)
def my_tool(param: str) -> dict:
    return {}
```

### Issue: Import Error in Container
**Diagnosis**: Module structure mismatch  
**Fix**: Ensure Python package structure correct
```
src/
├── __init__.py        # Required!
├── agent/
│   ├── __init__.py    # Required!
│   └── finance_agent.py
```

### Issue: "Unauthorized" When Calling Foundry
**Diagnosis**: Managed Identity not granted RBAC role  
**Fix**: Assign "Cognitive Services User" role
```powershell
az role assignment create `
  --role "Cognitive Services User" `
  --assignee <managed-identity-id> `
  --scope <foundry-resource-id>
```

---

## 📊 Success Metrics

**Module Completion Indicators**:
- ✅ 85%+ students have hosted agent in Running status
- ✅ 90%+ successfully tested agent with 3+ queries
- ✅ 75%+ completed custom tool implementation
- ✅ 100% can explain one difference between MAF and declarative
- ✅ <10 unique error types encountered (indicates good design)

**Learning Evidence**:
- ✅ Students can implement: New tool function registered in TOOLS list
- ✅ Students can debug: Use logs to identify tool call failures
- ✅ Students can decide: Choose pattern for given scenario

**Engagement Indicators**:
- ✅ 70%+ share custom tool screenshots
- ✅ 5+ substantive questions in Q&A
- ✅ 80%+ complete debugging activity successfully

---

## 🔄 Continuous Improvement Notes

**For Next Iteration**:
- If >20% build failures → Pre-build images, students just deploy
- If timing runs over → Reduce tool implementation to demo only
- If debugging too fast → Add more complex scenarios
- If pattern comparison underwhelming → Use real production case studies

**Feedback Collection**:
- Post-Day 1 poll: "Was split across 2 days effective?"
- Post-Day 2 poll: "Was debugging section valuable?"
- Track: Did students prefer MAF or declarative? Why?

**Enhancement Ideas**:
- **Advanced**: Multi-agent orchestration (MAF calling MAF)
- **Challenge**: Implement async tools with caching
- **Case Study**: Real production agent architecture review

---

## 📚 Resources for Students

**Documentation Links**:
- 📘 Microsoft Agent Framework documentation
- 📘 Tool decorator API reference
- 📘 Foundry Hosted Agents guide
- 🎥 Video: "Building Production Agents with MAF" (15 min)
- 💻 Sample code: MAF patterns repository

**Self-Paced Practice**:
- **Challenge 1**: Add error handling to all tools
- **Challenge 2**: Implement async tool with API call
- **Challenge 3**: Create agent that calls external database

---

**Script Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Reviewed by**: (Pending)  
**Status**: Draft - Awaiting approval
