# Instructional Script: Modules 5-6 - Microsoft Agent 365 Setup & SDK

---

**Modules**: 5-6 - Agent 365 Prerequisites & SDK Integration  
**Duration**: 180 minutes (Day 3 Hours 3-4 + Day 4 Hour 1: 11:15-14:30)  
**Instructor**: Technical SME + M365 Specialist  
**Location**: `instructor-guide/MODULES-5-6-A365-SETUP-SDK-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Learning Objectives

By the end of these modules, students will be able to:
1. **Configure** Agent 365 (A365) CLI and authentication for cross-tenant scenarios
2. **Register** Agent Blueprint in Microsoft 365 Entra ID
3. **Understand** cross-tenant architecture (Azure Tenant A + M365 Tenant B)
4. **Integrate** A365 SDK for observability, adaptive cards, and Bot Framework protocol
5. **Deploy** enhanced agent with Application Insights telemetry
6. **Test** agents in M365 context (Teams-ready endpoints)

---

## 📊 Module Overview

### Module 6: A365 Prerequisites (60 min - Day 3 Hour 3)
| Element | Duration | Method |
|---------|----------|--------|
| **Cross-Tenant Scenario** | 15 min | Presentation (Azure vs M365 tenant) |
| **A365 CLI Setup** | 20 min | Installation + configuration |
| **Agent Blueprint Registration** | 20 min | CLI commands + Entra ID verification |
| **Troubleshooting** | 5 min | Common auth issues |

### Module 5: A365 SDK Integration (120 min - Day 3 Hour 4 + Day 4 Hour 1)
| Element | Duration | Method |
|---------|----------|--------|
| **SDK Overview** | 15 min | A365 SDK capabilities |
| **Observability Integration** | 30 min | Application Insights + OpenTelemetry |
| **Bot Framework Protocol** | 30 min | `/api/messages` endpoint implementation |
| **Adaptive Cards** | 25 min | Rich M365 responses |
| **Deploy & Test** | 20 min | Deployment + Teams testing |

---

## 🗣️ Module 6: Instructional Script

### 11:15-11:30 | Cross-Tenant Scenario (15 min)

**Instructional Method**: Presentation with architecture diagrams

**Opening (2 min)**:
> "You've deployed agents to Azure. Now: make them accessible in Microsoft 365 (Teams, Outlook, Copilot)."
>
> "Challenge: Your Azure infrastructure might be in a different tenant than your M365 users. Today we solve this."

**Content Delivery (10 min)**:

**Slide 1: Two-Tenant Architecture**

| Resource | Tenant | Why |
|----------|--------|-----|
| **Azure (Foundry, ACA, ACR)** | Tenant A | Technical infrastructure, dev teams |
| **Microsoft 365 (Teams, Outlook)** | Tenant B | End users, corporate IT |

**Scenario**: Common in enterprises
- IT manages Azure in "Engineering Tenant"
- Users work in "Corporate M365 Tenant"
- Agent needs to bridge both

**Say**:
> "This isn't a workshop quirk—it's real enterprise architecture."
>
> "Many companies separate Azure subscriptions from M365 for governance, cost allocation, or acquisition history."

**Slide 2: What A365 Does**

**Agent 365 creates**:
1. **Agent Blueprint** in M365 Tenant's Entra ID (App Registration)
2. **Agent User** (Service Principal) for identity
3. **Messaging Endpoint** configuration pointing to your ACA (Tenant A)

**Flow**:
```
User in M365 Tenant (Tenant B)
    ↓ (invokes agent via Teams)
Microsoft Graph (Tenant B)
    ↓ (authenticates using Agent User)
Agent Blueprint (Tenant B)
    ↓ (routes request to)
Messaging Endpoint (ACA in Tenant A)
    ↓ (agent executes)
Response flows back through Graph
```

**Say**:
> "Key insight: **Agent identity lives in M365 Tenant**, but **agent code runs in Azure Tenant**."
>
> "A365 CLI bridges them by registering the endpoint URL in M365's Entra ID."

**Interactive (3 min)**:
- **Poll**: "How many work in multi-tenant environments?" (count)
- **Ask students**: "What challenges have you faced with cross-tenant access?"
- Common answers: Auth complexity, RBAC confusion, network routing

**Transition**:
> "Let's configure A365 CLI to handle this automatically."

---

### 11:30-11:50 | A365 CLI Setup (20 min)

**Instructional Method**: Hands-on installation + config

#### Checkpoint 1: Prerequisites Verification (5 min)

**Student Task**:
```powershell
# Check .NET SDK installed (required for A365 CLI)
dotnet --version
# Expected: 8.0+ (7.0 also works)

# If missing, install:
# Windows: winget install Microsoft.DotNet.SDK.8
# Mac: brew install dotnet
```

**Verify Frontier Program Access**:
> "Check email: Did you receive Frontier Program approval?"
>
> "If NO: You can follow along today, but won't be able to publish to M365."
>
> "If YES: You're ready for full A365 setup."

**Success Criteria**: ✅ .NET SDK available

---

#### Checkpoint 2: Install A365 CLI (5 min)

**Student Task**:
```powershell
# Install A365 CLI as .NET tool
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify installation
a365 --version
# Expected: 1.0.x or higher
```

**Expected Output**:
```
Microsoft Agent 365 CLI v1.0.5
Copyright (c) Microsoft Corporation. All rights reserved.
```

**Troubleshooting**:

| Issue | Cause | Fix |
|-------|-------|-----|
| "dotnet tool not found" | .NET not in PATH | Restart terminal |
| "A365 command not found" | Tool path not in PATH | Add `~/.dotnet/tools` to PATH |
| Version mismatch | Old version cached | `dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease` |

**Success Criteria**: ✅ `a365 --version` shows version

---

#### Checkpoint 3: Create A365 Config File (10 min)

**Instructor demonstrates, students follow**:

```powershell
cd lesson-6-a365-prereq

# Create config file
a365 config init
```

**CLI prompts** (show expected Q&A):
```
? Tenant ID (M365 Tenant): <paste-your-m365-tenant-id>
? Subscription ID (Azure): <paste-your-azure-subscription-id>
? Agent Name: financial-advisor-aca
? Messaging Endpoint: https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io/api/messages
? Need Azure deployment (create App Service)? No  ← IMPORTANT: We use existing ACA!
```

**Generated file**: `a365.config.json`

**Show content**:
```json
{
  "tenantId": "<m365-tenant-id>",
  "subscriptionId": "<azure-subscription-id>",
  "agentName": "financial-advisor-aca",
  "messagingEndpoint": "https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io/api/messages",
  "needDeployment": false,
  "resourceGroup": "rg-a365-placeholder",  // Not used (needDeployment=false)
  "appServicePlanName": "placeholder"       // Not used
}
```

**Explain `needDeployment: false`**:
> "CRITICAL setting: `needDeployment: false` tells A365: 'Don't create Azure infrastructure—I already have it.'"
>
> "Our agent is deployed to ACA (Module 4). A365 only needs to **register** it, not **deploy** it."
>
> "If you set `true`, A365 would create App Service—we don't want that duplication."

**Success Criteria**: ✅ `a365.config.json` created with correct endpoint

---

### 11:50-12:10 | Agent Blueprint Registration (20 min)

**Instructional Method**: CLI-driven registration with explanation

#### Step 1: Authenticate to M365 Tenant (5 min)

**Objective**: Login to the CORRECT tenant (M365, not Azure)

**⚠️ Key Concept: Two Tenants**

| Tenant | Purpose | Contains |
|--------|---------|----------|
| **Azure Tenant (A)** | Infrastructure | Subscription, Foundry, ACA, ACR |
| **M365 Tenant (B)** | End Users | Teams, Outlook, M365 users |

**How to Identify Your Tenants**:

```powershell
# 1. Find your current Azure Tenant ID
az account show --query tenantId -o tsv
# Output: e.g., 12345678-1234-1234-1234-123456789abc (this is Azure Tenant A)

# 2. Find your M365 Tenant ID
# Option A: Check in M365 Admin Center (admin.microsoft.com → Settings → Org settings → Organization profile)
# Option B: Ask your M365 administrator
# Option C: If you created Azure subscription through M365 org, they might be the same

# 3. Determine if they're different
# Same tenant: Azure & M365 in one tenant (simpler, less common in enterprises)
# Different tenants: Cross-tenant scenario (more complex, common in large orgs)
```

**Student Task**:
```powershell
# Login to M365 Tenant (Tenant B, NOT Azure Tenant!)
az login --tenant <m365-tenant-id>

# Verify you're in M365 Tenant
az account show --query tenantId -o tsv
# MUST match your M365 Tenant ID, NOT Azure Tenant ID
```

**⚠️ Common Mistake**:
> "Many will auto-login to Azure Tenant. YOU MUST LOGIN TO M365 TENANT."
>
> "A365 CLI creates resources in M365 Entra ID, not Azure Entra ID."
>
> "If unsure: Ask 'Where do my Teams users live?' That's your M365 Tenant."

**Verify permissions**:
```powershell
# Check if you have required roles in M365 Tenant
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --all
# Need: Global Administrator OR Agent ID Administrator OR Agent ID Developer
```

**If missing**: Ask M365 admin to grant role

**Troubleshooting**:

|  Issue | Cause | Fix |
|-------|-------|-----|
| "Already logged into wrong tenant" | Azure Tenant cached | `az logout` then `az login --tenant <m365-tenant-id>` |
| "Don't know M365 Tenant ID" | No M365 admin access | Check M365 Admin Center or ask IT |
| "Azure & M365  Tenant IDs same" | Single-tenant setup | Good! Simpler scenario, continue as-is |

**Success Criteria**: ✅ Logged into M365 Tenant with required permissions

---

#### Step 2: Register Agent Blueprint (10 min)

**Student Task**:
```powershell
# Run A365 setup
a365 setup blueprint
```

**What this does** (narrate step-by-step):

**Output walkthrough**:
```
🔍 Reading configuration from a365.config.json...
   Agent Name: financial-advisor-aca
   Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
   
📝 Creating App Registration in Entra ID...
   ✅ App Registration created: financial-advisor-aca
   App ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
   Object ID: <object-id>

🔐 Configuring API permissions...
   Adding permission: Microsoft Graph / User.Read
   Adding permission: Microsoft Graph / Conversations.Send
   ✅ Permissions configured (admin consent required)

🌐 Setting messaging endpoint...
   Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
   ✅ Bot channel registration created

🎉 Agent Blueprint registered successfully!

⚠️  NEXT STEPS:
   1. Admin consent required for permissions (see Portal)
   2. Update messaging endpoint to use /api/messages (if not already)
   3. Run 'a365 publish' to make available in M365 Admin Center
```

**Instructor explains each step**:

1. **App Registration**: "Creates identity for agent in M365 Entra ID. Like creating a service principal."
2. **API Permissions**: "Agent needs to read user profiles (User.Read) and send messages (Conversations.Send)."
3. **Bot Channel**: "Registers endpoint where Microsoft Graph will send messages."

**Interactive**: Pause for questions
- "What's confusing?" (address immediately)
- "Why do we need admin consent?" (security: app permissions require admin approval)

**Success Criteria**: ✅ Blueprint registered, App ID obtained

---

#### Step 3: Admin Consent (5 min)

**Instructor demonstrates** (students watch or follow if they have admin rights):

**Navigate to Azure Portal** (yes, Azure Portal even for M365 Tenant!):
1. portal.azure.com → Entra ID (top left, switch to M365 Tenant if needed)
2. App registrations → Find "financial-advisor-aca"
3. API permissions tab
4. Click "Grant admin consent for [Organization]"
5. Confirm: Yes

**Expected result**: Permissions show green checkmarks

**Say**:
> "Admin consent is one-time. Once granted, agent can access Microsoft Graph on behalf of users."
>
> "In production, your IT admin does this. For workshop, you need Global Admin role."

**⚠️ If students lack admin rights**:
> "No admin? No problem for today. Workshop continues—you can test locally. For M365 deployment, you'll need admin consent eventually."

**Success Criteria**: ✅ Permissions granted (or noted for later)

---

### 12:10-12:15 | Troubleshooting (5 min)

**Instructor reviews common issues**:

**Issue 1: "Insufficient privileges for app registration"**
- Fix: Verify Global Admin or Agent ID Administrator role
- Escalation: Ask M365 admin to register blueprint

**Issue 2: "Tenant not found"**
- Fix: Verify M365 Tenant ID correct in `a365.config.json`
- Fix: Run `az login --tenant <m365-tenant-id>` again

**Issue 3: "Messaging endpoint unreachable"**
- Fix: Verify ACA agent responds at `/api/messages` endpoint
- Test: `curl https://<your-aca-fqdn>/api/messages` (should return 405 Method Not Allowed for GET, but proves endpoint exists)

**Issue 4: Cross-tenant auth errors**
- Fix: Ensure Managed Identity (Tenant A) has no conflict with App Registration (Tenant B)
- Note: These are separate identities—no conflict unless networkingblocks access

**Wrap Module 6**:
> "Blueprint registered! Tomorrow we enhance the agent with A365 SDK features."
>
> "Break for lunch. Afternoon: SDK integration with telemetry and adaptive cards."

---

## 🗣️ Module 5: Instructional Script

### 13:15-13:30 | SDK Overview (15 min)

**Instructional Method**: Presentation

**Opening (2 min)**:
> "Your agent works in ACA (Module 4) and is registered in M365 (Module 6). Now: make it **production-ready** with observability, rich UX, and M365 protocol support."

**Content Delivery (10 min)**:

**Slide: A365 SDK Capabilities**

| Feature | Purpose | M365 Benefit |
|---------|---------|--------------|
| **Azure Monitor Integration** | Distributed tracing, metrics | Monitor agent performance across M365 interactions |
| **Bot Framework Protocol** | `/api/messages` endpoint | Native Teams/Outlook integration |
| **Adaptive Cards** | Rich UI responses | Interactive, branded messages in Teams |
| **Activity-based Conversations** | Multi-turn context | Maintain conversation history in M365 |

**Say**:
> "Without A365 SDK: Your agent is a generic REST API."
>
> "With A365 SDK: Your agent speaks M365's language—Activities, Adaptive Cards, telemetry."

**Show Before/After Code** (high-level):

**Before (Generic FastAPI)**:
```python
@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    message = body["message"]
    response = agent.invoke(message)
    return {"response": response}
```

**After (A365 SDK + Bot Framework)**:
```python
from botbuilder.core import BotFrameworkAdapter, TurnContext

adapter = BotFrameworkAdapter()

@app.post("/api/messages")  # Bot Framework endpoint
async def messages(request: Request):
    activity = await request.json()
    
    async def on_turn(turn_context: TurnContext):
        if turn_context.activity.type == "message":
            # Invoke agent with full context
            response = agent.invoke(turn_context.activity.text)
            
            # Send Adaptive Card response
            card = create_adaptive_card(response)
            await turn_context.send_activity(card)
    
    await adapter.process_activity(activity, on_turn)
```

**Say**:
> "Notice: We now handle `Activity` objects (Bot Framework protocol), not just JSON."
>
> "This enables Teams to send rich context: user identity, conversation ID, thread history."

**Interactive (3 min)**:
- **Ask**: "Who's built Teams bots before?" (gauge familiarity)
- **Explain**: "Bot Framework is Microsoft's standard. A365 SDK simplifies integration with agents."

**Transition**:
> "Let's add observability first—you'll see agent traces in Application Insights."

---

### 13:30-14:00 | Observability Integration (30 min)

**Instructional Method**: Code modification + deployment

**Objective**: Add OpenTelemetry tracing to agent

#### Step 1: Install Dependencies (5 min)

**Student Task**:
```powershell
cd lesson-5-a365-langgraph

# Install A365 SDK packages
pip install -r requirements.txt
```

**New dependencies**:
```txt
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
```

**Success Criteria**: ✅ Packages installed

---

#### Step 2: Configure Application Insights (10 min)

**Instructor demonstrates**:

**Add to `main.py`**:
```python
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Configure Application Insights
app_insights_connection_string = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
if app_insights_connection_string:
    configure_azure_monitor(connection_string=app_insights_connection_string)
    print("✅ Application Insights initialized")

# Create FastAPI app
app = FastAPI()

# Instrument FastAPI (auto-trace all endpoints)
FastAPIInstrumentor.instrument_app(app)
```

**Explain components**:
- `configure_azure_monitor`: "Sends telemetry to Application Insights"
- `FastAPIInstrumentor`: "Automatically traces HTTP requests"

**Get connection string**:
```powershell
# From Module 0 deployment, we have Application Insights
az monitor app-insights component show \
  --resource-group $rgName \
  --app <app-insights-name> \
  --query connectionString
```

**Add to ACA environment variables**:
```powershell
# Update ACA with App Insights connection string
az containerapp update \
  --name aca-lg-agent \
  --resource-group $rgName \
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString"
```

**Success Criteria**: ✅ Environment variable configured

---

#### Step 3: Add Custom Spans (10 min)

**Instructor shows how to instrument tool calls**:

**Modify tool functions**:
```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def get_stock_price(symbol: str) -> dict:
    with tracer.start_as_current_span("get_stock_price") as span:
        span.set_attribute("stock.symbol", symbol)
        
        # Simulate API call
        price_data = fetch_price(symbol)  # Your logic
        
        span.set_attribute("stock.price", price_data["price"])
        span.set_status(trace.Status(trace.StatusCode.OK))
        
        return price_data
```

**Say**:
> "Custom spans give you detailed timing for each tool call."
>
> "In Application Insights, you'll see: How long did `get_stock_price` take? Success rate?"

**Student Task**: Add spans to 1-2 tools in their agent

**Success Criteria**: ✅ Span instrumentation added

---

#### Step 4: Test Telemetry (5 min)

**Deploy updated agent**:
```powershell
.\deploy.ps1  # Redeploy with telemetry
```

**Invoke agent**:
```powershell
$body = @{message = "What is AAPL price?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<aca-fqdn>/chat" -Method Post -Body $body -ContentType "application/json"
```

**View in Portal**:
1. Azure Portal → Application Insights → Transaction search
2. Find recent request (within last 5 min)
3. Click to see End-to-end transaction
4. Verify spans: `get_stock_price` visible with timing

**Instructor screenshot**: Show example trace with spans

**Say**:
> "This is production observability. You can debug: Which tool is slow? Where do errors happen?"

**Success Criteria**: ✅ Telemetry visible in Application Insights

---

### 14:00-14:30 | Bot Framework Protocol (30 min)

**Instructional Method**: Implementation + testing

**Objective**: Add `/api/messages` endpoint for Teams integration

#### Implement Activity Handler (20 min)

**Instructor walks through**:

**Add to `main.py`**:
```python
from botbuilder.core import BotFrameworkAdapter, TurnContext
from botbuilder.schema import Activity, ActivityTypes

# Bot adapter
adapter = BotFrameworkAdapter(settings=BotAdapterSettings(
    app_id=os.getenv("APP_ID"),  # From A365 registration
    app_password=os.getenv("APP_PASSWORD")
))

@app.post("/api/messages")
async def messages(request: Request):
    body = await request.json()
    activity = Activity().deserialize(body)
    
    async def on_turn(turn_context: TurnContext):
        if turn_context.activity.type == ActivityTypes.message:
            user_message = turn_context.activity.text
            
            # Invoke agent
            response = agent.invoke(user_message)
            
            # Send response
            await turn_context.send_activity(response)
    
    await adapter.process_activity(activity, on_turn)
    return {"status": "ok"}
```

**Explain**:
- **Activity**: "M365's message format. Contains user ID, text, conversation ID, timestamp."
- **TurnContext**: "Encapsulates conversation state. Use to send/receive messages."
- **adapter.process_activity**: "Handles Bot Framework protocol authentication and routing."

**Student Task**: Implement (or review) `/api/messages` endpoint

**Success Criteria**: ✅ Endpoint implemented

---

#### Test with Teams Emulator (10 min)

**Option 1: Local Testing with Bot Framework Emulator** (if available)
1. Download Bot Framework Emulator
2. Connect to: `https://<aca-fqdn>/api/messages`
3. Send message: "What is AAPL price?"
4. Verify response appears

**Option 2: curl Testing**:
```powershell
# Simulate Teams Activity
$activity = @{
    type = "message"
    text = "What is AAPL price?"
    from = @{ id = "user123"; name = "Test User" }
    conversation = @{ id = "conv123" }
    id = "msg123"
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://<aca-fqdn>/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

**Expected**: Agent responds to curl (in production, Teams would call this endpoint)

**Success Criteria**: ✅ `/api/messages` responds to Activity format

---

### 14:30 | Wrap Modules 5-6

**Summary**:
> "You've configured A365 CLI (Module 6) and integrated A365 SDK (Module 5)."
>
> "Next modules: Publish to M365 Admin Center (Module 7) and create agent instances in Teams (Module 8)."
>
> "Tomorrow (Day 4): Publishing workflow and end-user testing."

---

## 📋 Instructor Checklist

### Before Modules 5-6:
- [ ] Verify Frontier Program access for students
- [ ] Test A365 CLI setup end-to-end
- [ ] Prepare M365 Tenant credentials (if shared tenant for workshop)
- [ ] Application Insights connection string ready
- [ ] Bot Framework Emulator installed (optional for demo)

### During Modules 5-6:
- [ ] Monitor A365 CLI authentication (cross-tenant complexity)
- [ ] Track Blueprint registration success rate
- [ ] Verify telemetry appears in Application Insights for 80%+
- [ ] Capture Bot Framework endpoint errors (common issue)

### After Modules 5-6:
- [ ] Update `7-DELIVERY-LOG.md` with A365-specific issues
- [ ] Document cross-tenant auth troubleshooting
- [ ] Verify all students ready for Module 7 (Blueprint registered)

---

## 🔧 Troubleshooting Playbook

### Issue: A365 CLI "Tenant not found"
**Fix**: Ensure logged into M365 Tenant, not Azure Tenant
```powershell
az logout
az login --tenant <m365-tenant-id>
```

### Issue: "Insufficient privileges to complete operation"
**Fix**: Verify Global Admin or Agent ID Administrator role in M365 Tenant

### Issue: Telemetry Not Appearing in Application Insights
**Fix**: Verify connection string correct and container restarted after env var update

### Issue: `/api/messages` Returns 401 Unauthorized
**Fix**: Verify App ID and App Password environment variables set correctly

---

## 📊 Success Metrics

**Modules 5-6 Completion Indicators**:
- ✅ 85%+ successfully register Agent Blueprint
- ✅ 90%+ see telemetry in Application Insights
- ✅ 75%+ implement `/api/messages` endpoint
- ✅ 100% understand cross-tenant architecture

---

**Script Version**: 0.7  
**Last Updated**: 2026-02-16  
**Created by**: Agent 3 (Instructional Designer)  
**Status**: Draft - Awaiting approval
