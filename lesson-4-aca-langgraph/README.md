# Lesson 4 - LangGraph Agent on Azure Container Apps

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Deploy** containerized agents to Azure Container Apps (ACA) infrastructure
2. **Understand** the difference between Foundry Hosted vs ACA (Connected Agent)
3. **Configure** ACA with managed identity, environment variables, and auto-scaling
4. **Register** external agents as Connected Agents in Foundry Control Plane
5. **Implement** FastAPI-based agent server (alternative to agentserver adapter)
6. **Compare** deployment models: Hosted (Foundry) vs Connected (ACA)
7. **Evaluate** when to deploy on your own infrastructure vs Foundry's

---

## Navigation

| Resource | Description |
|----------|-------------|
| [📖 Demo Walkthrough](demos/README.md) | Code walkthrough and demo instructions |
| [🔬 Lab Exercise](labs/LAB-STATEMENT.md) | Hands-on lab with tasks and success criteria |
| [📐 Architecture Diagram](media/lesson-4-architecture.png) | Architecture overview |
| [🛠️ Deployment Diagram](media/lesson-4-deployment.png) | Deployment flow |
| [📁 Solution Notes](labs/solution/README.md) | Solution code and deployment details |
| [📝 Agent Registration](REGISTER.md) | How to register agent as Connected Agent in Foundry |

---

## Overview

In this lesson, we deploy the same LangGraph agent from previous lessons on
our own infrastructure (**Azure Container Apps**) and register it as a
**Connected Agent** in the Microsoft Foundry Control Plane.

See complete details in [labs/solution/README.md](labs/solution/README.md).

---

## Architecture: Hosted vs Connected Agent

Understanding the two deployment models is essential for making production decisions.

### Hosted Agent (Lessons 2-3)
```
User Request
    ↓
Foundry Responses API
    ↓
Foundry Capability Host (Microsoft's infra)
    ↓
Your Container (managed by Foundry)
    ↓
Azure OpenAI (via Foundry)
```

### Connected Agent (This Lesson)
```
User Request
    ↓
Foundry Responses API
    ↓
AI Gateway (APIM) ← Foundry routes here
    ↓
Azure Container Apps (YOUR infra)
    ↓
Your Container (you manage)
    ↓
Azure OpenAI (YOUR endpoint, YOUR keys/MI)
```

> **Key difference**: Hosted → Foundry manages everything. Connected → You manage infrastructure. Foundry proxies requests and collects telemetry.

---

## Three Deployment Models Comparison

| Model | Where It Runs | Foundry Integration | Use Case |
|-------|---------------|---------------------|----------|
| **Declarative** | Foundry backend | Native | Prototypes, no custom code |
| **Hosted** | Foundry Capability Host | Native | Production, custom tools, trust Foundry infra |
| **Connected** | Your infrastructure (ACA) | API Gateway proxy | Production, need infra control, compliance |

### Why Deploy to ACA (Connected Agent)?

| Reason | Benefit |
|--------|---------|
| ✅ **Compliance** | Data never touches Foundry infra (stays in your VNet) |
| ✅ **Control** | Full control over scaling, networking, resource quotas |
| ✅ **Cost** | Optimize compute costs (reserved capacity, spot instances) |
| ✅ **Existing Infra** | Leverage existing ACA environments (multi-tenant) |
| ✅ **Custom Networking** | Private endpoints, custom DNS, VPN access |
| ✅ **Multi-Cloud** | Run agents on any container platform, register in Foundry |

### Why Stay with Foundry Hosted?

| Reason | Benefit |
|--------|---------|
| ✅ **Simplicity** | No infrastructure management |
| ✅ **Fast Deployment** | 1 CLI command vs Bicep + networking setup |
| ✅ **Built-In Monitoring** | Native telemetry, no config needed |
| ✅ **Auto-Scaling** | Foundry handles scaling logic |
| ✅ **Lower Barrier** | No Azure infra expertise required |

---

## Key Concepts

- **Azure Container Apps (ACA)**: Serverless platform for containers with auto-scaling
- **Connected Agent**: External agent registered in the Foundry Control Plane for governance
- **AI Gateway (APIM)**: Foundry proxy that routes requests and collects telemetry
- **FastAPI**: HTTP framework that serves the agent (replaces the agentserver adapter from hosted agents)
- **Managed Identity**: ACA uses its own MI (different from the Foundry project's MI)

---

## Hosted vs Connected: Side-by-Side

| Aspect | Lessons 2-3 (Hosted) | Lesson 4 (ACA) |
|---|---|---|
| Infrastructure | Foundry (Capability Host) | Azure Container Apps (user) |
| HTTP Server | agentserver adapter (port 8088) | FastAPI + uvicorn (port 8080) |
| Registration | Hosted Agent (CLI/SDK) | Connected Agent (Control Plane portal) |
| Scaling | Foundry managed | ACA managed (minReplicas/maxReplicas) |
| Proxy | Native Responses API | AI Gateway (APIM) |
| Managed Identity | Foundry project MI | Container App MI |

---

## Infrastructure as Code: Bicep Walkthrough

The key difference from Lessons 2-3 is that **you** define infrastructure with Bicep.

### File Structure

```
labs/solution/
├── aca.bicep                # ACA infrastructure definition
├── main.py                  # LangGraph agent (same as Module 3)
├── Dockerfile               # Container definition
├── deploy.ps1               # Deployment automation
├── REGISTER.md              # Connected Agent registration guide
└── requirements.txt
```

### Key Bicep Components

**ACA Environment** (infrastructure foundation):
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

**Container App** (the actual agent):
```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'  // Managed Identity for Azure OpenAI access
  }
  properties: {
    managedEnvironmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080  // FastAPI port (not 8088!)
        transport: 'http'
      }
    }
    template: {
      containers: [{
        name: 'agent'
        image: containerImage
        resources: { cpu: json('0.5'), memory: '1Gi' }
      }]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [{
          name: 'http-scaling'
          http: { metadata: { concurrentRequests: '10' } }
        }]
      }
    }
  }
}
```

**⚠️ CRITICAL: RBAC Role Assignment** (without this, your container can't call Azure OpenAI):
```bicep
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerApp.id, 'CognitiveServicesOpenAIUser')
  scope: azureOpenAI
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')  // Cognitive Services OpenAI User
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### FastAPI Server vs Foundry Adapter

**Lesson 3 (Foundry Hosted)** — used Foundry's adapter:
```python
# Dockerfile CMD:
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
```

**Lesson 4 (ACA Connected)** — you implement the HTTP server:
```python
from fastapi import FastAPI, Request
from langgraph.graph import StateGraph

app = FastAPI()
graph = build_langgraph()

@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    message = body.get("message")
    result = graph.invoke({"messages": [("user", message)]})
    return {"response": result["messages"][-1][1]}

# Dockerfile CMD:
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

> **Key change**: YOU implement the HTTP server. No adapter needed. When you register as Connected Agent, Foundry learns your API schema.

---

## Quick Start

```powershell
cd labs/solution
.\deploy.ps1
```

The deployment script automates 5 steps:
1. 🔨 Build container image in ACR
2. 📦 Deploy ACA infrastructure with Bicep
3. 🔐 Configure Managed Identity RBAC
4. 🌐 Test health endpoint
5. 🧪 Validate chat endpoint

---

## Connected Agent Registration

After deployment, register your ACA agent in Foundry Control Plane:

```powershell
az cognitiveservices connectedagent create \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --foundry-project $foundryProjectName \
  --endpoint "https://$agentFqdn" \
  --description "LangGraph agent deployed on ACA"
```

### Connected Agent Benefits

1. **Governance**: Foundry tracks all agents (even external ones)
2. **Unified Monitoring**: Telemetry flows into Foundry dashboard
3. **Access Control**: Use Foundry RBAC for ACA agent access
4. **Discovery**: Users find connected agents in Foundry catalog
5. **AI Gateway**: Optional routing through APIM (rate limiting, auth)

> **Connected Agent** = "Hey Foundry, I have an agent running elsewhere. Please manage it."

### ♻️ Do I Need to Re-Register After Updating My Code?

**No.** The registration stores your ACA **endpoint URL**, not a reference to a specific container image or code version. When you push a new image version (`v2`, `v3`, etc.) to the same ACA app, the URL remains unchanged — Foundry continues routing to that same endpoint and automatically picks up the new code.

| Change | Re-registration needed? |
|--------|------------------------|
| Updated container image (same ACA app) | ❌ No |
| Bug fix, new feature, dependency update | ❌ No |
| New ACA app or different FQDN | ✅ Yes |
| Moved to a different resource group / subscription | ✅ Yes |
| Changed the `/chat` path or API contract | ✅ Yes (update `--endpoint`) |

To **update** an existing registration (e.g., new endpoint URL):
```powershell
az cognitiveservices connectedagent update \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --foundry-project $foundryProjectName \
  --endpoint "https://$newAgentFqdn"
```

To **verify** the current registered endpoint:
```powershell
az cognitiveservices connectedagent show \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --foundry-project $foundryProjectName \
  --query "properties.endpoint"
```

---

## Testing: Two Paths

### Test Path 1: Direct ACA Call (bypassing Foundry)

```powershell
# Direct HTTP call to ACA
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the PETR4 stock price?"}'
```

### Test Path 2: Via Foundry Proxy (through AI Gateway)

```powershell
az cognitiveservices agent invoke \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --query "What is the market sentiment for VALE3?"
```

> **When to use which?**
> - **Direct**: Internal tools, high throughput, lower latency
> - **Proxy**: External access, rate limiting, governance

---

## Cost Comparison

| Item | Foundry Hosted | ACA Connected |
|------|----------------|---------------|
| Estimated monthly cost | ~$20-40/month | ~$15-30/month (1 replica) |
| Scaling control | Foundry-managed | You choose (min/max replicas) |
| Reserved capacity | Not available | Available (cost savings) |
| Best for | Simplicity, fast start | High utilization, cost optimization |

---

## Managed Identity Deep Dive

The ACA Managed Identity flow:
1. Container requests token from Azure metadata endpoint
2. Azure verifies container identity (via system-assigned MI)
3. Token issued (scoped to Cognitive Services)
4. Container uses token to call Azure OpenAI

> No credential management needed. MI handles authentication automatically.

---

## 🔧 Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "Quota exceeded for Managed Environments" | Subscription limit | Request quota increase OR delete unused ACA envs |
| "Container image not found" | ACR build failed | Check ACR build logs: `az acr task logs` |
| "Role assignment failed" | Insufficient permissions | Ensure user has "User Access Administrator" role |
| Health check timeout | Container not starting | Check ACA logs: `az containerapp logs show` |
| Agent returns 500 on `/chat` | Azure OpenAI endpoint misconfigured | Verify env vars and MI permissions |
| Container stuck in "Provisioning" | Image pull failure or startup timeout | Check for `ImagePullBackOff` in logs |

### Verify ACA Status

```powershell
# Check container status
az containerapp show --name aca-lg-agent --resource-group $rgName \
  --query "properties.runningStatus"

# View real-time logs
az containerapp logs show --name aca-lg-agent --resource-group $rgName --follow

# Query logs in Log Analytics
# ContainerAppConsoleLogs_CL | where TimeGenerated > ago(10m) | project TimeGenerated, Log_s
```

---

## ❓ Frequently Asked Questions

**Q: Can I use both Hosted and Connected agents in the same Foundry project?**
A: Yes! You can mix and match deployment models. Use Hosted for simple agents and Connected for agents needing infra control.

**Q: Does Foundry track usage for Connected Agents?**
A: Yes. Foundry collects telemetry through the AI Gateway proxy—request count, latency, success rate. Useful for chargeback and quotas.

**Q: What happens if my ACA goes down?**
A: Requests through the Foundry proxy will fail with a timeout. Configure ACA with `minReplicas: 1` to avoid cold starts, and set up health probes.

**Q: Why port 8080 instead of 8088?**
A: ACA doesn't use the Foundry adapter (which binds to 8088). You control the HTTP server with FastAPI/uvicorn, and 8080 is the conventional choice.

**Q: Can I use a private endpoint for ACA?**
A: Yes. Configure VNet integration for ACA and register the internal endpoint as the Connected Agent URL. Foundry's AI Gateway needs network access to reach it.

---

## 🏆 Self-Paced Challenges

1. **Custom Domain**: Configure a custom domain for your ACA agent (e.g., `agent.contoso.com`)
2. **VNet Integration**: Deploy ACA with private VNet and internal-only ingress
3. **Multi-Agent System**: Deploy multiple agents on the same ACA Environment and register each as a Connected Agent
4. **Auto-Scaling Tuning**: Experiment with different scaling rules (KEDA, CPU-based, queue-length)
5. **Blue-Green Deployment**: Implement revision-based blue-green deployment on ACA for zero-downtime upgrades

---

## References

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Bicep Language Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Foundry Connected Agents Guide](https://learn.microsoft.com/azure/ai-services/)
- [Managed Identity for ACA](https://learn.microsoft.com/azure/container-apps/managed-identity)
