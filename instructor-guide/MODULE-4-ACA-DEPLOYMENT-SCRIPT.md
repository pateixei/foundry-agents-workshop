# Instructional Script: Module 4 - Azure Container Apps Deployment

---

**Module**: 4 - Azure Container Apps (ACA) Deployment  
**Duration**: 120 minutes (Day 3, Hours 1-2: 09:00-11:00)  
**Instructor**: Technical SME + Facilitator  
**Location**: `instructor-guide/MODULE-4-ACA-DEPLOYMENT-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Learning Objectives

By the end of this module, students will be able to:
1. **Deploy** containerized agents to Azure Container Apps (ACA) infrastructure
2. **Understand** the difference between Foundry Hosted vs ACA (Connected Agent)
3. **Configure** ACA with custom domains, managed identity, and environment variables
4. **Register** external agents as Connected Agents in Foundry Control Plane
5. **Implement** FastAPI-based agent server (alternative to agentserver adapter)
6. **Compare** deployment models: Hosted (Foundry) vs Connected (ACA)
7. **Evaluate** when to deploy on your own infrastructure vs Foundry's

---

## 📊 Module Overview

| Element | Duration | Method |
|---------|----------|--------|
| **Deployment Models Comparison** | 20 min | Presentation (Hosted vs Connected) |
| **ACA Architecture & Bicep** | 25 min | Infrastructure as Code walkthrough |
| **Deploy to ACA** | 40 min | Hands-on deployment with Bicep |
| **Connected Agent Registration** | 20 min | Register in Foundry Control Plane |
| **Testing & Validation** | 15 min | Direct ACA testing + Foundry routing |

---

## 🗣️ Instructional Script (Minute-by-Minute)

### 09:00-09:20 | Deployment Models Comparison (20 min)

**Instructional Method**: Presentation with decision framework

**Opening (2 min)**:
> "Days 1-2: agents ran IN Foundry (Hosted Agents). Today: agents run OUTSIDE Foundry, on your own infrastructure."
>
> "Why would you do this? Control, compliance, cost optimization, existing infrastructure investment."

**Content Delivery (15 min)**:

**Slide 1: Three Deployment Models**

| Model | Where It Runs | Foundry Integration | Use Case |
|-------|---------------|---------------------|----------|
| **Declarative** | Foundry backend | Native | Prototypes, no custom code |
| **Hosted** | Foundry Capability Host | Native | Production, custom tools, trust Foundry infra |
| **Connected** | Your infrastructure (ACA) | API Gateway proxy | Production, need infra control, compliance |

**Say**:
> "Connected Agents give you best of both worlds:"
> - Run on your infrastructure (control, compliance)
> - Registered in Foundry (governance, monitoring, unified management)
>
> "Foundry routes requests via AI Gateway, but execution happens on YOUR containers."

**Slide 2: Architecture Comparison**

**Hosted Agent**:
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

**Connected Agent**:
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

**Narrate**:
> "Hosted: Foundry manages everything. You just provide container image."
>
> "Connected: You manage infrastructure. Foundry just proxies requests and collects telemetry."

**Slide 3: Why Deploy to ACA Instead of Foundry Hosted?**

**Reasons to use ACA (Connected Agent)**:
1. ✅ **Compliance**: Data never touches Foundry infra (stays in your VNet)
2. ✅ **Control**: Full control over scaling, networking, resource quotas
3. ✅ **Cost**: Optimize compute costs (reserved capacity, spot instances)
4. ✅ **Existing Infra**: Leverage existing ACA environments (multi-tenant)
5. ✅ **Custom Networking**: Private endpoints, custom DNS, VPN access
6. ✅ **Multi-Cloud**: Run agents on any container platform, register in Foundry (hybrid)

**Reasons to use Foundry Hosted**:
1. ✅ **Simplicity**: No infrastructure management
2. ✅ **Fast Deployment**: 1 CLI command vs Bicep + networking setup
3. ✅ **Built-In Monitoring**: Native telemetry, no config needed
4. ✅ **Auto-Scaling**: Foundry handles scaling logic
5. ✅ **Lower Barrier**: No Azure infra expertise required

**Interactive (3 min)**:
- **Poll**: "Which model fits your production needs?" (Hosted / Connected / Both)
- **Ask "Connected" voters**: "What's your primary reason?" (compliance, cost, control?)
- **Discuss**: "Can you use both models in same project?" (Yes! Mix and match)

**Transition**:
> "Today we deploy to ACA. You'll see it's more work, but you get full control."

---

### 09:20-09:45 | ACA Architecture & Bicep (25 min)

**Instructional Method**: Infrastructure as Code walkthrough

**Setup**:
- Share screen with VS Code
- Open `lesson-4-aca-langgraph/solution/`
- Show file tree

#### Section 1: File Structure (5 min)

```
solution/
├── aca.bicep                # ACA infrastructure definition
├── main.py                  # LangGraph agent (same as Module 3)
├── Dockerfile               # Container definition
├── deploy.ps1               # Deployment automation
├── REGISTER.md              # Connected Agent registration guide
└── requirements.txt
```

**Say**:
> "Key difference from Modules 2-3: We define infrastructure with `aca.bicep`."
>
> "Hosted agents: Foundry provisioned infra. Connected: YOU provision with Bicep."

#### Section 2: Bicep Template Walkthrough (15 min)

**Open**: `aca.bicep`

**Show parameters**:
```bicep
@description('Name of the Container App')
param containerAppName string = 'aca-lg-agent'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container image')
param containerImage string

@description('Azure OpenAI endpoint')
param azureOpenAIEndpoint string
```

**Say**:
> "Standard Bicep parameters. We inject container image URL and OpenAI endpoint at deployment."

**Show ACA Environment** (infrastructure foundation):
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

**Narrate**:
> "ACA Environment is like an ECS Cluster—hosts multiple container apps."
>
> "We configure logging to Log Analytics (Azure's CloudWatch equivalent)."

**Show Container App** (the actual agent):
```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'  // Managed Identity
  }
  properties: {
    managedEnvironmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080  // ← Note: Port 8080 (not 8088!)
        transport: 'http'
      }
      secrets: [
        {
          name: 'openai-endpoint'
          value: azureOpenAIEndpoint
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'agent'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'AZURE_OPENAI_ENDPOINT'
              secretRef: 'openai-endpoint'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
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

**Highlight critical differences**:

1. **Port 8080 vs 8088**:
   > "ACA uses FastAPI on port 8080. Foundry Hosted used 8088."
   > "Why? You control the HTTP server now. No Foundry adapter constraints."

2. **Managed Identity (MI)**:
   > "`identity: { type: 'SystemAssigned' }` creates MI for the container."
   > "This MI needs RBAC roles on Azure OpenAI (we'll config later)."

3. **Scaling Rules**:
   > "Define auto-scaling: 1-3 replicas based on concurrent requests."
   > "Foundry Hosted: Microsoft chose scaling. ACA: YOU choose."

4. **Secrets**:
   > "OpenAI endpoint stored as secret, injected as env var."
   > "Sensitive data never in plaintext."

**Show outputs**:
```bicep
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output managedIdentityPrincipalId string = containerApp.identity.principalId
```

**⚠️ CRITICAL: Add RBAC Role Assignment** (show this resource):
```bicep
// Role assignment for Managed Identity to access Azure OpenAI
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerApp.id, 'CognitiveServicesOpenAIUser')
  scope: azureOpenAI  // Reference to your Azure OpenAI resource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')  // Cognitive Services OpenAI User
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

**Say**:
> "Without this role assignment, your container can't call Azure OpenAI—authentication will fail."
>
> "The role 'Cognitive Services OpenAI User' (ID: 5e0bd9bd...) allows the MI to invoke models."
>
> "In production: use least-privilege roles. This role allows model inference only, no management operations."

**Alternative approach** (if Azure OpenAI in different resource group):
> "If OpenAI is elsewhere, assign role post-deployment:"
```powershell
az role assignment create \
  --assignee <managed-identity-principal-id> \
  --role "Cognitive Services OpenAI User" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.CognitiveServices/accounts/<openai-name>
```

**Say**:
> "FQDN is your agent's public URL. We'll use this for Connected Agent registration."
>
> "Managed Identity ID needed for RBAC role assignment (already handled in Bicep above)."

**Interactive (3 min)**:
- **Ask**: "Who's written Bicep or Terraform before?" (gauge familiarity)
- **Ask**: "What's the Azure equivalent of a cloud security group?" (answer: NSG, but ACA abstracts it)

#### Section 3: FastAPI Server Implementation (5 min)

**Open**: `main.py` (show relevant section)

**Contrast with Module 3**:

**Module 3 (Foundry Hosted)**:
```python
# Dockerfile CMD:
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
# Used Foundry's adapter
```

**Module 4 (ACA Connected)**:
```python
# main.py has FastAPI server
from fastapi import FastAPI, Request
from langgraph.graph import StateGraph

app = FastAPI()
graph = build_langgraph()  # Your graph definition

@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    message = body.get("message")
    
    # Invoke LangGraph
    result = graph.invoke({"messages": [("user", message)]})
    
    return {"response": result["messages"][-1][1]}

# Dockerfile CMD:
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Say**:
> "Key change: YOU implement the HTTP server. No adapter needed."
>
> "Why? ACA doesn't care about Foundry protocols. You expose any API you want."
>
> "When we register as Connected Agent, Foundry learns your API schema."

**Transition**:
> "Let's deploy this infrastructure and see it live."

---

### 09:45-10:25 | Deploy to ACA (40 min)

**Instructional Method**: Automated deployment with validation

#### Checkpoint 1: Pre-Deployment Configuration (8 min)

**Student Task**:
```powershell
cd lesson-4-aca-langgraph/aca-agent

# Review Bicep parameters (no changes needed by default)
notepad aca.bicep

# Verify Azure CLI logged in
az account show

# Load environment from Module 0
$rgName = (Get-Content ..\..\prereq\setup-output.txt | Where-Object {$_ -match "AZURE_RESOURCE_GROUP"}).Split("=")[1]
$acrName = (Get-Content ..\..\prereq\setup-output.txt | Where-Object {$_ -match "AZURE_CONTAINER_REGISTRY"}).Split("=")[1]

echo "Resource Group: $rgName"
echo "ACR: $acrName"
```

**Instructor Facilitation**:
- "Everyone see their resource group name? Good."
- "If any errors loading vars, paste setup-output.txt content in chat"

**Success Criteria**: ✅ Environment variables loaded

---

#### Checkpoint 2: Execute Deployment Script (25 min)

**Student Task**:
```powershell
# Run deployment (builds container + deploys ACA)
.\deploy.ps1
```

**Expected Output** (annotate on screen):
```powershell
🔨 [1/5] Building container image in ACR...
⏳ Est. time: 8-10 minutes

Uploading context...
Step 1/8 : FROM python:3.11-slim
Step 2/8 : WORKDIR /app
...
✅ Container built: acrworkshopxyz.azurecr.io/aca-lg-agent:latest

📦 [2/5] Deploying ACA infrastructure with Bicep...
⏳ Est. time: 5-7 minutes

Creating deployment...
 ⠋ Resource: Microsoft.App/managedEnvironments (deploying)
 ⠋ Resource: Microsoft.App/containerApps (waiting)
 ⠋ Resource: Microsoft.OperationalInsights/workspaces (succeeded)
 
✅ Deployment succeeded!

🔐 [3/5] Configuring Managed Identity RBAC...
Assigning 'Cognitive Services User' role to container MI...
✅ Role assigned

🌐 [4/5] Testing agent endpoint...
Agent FQDN: aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io
Health check: https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io/health

Response: {"status": "healthy", "agent": "financial-advisor-lg"}
✅ Agent is live!

🧪 [5/5] Testing chat endpoint...
POST https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io/chat
Body: {"message": "What is the price of AAPL?"}

Response: {"response": "The current price of AAPL is $175.50 USD."}
✅ Agent responding correctly!

🎉 Deployment complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent URL: https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io
Next Step: Register as Connected Agent in Foundry (see REGISTER.md)
```

**Instructor Facilitation** (during 15-20 min wait):

**Activity 1: Architecture Diagram Review** (10 min)
- Display reference architecture slide
- Trace request flow: User → Foundry → APIM → ACA → OpenAI
- Highlight components: ACA Environment, Container App, Managed Identity, Log Analytics

**Activity 2: Cost Comparison Discussion** (5 min)
- **Question**: "How much does ACA cost vs Foundry Hosted?"
- **Provide data**:
  - Foundry Hosted: ~$20-40/month (estimated, varies by Foundry pricing)
  - ACA: ~$0.04/vCPU-hour + $0.004/GB-hour = ~$15-30/month for 1 replica
- **Discussion**: "When does ACA save money?" (high utilization, reserved capacity)

**Activity 3: Managed Identity Deep Dive** (5 min)
- **Show slide**: Managed Identity flow
  1. Container requests token from Azure metadata endpoint
  2. Azure verifies container identity (via system-assigned MI)
  3. Token issued (scoped to Cognitive Services)
  4. Container uses token to call Azure OpenAI
- **Compare**: "Like a task execution role in other container platforms, but with no credential management"

**Monitor Progress**:
- "If you see '✅ Deployment complete', thumbs up in chat"
- "If deployment fails, share error message immediately"

**Common Errors**:

| Error | Cause | Fix |
|-------|-------|-----|
| "Quota exceeded for Managed Environments" | Subscription limit | Request quota increase OR delete unused ACA envs |
| "Container image not found" | ACR build failed | Check ACR build logs: `az acr task logs` |
| "Role assignment failed" | Insufficient permissions | Ensure user has "User Access Administrator" role |
| "Health check timeout" | Container not starting | Check ACA logs: `az containerapp logs show` |

**Success Criteria**: ✅ 80%+ students see "Deployment complete" message

---

#### Checkpoint 3: Portal Verification (7 min)

**Instructor demonstrates**, students follow:

1. **Navigate to Azure Portal** → Container Apps
2. **Find your Container App**: `aca-lg-agent-<yourname>`
3. **Overview tab**: Verify status = "Running"
4. **Ingress tab**: Note FQDN (public URL)
5. **Identity tab**: Verify System Assigned MI enabled
6. **Logs tab**: View application logs (real-time)

**Interactive**:
- "Click 'Logs' and run this query:"
  ```kusto
  ContainerAppConsoleLogs_CL
  | where TimeGenerated > ago(10m)
  | project TimeGenerated, Log_s
  | order by TimeGenerated desc
  ```
- "You should see FastAPI startup logs and recent requests"

**Say**:
> "ACA portal is powerful. You have full visibility into container health, metrics, logs."
>
> "Unlike Foundry Hosted, you can SSH into containers, adjust resource limits, configure custom domains—full control."

**Success Criteria**: ✅ All students can see their ACA in portal with Running status

---

### 10:25-10:45 | Connected Agent Registration (20 min)

**Instructional Method**: Guided CLI registration

**Objective**: Register ACA-deployed agent in Foundry Control Plane

#### Step 1: Understand Connected Agent Concept (5 min)

**Slide: Connected Agent Benefits**

1. **Governance**: Foundry tracks all agents (even external ones)
2. **Unified Monitoring**: Telemetry flows into Foundry dashboard
3. **Access Control**: Use Foundry RBAC for ACA agent access
4. **Discovery**: Users find connected agents in Foundry catalog
5. **AI Gateway**: Optional routing through APIM (rate limiting, auth)

**Say**:
> "Connected Agent = 'Hey Foundry, I have an agent running elsewhere. Please manage it.'"
>
> "Foundry doesn't control execution, but it tracks usage, applies policies, routes requests."

#### Step 2: Registration via Foundry CLI (10 min)

**Instructor demonstrates** (students follow):

```powershell
# Get agent FQDN from deployment output
$agentFqdn = "aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io"

# Register as Connected Agent
az cognitiveservices connectedagent create \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --foundry-project $foundryProjectName \
  --endpoint "https://$agentFqdn" \
  --description "LangGraph agent deployed on ACA" \
  --api-spec openapi.json  # Optional: OpenAPI spec for your /chat endpoint
```

**Expected Output**:
```json
{
  "id": "/subscriptions/.../connectedAgents/financial-advisor-aca",
  "name": "financial-advisor-aca",
  "type": "Microsoft.CognitiveServices/connectedAgents",
  "properties": {
    "endpoint": "https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io",
    "status": "Active",
    "registeredAt": "2026-02-14T10:35:00Z"
  }
}
```

**Say**:
> "That's it! Agent is now visible in Foundry Control Plane."
>
> "Foundry will proxy requests to your ACA endpoint and collect telemetry."

#### Step 3: Verify in Foundry Portal (5 min)

**Instructor guides**:
1. Open Foundry portal
2. Navigate to "Agents" section
3. Filter: Show "Connected Agents"
4. Find "financial-advisor-aca"
5. Click to see details:
   - External Endpoint: Your ACA FQDN
   - Status: Active
   - Telemetry: Request count (will populate after testing)

**Interactive**:
- "Screenshot your Connected Agent in portal"
- "Share in chat"

**Say**:
> "Notice: Unlike Hosted Agents, you can't edit configuration in portal. It's read-only—agent lives outside Foundry."

**Success Criteria**: ✅ All students see Connected Agent in Foundry portal

---

### 10:45-11:00 | Testing & Validation (15 min)

**Instructional Method**: Multi-path testing

#### Test Path 1: Direct ACA Call (5 min)

**Test bypassing Foundry**:
```powershell
# Direct HTTP call to ACA
$agentFqdn = "aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io"
$body = @{message = "What is the market sentiment for VALE3?"} | ConvertTo-Json

Invoke-RestMethod -Uri "https://$agentFqdn/chat" -Method Post -Body $body -ContentType "application/json"
```

**Expected Response**:
```json
{
  "response": "VALE3 has negative market sentiment (75% confidence) due to commodity price decline."
}
```

**Say**:
> "This proves agent works independently. No Foundry involved."

#### Test Path 2: Via Foundry Proxy (5 min)

**Test through Foundry Control Plane**:
```powershell
# Call via Foundry (uses AI Gateway)
az cognitiveservices agent invoke \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --query "What is the market sentiment for VALE3?"
```

**Expected**: Same response, but routed through Foundry

**Say**:
> "Foundry proxies request to your ACA endpoint. You get governance benefits + direct access flexibility."

#### Test Path 3: Check Telemetry (5 min)

**View request metrics in Foundry**:
1. Foundry portal → Agents → financial-advisor-aca
2. Metrics tab:
   - Total requests: 2 (direct + proxy)
   - Avg latency: ~300ms
   - Success rate: 100%

**Say**:
> "Foundry tracks usage even for Connected Agents. Useful for chargeback, quotas, cost allocation."

**Interactive Discussion**:
- **Ask**: "When would you use direct access vs Foundry proxy?"
- Answers:
  - Direct: Internal tools, high throughput, lower latency
  - Proxy: External access, need rate limiting, governance
- **Key**: Connected Agents give you BOTH options

**Success Criteria**: ✅ All students successfully tested both paths

---

## 📋 Instructor Checklist

### Before Module 4:
- [ ] All students completed Module 3 (LangGraph agent deployed)
- [ ] Slides loaded (deployment models, architecture diagrams)
- [ ] Bicep template tested (verify it deploys cleanly)
- [ ] ACA quota verified (ensure subscription can create environments)
- [ ] Connected Agent registration process tested

### During Module 4:
- [ ] Monitor ACA deployments (expect 15-20 min total)
- [ ] Track Bicep deployment errors (capture for troubleshooting)
- [ ] Verify Managed Identity role assignments succeed
- [ ] Confirm Connected Agent registration works for 90%+
- [ ] Validate both test paths (direct + proxy) functional

### After Module 4:
- [ ] Update `7-DELIVERY-LOG.md` with ACA-specific issues
- [ ] Document common Bicep errors
- [ ] Share cost comparison data (Hosted vs Connected)
- [ ] Verify all students ready for Module 5 (need working ACA agent)

---

## 🎓 Pedagogical Notes

### Learning Theory Applied:
- **Constructivism**: Build infrastructure from scratch (not just consume)
- **Comparative Analysis**: Hosted vs Connected (build decision-making schema)
- **Authentic Task**: Real production deployment scenario
- **Progressive Complexity**: Declarative → Hosted → Connected (scaffolding)

### Cognitive Load Management:
- **Intrinsic**: Bicep introduces new complexity (managed carefully)
- **Extraneous**: Automate deployment script (reduce manual steps)
- **Germane**: Focus on architectural differences (transferable knowledge)

---

## 🔧 Troubleshooting Playbook

### Issue: Bicep Deployment Fails with "ManagedEnvironment quota exceeded"
**Diagnosis**: Subscription limit reached  
**Fix**: Request quota increase or deploy to different region
```powershell
az provider show --namespace Microsoft.App --query "resourceTypes[?resourceType=='managedEnvironments'].locations"
# Try region with availability
```

### Issue: Container App Stuck in "Provisioning" State
**Diagnosis**: Image pull failure or startup timeout  
**Fix**: Check logs
```powershell
az containerapp logs show --name aca-lg-agent --resource-group $rgName
# Look for "ImagePullBackOff" or startup errors
```

### Issue: Managed Identity Role Assignment Fails
**Diagnosis**: User lacks "User Access Administrator" role  
**Fix**: Ask subscription admin to grant role OR use service principal
```powershell
az role assignment create \
  --assignee <your-user-id> \
  --role "User Access Administrator" \
  --scope "/subscriptions/<subscription-id>"
```

### Issue: Agent Returns 500 Error on /chat
**Diagnosis**: Azure OpenAI endpoint misconfigured  
**Fix**: Verify env var and MI permissions
```powershell
# Check container env vars
az containerapp show --name aca-lg-agent --resource-group $rgName \
  --query "properties.template.containers[0].env"

# Verify MI has Cognitive Services User role
az role assignment list --assignee <mi-principal-id> --all
```

---

## 📊 Success Metrics

**Module Completion Indicators**:
- ✅ 80%+ students deploy ACA successfully
- ✅ 90%+ register Connected Agent in Foundry
- ✅ 85%+ test both direct and proxy paths successfully
- ✅ 100% understand difference between Hosted and Connected

**Learning Evidence**:
- ✅ Students can explain: When to use Connected vs Hosted
- ✅ Students can deploy: Bicep infrastructure for agent
- ✅ Students can configure: Managed Identity with RBAC

---

## 📚 Resources for Students

**Documentation Links**:
- 📘 Azure Container Apps documentation
- 📘 Bicep language reference
- 📘 Foundry Connected Agents guide
- 🎥 Video: "Deploying Agents to ACA" (10 min)

**Self-Paced Practice**:
- **Challenge 1**: Configure custom domain for ACA agent
- **Challenge 2**: Implement VNet integration (private ACA)
- **Challenge 3**: Deploy multi-agent system on ACA

---

**Script Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Reviewed by**: (Pending)  
**Status**: Draft - Awaiting approval
