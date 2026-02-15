# Demo 5: Microsoft Agent 365 SDK Integration

> **Demo Type**: Instructor-led walkthrough. This demo references source code in `lesson-6-a365-sdk/`. The instructor walks through A365 CLI setup, Bot Framework integration, and deployment live on screen.

## Overview

Demonstrates integrating **Microsoft Agent 365 (A365) SDK** with deployed agents to enable Microsoft 365 features: Bot Framework protocol, Adaptive Cards, and observability for Teams/Outlook deployment.

## Key Concepts

- ✅ Cross-tenant architecture (Azure Tenant A + M365 Tenant B)
- ✅ Agent Blueprint registration in Entra ID
- ✅ Bot Framework `/api/messages` endpoint
- ✅ Adaptive Cards for rich M365 UI
- ✅ OpenTelemetry integration with Application Insights
- ✅ Publishing to M365 Admin Center
- ✅ Creating agent instances in Teams

## Architecture

```
┌────────────────────────────────────┐
│ M365 Tenant (Tenant B)             │
│  ├─> Agent Blueprint (Entra ID)    │
│  ├─> Agent User (Service Principal)│
│  └─> Teams/Outlook interface       │
└─────────┬──────────────────────────┘
          │ (routes to)
          ▼
┌────────────────────────────────────┐
│ Azure Tenant (Tenant A)            │
│  ├─> ACA with agent code           │
│  ├─> /api/messages endpoint        │
│  └─> Managed Identity auth         │
└────────────────────────────────────┘
```

## Prerequisites

1. **Frontier Program Access**: Required for A365 registration
2. **.NET SDK 8.0+**: For A365 CLI tool
3. **M365 Admin Access**: For publishing approval
4. **Existing Agent**: Deployed in ACA (from Demo 4) or Foundry

## Quick Start

### Phase 1: A365 CLI Setup

```powershell
# Install A365 CLI
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify installation
a365 --version

# Initialize config (interactive)
cd lesson-5-a365-prereq
a365 config init
```

### Phase 2: Blueprint Registration

```powershell
# Login to M365 tenant (Tenant B)
az login --tenant <m365-tenant-id>

# Create Agent Blueprint
a365 setup blueprint --config a365.config.json
```

Expected output:
```
✅ Agent Blueprint registered
  App ID: f7a3b8e9-...
  Name: financial-advisor-aca
  Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
```

### Phase 3: Enhance Agent with A365 SDK

The agent code now includes Bot Framework handling:

```python
# Enhanced main.py with Bot Framework
from botbuilder.core import BotFrameworkAdapter, TurnContext
from botbuilder.schema import Activity
from langgraph_agent import create_agent

agent = create_agent()

async def on_message_activity(turn_context: TurnContext):
    """Handles incoming Bot Framework Activities."""
    user_message = turn_context.activity.text
    
    # Process with LangGraph agent
    response = await agent.run(user_message)
    
    # Return Adaptive Card (rich UI)
    card = create_adaptive_card(response)
    await turn_context.send_activity(Activity(attachments=[card]))

def create_adaptive_card(text: str) -> dict:
    """Creates an Adaptive Card for M365."""
    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "Financial Advisor",
                    "weight": "Bolder",
                    "size": "Large"
                },
                {
                    "type": "TextBlock",
                    "text": text,
                    "wrap": True
                }
            ]
        }
    }

# FastAPI endpoint for Bot Framework
@app.post("/api/messages")
async def handle_messages(request: Request):
    body = await request.json()
    activity = Activity().deserialize(body)
    
    auth_header = request.headers.get("Authorization", "")
    await adapter.process_activity(activity, auth_header, on_message_activity)
    
    return {"status": "ok"}
```

### Phase 4: Deploy Enhanced Agent

```powershell
cd lesson-6-a365-sdk
.\deploy.ps1
```

### Phase 5: Publish to M365 Admin Center

```powershell
cd lesson-7-publish

# Submit for publication
a365 publish --manifest publication-manifest.json
```

**publication-manifest.json**:
```json
{
  "name": "Financial Advisor Agent",
  "shortDescription": "AI agent providing stock insights",
  "longDescription": "Leverages LangGraph with real-time market data tools...",
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
  "categories": ["Finance", "AI Assistant"],
  "isPrivate": true,
  "permissions": [
    "Microsoft.Graph.User.Read",
    "Microsoft.Graph.Conversations.Send"
  ]
}
```

### Phase 6: Create Agent Instance in Teams

```powershell
# After admin approval
cd lesson-8-instances

# Create personal instance
a365 instance create --type personal --agent-id <blueprint-app-id>

# Create shared instance (team/channel)
a365 instance create --type shared --team-id <teams-team-id> --agent-id <blueprint-app-id>
```

## Bot Framework Activity Flow

```
Teams User → Message
    ↓
Microsoft Graph API (M365 Tenant)
    ↓
Agent Blueprint (Entra ID)
    ↓
Messaging Endpoint (ACA in Azure Tenant)
    ↓
/api/messages endpoint
    ↓
BotFrameworkAdapter
    ↓
on_message_activity handler
    ↓
LangGraph agent processes
    ↓
Adaptive Card response
    ↓
Response flows back to Teams
```

## Adaptive Cards Examples

### Stock Quote Card

```json
{
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
            "type": "TextBlock",
            "text": "📈 PETR4",
            "size": "Large",
            "weight": "Bolder"
          }]
        },
        {
          "type": "Column",
          "width": "stretch",
          "items": [{
            "type": "TextBlock",
            "text": "R$ 35,42",
            "size": "Large",
            "horizontalAlignment": "Right",
            "color": "Good"
          }]
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Variação: +1.23% (alta)",
      "color": "Good"
    },
    {
      "type": "TextBlock",
      "text": "Informação apenas para fins educativos.",
      "size": "Small",
      "isSubtle": True,
      "wrap": True
    }
  ]
}
```

## Cross-Tenant Authentication Flow

1. **Developer** (Azure Tenant A): Deploys agent infrastructure
2. **A365 CLI** (via M365 Tenant B login): Creates Blueprint in Tenant B
3. **Agent Blueprint** (M365 Tenant B): References messaging endpoint in Tenant A
4. **Runtime**: M365 authenticates user → Agent Blueprint → routes to Azure Tenant A endpoint

## Troubleshooting

**Issue: "A365 CLI command not found"**  
**Cause**: .NET tools path not in PATH  
**Fix**: Add `~/.dotnet/tools` to PATH or restart terminal

**Issue: "Frontier Program access denied"**  
**Cause**: Not enrolled in preview program  
**Fix**: Apply at https://adoption.microsoft.com/copilot/frontier-program/

**Issue: "Blueprint registration failed: tenant mismatch"**  
**Cause**: Logged into wrong tenant with `az login`  
**Fix**: `az login --tenant <m365-tenant-id>` explicitly

**Issue: "/api/messages returns 404"**  
**Cause**: Bot Framework endpoint not implemented or route misconfigured  
**Fix**: Verify FastAPI route exists: `@app.post("/api/messages")`

**Issue: "Adaptive Card not rendering in Teams"**  
**Cause**: Invalid JSON schema or version mismatch  
**Fix**: Validate at https://adaptivecards.io/designer

## Agent Instance Types

| Type | Scope | Use Case |
|------|-------|----------|
| **Personal** | Individual user | Private agent for personal use |
| **Shared** | Team/Channel | Collaborative agent for team |
| **Org-wide** | Entire organization | Company-wide deployment |

## Resources

- [Microsoft Agent 365 Developer Guide](https://learn.microsoft.com/microsoft-agent-365/developer/)
- [Bot Framework SDK](https://learn.microsoft.com/azure/bot-service/)
- [Adaptive Cards Designer](https://adaptivecards.io/designer/)
- [Frontier Program](https://adoption.microsoft.com/copilot/frontier-program/)

---

**Demo Level**: Advanced  
**Estimated Time**: 45-60 minutes (includes admin approval wait)  
**Best For**: Enterprise deployments to M365 ecosystem (Teams, Outlook, Copilot)
