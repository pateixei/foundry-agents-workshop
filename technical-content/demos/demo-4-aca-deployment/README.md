# Demo 4: Azure Container Apps (ACA) Deployment

> **Demo Type**: Instructor-led walkthrough. This demo references source code in `lesson-4-aca-langgraph/aca-agent/`. The instructor walks through the code and Bicep template live on screen.

## Overview

Demonstrates deploying agents to **Azure Container Apps (ACA)** infrastructure instead of Foundry's Hosted Agent platform. Shows the "Connected Agent" pattern where you control the infrastructure but register with Foundry for governance.

## Key Concepts

- ✅ ACA deployment with Bicep IaC
- ✅ Connected Agent registration in Foundry
- ✅ FastAPI-based agent server (alternative to agentserver)
- ✅ Managed Identity for ACR pull and Azure OpenAI access
- ✅ Infrastructure control vs Foundry managed

## Architecture

```
Your Infrastructure (ACA) + Foundry Control Plane
┌──────────────────────┐
│ User Request         │
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Foundry AI Gateway   │  (optional routing)
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Azure Container Apps │  ← YOUR infrastructure
│  ├─> FastAPI Server  │
│  └─> LangGraph Agent │
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Azure OpenAI         │  (YOUR endpoint, YOUR quota)
└──────────────────────┘
```

## Hosted vs Connected Agents

| Aspect | Hosted (Demo 2-3) | Connected (This Demo) |
|--------|------------------|----------------------|
| **Infrastructure** | Foundry managed | YOU manage (ACA) |
| **Deployment** | `az cognitiveservices agent` | `az containerapp create` |
| **Scaling** | Foundry controls | ACA controls |
| **Networking** | Foundry VNet | YOUR VNet |
| **Cost** | Foundry compute | YOUR compute |
| **Control** | Low | High |
| **Compliance** | Shared responsibility | Full control |

## When to Use ACA (Connected Agent)

**✅ USE WHEN:**
- Compliance requires data stay in your VNet
- Need custom networking (private endpoints, VPN)
- Want cost optimization control
- Already have ACA infrastructure
- Require specific resource quotas

**❌ AVOID WHEN:**
- Simple deployment needs (use Hosted)
- Don't want infrastructure management overhead
- Foundry scalability is sufficient

## Prerequisites

- Azure subscription with Container Apps quota
- ACR for images
- Azure OpenAI resource
- Bicep knowledge (helpful)

## Quick Start

```powershell
cd demo-4-aca-deployment
.\deploy.ps1
```

The script:
1. Builds LangGraph agent container
2. Pushes to ACR
3. Deploys ACA infrastructure via Bicep
4. Configures Managed Identity + RBAC
5. Tests agent endpoint

## Key Files

- `aca.bicep` - ACA infrastructure definition
- `main.py` - FastAPI + LangGraph agent
- `Dockerfile` - Container image
- `deploy.ps1` - Automation script
- `REGISTER.md` - Connected Agent registration guide

## Bicep Template Highlights

```bicep
// ACA Environment (like ECS Cluster)
resource acaEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${appName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Container App (like ECS Service)
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    environmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
      registries: [{
        server: acr.properties.loginServer
        identity: containerApp.identity.principalId  // MI auth!
      }]
    }
    template: {
      containers: [{
        name: 'agent'
        image: containerImage
        resources: {
          cpu: json('1.0')
          memory: '2Gi'
        }
        env: [{
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAIEndpoint
        }]
      }]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

// RBAC: ACA MI → ACR Pull
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerApp.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'  // AcrPull
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: ACA MI → Azure OpenAI
resource cognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAI.id, containerApp.id, 'CognitiveServicesUser')
  scope: openAI
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'a97b65f3-24c7-4388-baec-2e87135dc908'  // Cognitive Services User
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

## FastAPI Agent Server

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from langgraph_agent import create_agent

app = FastAPI()
agent = create_agent()

class ChatRequest(BaseModel):
    message: str
    thread_id: str = None

@app.post("/chat")
async def chat(request: ChatRequest):
    try:
        response = await agent.run(request.message)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

## Testing

### Direct Call (without Foundry)
```powershell
# Health check
curl https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io/health

# Chat
$body = @{message = "Qual o preco da PETR4?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://aca-lg-agent...azurecontainerapps.io/chat" -Method Post -Body $body -ContentType "application/json"
```

### Via Foundry AI Gateway (Connected Agent)
After registering as Connected Agent:
```powershell
# Use Foundry SDK or Responses API
# Foundry routes through AI Gateway to your ACA endpoint
```

## Registering as Connected Agent

See `REGISTER.md` for detailed steps:
1. Get ACA public FQDN
2. Navigate to Foundry Control Plane
3. Register new Connected Agent
4. Provide endpoint URL and authentication
5. Test via Foundry Responses API

## Troubleshooting

**Issue: "ACR pull failed: 401 Unauthorized"**  
**Cause**: RBAC role assignment not propagated (takes 2-5 min)  
**Fix**: Wait 5 minutes, then restart container app

**Issue: "Container fails health check"**  
**Cause**: `/health` endpoint not responding  
**Fix**: Check logs: `az containerapp logs show --name aca-lg-agent --resource-group rg-aca`

**Issue: "Azure OpenAI 403 Forbidden"**  
**Cause**: MI doesn't have "Cognitive Services User" role  
**Fix**: Verify RBAC assignment in Bicep was deployed

## Cost Considerations

| Service | Daily Cost (USD) | Notes |
|---------|-----------------|-------|
| **ACA** | $0.50-2.00 | Depends on CPU/memory, scale |
| **Azure OpenAI** | $10-50 | Depends on usage |
| **ACR** | $0.17 | Basic tier |
| **Log Analytics** | $0.10-1.00 | Depends on ingestion |
| **Total** | ~$11-53/day | ~$330-1590/month |

**Cost Optimization**:
- Scale to 0 replicas during off-hours
- Use consumption plan instead of dedicated
- Set appropriate resource limits
- Monitor usage with Cost Management

## Resources

- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Bicep Language Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Connected Agent Pattern](https://learn.microsoft.com/azure/ai-foundry/concepts/connected-agents)

---

**Demo Level**: Advanced  
**Estimated Time**: 35-45 minutes  
**Best For**: Production deployments requiring infrastructure control
