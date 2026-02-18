# Lab 6: Microsoft Agent 365 Integration and M365 Deployment

> 🇧🇷 **[Leia em Português (pt-BR)](LAB-STATEMENT.pt-BR.md)**

## Objective

Enhance your agent with **Microsoft Agent 365 (A365) SDK**, register Agent Blueprint in Microsoft 365, and deploy to Teams for end-user access. This lab completes the full enterprise deployment cycle.

## Scenario

Your financial advisor agent (from Lab 4) is ready for production. The business requires:
- Deployment to Microsoft Teams for employees
- Bot Framework integration for rich conversations
- Adaptive Cards for financial data visualization
- Cross-tenant support (Azure infra in Tenant A, M365 in Tenant B)
- Admin-approved publication process

## Learning Outcomes

- Configure A365 CLI for cross-tenant scenarios
- Register Agent Blueprints in Microsoft Entra ID
- Implement Bot Framework `/api/messages` endpoint
- Create Adaptive Cards for financial data
- Publish agents to M365 Admin Center
- Create and manage agent instances in Teams
- Understand M365 governance model for agents

## Prerequisites

- [x] Lab 4 completed (ACA-deployed agent)
- [x] Frontier Program access (required for A365)
- [x] .NET SDK 8.0+ installed
- [x] M365 Admin permissions (or simulated for workshop)
- [x] Understanding of cross-tenant scenarios

## Tasks

### Task 1: Install and Configure A365 CLI (15 minutes)

**1.1 - Install .NET SDK**

```powershell
# Check version
dotnet --version
# Required: 8.0+

# If missing:
winget install Microsoft.DotNet.SDK.8
```

**1.2 - Install A365 CLI**

```powershell
# Install as .NET global tool
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify
a365 --version
# Expected: 1.0.x or higher
```

**1.3 - Configure A365**

```powershell
cd starter/a365-config
a365 config init
```

**Interactive prompts**:
```
? M365 Tenant ID: <your-m365-tenant-id>
? Azure Subscription ID: <your-azure-subscription-id>
? Agent Name: financial-advisor-teams
? Messaging Endpoint: https://aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io/api/messages
? Create Azure infrastructure (App Service)? No  ← IMPORTANT: We already have ACA!
```

**Generated `a365.config.json`**:
```json
{
  "tenantId": "<m365-tenant-id>",
  "subscriptionId": "<azure-subscription-id>",
  "agentName": "financial-advisor-teams",
  "messagingEndpoint": "https://aca-financial-agent...azurecontainerapps.io/api/messages",
  "needDeployment": false
}
```

**Success Criteria**:
- ✅ A365 CLI installed and working
- ✅ Config file created with correct values
- ✅ `needDeployment: false` (using existing ACA)

### Task 2: Register Agent Blueprint (20 minutes)

**2.1 - Login to M365 Tenant**

```powershell
# Important: Login to M365 tenant (Tenant B), not Azure tenant (Tenant A)
az login --tenant <m365-tenant-id>

# Verify
az account show
# Tenant ID should match M365 tenant
```

**2.2 - Create Agent Blueprint**

```powershell
a365 setup blueprint --config a365.config.json
```

**Expected Output**:
```
🔧 Creating Agent Blueprint...
✅ Blueprint registered in Entra ID
   App ID: f7a3b8e9-1234-5678-abcd-9876543210ef
   Name: financial-advisor-teams
   Messaging Endpoint: https://aca-financial-agent...azurecontainerapps.io/api/messages

🔐 Creating Service Principal (Agent User)...
✅ Service Principal created
   Principal ID: abc12345-...

✅ Configuring permissions...
   - Microsoft.Graph.User.Read
   - Microsoft.Graph.Conversations.Send

✅ Agent Blueprint registration complete
```

**What just happened?**:
- Created App Registration in M365 Tenant's Entra ID
- Created Service Principal (Agent User identity)
- Configured Graph API permissions
- Linked messaging endpoint (your ACA agent in Azure Tenant)

**2.3 - Verify in Portal**

1. Navigate to [Entra ID Portal](https://entra.microsoft.com/)
2. Select **App registrations** → **All applications**
3. Search for "financial-advisor-teams"
4. Verify messaging endpoint in **Authentication** settings

**Success Criteria**:
- ✅ Blueprint visible in Entra ID
- ✅ Service Principal created
- ✅ Permissions configured correctly
- ✅ Messaging endpoint points to ACA

### Task 3: Enhance Agent with Bot Framework (30 minutes)

**3.1 - Add Bot Framework dependencies**

Update `requirements.txt`:
```txt
# Existing dependencies...
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
botframework-connector>=4.16.0
```

**3.2 - Implement `/api/messages` endpoint**

Open `starter/main.py` and add:

```python
from fastapi import FastAPI, Request, Response
from botbuilder.core import BotFrameworkAdapter, TurnContext
from botbuilder.schema import Activity
from langgraph_agent import create_agent

app = FastAPI()
agent_graph = create_agent()

# Bot Framework Adapter
adapter = BotFrameworkAdapter(
    app_id=os.environ.get("MICROSOFT_APP_ID"),  # From Agent Blueprint
    app_password=os.environ.get("MICROSOFT_APP_PASSWORD", "")  # MI auth
)

async def on_message_activity(turn_context: TurnContext):
    """Handles incoming Bot Framework Activities from M365."""
    user_message = turn_context.activity.text
    
    # Process with LangGraph agent
    result = await agent_graph.ainvoke({
        "messages": [user_message],
        "current_tool": None,
        "tool_result": {}
    })
    
    response_text = result["messages"][-1].content
    
    # Create Adaptive Card for rich display
    card = create_financial_card(response_text)
    
    await turn_context.send_activity(
        Activity(
            type="message",
            attachments=[card]
        )
    )

@app.post("/api/messages")
async def handle_messages(request: Request):
    """Bot Framework messaging endpoint for M365."""
    auth_header = request.headers.get("Authorization", "")
    body = await request.json()
    
    activity = Activity().deserialize(body)
    
    # Process with Bot Framework adapter
    await adapter.process_activity(activity, auth_header, on_message_activity)
    
    return Response(status_code=200)
```

**3.3 - Create Adaptive Card helper**

```python
def create_financial_card(text: str, data: dict = None) -> dict:
    """Creates an Adaptive Card for financial information."""
    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.4",
            "body": [
                {
                    "type": "ColumnSet",
                    "columns": [
                        {
                            "type": "Column",
                            "width": "auto",
                            "items": [{
                                "type": "Image",
                                "url": "https://example.com/finance-icon.png",
                                "size": "Small"
                            }]
                        },
                        {
                            "type": "Column",
                            "width": "stretch",
                            "items": [{
                                "type": "TextBlock",
                                "text": "Financial Advisor",
                                "weight": "Bolder",
                                "size": "Large"
                            }]
                        }
                    ]
                },
                {
                    "type": "TextBlock",
                    "text": text,
                    "wrap": True
                }
            ]
        }
    }
```

**3.4 - Redeploy to ACA**

```powershell
# Rebuild container with Bot Framework support
docker build -t langgraph-financial-agent:v2 .
docker tag langgraph-financial-agent:v2 YOUR-ACR.azurecr.io/langgraph-financial-agent:v2
docker push YOUR-ACR.azurecr.io/langgraph-financial-agent:v2

# Update ACA to use new image
az containerapp update \
  --name aca-financial-agent \
  --resource-group rg-aca \
  --image YOUR-ACR.azurecr.io/langgraph-financial-agent:v2
```

**3.5 - Test Bot Framework endpoint**

```powershell
# Simulate Bot Framework Activity
$activity = @{
    type = "message"
    text = "Qual o preco da PETR4?"
    from = @{ id = "user123"; name = "Test User" }
    conversation = @{ id = "conv123" }
    channelId = "test"
    serviceUrl = "https://test.botframework.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://aca-financial-agent...azurecontainerapps.io/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

**Success Criteria**:
- ✅ `/api/messages` endpoint implemented
- ✅ Bot Framework activities processed
- ✅ Adaptive Cards rendered
- ✅ Agent redeployed successfully

### Task 4: Publish to M365 Admin Center (20 minutes)

**4.1 - Create publication manifest**

Create `publication-manifest.json`:
```json
{
  "name": "Financial Advisor Agent",
  "shortDescription": "AI-powered financial market insights for Brazilian and international markets",
  "longDescription": "Leverages LangGraph orchestration with real-time market data tools. Provides stock quotes, exchange rates, and market summaries. Includes appropriate disclaimers for educational purposes.",
  "developer": {
    "name": "Contoso Financial Services",
    "websiteUrl": "https://contoso.com",
    "privacyUrl": "https://contoso.com/privacy",
    "termsOfUseUrl": "https://contoso.com/terms"
  },
  "icons": {
    "color": "icon-color.png",
    "outline": "icon-outline.png"
  },
  "categories": ["Finance", "AI Assistant", "Productivity"],
  "isPrivate": true,
  "permissions": [
    "Microsoft.Graph.User.Read",
    "Microsoft.Graph.Conversations.Send"
  ]
}
```

**4.2 - Submit for publication**

```powershell
a365 publish --manifest publication-manifest.json
```

**Expected Output**:
```
📤 Submitting agent for publication...
   Blueprint: financial-advisor-teams
   App ID: f7a3b8e9-...
   
✅ Submission successful!
   
📋 Publication Details:
   Submission ID: sub-abc123
   Status: Pending Admin Approval
   Submitted: 2026-02-14 15:30 UTC
   
⏳ Next Steps:
   1. M365 Admin reviews in Admin Center
   2. You'll receive email when status changes
   3. After approval, agent appears in Teams app catalog
```

**4.3 - Admin Approval (Simulated for Workshop)**

In production:
1. M365 Admin receives notification
2. Admin Center → **Apps** → **Manage apps** → **financial-advisor-teams**
3. Review metadata, permissions, privacy policy
4. Click **Approve** or **Reject**
5. If approved, set visibility: Private org / Public / Specific users

**Success Criteria**:
- ✅ Publication manifest valid JSON
- ✅ Successfully submitted to Admin Center
- ✅ (In production) Admin approval obtained

### Task 5: Create Agent Instance in Teams (15 minutes)

**Assumptionl**: Agent is approved and published (or using pre-approved test agent)

**5.1 - Create personal instance**

```powershell
# Personal agent (private to one user)
a365 instance create \
  --type personal \
  --agent-id f7a3b8e9-1234-5678-abcd-9876543210ef \
  --user-id <your-m365-user-id>
```

**5.2 - Test in Teams**

1. Open Microsoft Teams (desktop or web)
2. Go to **Apps** → **Built for your org**
3. Search for "Financial Advisor"
4. Click **Add**
5. Start conversation:
   - "Qual é o preço da PETR4?"
   - "Calcule valor: 100 PETR4, 50 VALE3"
   - "Resumo do mercado brasileiro"

**Expected Behavior**:
- Agent responds with Adaptive Cards (rich UI)
- Financial data formatted professionally
- Disclaimers included
- Conversation context maintained

**5.3 - Create shared instance (Optional)**

```powershell
# Shared agent for entire team
a365 instance create \
  --type shared \
  --agent-id f7a3b8e9-... \
  --team-id <teams-team-id>
```

**Success Criteria**:
- ✅ Agent visible in Teams app catalog
- ✅ Personal instance created
- ✅ Conversations work in Teams
- ✅ Adaptive Cards render correctly

## Deliverables

- [x] A365 CLI configured
- [x] Agent Blueprint registered in Entra ID
- [x] Bot Framework integration implemented
- [x] Agent enhanced with Adaptive Cards
- [x] Publication manifest created
- [x] Agent instance working in Teams

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **A365 Configuration** | 15 pts | CLI setup and config file |
| **Blueprint Registration** | 20 pts | Successfully registered in Entra ID |
| **Bot Framework** | 30 pts | `/api/messages` endpoint functional |
| **Adaptive Cards** | 15 pts | Rich cards implemented and rendering |
| **Publication** | 10 pts | Manifest valid, submitted to Admin Center |
| **Teams Integration** | 10 pts | Agent working in Teams |

**Total**: 100 points

## Troubleshooting

### "A365 CLI not found"
- .NET tools path not in PATH
- Fix: Add `~/.dotnet/tools` to PATH, restart terminal

### "Blueprint registration failed: tenant mismatch"
- Logged into wrong tenant
- Fix: `az login --tenant <m365-tenant-id>` explicitly

### "/api/messages returns 400"
- Activity JSON format invalid
- Fix: Ensure Activity schema matches Bot Framework spec

### "Adaptive Card not rendering in Teams"
- Invalid schema or unsupported version
- Fix: Validate at https://adaptivecards.io/designer
- Ensure version is 1.4 or lower (Teams limit)

### "Frontier Program access denied"
- Not enrolled in preview
- Fix: Apply at https://adoption.microsoft.com/copilot/frontier-program/

## Time Estimate

- Task 1: 15 minutes
- Task 2: 20 minutes
- Task 3: 30 minutes
- Task 4: 20 minutes
- Task 5: 15 minutes
- **Total**: 100 minutes

## Congratulations! 🎉

You've completed the full enterprise agent deployment cycle:
1. ✅ Built declarative agent (Lab 1)
2. ✅ Implemented custom tools with MAF (Lab 2)
3. ✅ Deployed LangGraph agent on Foundry (Lab 3)
4. ✅ Deployed to ACA with Bicep (Lab 4)
5. ✅ Integrated A365 and published to Teams (Lab 6)

Your agent is now accessible to end users in Microsoft 365!

---

**Difficulty**: Advanced  
**Prerequisites**: All previous labs, Frontier Program access  
**Estimated Time**: 100 minutes
