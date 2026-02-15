# Instructional Script: Module 1 - Declarative Agent Pattern


---

**Module**: 1 - Declarative Agent Pattern  
**Duration**: 120 minutes (Day 1, Hours 2-3: 01:15-03:15)  
**Instructor**: Technical SME + Facilitator  
**Location**: `instructional-scripts/MODULE-1-DECLARATIVE-AGENT-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Learning Objectives

By the end of this module, students will be able to:
1. **Create** a declarative agent using `PromptAgentDefinition` SDK
2. **Configure** agent instructions, tools, and model selection
3. **Test** the agent in Foundry portal playground  
4. **Modify** agent configuration in portal without redeployment
5. **Explain** when to use declarative vs hosted patterns
6. **Compare** declarative agents to AWS Lambda functions (architectural shift)

---

## 📊 Module Overview

| Element | Duration | Method |
|---------|----------|--------|
| **Agent Patterns Overview** | 15 min | Presentation + comparison matrix |
| **Declarative Pattern Deep Dive** | 20 min | Architecture + SDK walkthrough |
| **Hands-On Lab: Create Agent** | 45 min | Guided practice with checkpoints |
| **Portal Modification Lab** | 20 min | Interactive experiment |
| **Pattern Decision Framework** | 10 min | Decision tree activity |
| **Q&A + Transition** | 10 min | Discussion |

---

## 🗣️ Instructional Script (Minute-by-Minute)

### 01:15-01:30 | Agent Patterns Overview (15 min)

**Instructional Method**: Presentation with AWS comparison

**Opening (2 min)**:
> "You've got infrastructure running. Now let's deploy actual AI agents. Microsoft supports three patterns, and choosing the right one is critical for your architecture."

**Content Delivery (10 min)**:

**Slide 1: Three Agent Patterns**

Display table:

| Pattern | Where It Runs | When to Use | AWS Analogy |
|---------|---------------|-------------|-------------|
| **Declarative** | Foundry backend | Quick prototypes, no custom code | Lambda with SDK only |
| **Hosted (MAF)** | Your container | Custom tools, complex logic | Lambda with layers |
| **Hosted (LangGraph)** | Your container | Migration from LangChain | ECS container task |

**Say**:
> "Today we focus on **declarative agents**—the simplest pattern. Think of this as a 'serverless agent' where Foundry manages execution."
>
> "You define instructions and tools via SDK or portal. Foundry handles model calls, function execution, and scaling."

**Slide 2: Declarative Agent Architecture Diagram**

Show diagram:
```
┌─────────────────────────────────────────────┐
│ Your Code (create_agent.py)                │
│   └─> PromptAgentDefinition (SDK)          │
└─────────────────┬───────────────────────────┘
                  │ 
                  ▼ (register agent)
┌─────────────────────────────────────────────┐
│ Azure AI Foundry (Backend)                  │
│   ├─> Agent Runtime (serverless)            │
│   ├─> Model (GPT-4)                         │
│   └─> Tools (Bing, Code Interpreter)        │
└─────────────────┬───────────────────────────┘
                  │
                  ▼ (invoke via API)
┌─────────────────────────────────────────────┐
│ Client Application (chat interface)         │
└─────────────────────────────────────────────┘
```

**Narration**:
> "Notice: your code only **defines** the agent. The agent **runs** in Foundry, not your container."
>
> "This is fundamentally different from Lambda functions where your code executes on invocation."

**Interactive Activity (3 min)**:
- **Poll**: "Who's built Lambda functions that just call another API?" (many hands)
- **Say**: "That's declarative! Your Lambda doesn't have business logic—it orchestrates. Same concept here."
- **Contrast**: "Hosted agents are like Lambda with full business logic inside."

**Slide 3: Key Advantages & Limitations**

| Advantage ✅ | Limitation ⚠️ |
|-------------|---------------|
| No container build/deploy | No custom Python tools |
| Instant updates in portal | Tools limited to Foundry catalog |
| Foundry manages scaling | Less control over execution |
| Great for prototypes | Not ideal for complex workflows |

**Say**:
> "Quick wins: If your agent needs Bing search, Azure AI Search, or Code Interpreter, declarative is perfect."
>
> "You'll hit limits when you need: custom API calls, database queries, or multi-step orchestration. That's when you go hosted."

**Transition (1 min)**:
> "Let's build one. In 45 minutes, you'll have a financial agent answering market questions."

---

### 01:30-01:50 | Declarative Pattern Deep Dive (20 min)

**Instructional Method**: Live code walkthrough + narration

**Setup**:
- Share screen with VS Code
- Open `lesson-1-declarative/create_agent.py`
- Split screen: Code (left) + Foundry Portal (right)

#### Section 1: SDK Code Walkthrough (12 min)

**Show imports**:
```python
from azure.ai.agents import AgentsClient
from azure.ai.agents.models import PromptAgentDefinition
```

**Say**:
> "The SDK is `azure-ai-agents`. This is Microsoft's Python SDK for AI Agent operations in Foundry."
>
> "`PromptAgentDefinition` is the key—this is how we define declarative agents."

**Show authentication**:
```python
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"],
    credential=credential,
)
```

**Say**:
> "Authentication uses `DefaultAzureCredential`—like AWS SDK's credential chain."
>
> "It tries: CLI credentials → managed identity → environment variables."
>
> "We set `AZURE_AI_PROJECT_ENDPOINT` from our deployment output. Check `setup-output.txt`."

**Show agent definition** (most important part):
```python
agent = project_client.agents.create_version(
    agent_name="financial-advisor",
    definition=PromptAgentDefinition(
        model="gpt-4",
        instructions="""You are a financial market advisor.
Help users analyze stocks, understand market trends, and make informed decisions.
Be concise and data-driven.""",
        
        # No tools for now (we'll add later)
        tools=[],
        
        # Configuration
        temperature=0.7,
        top_p=0.95,
    )
)
```

**Narrate line-by-line**:
- `agent_name`: **Say**: "This is your agent's identifier. Must be unique within your Foundry project."
- `model`: **Say**: "GPT-4 by default. You can choose: `gpt-4`, `gpt-4-turbo`, `gpt-35-turbo`. Think of this as choosing Lambda runtime."
- `instructions`: **Say**: "This is your system prompt. The 'personality' of your agent. Foundry injects this on every request."
- `tools`: **Say**: "Empty for now. Later we'll add Bing, Code Interpreter, etc."
- `temperature`: **Say**: "0 = deterministic, 1 = creative. Finance needs accuracy → 0.7 is balanced."

**Interactive Check (2 min)**:
- **Ask**: "What's the equivalent of `instructions` in AWS Bedrock?" (wait for answer: "system prompt")
- **Ask**: "Why would you set temperature=0 for a finance agent?" (answer: "deterministic, reproducible")

**Show output handling**:
```python
print(f"✅ Agent created: {agent.name}")
print(f"   ID: {agent.id}")
print(f"   Version: {agent.version}")
print(f"   Model: {agent.model}")
print(f"   Status: {agent.status}")
```

**Say**:
> "After creation, Foundry returns the agent object with an ID and version."
>
> "Versions are immutable—every update creates a new version. This enables rollback."

#### Section 2: Portal Demonstration (8 min)

**Action**: Switch to Foundry Portal tab

**Navigate** (narrate each step):
1. Open portal.azure.com
2. Search "AI Foundry" → select your project
3. Left menu → "Agents"
4. Show empty list (no agents yet)

**Say**:
> "Right now, no agents exist. After we run `create_agent.py`, this screen will populate."
>
> "The portal is both a viewer AND an editor. You can create agents entirely in the portal, no code."

**Demo**: Click "Create Agent" button
- Show UI: Name, Model dropdown, Instructions textarea, Tools section
- **Say**: "See? This UI maps 1:1 to our SDK code."
- **Click Cancel**: "We'll create via code—it's reproducible and version-controlled."

**Highlight Portal Features**:
- **Playground**: Test agent without writing client code
- **Versions**: View history, compare, rollback
- **Monitoring**: See invocations, costs, latency
- **Sharing**: Publish to organization

**Transition**:
> "Alright, enough theory. Let's deploy an agent. Hands-on time."

---

### 01:50-02:35 | Hands-On Lab: Create Agent (45 min)

**Instructional Method**: Guided practice with checkpoints

**Lab Structure**: Progressive checkpoints every 10-12 minutes

#### Checkpoint 1: Environment Setup (10 min) | 01:50-02:00

**Instructor Action**: Display setup checklist

**Student Task**:
```powershell
# Navigate to lesson folder
cd c:\Cloud\Code\a365-workshop\lesson-1-declarative

# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

**Instructor Facilitation**:
- "If `python` command not found, try `python3` or `py`"
- "Windows users: PowerShell may block script execution. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`"
- **Success indicator**: "You should see `(venv)` in your terminal prompt"

**Common Issues**:

| Issue | Cause | Fix |
|-------|-------|-----|
| "python not found" | Not in PATH | Use Python Launcher: `py -m venv venv` |
| "cannot be loaded" (PowerShell) | Execution policy | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| "pip install" fails | Version mismatch | Upgrade pip: `python -m pip install --upgrade pip` |

**Verify Installation**:
```powershell
python -c "import azure.ai.agents; print('✅ SDK installed')"
```

**Success Criteria**: ✅ All students see "✅ SDK installed"

---

#### Checkpoint 2: Configure Environment Variables (8 min) | 02:00-02:08

**Instructor Action**: Demonstrate variable setup

**Open** `setup-output.txt` from prereq deployment:
```powershell
notepad ..\prereq\setup-output.txt
```

**Expected Content** (show on screen):
```
AZURE_AI_PROJECT_ENDPOINT=https://foundry-workshop-xyz.cognitiveservices.azure.com
AZURE_SUBSCRIPTION_ID=xxxxx-xxxxx-xxxxx
AZURE_RESOURCE_GROUP=rg-foundry-workshop-xyz
```

**Student Task**: Set environment variables

**Windows (PowerShell)**:
```powershell
$env:AZURE_AI_PROJECT_ENDPOINT="<value from setup-output.txt>"
```

**Linux/Mac**:
```bash
export AZURE_AI_PROJECT_ENDPOINT="<value from setup-output.txt>"
```

**Alternative**: Create `.env` file (show VS Code):
```env
AZURE_AI_PROJECT_ENDPOINT=https://foundry-workshop-xyz.cognitiveservices.azure.com
```

**Instructor Tip**:
> "Pro tip: If you create `.env` file, add this to your code:"
> ```python
> from dotenv import load_dotenv
> load_dotenv()
> ```

**Verify**:
```powershell
echo $env:AZURE_AI_PROJECT_ENDPOINT  # PowerShell
echo $AZURE_AI_PROJECT_ENDPOINT     # Bash
```

**Success Criteria**: ✅ Students see their Foundry endpoint URL

---

#### Checkpoint 3: Review and Customize Agent Code (7 min) | 02:08-02:15

**Instructor Action**: Live code review

**Open** `create_agent.py`:
```python
# Show entire file structure
```

**Customization Exercise**:
**Say**: 
> "Before running, let's personalize your agent. Make these changes:"

**Task 1**: Change agent name (add initials)
```python
agent_name="financial-advisor-PT"  # Your initials
```

**Rationale**:
> "Foundry project is shared (if team env). Unique names prevent conflicts."

**Task 2**: Customize instructions
```python
instructions="""You are a financial market advisor specializing in Brazilian markets.
Help users analyze B3 stocks (Bovespa), understand IBOV trends, and make informed decisions.
Always mention risk disclaimers. Be concise and data-driven."""
```

**Say**:
> "This makes it relevant to our Brazilian audience. Feel free to adjust to your region."

**Task 3** (Optional/Advanced): Modify temperature
```python
temperature=0.3  # More deterministic
```

**Interactive**:
- "Who wants a more creative agent? Increase temperature to 0.9"
- "Who needs strict factual responses? Lower to 0.2"

**Save File**: Remind students to save changes

**Success Criteria**: ✅ Code customized and saved

---

#### Checkpoint 4: Execute Agent Creation (12 min) | 02:15-02:27

**Instructor Action**: Demonstrate execution, then students run

**Demo First** (2 min):
```powershell
python create_agent.py
```

**Expected Output** (show on screen):
```
🔄 Creating declarative agent: financial-advisor-PT...
✅ Agent created successfully!
   Name: financial-advisor-PT
   ID: asst_AbC123XyZ
   Version: 1
   Model: gpt-4
   Status: active
   
🔗 View in portal: https://portal.azure.com/...
```

**Narrate**:
> "In 3 seconds, we've deployed an AI agent. No Docker, no container registry—just SDK call."
>
> "Contrast this with Lambda: you'd upload code, configure triggers, set IAM roles. Here? One SDK call."

**Student Execution** (5 min):
**Say**: "Your turn. Run `python create_agent.py` now."

**Monitor Progress**:
- Watch chat for "✅ Agent created"
- If errors appear, paste in chat immediately

**Common Errors**:

| Error | Cause | Fix |
|-------|-------|-----|
| "Authentication failed" | Not logged in | `az login` |
| "Endpoint not found" | Wrong env var | Check `$env:AZURE_AI_PROJECT_ENDPOINT` |
| "Agent name already exists" | Name collision | Change `agent_name` to unique value |
| "Insufficient permissions" | Missing RBAC role | Verify "Cognitive Services User" role |

**While Waiting** (engagement):
- Show portal (refresh agents page)
- "Each agent appearing in portal as people complete"
- Take poll: "Who's done?" (track completion rate)

**Success Criteria**: ✅ 90% students see "✅ Agent created successfully!"

---

#### Checkpoint 5: Verify in Portal (8 min) | 02:27-02:35

**Instructor Action**: Guide portal exploration

**Navigate Together**:
1. Portal → AI Foundry → Your project
2. Left menu → "Agents"
3. Find your agent (`financial-advisor-YOURINITIALS`)
4. Click to open details

**Portal Exploration** (show and tell):
- **Overview tab**: Name, ID, model, version, created date
- **Instructions**: Shows system prompt (editable here!)
- **Tools**: Currently empty
- **Versions**: Shows version 1 (immutable)
- **Monitoring**: No data yet (we haven't invoked)

**Interactive Activity**:
**Say**: "Let's test your agent right in the portal. Click 'Playground' tab."

**Playground Demo**:
- **Type**: "What are the top 3 Brazilian stocks to watch in 2026?"
- **Send** (click send icon)
- **Wait**: Agent responds (~5 seconds)

**Expected Response**:
```
Based on market trends, here are three Brazilian stocks to watch:

1. Petrobras (PETR4) - Energy sector leader
2. Vale (VALE3) - Commodity exposure
3. Itaú Unibanco (ITUB4) - Financial stability

⚠️ Disclaimer: This is not financial advice. Consult a licensed advisor.
```

**Narrate**:
> "Your agent is LIVE. No deployment, no hosting—instant availability."
>
> "Notice the disclaimer? That's from our instructions. The model respects our system prompt."

**Student Task**: 
- "Everyone test your agent with a question"
- "Screenshot your agent's response and share in chat"

**Engagement**:
- Show 3-4 screenshots from students
- Highlight variations based on customized instructions
- Celebrate: "You've deployed your first Azure AI agent!"

**Success Criteria**: ✅ All students successfully invoke agent in playground

---

### 02:35-02:55 | Portal Modification Lab (20 min)

**Instructional Method**: Interactive experiment (guided discovery)

**Objective**: Demonstrate **instant updates without code redeployment**

#### Experiment 1: Modify Instructions (10 min)

**Instructor Setup**:
> "Now here's the magic of declarative agents. Let's modify the agent WITHOUT running code again."

**Student Steps**:
1. **In Portal** → Agents → Your agent
2. Click **"Edit"** (top right)
3. **Modify Instructions**: Add new line:
   ```
   Always respond in Portuguese when discussing Brazilian markets.
   ```
4. Click **"Save"** (creates version 2)
5. **Test in Playground**: "Quais são as ações mais promissoras para 2026?"

**Expected Behavior**:
- Agent responds in Portuguese
- No code rebuild, no container push
- Change took <10 seconds

**Instructor Narration**:
> "This is powerful for rapid iteration. Your product manager can tweak prompts without engineering support."
>
> "In AWS Lambda, you'd: update code → redeploy → wait for provisioning. Here? Edit in UI, instant."

**Interactive Check**:
- **Ask**: "Who got a Portuguese response?" (count responses)
- **Discuss**: "What business scenarios benefit from instant prompt updates?"
  - A/B testing prompts
  - Regulatory compliance changes (add disclaimers)
  - Tone adjustments based on user feedback

#### Experiment 2: Model Swapping (5 min)

**Student Steps**:
1. Click **"Edit"** again
2. Change **Model**: `gpt-4` → `gpt-4-turbo`
3. **Save** (creates version 3)
4. **Test**: Same question as before
5. **Observe**: Faster response, potentially different style

**Instructor Narration**:
> "Model changes in seconds. Useful for cost optimization or latency tuning."
>
> "GPT-4 Turbo is 50% cheaper than GPT-4. You can test cost vs quality tradeoffs live."

#### Experiment 3: Version Rollback (5 min)

**Student Steps**:
1. Go to **"Versions"** tab
2. See: Version 1, 2, 3 (all preserved)
3. Click **Version 1** → "Set as Active"
4. **Test**: Question in English → responds in English again

**Instructor Narration**:
> "Immutable versioning is built-in. If a prompt change breaks production, rollback in one click."
>
> "This is like Lambda aliases/versions, but simpler."

**Key Takeaway** (wrap up):
**Say**:
> "Three experiments, zero container builds. This is the speed of declarative agents."
>
> "Trade-off: you can't add custom Python tools. For that, we'll use hosted agents tomorrow."

---

### 02:55-03:05 | Pattern Decision Framework (10 min)

**Instructional Method**: Decision tree activity (interactive)

**Display Decision Tree** (slide):

```
START: I need an AI agent
           |
           v
     Does it need custom Python tools?
     (API calls, DB queries, file processing)
           |
      Yes  |  No
      /    |    \
     v     |     v
  Hosted  |  Does it need complex multi-step workflows?
          |          |
          |     Yes  |  No
          |     /    |    \
          |    v     |     v
          | Hosted   |  Declarative ✅
```

**Walkthrough** (5 min):
**Say**:
> "Let's build your decision-making intuition. I'll give scenarios, you choose declarative or hosted."

**Scenario 1**:
> "Agent needs to query company financial database (SQL), then analyze data."
- **Answer**: Hosted (requires DB connection tool)
- **Why**: Declarative can't execute custom Python DB queries

**Scenario 2**:
> "Agent helps employees find internal documents using Azure AI Search."
- **Answer**: Declarative ✅
- **Why**: Azure AI Search is a built-in Foundry tool

**Scenario 3**:
> "Agent books customer meetings by checking calendar API and sending emails."
- **Answer**: Hosted (custom API calls)
- **Why**: Calendar/email APIs require custom tools

**Scenario 4**:
> "Agent answers HR policy questions from PDF documents (RAG pattern)."
- **Answer**: Declarative ✅ (if using Azure AI Search) OR Hosted (if custom vector DB)
- **Why**: Depends on data storage choice

**Interactive Poll** (3 min):
_Display on screen_:
> "Your use case: Financial agent needs to fetch live stock prices from Bloomberg API and store analysis in PostgreSQL."
>
> A) Declarative  
> B) Hosted  
> C) Could be either

**Collect votes** → **Answer**: B (Hosted)
**Explain**: "Bloomberg API = custom tool, PostgreSQL = custom tool. Must be hosted."

**Provide Comparison Matrix** (handout):

| Feature | Declarative | Hosted |
|---------|-------------|--------|
| **Deploy time** | <10 seconds | ~5 minutes (container build) |
| **Custom tools** | ❌ | ✅ |
| **Portal editable** | ✅ | ❌ |
| **Cost** | Lower (serverless) | Higher (container always-on) |
| **Use case** | Prototypes, simple workflows | Production, complex logic |
| **Maintenance** | Low (managed) | Medium (update containers) |

**Takeaway**:
> "Start declarative. Migrate to hosted when you hit limitations. That's tomorrow's lesson."

---

### 03:05-03:15 | Q&A + Transition (10 min)

**Format**: Open discussion + preview of Module 2

**Key Questions to Address**:
1. **Q**: "Can I use both declarative and hosted agents in same project?"
   - **A**: Yes! Mix and match based on requirements.

2. **Q**: "How do I version control declarative agents?"
   - **A**: Export agent JSON via SDK, commit to Git. Recreate via CI/CD.

3. **Q**: "What's the cost model?"
   - **A**: Pay per token (model usage). No container compute costs.

4. **Q**: "Can I use models other than OpenAI?"
   - **A**: Yes—Foundry supports Azure OpenAI, Meta Llama, Mistral. Configure in portal.

**Preview Module 2**:
**Say**:
> "Next, we tackle **hosted agents with Microsoft Agent Framework**. You'll:"
> - Build custom tools in Python (stock price fetcher)
> - Containerize the agent
> - Deploy to Azure Container Apps
> - See how it compares to Lambda containerization
>
> "Same agent, different hosting model. You'll understand when to use each."

**Transition**:
> "15-minute break. Stretch, coffee, then we go deeper into hosted patterns."

---

## 📋 Instructor Checklist

### Before Module 1:
- [ ] Verify all students completed Module 0 (infrastructure deployed)
- [ ] Slides loaded (patterns comparison, decision tree)
- [ ] VS Code open with `lesson-1-declarative/create_agent.py`
- [ ] Foundry Portal open (agents page)
- [ ] Test agent creation script (dry run)
- [ ] Prepare troubleshooting notes (RBAC, authentication)
- [ ] Load poll tool (for scenarios)

### During Module 1:
- [ ] Monitor agent creation success rate (aim 90%+)
- [ ] Capture screenshots of student agents in portal
- [ ] Note timing: Is 45 min sufficient for lab?
- [ ] Track common errors (update troubleshooting guide)
- [ ] Verify at least 3 students test experiments successfully
- [ ] Collect feedback on pacing (poll at end)

### After Module 1:
- [ ] Update `7-DELIVERY-LOG.md` with issues encountered
- [ ] Share screenshots of student agents (celebrate wins)
- [ ] Post FAQ responses to common questions
- [ ] Verify all students have working agent (required for Module 2)
- [ ] Prepare container environment setup for Module 2

---

## 🎓 Pedagogical Notes

### Learning Theory Applied:
- **Experiential Learning**: Immediate hands-on creation (not passive observation)
- **Discovery Learning**: Portal experiments encourage exploration
- **Comparative Learning**: Constant AWS analogies leverage prior knowledge
- **Scaffolded Complexity**: Start simple (no tools), add complexity tomorrow

### Adult Learning Principles:
- **Autonomy**: Students customize agent (name, instructions, model)
- **Relevance**: Financial agent relatable to target audience
- **Immediate Feedback**: Playground provides instant validation
- **Problem-Centered**: Scenarios drive pattern decision-making

### Cognitive Load Management:
- **Intrinsic Load**: One concept at a time (auth → definition → deployment)
- **Extraneous Load**: Portal UI familiar (Azure standard)
- **Germane Load**: Decision tree builds schema for pattern selection

### Bloom's Taxonomy Levels Achieved:
- **Remember**: Recall three agent patterns
- **Understand**: Explain when to use declarative
- **Apply**: Create agent with SDK
- **Analyze**: Compare declarative vs hosted trade-offs
- **Evaluate**: Decide pattern for given scenarios
- **Create**: Customize agent for specific domain

---

## 🔧 Troubleshooting Playbook

### Issue: "Authentication failed" Error
**Diagnosis**: Azure CLI not logged in or expired token  
**Fix**:
```powershell
az login
az account show  # Verify subscription
```

### Issue: "Agent name already exists"
**Diagnosis**: Name collision in shared Foundry project  
**Fix**: Change `agent_name` to include unique identifier (initials, timestamp)
```python
agent_name=f"financial-advisor-{os.getlogin()}"  # Uses username
```

### Issue: Agent Created But Not Visible in Portal
**Diagnosis**: Portal caching or wrong project  
**Fix**: 
1. Refresh browser (Ctrl+F5)
2. Verify `AZURE_AI_PROJECT_ENDPOINT` matches portal project URL
3. Check agent list API:
   ```python
   agents = project_client.agents.list()
   for agent in agents:
       print(agent.name)
   ```

### Issue: Playground Doesn't Respond
**Diagnosis**: Model quota exhausted or deployment issue  
**Fix**:
1. Check Azure Service Health
2. Try different model: `gpt-35-turbo`
3. Verify model deployment exists in Foundry → Models

### Issue: Python Environment Conflicts
**Diagnosis**: Global packages interfering  
**Fix**: Delete and recreate venv:
```powershell
deactivate
Remove-Item -Recurse -Force venv
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
```

---

## 📊 Success Metrics

**Module Completion Indicators**:
- ✅ 90%+ students successfully create agent via SDK
- ✅ 85%+ complete all three portal experiments
- ✅ 100% can articulate one difference between declarative vs hosted
- ✅ <5 unique error types encountered (good design if low)

**Learning Evidence**:
- ✅ Students can explain: "When would you NOT use declarative?"
- ✅ Students can demonstrate: Portal instruction editing
- ✅ Students can decide: Pattern selection given scenario

**Engagement Indicators**:
- ✅ 70%+ share playground screenshot in chat
- ✅ 3+ substantive questions in Q&A
- ✅ 80%+ complete customization task (shows initiative)

---

## 🔄 Continuous Improvement Notes

**For Next Iteration**:
- If >15% encounter auth errors → Add pre-workshop auth validation step
- If timing runs over → Reduce theory to 10 min, extend lab by 5 min
- If portal experiments confusing → Add video tutorial as pre-work
- If decision tree underwhelming → Replace with Kahoot quiz (gamification)

**Feedback Collection**:
- Post-module poll: "Which part was most valuable?"
  - A) SDK code walkthrough
  - B) Hands-on lab
  - C) Portal experiments
  - D) Decision framework
- Track: Did students find AWS comparisons helpful? (yes/no)

**Enhancement Ideas**:
- Add "Challenge" task: Create second agent with Code Interpreter tool
- Create troubleshooting video (5 min) for common errors
- Develop decision tree poster (print for physical workshops)

---

## 📚 Resources for Students

**Documentation Links**:
- 📘 Azure AI Foundry SDK Reference: [link]
- 📘 PromptAgentDefinition schema: [link]
- 📘 Model selection guide: [link]
- 🎥 Video: "Declarative vs Hosted Agents" (8 min): [link]

**Sample Code Repository**:
- GitHub: `azure-samples/foundry-agents-patterns`
- Contains: 20+ agent examples with different tools

**Self-Paced Practice**:
- **Challenge 1**: Add Bing Grounding tool to agent
- **Challenge 2**: Create multi-agent orchestration (advanced)
- **Challenge 3**: Implement agent with Azure AI Search

---

**Script Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Reviewed by**: (Pending)  
**Status**: Draft - Awaiting approval  
