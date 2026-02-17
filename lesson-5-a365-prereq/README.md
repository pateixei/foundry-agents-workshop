# Lesson 5 - Microsoft Agent 365 Complete Setup

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Configure** Agent 365 (A365) CLI and authentication for cross-tenant scenarios
2. **Register** Agent Blueprint in Microsoft 365 Entra ID
3. **Understand** cross-tenant architecture (Azure Tenant A + M365 Tenant B)
4. **Publish** agent Blueprint to M365 Admin Center for admin approval
5. **Create** agent instances in Microsoft Teams (personal and shared)
6. **Manage** the full Agent 365 development lifecycle (config → blueprint → publish → instances)

---

## Overview

This lesson covers the complete setup and deployment of agents to **Microsoft Agent 365** (A365), from configuration to publishing and creating agent instances in Microsoft 365.

> **IMPORTANT**: Agent 365 requires participation in the [Frontier preview program](https://adoption.microsoft.com/copilot/frontier-program/).

---

## Architecture: Cross-Tenant Flow

```
User in M365 Tenant (Tenant B)
    ↓ (invokes agent via Teams)
Microsoft Graph (Tenant B)
    ↓ (authenticates using Agent User)
Agent Blueprint (Tenant B Entra ID)
    ↓ (routes request to)
Messaging Endpoint (ACA in Tenant A)
    ↓ (agent executes)
Response flows back through Graph
```

> **Key insight**: Agent identity lives in M365 Tenant, but agent code runs in Azure Tenant. A365 CLI bridges them by registering the endpoint URL in M365's Entra ID.

---

## A365 Development Lifecycle

| Step | Phase | Where | This Lesson? |
|------|-------|-------|:------------:|
| 1 | Build and run agent | Azure Tenant A | ❌ (Lesson 4) |
| 2 | Setup A365 config | M365 Tenant B | ✅ |
| 3 | Setup agent blueprint | M365 Tenant B | ✅ |
| 4 | Deploy infrastructure | Azure Tenant A | ❌ (Lesson 4) |
| 5 | Publish to M365 admin center | M365 Tenant B | ✅ |
| 6 | Create agent instances | M365 (Teams/Outlook) | ✅ |

---

## Context: Cross-Tenant Scenario

In this workshop, we have a specific scenario:

| Resource | Tenant | Description |
|---------|--------|-----------|
| **Azure** (Foundry, ACA, ACR) | Tenant A (Azure) | Where the agents are deployed |
| **Microsoft 365** (Teams, Outlook) | Tenant B (M365) | Where end users interact with the agents |

The Agent 365 CLI uses **a single `tenantId`** in the `a365.config.json`. This tenant is the **Microsoft 365 tenant** (Tenant B), because that's where:
- The Agent Blueprint is registered in Entra ID
- The Agent User (service principal) is created
- The agent appears in users' Teams and Outlook
- Microsoft Graph permissions are granted

The Azure subscription (in Tenant A) is referenced separately in the config's `subscriptionId` field. However, `a365 setup` creates Azure resources (Resource Group, App Service Plan, Web App) **in the logged-in tenant's subscription**.

### Approach: `needDeployment: false`

Since the agent is already deployed in ACA (Tenant A, lesson 4), we don't need the A365 CLI to create Azure infrastructure. We'll use `needDeployment: false` so the CLI only:

1. **Registers the Agent Blueprint** in M365 Tenant's Entra ID (Tenant B)
2. **Configures the messaging endpoint** pointing to ACA in Tenant A
3. **Creates the agent identity** (service principal) in M365 Tenant

This means:

- `az login` must authenticate to **M365 Tenant** (Tenant B)
- Custom Client App Registration must be done in **Tenant B** (M365)
- CLI user needs roles in **Tenant B**: Global Administrator, Agent ID Administrator, or Agent ID Developer
- **No Azure subscription is needed** in M365 Tenant for creating infra (we won't create any Azure resources via CLI)
- Azure infra fields in `a365.config.json` (`resourceGroup`, `appServicePlanName`, etc.) can contain placeholder values - they won't be used

---

## Agent 365 Development Cycle

The complete cycle has 6 steps. **In this lesson we cover steps 2-6 (complete A365 setup)**:

```
1. Build and run agent          <-- already done (lesson 4, ACA in Tenant A)
2. Setup Agent 365 config       <-- THIS LESSON
3. Setup agent blueprint        <-- THIS LESSON
4. Deploy                       <-- already done (lesson 4, needDeployment: false)
5. Publish to M365 admin center <-- THIS LESSON
6. Create agent instances       <-- THIS LESSON
```

Reference: [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)

---

## Prerequisite 0 - Frontier Preview Program

Agent 365 requires access to the Frontier preview program:

1. Go to [https://adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/)
2. Sign in with your **M365 Tenant** account (Tenant B)
3. Request access to the program
4. Wait for approval (may take a few days)

---

## Prerequisite 1 - Install .NET SDK

The Agent 365 CLI is distributed as a .NET tool:

```powershell
# Check if .NET is installed
dotnet --version
# Recommended: .NET 8.0+

# If not installed, download from:
# https://dotnet.microsoft.com/download
```

---

## Prerequisite 2 - Install Agent 365 CLI

```powershell
# Install the CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify installation
a365 -h

# To update in the future:
dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease
```

> **Note**: Always use `--prerelease` while the CLI is in preview.
> NuGet: [Microsoft.Agents.A365.DevTools.Cli](https://www.nuget.org/packages/Microsoft.Agents.A365.DevTools.Cli)

---

## Prerequisite 3 - Custom Client App Registration (in M365 Tenant)

The CLI needs an app registration in **M365 Tenant's** Entra ID to authenticate.

### 3.1 - Register the application

1. Go to the [Microsoft Entra admin center](https://entra.microsoft.com/) of **Tenant B (M365)**
2. Navigate to **App registrations > New registration**
3. Fill in:
   - **Name**: `a365-workshop-cli`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**: Select `Public client/native (mobile & desktop)` and enter `http://localhost:8400/`
4. Click **Register**

### 3.2 - Configure additional Redirect URI

1. On the app's **Overview** page, copy the **Application (client) ID** (GUID format)
2. Go to **Authentication (preview)** > **Add Redirect URI**
3. Select **Mobile and desktop applications** and add:
   ```
   ms-appx-web://Microsoft.AAD.BrokerPlugin/{YOUR-CLIENT-ID}
   ```
   (replace `{YOUR-CLIENT-ID}` with the copied Application (client) ID)
4. Click **Configure**

### 3.3 - Configure API Permissions

> **IMPORTANT**: Use **Delegated permissions** (NOT Application permissions).

#### Option A - Via Entra admin center (if beta permissions are visible)

1. In the app registration, go to **API permissions > Add a permission**
2. Select **Microsoft Graph > Delegated permissions**
3. Add the 5 permissions:

| Permission | Description |
|-----------|-----------|
| `AgentIdentityBlueprint.ReadWrite.All` | Manage Agent Blueprints (beta) |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Update Blueprint's inherited permissions (beta) |
| `Application.ReadWrite.All` | Create and manage applications |
| `DelegatedPermissionGrant.ReadWrite.All` | Grant permissions for blueprints |
| `Directory.Read.All` | Read directory data |

4. Click **Grant admin consent for [Your Tenant]**
5. Verify that all show green checkmarks

#### Option B - Via Microsoft Graph API (if beta permissions are NOT visible)

If `AgentIdentityBlueprint.*` permissions don't appear in the portal, use Graph Explorer:

1. Go to [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
2. Sign in with M365 Tenant admin account

**Get the app's Service Principal ID:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{YOUR-CLIENT-ID}'&$select=id
```
The returned `id` is the `SP_OBJECT_ID`.

If it returns empty, create the service principal:
```http
POST https://graph.microsoft.com/v1.0/servicePrincipals
Body: { "appId": "{YOUR-CLIENT-ID}" }
```

**Get the Graph Resource ID:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=id
```
The returned `id` is the `GRAPH_RESOURCE_ID`.

**Create the delegated permissions (with automatic admin consent):**
```http
POST https://graph.microsoft.com/v1.0/oauth2PermissionGrants
Body:
{
  "clientId": "<SP_OBJECT_ID>",
  "consentType": "AllPrincipals",
  "principalId": null,
  "resourceId": "<GRAPH_RESOURCE_ID>",
  "scope": "Application.ReadWrite.All Directory.Read.All DelegatedPermissionGrant.ReadWrite.All AgentIdentityBlueprint.ReadWrite.All AgentIdentityBlueprint.UpdateAuthProperties.All"
}
```

> **WARNING**: If you used Option B, **DO NOT** click "Grant admin consent" in the Entra portal afterwards. The portal doesn't see beta permissions and will overwrite what you created via API.

### 3.4 - Note the Client ID

Save the **Application (client) ID** - you'll need it in the next step.

```
Application (client) ID: ________-____-____-____-____________
```

---

## Step 2 - Setup Agent 365 Config

Since we use `needDeployment: false`, we will **not** run the interactive wizard `a365 config init` (it tries to list Azure subscriptions and may fail without a subscription in M365 Tenant). Instead, we'll create the `a365.config.json` manually.

### 4.1 - Authenticate to M365 Tenant

```powershell
# Login to M365 Tenant (Tenant B)
az login --tenant <TENANT-M365-ID>

# Verify we're in the correct tenant
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> `az login` is necessary for the CLI to authenticate to M365 Tenant's Entra ID. We DO NOT need an Azure subscription here.

### 4.2 - Create a365.config.json manually

Navigate to lesson 5 directory and create the file:

```powershell
cd lesson-5-a365-prereq
```

Create the `a365.config.json` file with the following content:

```json
{
  "$schema": "./a365.config.schema.json",
  "tenantId": "<TENANT-M365-ID>",
  "clientAppId": "<CLIENT-APP-ID-FROM-STEP-3>",
  "agentBlueprintDisplayName": "Financial Market Agent Blueprint",
  "agentIdentityDisplayName": "Financial Market Agent Identity",
  "agentUserPrincipalName": "fin-market-agent@<tenant-m365>.onmicrosoft.com",
  "agentUserDisplayName": "Financial Market Agent",
  "managerEmail": "your-email@<tenant-m365>.com",
  "agentUserUsageLocation": "BR",
  "deploymentProjectPath": ".",
  "needDeployment": false,
  "messagingEndpoint": "https://<your-aca-app>.<aca-env-hash>.<region>.azurecontainerapps.io/api/messages",
  "agentDescription": "Financial market agent (LangGraph on ACA) - A365 Workshop"
}
```

**Important fields:**

| Field | Value | Explanation |
|-------|-------|------------|
| `tenantId` | M365 Tenant GUID | Where the blueprint is registered in Entra ID |
| `clientAppId` | GUID from step 3.4 | App registration for CLI authentication |
| `needDeployment` | `false` | **Does not create Azure infra** - agent already runs in ACA |
| `messagingEndpoint` | ACA URL + `/api/messages` | Endpoint that A365 uses to send messages to the agent |
| `agentUserPrincipalName` | `name@tenant.onmicrosoft.com` | Agent's UPN in Entra (M365 Tenant domain) |
| `managerEmail` | Email in M365 Tenant | Manager responsible for the agent |

> **Note**: Azure infra fields (`subscriptionId`, `resourceGroup`, `appServicePlanName`, `webAppName`) were **omitted** because `needDeployment: false`. If the CLI requires these fields, add placeholder values.

### 4.3 - Verify the configuration

```powershell
# Verify the file exists
Test-Path a365.config.json
# Expected: True

# Display the configuration
a365 config display
```

**Verification checklist:**
- [ ] `tenantId` is the M365 Tenant GUID (NOT Azure)
- [ ] `clientAppId` is the App Registration from step 3
- [ ] `needDeployment` is `false`
- [ ] `messagingEndpoint` points to ACA from lesson 4
- [ ] `agentUserPrincipalName` uses the domain `@<tenant-m365>.onmicrosoft.com`
- [ ] `managerEmail` uses the M365 Tenant domain

---

## Step 3 - Setup Agent Blueprint

The blueprint defines the agent's identity and permissions in Entra ID. With `needDeployment: false`, the CLI **skips Azure infra creation** and focuses only on identity registration.

### 5.1 - Execute the setup

```powershell
# Execute the complete setup (inside lesson-5-a365-prereq/)
a365 setup all
```

With `needDeployment: false`, the command performs **only**:

1. **Registers the Agent Blueprint** in M365 Tenant's Entra ID:
   - Creates the Agent Identity Blueprint (app registration)
   - Creates the associated service principal
   - Configures the agent identity (`agentUserPrincipalName`)

2. **Configures API Permissions**:
   - Microsoft Graph API scopes
   - Messaging Bot API permissions
   - Inherited permissions for future instances

3. **Registers the messaging endpoint**:
   - Associates the `messagingEndpoint` (ACA from lesson 4) to the blueprint

4. **Generates `a365.generated.config.json`**:
   - Blueprint IDs, service principal, client secret, endpoint

> **Note**: The CLI opens browser windows for admin consent. Complete all flows. Takes 3-5 minutes.
>
> **No Azure infra will be created** (Resource Group, App Service Plan, Web App). The agent already runs in ACA of Tenant A.

### 5.2 - Verify the setup

```powershell
# Display generated configuration
a365 config display -g
```

Expected output (key fields):
```json
{
  "agentBlueprintId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "agentBlueprintObjectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "agentBlueprintServicePrincipalObjectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "agentBlueprintClientSecret": "xxx~xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "botMessagingEndpoint": "https://<your-aca-app>.<aca-env-hash>.<region>.azurecontainerapps.io/api/messages",
  "completed": true
}
```

```powershell
# Verify the generated file exists
Test-Path a365.generated.config.json
# Expected: True
```

**Verifications in Entra admin center** (M365 Tenant):
- [ ] App Registration exists (search by `agentBlueprintId`)
- [ ] Corresponding Enterprise Application exists
- [ ] API permissions show green checkmarks ("Granted for [Your Tenant]")
- [ ] Permissions include Microsoft Graph and Messaging Bot API
- [ ] Agent Identity visible in [Entra Agent Registry](https://entra.microsoft.com/#view/Microsoft_AAD_IAM/AgentIdentitiesListBlade)

---

## Step 5 - Publish to M365 Admin Center

After setting up the blueprint, the agent must be published to the M365 admin center so tenant administrators can make it available to users.

### 5.1 - Understanding Agent Publishing

Publishing makes the agent available in the **Microsoft 365 admin center** under **Integrated apps**. This allows:
- **Tenant administrators** to review and approve the agent
- **Deployment controls** to specific users, groups, or the entire organization
- **Centralized management** of agent availability and permissions

### 5.2 - Publish the Agent

```powershell
# Publish the agent blueprint to M365 admin center
a365 publish
```

The command performs these actions:

1. **Packages the agent manifest** with blueprint metadata
2. **Submits to M365 admin center** for tenant admin review
3. **Creates an app listing** in the Integrated apps catalog
4. **Generates publish artifacts** in `a365.generated.config.json`

Expected output:
```
Publishing agent to Microsoft 365...
✓ Agent blueprint validated
✓ Manifest packaged
✓ Submitted to M365 admin center
✓ Agent available for admin approval

Agent publish details:
  Agent Name: Financial Market Agent
  Blueprint ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Status: Pending Admin Approval
  Admin Center URL: https://admin.microsoft.com/AdminPortal/Home#/Settings/IntegratedApps
```

### 5.3 - Admin Approval (M365 Admin Center)

After publishing, a **tenant administrator** must approve the agent:

1. Go to [M365 Admin Center](https://admin.microsoft.com/)
2. Navigate to **Settings > Integrated apps**
3. Find **Financial Market Agent** in the list
4. Click on the agent to review:
   - Blueprint permissions (Microsoft Graph, etc.)
   - Messaging endpoint
   - Publisher information
5. Click **Deploy** and configure:
   - **Users**: Specific users, groups, or entire organization
   - **Deployment type**: Optional or Required
6. Click **Next** and then **Finish deployment**

> **Note**: Only Global Administrators can deploy integrated apps in M365 admin center.

### 5.4 - Verify Publishing Status

```powershell
# Check agent publishing status
a365 publish status

# Expected output when approved:
# Status: Deployed
# Availability: Enabled for selected users
# Deployed to: 15 users in "Sales Team" group
```

**Verification checklist**:
- [ ] Agent appears in M365 admin center > Integrated apps
- [ ] Status shows "Deployed" or "Available"
- [ ] Deployment scope configured (users/groups)
- [ ] Permissions granted by admin

---

## Step 6 - Create Agent Instances

After publishing and admin approval, users can create **agent instances** in Teams and Outlook. Each instance is a personal or shared bot that users interact with.

### 6.1 - Understanding Agent Instances

- **Agent Blueprint**: The template/identity registered in Entra ID (Step 3)
- **Agent Instance**: An active bot created from the blueprint, appearing in Teams/Outlook
- **Instance Types**:
  - **Personal**: Individual user's private agent
  - **Shared**: Team or group agent accessible by multiple users

### 6.2 - Create an Instance via CLI

```powershell
# Create a personal agent instance
a365 create-instance `
  --name "My Market Agent" `
  --type personal `
  --deploy-to-teams `
  --deploy-to-outlook

# Create a shared team instance
a365 create-instance `
  --name "Sales Team Market Agent" `
  --type shared `
  --team-id "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
  --deploy-to-teams
```

**Parameters**:
| Parameter | Description | Required |
|-----------|-------------|:--------:|
| `--name` | Display name for the instance | Yes |
| `--type` | `personal` or `shared` | Yes |
| `--deploy-to-teams` | Make available in Teams | No |
| `--deploy-to-outlook` | Make available in Outlook | No |
| `--team-id` | Teams team ID (for shared instances) | For shared |
| `--description` | Instance description | No |

Expected output:
```
Creating agent instance...
✓ Instance created successfully
✓ Deployed to Microsoft Teams
✓ Deployed to Outlook

Instance details:
  Name: My Market Agent
  Instance ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Type: Personal
  Status: Active
  Teams App ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Outlook Add-in ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 6.3 - Create Instance via Teams App

Users can also install agent instances directly from Teams:

1. Open **Microsoft Teams**
2. Click **Apps** in the left sidebar
3. Search for **"Financial Market Agent"** (or browse **Built by your org**)
4. Click **Add** to create a personal instance
5. Or click **Add to a team** to create a shared instance

The agent will appear in:
- **Teams**: Chat list or Team channels
- **Outlook**: Add-ins panel (if deployed)

### 6.4 - Manage Instances

```powershell
# List all instances
a365 list-instances

# Get instance details
a365 get-instance --instance-id <instance-id>

# Delete an instance
a365 delete-instance --instance-id <instance-id>

# Update instance settings
a365 update-instance `
  --instance-id <instance-id> `
  --name "Updated Name" `
  --description "New description"
```

### 6.5 - Test the Agent Instance

Once the instance is created, test it in Teams:

1. **Open Teams** and find the agent in your chat list
2. **Send a message**: `What is the PETR4 stock price?`
3. **Verify response**: The agent should call your ACA endpoint and return market data
4. **Check telemetry**: View requests in Azure Monitor (ACA logs)

**Expected flow**:
```
User (Teams) 
  → M365 Agent Service 
  → Messaging Endpoint (ACA) 
  → LangGraph Agent 
  → Azure OpenAI (gpt-4.1) 
  → Response → User
```

### 6.6 - Instance Lifecycle

| State | Description | Actions Available |
|-------|-------------|-------------------|
| **Active** | Instance is running and available | Chat, update settings, suspend |
| **Suspended** | Temporarily disabled | Resume, delete |
| **Deleted** | Permanently removed | None (create new) |

```powershell
# Suspend an instance
a365 suspend-instance --instance-id <instance-id>

# Resume a suspended instance
a365 resume-instance --instance-id <instance-id>
```

---

## Summary of artifacts generated

At the end of this lesson, you will have:

| Artifact | Location | Description |
|----------|-------------|-----------|
| `a365.config.json` | `lesson-5-a365-prereq/` | Manual configuration (created by hand, no wizard) |
| `a365.generated.config.json` | `lesson-5-a365-prereq/` | Configuration generated by CLI (IDs, secrets, publish details) |
| Custom Client App | Entra ID (M365 Tenant) | App registration for CLI authentication |
| Agent Blueprint | Entra ID (M365 Tenant) | Agent identity + permissions |
| Service Principal | Entra ID (M365 Tenant) | Agent identity for authentication |
| Published Agent | M365 Admin Center | Agent available in Integrated apps catalog |
| Agent Instances | Teams/Outlook | Active bots users can interact with |

> **What was NOT created**: No Azure resources (Resource Group, App Service Plan, Web App). The agent continues running in ACA of Tenant A (lesson 4) and A365 only points to it via `messagingEndpoint`.

---

## Troubleshooting

### Steps 2-3 (Config & Blueprint)

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| `az login` doesn't show subscription | Wrong tenant | Use `az login --tenant <TENANT-M365-ID>` |
| `a365 config init` fails listing subscriptions | No subscription in M365 Tenant | Don't use the wizard. Create `a365.config.json` manually (section 4.2) |
| CLI requires Azure infra fields | Schema validation | Add placeholder fields: `"subscriptionId": "00000000-0000-0000-0000-000000000000"` |
| Invalid Client App ID | App ID vs Object ID | Verify you used Application (client) ID, not Object ID |
| Beta permissions not visible | AgentIdentityBlueprint.* in beta | Use Option B (Graph API) to add permissions |
| Admin consent fails | No admin role | Ask M365 Tenant admin to complete step 3.3 |
| `a365 setup` fails with permissions | Insufficient role | Need Global Admin, Agent ID Admin, or Agent ID Developer |
| Blueprint doesn't appear in Entra | Incomplete setup | Run `a365 setup all` again |
| Endpoint not registered | needDeployment=false without messagingEndpoint | Run `a365 setup blueprint --endpoint-only` |

### Step 5 (Publish)

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| `a365 publish` fails with 403 | Insufficient permissions | Ensure CLI user has Agent ID Admin or Global Admin role |
| Agent not in admin center | Publish incomplete | Run `a365 publish status` to check, retry `a365 publish` |
| Admin can't find agent | Wrong tenant | Verify admin is logged into M365 Tenant (Tenant B) |
| Deployment fails in admin center | Permission issues | Review and grant all requested Graph permissions |
| Agent shows "Blocked" | Tenant policies | Check M365 tenant policies for third-party apps |

### Step 6 (Create Instances)

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| `a365 create-instance` fails | Agent not published/approved | Ensure step 5 is complete and admin approved |
| Instance not in Teams | Deployment scope | Verify user is in deployment scope configured in admin center |
| Agent doesn't respond | Endpoint unreachable | Check ACA is running: `az containerapp show --name aca-lg-agent` |
| 404 from messaging endpoint | Wrong endpoint path | Verify endpoint in `a365.config.json` includes `/api/messages` |
| Agent responds with error | Azure OpenAI access | Check ACA managed identity has RBAC on Foundry OpenAI |
| Slow responses | Cold start | ACA may be scaling from 0 replicas, subsequent calls will be faster |
| Instance not in Outlook | Not deployed to Outlook | Use `--deploy-to-outlook` flag when creating instance |

---

## Next steps

With the complete A365 setup done, you can now:

- **Monitor agent usage** in Azure Monitor and M365 admin center analytics
- **Update the agent** by deploying new versions to ACA and updating the messaging endpoint
- **Scale deployment** to more users, groups, or the entire organization
- **Integrate advanced features** like proactive notifications, adaptive cards, and SSO
- **Monitor compliance** and data governance through M365 admin center reports

### Advanced Topics (Beyond Workshop)

- **Proactive Notifications**: Send messages from agent to users without user initiation
- **Adaptive Cards**: Rich interactive UI in Teams/Outlook messages
- **Single Sign-On (SSO)**: Seamless authentication with user's M365 identity
- **Multi-language Support**: Localized agent responses
- **Analytics & Telemetry**: Detailed usage tracking and performance metrics
- **Lifecycle Management**: Automated testing, staging, and production deployments

---

## ❓ Frequently Asked Questions

**Q: Why do we use `needDeployment: false` instead of letting A365 create infrastructure?**
A: Our agent is already deployed to ACA (Lesson 4). A365 only needs to register the blueprint identity in M365 Entra ID and point to the existing ACA endpoint. Setting `needDeployment: true` would create duplicate App Service infrastructure.

**Q: Can Azure Tenant (A) and M365 Tenant (B) be the same tenant?**
A: Yes! Single-tenant is simpler. The cross-tenant scenario is common in enterprises that separate Azure subscriptions from M365 for governance, cost allocation, or acquisition history.

**Q: What if `AgentIdentityBlueprint.*` permissions don't appear in Entra portal?**
A: These are beta permissions. Use the Graph API method (Option B in step 3.3) to add them programmatically. Do NOT click "Grant admin consent" in the portal afterwards—it will overwrite the beta permissions.

**Q: What role do I need in the M365 Tenant?**
A: Global Administrator, Agent ID Administrator, or Agent ID Developer. For the full workshop flow (including admin consent), Global Administrator is easiest.

**Q: How long does admin approval take after publishing?**
A: In the workshop, approval is near-instant (same person). In production, it depends on your organization's approval workflow—hours to days.

**Q: What happens to instances if I redeploy ACA?**
A: Instances point to the messaging endpoint URL. As long as the FQDN stays the same after redeployment, instances continue working with the new version automatically.

---

## 🏆 Self-Paced Challenges

1. **Multi-Tenant Investigation**: Document your organization's tenant topology. Are Azure and M365 in the same tenant? Map which A365 config fields change for each scenario.
2. **Permission Audit**: Use Graph Explorer to list all permissions granted to your agent's service principal. Compare delegated vs application permissions.
3. **Endpoint Failover**: Configure a secondary ACA deployment and update the messaging endpoint. Test switching between primary and secondary.
4. **Instance Governance**: Create both personal and shared instances, then write a governance policy defining who should use which type and why.
5. **Automation Script**: Write a PowerShell script that automates the entire A365 setup (steps 2-6) from a single config file, including error handling and validation.

---

## References

### Core Documentation
- [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Agent 365 CLI](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli)
- [Agent 365 Config Reference](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/config)

### Setup & Configuration
- [Setting up Agent 365 Config](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-config)
- [Custom Client App Registration](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/custom-client-app-registration)
- [Setup Agent Blueprint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/registration)
- [Agent Messaging Endpoint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-messaging-endpoint)

### Publishing & Deployment
- [Publish Agents to M365](https://learn.microsoft.com/en-us/microsoft-agent-365/admin/publish-agents)
- [M365 Admin Center - Integrated Apps](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/manage-deployment-of-add-ins)
- [Deploy Apps in M365](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/test-and-deploy-microsoft-365-apps)

### Instance Management
- [Create Agent Instances](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/create-instances)
- [Teams Apps Development](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/what-are-bots)
- [Outlook Add-ins](https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/outlook-add-ins-overview)

### Program Access
- [Frontier Preview Program](https://adoption.microsoft.com/copilot/frontier-program/)
