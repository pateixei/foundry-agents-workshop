# Lab 4: Deploy Agent to Azure Container Apps (ACA) with Bicep

> 🇧🇷 **[Leia em Português (pt-BR)](LAB-STATEMENT.pt-BR.md)**

## Objective

Deploy infrastructure using **Bicep IaC** and register agent as a **Connected Agent** in Foundry, giving you full infrastructure control while maintaining Foundry governance integration.

## Scenario

Your company requires:
- Data must stay in corporate VNet (compliance)
- Custom scaling policies (cost optimization)
- Integration with existing ACA environment
- Foundry governance for agent lifecycle management

Solution: Deploy to ACA (your infrastructure) + register as Connected Agent in Foundry.

## Learning Outcomes

- Deploy Azure Container Apps with Bicep IaC
- Configure Managed Identity for ACR and Azure OpenAI access
- Implement RBAC role assignments in Bicep
- Register Connected Agents in Foundry Control Plane
- Understand Hosted vs Connected agent patterns
- Make infrastructure decisions based on compliance needs

## Prerequisites

- [x] Lab 3 completed (LangGraph agent)
- [x] Azure subscription with Container Apps quota
- [x] ACR with pushed agent image
- [x] Bicep knowledge (helpful but not required)

## Tasks

### Task 1: Review Infrastructure Requirements (10 minutes)

**Study the architecture**:

```
┌─────────────────────────────────┐
│ User Request via Foundry API    │
└──────────┬──────────────────────┘
           ▼
┌─────────────────────────────────┐
│ Foundry AI Gateway (optional)   │
└──────────┬──────────────────────┘
           ▼
┌─────────────────────────────────┐
│ Azure Container Apps (YOUR VNet)│
│  ├─> Load Balancer (public)     │
│  ├─> Container Instances (1-10) │
│  └─> Managed Identity (MI)      │
└──────────┬──────────────────────┘
           ▼
┌─────────────────────────────────┐
│ Azure OpenAI (YOUR endpoint)    │
└─────────────────────────────────┘
```

**What you'll deploy**:
1. Log Analytics Workspace (telemetry)
2. ACA Environment (like ECS cluster)
3. Container App (agent runtime)
4. Managed Identity (for auth)
5. RBAC roles (ACR Pull + Cognitive Services User)

**Success Criteria**:
- ✅ Understand ACA vs Foundry Hosted differences
- ✅ Identify RBAC requirements
- ✅ Recognize Managed Identity usage pattern

### Task 2: Complete Bicep Template (30 minutes)

Navigate to `starter/aca.bicep` and implement:

**2.1 - Define Parameters**

```bicep
@description('Name of the Container App')
param containerAppName string = 'aca-financial-agent'

@description('Container image from ACR')
param containerImage string

@description('Azure OpenAI endpoint')
param azureOpenAIEndpoint string

@description('Azure OpenAI deployment name')
param openAIDeploymentName string = 'gpt-4'

@description('Location for all resources')
param location string = resourceGroup().location
```

**2.2 - Create Log Analytics Workspace**

```bicep
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${containerAppName}-logs'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}
```

**2.3 - Create ACA Environment**

```bicep
resource acaEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${containerAppName}-env'
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
```

**2.4 - Create Container App with Managed Identity**

```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'  // Creates Managed Identity
  }
  properties: {
    environmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true  // Public endpoint
        targetPort: 8080
        transport: 'http'
        allowInsecure: true  // HTTPS termination at gateway
      }
      registries: [
        {
          server: 'YOUR-ACR.azurecr.io'
          identity: 'system'  // Use MI for ACR auth (not admin password!)
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'agent'
          image: containerImage
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
          env: [
            {
              name: 'AZURE_OPENAI_ENDPOINT'
              value: azureOpenAIEndpoint
            }
            {
              name: 'AZURE_OPENAI_DEPLOYMENT'
              value: openAIDeploymentName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
```

**2.5 - Add RBAC Role Assignments**

```bicep
// ACR Pull Role (7f951dda-4ed3-4680-a7ca-43fe172d538d)
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerApp.id, 'AcrPull')
  scope: resourceGroup()  // Or specific ACR resource
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Cognitive Services User for Azure OpenAI (a97b65f3-24c7-4388-baec-2e87135dc908)
resource cognitiveServicesRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerApp.id, 'CognitiveServicesUser')
  scope: resourceGroup()  // Or specific OpenAI resource
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'a97b65f3-24c7-4388-baec-2e87135dc908'
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

**2.6 - Add Outputs**

```bicep
output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
output containerAppPrincipalId string = containerApp.identity.principalId
output acaEnvironmentId string = acaEnvironment.id
```

**Success Criteria**:
- ✅ Bicep template has no syntax errors (`az bicep build`)
- ✅ All resources defined with proper dependencies
- ✅ Managed Identity configured
- ✅ RBAC roles assigned
- ✅ Outputs configured for next steps

### Task 3: Deploy Infrastructure (15 minutes)

**3.1 - Validate Bicep template**

```powershell
az bicep build --file aca.bicep
```

**3.2 - Create parameters file** (`aca.bicepparam`)

```bicep
using './aca.bicep'

param containerAppName = 'aca-financial-agent'
param containerImage = 'YOUR-ACR.azurecr.io/langgraph-financial-agent:v1'
param azureOpenAIEndpoint = 'https://YOUR-OPENAI.openai.azure.com/'
param openAIDeploymentName = 'gpt-4'
```

**3.3 - Deploy**

```powershell
az deployment group create \
  --resource-group rg-aca-agents \
  --template-file aca.bicep \
  --parameters aca.bicepparam
```

**Expected Output**:
```
Deployment 'aca' succeeded.
Outputs:
  containerAppFQDN: aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io
  containerAppPrincipalId: 12345678-abcd-...
```

**Wait for RBAC propagation** (2-5 minutes):
- RBAC assignments take time to propagate
- Container may initially fail to pull from ACR (401 error)
- This is expected—will succeed after propagation

**Success Criteria**:
- ✅ Deployment completes without errors
- ✅ ACA app shows "Running" status
- ✅ FQDN is accessible: `curl https://FQDN/health`

### Task 4: Test Direct Access (10 minutes)

**4.1 - Health check**

```powershell
$fqdn = "aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io"
Invoke-RestMethod "https://$fqdn/health"
# Expected: { "status": "healthy" }
```

**4.2 - Chat endpoint**

```powershell
$body = @{ message = "Qual o preco da PETR4?" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://$fqdn/chat" -Method Post -Body $body -ContentType "application/json"
```

**Success Criteria**:
- ✅ Health check returns 200 OK
- ✅ Chat endpoint processes requests
- ✅ Agent responses are correct

### Task 5: Understand ACA Deployment vs Foundry Integration (15 minutes)

> **IMPORTANT — Foundry Playground Limitation**: The Foundry Playground **does not** support testing agents deployed on your own infrastructure (ACA). The Playground only works with **Prompt/Workflow agents** and **Hosted Agents** (where Foundry manages the container runtime). If you need Playground integration, see Lab 3 (Hosted Agent model).

**5.1 - Why ACA Agents Don't Appear in the Playground**

The new Foundry experience distinguishes between:

| Concept | Description | Playground? |
|---------|-------------|-------------|
| **Prompt/Workflow Agents** | Created directly in Foundry Agent Builder | ✅ Yes |
| **Hosted Agents** | Your container code running on Foundry's managed infrastructure (`ImageBasedHostedAgentDefinition`) | ✅ Yes |
| **ACA Agents (this lab)** | Your container code on YOUR own Azure Container Apps | ❌ No |

The Foundry portal's **Operate → Overview → Register asset** only adds your ACA URL as a **reference asset** — it does NOT integrate it as a testable agent.

**5.2 - When to Choose Each Model**

| Use Case | Recommended Model |
|----------|-------------------|
| Rapid prototyping with Foundry Playground | **Hosted Agent** (Lab 3) |
| Full infrastructure control (VNet, scaling, compliance) | **ACA** (This Lab) |
| Need Foundry telemetry + Playground testing | **Hosted Agent** (Lab 3) |
| Integration with existing ACA/Kubernetes environment | **ACA** (This Lab) |
| Publishing to Teams/M365 via Foundry | **Hosted Agent** (Lab 3) |

**5.3 - Testing Your ACA Agent**

Since Foundry Playground is not available for ACA agents, all testing is done **directly** via the ACA endpoints:

```powershell
# Health check
curl https://<ACA_FQDN>/health

# Chat endpoint
curl -X POST https://<ACA_FQDN>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the current price of PETR4?"}'

# API Documentation
open https://<ACA_FQDN>/docs
```

You can also integrate ACA agents into your own applications via standard HTTP calls — the ACA endpoint is a regular REST API.

> **Optional**: You can register the ACA URL as an asset in Foundry for documentation purposes: **Operate → Overview → Register asset**. This won't enable Playground testing, but keeps a reference in your project.

**Success Criteria**:
- ✅ Understand why ACA agents don't appear in Foundry Playground
- ✅ Can articulate when to use ACA vs Hosted Agents
- ✅ Agent tested successfully via direct ACA endpoints (Task 4)
- ✅ Know how to integrate ACA agents into custom applications

### Task 6: Compare Hosting Models (10 minutes)

**Complete comparison table**:

| Feature | Hosted (Lab 2-3) | ACA Self-Hosted (This Lab) |
|---------|------------------|----------------------------|
| **Infrastructure Owner** | ? | ? |
| **Foundry Playground** | ? | ? |
| **Deployment Command** | ? | ? |
| **Scaling Control** | ? | ? |
| **Cost Model** | ? | ? |
| **VNet Integration** | ? | ? |
| **Compliance** | ? | ? |
| **Setup Complexity** | ? | ? |
| **When to Use** | ? | ? |

**Decision Framework**:

Use **Hosted** when:
- [ ] Rapid deployment is priority
- [ ] No special compliance requirements
- [ ] Foundry scalability is sufficient
- [ ] Don't want infrastructure overhead

Use **Connected (ACA)** when:
- [ ] Need data in corporate VNet
- [ ] Custom scaling/networking required
- [ ] Cost optimization is important
- [ ] Already have ACA environment
- [ ] Compliance mandates  infrastructure control

**Success Criteria**:
- ✅ Table completed with accurate information
- ✅ Decision framework reflects understanding
- ✅ Can justify deployment model choice

## Deliverables

- [x] Complete Bicep template (aca.bicep)
- [x] Deployed ACA infrastructure
- [x] Agent running and accessible
- [x] Understand ACA vs Hosted Agent tradeoffs
- [x] Comparison document: Hosted vs Connected
- [x] Cost estimate for ACA deployment

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **Bicep Template** | 30 pts | Complete, correct IaC with proper dependencies |
| **RBAC Configuration** | 20 pts | Managed Identity + role assignments |
| **Deployment** | 20 pts | Successfully deployed and running |
| **Testing** | 15 pts | Direct access via ACA endpoints works |
| **Architecture Understanding** | 10 pts | Can explain ACA vs Hosted Agent tradeoffs |
| **Analysis** | 5 pts | Thoughtful comparison of hosting models |

**Total**: 100 points

## Troubleshooting

### "ACR pull failed: 401 Unauthorized"
- **Cause**: RBAC role not propagated yet
- **Fix**: Wait 5 minutes, restart container app

### "Container fails to start: health check timeout"
- **Cause**: `/health` endpoint not responding
- **Fix**: Check logs: `az containerapp logs show --name aca-financial-agent --resource-group rg-aca`

### "Azure OpenAI 403 Forbidden"
- **Cause**: MI missing Cognitive Services User role
- **Fix**: Verify RBAC assignment deployed, wait for propagation

### "Bicep deployment failed: QuotaExceeded"
- **Cause**: Container Apps quota exceeded in region
- **Fix**: Request quota increase or use different region

## Time Estimate

- Task 1: 10 minutes
- Task 2: 30 minutes
- Task 3: 15 minutes
- Task 4: 10 minutes
- Task 5: 15 minutes
- Task 6: 10 minutes
- **Total**: 90 minutes

## Next Steps

- **Lab 6**: Integrate Microsoft Agent 365 SDK for M365 deployment
- Learn cross-tenant architecture
- Publish to Teams and Outlook

---

**Difficulty**: Advanced  
**Prerequisites**: Labs 1-3, basic Bicep/IaC knowledge  
**Estimated Time**: 90 minutes
