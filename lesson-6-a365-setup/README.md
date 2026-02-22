# IMPORTANT NOTICE

**Agent365 still in PREVIEW**

The content of this lession might not work due on-going development in the Service. 

# Lesson 6 - Microsoft Agent 365: Complete Setup, Publish & Instances

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

By the end of this lesson, you will be able to:
1. **Configure** Agent 365 (A365) CLI and authentication for cross-tenant scenarios
2. **Register** an Agent Blueprint in Microsoft 365 Entra ID
3. **Understand** the cross-tenant architecture (Azure Tenant A + M365 Tenant B)
4. **Publish** the agent Blueprint to M365 Admin Center using `a365 publish`
5. **Customize** the agent manifest (name, version, descriptions, icons)
6. **Configure** the agent in Teams Developer Portal for messaging
7. **Create** agent instances in Microsoft Teams through the official governance workflow
8. **Manage** the full Agent 365 development lifecycle (config → blueprint → publish → instances)

---

## Overview

This lesson covers the **complete end-to-end deployment** of agents to **Microsoft Agent 365** (A365): from initial CLI configuration and blueprint registration, through publishing to the M365 Admin Center, to creating and testing live agent instances in Microsoft Teams.

> **IMPORTANT**: Agent 365 requires at least one active **Microsoft 365 Copilot license** in the M365 tenant and Copilot Frontier enabled in the Admin Center. No separate enrollment form is needed — access is granted automatically once a valid Copilot license is present.

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
- Azure infrastructure fields like `appServicePlanName` and `webAppName` are not needed — no new Azure infrastructure will be created
- `resourceGroup` and `location` **must** still be set to your ACA resource group and Azure region — the A365 CLI needs them to register the messaging endpoint with the Frontier backend

---

## Prerequisite 0 - Microsoft 365 Copilot License + Frontier Access

Agent 365 requires a **Microsoft 365 Copilot license** in the M365 tenant. No separate enrollment form is needed.

1. Ensure at least one user in the M365 tenant has a **Microsoft 365 Copilot** license (a 30-day trial is sufficient → [Start free trial](https://www.microsoft.com/microsoft-365/copilot/microsoft-365-copilot))
2. Sign in to the [Microsoft 365 Admin Center](https://admin.microsoft.com/) with a Global Admin account
3. Navigate to **Copilot** → **Settings** → **User access** → **Copilot Frontier**
4. Enable Frontier for the required users or the entire organization

> **Note:** The **Copilot Frontier** option only appears in the Admin Center once a valid Microsoft 365 Copilot license is active in the tenant. If the option is missing, verify the license assignment first.

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

## Step 1 - Setup Agent 365 Config

Since we use `needDeployment: false`, we will **not** run the interactive wizard `a365 config init` (it tries to list Azure subscriptions and may fail without a subscription in M365 Tenant). Instead, we'll create the `a365.config.json` manually.

### 1.1 - Authenticate to M365 Tenant

```powershell
# Login to M365 Tenant (Tenant B)
az login --tenant <TENANT-M365-ID>

# Verify we're in the correct tenant
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> `az login` is necessary for the CLI to authenticate to M365 Tenant's Entra ID. We DO NOT need an Azure subscription here.

### 1.2 - Create a365.config.json manually

Navigate to the lesson 6 lab directory and create the file:

```powershell
cd lesson-6-a365-setup\labs\solution
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
  "agentDescription": "Financial market agent (LangGraph on ACA) - A365 Workshop",
  "resourceGroup": "<RESOURCE-GROUP-FROM-LESSON-4>",
  "location": "<AZURE-REGION-FROM-LESSON-4>"
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
| `resourceGroup` | Resource group name from lesson 4 | Azure resource group containing the ACA deployment — **required** for Frontier endpoint registration |
| `location` | Azure region name (e.g. `"eastus"`) | Azure region of the ACA deployment — **required** for Frontier endpoint registration |

> **Note**: Fields like `subscriptionId`, `appServicePlanName`, and `webAppName` can be omitted with `needDeployment: false` — no new Azure infrastructure will be created. However, `resourceGroup` and `location` **must** be provided: the A365 CLI uses them to register the messaging endpoint with the Frontier backend.

### 1.3 - Verify the configuration

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
- [ ] `resourceGroup` is the resource group where ACA is deployed (from lesson 4)
- [ ] `location` is the Azure region of the ACA deployment (e.g. `"eastus"`)

---

## Step 2 - Setup Agent Blueprint

The blueprint defines the agent's identity and permissions in Entra ID. With `needDeployment: false`, the CLI **skips Azure infra creation** and focuses only on identity registration.

### 2.1 - Execute the setup

```powershell
# Execute the complete setup (inside lesson-6-a365-setup/labs/solution/)
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

### 2.2 - Verify the setup

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

## Step 3 - Publish to M365 Admin Center

After setting up the blueprint, publish the agent to the Microsoft 365 Admin Center. Publishing creates a **Teams app package** from your agent blueprint and makes it visible in the admin center as a managed agent. Once published, admins can onboard instances in Microsoft Teams.

> **Important:** `a365 publish` requires the Frontier preview program to be enabled for your tenant and the user to have the **Agent ID Developer**, **Agent ID Administrator**, or **Global Administrator** role.

### Publication Pipeline

```
Developer Machine                   Microsoft Services
        |                                    |
        |  a365 publish                      |
        |  1. Update manifest.json           |
        |  2. Pause for customization        |
        |  3. Package → manifest.zip         |
        |  4. Add API permissions     ------>|  Microsoft Entra ID
        |  5. Upload package          ------>|  M365 Titles Service
        |  6. Configure user access          |
        |  7. Setup federated identity ---|->|  Blueprint App (Entra)
        |  8. Grant Graph permissions        |
        |       ✅ Published                 |
        |                                    |  admin.cloud.microsoft
        |                                    |  Registry tab: agent visible
```

### Prerequisites check

Before running `a365 publish`, ensure:

```powershell
cd lesson-6-a365-setup\labs\solution

# Display current config and confirm agentBlueprintId is filled
a365 config display -g
```

Look for `agentBlueprintId` — it must be a non-empty UUID. If empty, re-run Step 2 setup.

Also verify the following setup commands ran successfully:
```powershell
a365 setup blueprint --endpoint-only   # or a365 setup all on first-time setup
a365 setup permissions mcp
a365 setup permissions bot
```

### 3.1 - Run `a365 publish`

```powershell
cd lesson-6-a365-setup\labs\solution
a365 publish
```

> **Note:** `a365 publish` does **not** accept a `--config` flag. It always auto-detects `a365.config.json` from the current working directory. Make sure to `cd` into the correct directory first.

What the command does (in order):

| # | Action | Result |
|---|--------|--------|
| 1 | Updates `manifest.json` with your blueprint ID | `manifest/manifest.json` created |
| 2 | **Pauses** — prompts to open and customize the manifest | (interactive prompt) |
| 3 | Packages manifest + icons into a zip | `manifest/manifest.zip` created |
| 4 | Adds required API permissions to your custom client app | Entra permission grant |
| 5 | Uploads the package to the M365 Titles service | Agent entry in admin center |
| 6 | Configures title access for all users | Availability: All Users |
| 7 | Sets up workload identity / federated credentials on blueprint app | 2 FICs on blueprint app |
| 8 | Grants Microsoft Graph permissions to the blueprint service principal | Graph consent |

### 3.2 - Customize the Agent Manifest

When the CLI pauses, it shows output similar to:

```
=== MANIFEST UPDATED ===
Location: ...\manifest\manifest.json

=== CUSTOMIZE YOUR AGENT MANIFEST ===
  Version ('version')          - increment for republishing (e.g. 1.0.0 → 1.0.1)
  Agent Name ('name.short')    - MUST be 30 characters or fewer
  Agent Name ('name.full')     - full descriptive name
  Descriptions                 - 'description.short' and 'description.full'
  Developer Info               - developer.name, websiteUrl, privacyUrl
  Icons                        - replace color.png and outline.png

Open manifest in your default editor now? (Y/n):
```

Open `manifest/manifest.json` and update the key fields:

```json
{
  "version": "1.0.0",
  "name": {
    "short": "Financial Market Agent",
    "full": "Financial Market Agent (A365 Workshop)"
  },
  "description": {
    "short": "AI agent for real-time stock and financial data.",
    "full": "LangGraph-based agent providing real-time stock prices, financial news, and portfolio insights via the Microsoft Agent 365 platform."
  },
  "developer": {
    "name": "Workshop Developer",
    "websiteUrl": "https://example.com",
    "privacyUrl": "https://example.com/privacy",
    "termsOfUseUrl": "https://example.com/terms"
  }
}
```

> **Rules:**
> - `name.short` must be **≤ 30 characters**
> - `version` must be **higher** than any previously published version
> - Do **not** change the `id` or `bots[0].botId` fields — these were injected by the CLI and must match your blueprint ID

When done editing, return to the terminal and type:

```
continue
```

### 3.3 - Verify Successful Publication

**Expected CLI output:**

```
✅ Upload succeeded
✅ Title access configured for all users
✅ Microsoft Graph permissions granted successfully
✅ Agent blueprint configuration completed successfully
✅ Publish completed successfully!
```

**Check manifest files were created:**

```powershell
Test-Path lesson-6-a365-setup\labs\solution\manifest\manifest.json   # → True
Test-Path lesson-6-a365-setup\labs\solution\manifest\manifest.zip    # → True
```

**Check the Microsoft 365 admin center:**

1. Go to [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Open the **Registry** tab
3. Your agent (e.g. "Financial Market Agent") should appear with **Availability: All Users** ✅

> **Note:** It may take **5–10 minutes** after publishing for the agent to appear. Refresh the page if not visible immediately.

**Check federated identity credentials:**

1. [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations** → search for your blueprint app
2. **Certificates & secrets** → **Federated credentials**
3. You should see **2 federated identity credentials (FICs)** ✅

### Available `a365 publish` options

```
a365 publish [options]

Options:
  --dry-run         Show changes without writing files or calling APIs
  --skip-graph      Skip Graph federated identity and role assignment steps
  --mos-env <env>   MOS environment identifier (e.g. prod, dev) [default: prod]
  --mos-token <t>   Override MOS token — bypass script and cache
  -v, --verbose     Enable verbose logging
```

**Dry-run example** — preview what would happen without making changes:

```powershell
a365 publish --dry-run
```

---

## Step 4 - Configure Agent in Teams Developer Portal

Before creating instances, you must configure the agent blueprint in the Teams Developer Portal to connect it to the Microsoft 365 messaging infrastructure. **Without this step, the agent won't receive messages from Teams.**

### 4.1 - Get Your Blueprint ID

```powershell
cd lesson-6-a365-setup\labs\solution
a365 config display -g
```

Copy the value of `agentBlueprintId` from the output. It will look like:

```
agentBlueprintId: 809bce64-ea7f-4f64-94b1-6f0c582b2f21
```

### 4.2 - Configure in Developer Portal

1. **Open the Developer Portal configuration page:**

   ```
   https://dev.teams.microsoft.com/tools/agent-blueprint/<your-blueprint-id>/configuration
   ```

   Replace `<your-blueprint-id>` with your actual `agentBlueprintId`.

2. **Configure the agent:**
   - Set **Agent Type** → `Bot Based`
   - Set **Bot ID** → paste your `agentBlueprintId`
   - Click **Save**

3. **Verify the save:**
   - ✅ Agent Type shows: `Bot Based`
   - ✅ Bot ID matches your `agentBlueprintId`
   - ✅ Page shows "Saved successfully"

> **Tip:** If you don't have access to the Teams Developer Portal, contact your tenant administrator to complete this step.

---

## Step 5 - Request an Agent Instance in Teams

> **Important design note:** The `a365 create-instance` CLI command has been **removed**. It bypassed required registration steps necessary for full agent functionality. Instance creation is now done entirely through the **Microsoft Teams UI** and **Microsoft 365 admin center**, following the official governance workflow.

### What is an agent instance?

| Concept | Description |
|---------|-------------|
| **Blueprint** | The Entra app registration — the template defining the agent type, permissions, and config |
| **Instance** | A specific instantiation of the blueprint — the agent gets its own Entra user identity |
| **Agentic user** | An Entra user account for the agent (e.g. `fin-market-agent@domain.com`) — appears in Teams like a person |

### 5.1 - Request the instance

1. Open **Microsoft Teams** (desktop or web)
2. Click the **Apps** icon in the left sidebar (or use the top search bar)
3. Search for your agent by name — e.g. `Financial Market Agent`
4. Click on the agent card
5. Click **Request Instance** (or **Create Instance** if directly available)
6. Optionally enter a custom display name for your instance
7. Confirm — this sends an **approval request to your tenant admin**

> **Note:** The instance creation process is asynchronous. After the admin approves, the agent user account is created in Entra and the agent becomes available in Teams. This can take a few minutes to a few hours.

---

## Step 6 - Approve the Instance Request (Admin)

As the admin, approve the pending request:

1. Go to [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
2. Find the pending request for your agent
3. Review the permissions and details
4. Click **Approve**

After approval:
- The agentic user account is created in Microsoft Entra
- The agent becomes searchable and chattable in Teams
- The agent appears under **All Agents** in the admin center

---

## Step 7 - Test Your Agent in Teams

> **Note:** After admin approval, it may take **a few minutes to a few hours** for the agent user to become searchable in Teams. This is an asynchronous background process.

1. In Microsoft Teams, search for your agent's display name in the **Search** bar or **New Chat**
2. Open a chat with the agent
3. Send a test message — for example:
   ```
   What's the current stock price for MSFT?
   ```
4. Verify the agent responds correctly:
   - Agent shows typing indicator
   - Agent responds within a few seconds
   - Response includes relevant financial data

### Example conversation

```
You: What's the current price of AAPL?

Financial Market Agent:
📈 Apple Inc. (AAPL)
Current Price: $178.42
Change: +2.34 (+1.33%)
[Last 30 days data retrieval requested...]
```

---

## Step 8 - Monitor Agent Activity

### Check in Microsoft 365 Admin Center

1. Go to [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Select your agent
3. Open the **Activity** tab

You should see:
- ✅ Sessions listed with timestamps
- ✅ Each session shows triggers and actions taken
- ✅ Tool calls logged with timestamps and inputs/outputs

### Check Azure Container App logs

```powershell
az containerapp logs show `
  --name aca-lg-agent `
  --resource-group <your-resource-group> `
  --follow
```

Look for:
- ✅ Incoming requests from Teams (`POST /api/messages`)
- ✅ Successful authentication
- ✅ Tool calls executing
- ❌ Error messages or exceptions

### Check messaging endpoint health

```powershell
curl https://aca-lg-agent.<aca-env-hash>.<region>.azurecontainerapps.io/health
# Expected: {"status": "ok"} or HTTP 200
```

### Query Entra scopes and consent status

```powershell
cd lesson-6-a365-setup\labs\solution

# Check blueprint scopes
a365 query-entra blueprint-scopes --config a365.config.json

# Check instance scopes (after instance is created)
a365 query-entra instance-scopes --config a365.config.json
```

---

## Summary of Artifacts Generated

At the end of this lesson, you will have:

| Artifact | Location | Description |
|----------|-------------|-----------|
| `a365.config.json` | `lesson-6-a365-setup/labs/solution/` | Manual configuration (created by hand, no wizard) |
| `a365.generated.config.json` | `lesson-6-a365-setup/labs/solution/` | Configuration generated by CLI (IDs, secrets, publish details) |
| `manifest/manifest.json` | `lesson-6-a365-setup/labs/solution/manifest/` | Agent Teams app manifest |
| `manifest/manifest.zip` | `lesson-6-a365-setup/labs/solution/manifest/` | Packaged Teams app submitted to admin center |
| Custom Client App | Entra ID (M365 Tenant) | App registration for CLI authentication |
| Agent Blueprint | Entra ID (M365 Tenant) | Agent identity + permissions |
| Service Principal | Entra ID (M365 Tenant) | Agent identity for authentication |
| Federated credentials | Blueprint App (Entra) | 2 FICs for workload identity |
| Published Agent | M365 Admin Center | Agent visible in Registry tab |
| Agent Instance | Teams | Agentic user — chattable in Teams |

> **What was NOT created**: No Azure resources (Resource Group, App Service Plan, Web App). The agent continues running in ACA of Tenant A (lesson 4) and A365 only points to it via `messagingEndpoint`.

---

## Instance Lifecycle Management

### CLI commands (Entra resources only)

```powershell
# Remove instance identity and user from Entra
a365 cleanup instance --config a365.config.json

# Remove blueprint and service principal from Entra
a365 cleanup blueprint --config a365.config.json

# Remove Azure resources (App Service, App Service Plan)
a365 cleanup azure --config a365.config.json
```

> **Note:** These CLI commands remove Entra resources only. To remove an agent instance from a user's Teams, the user removes the chat (or the admin removes the app from the tenant's installed apps in Teams Admin Center).

### Admin center management

All instance lifecycle actions (suspend, resume, delete, permissions review) are managed through the admin center:

- **All agents:** [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
- **Requested agents:** [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
- **Teams Admin Center:** [https://admin.teams.microsoft.com](https://admin.teams.microsoft.com) → Teams apps → Manage apps

---

## Troubleshooting

### Prerequisites & Config (Steps 1-2)

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| `az login` doesn't show subscription | Wrong tenant | Use `az login --tenant <TENANT-M365-ID>` |
| `a365 config init` fails listing subscriptions | No subscription in M365 Tenant | Don't use the wizard. Create `a365.config.json` manually (section 1.2) |
| CLI requires Azure infra fields | Schema validation | Add placeholder fields: `"subscriptionId": "00000000-0000-0000-0000-000000000000"` |
| Invalid Client App ID | App ID vs Object ID | Verify you used Application (client) ID, not Object ID |
| Beta permissions not visible | AgentIdentityBlueprint.* in beta | Use Option B (Graph API) to add permissions |
| Admin consent fails | No admin role | Ask M365 Tenant admin to complete step 3.3 |
| `a365 setup` fails with permissions | Insufficient role | Need Global Admin, Agent ID Admin, or Agent ID Developer |
| Blueprint doesn't appear in Entra | Incomplete setup | Run `a365 setup all` again |
| Endpoint not registered | needDeployment=false without messagingEndpoint | Run `a365 setup blueprint --endpoint-only` |
| `a365 setup blueprint --endpoint-only` fails with `400 BadRequest` | Missing `location` or `resourceGroup` in `a365.config.json` | Add `"resourceGroup": "<rg>"` and `"location": "<region>"` to `a365.config.json` — required even when `needDeployment: false` |

### Publish (Step 3)

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| `a365 publish` fails with 403 | Insufficient permissions | Ensure CLI user has Agent ID Admin or Global Admin role |
| `Agent already exists` error | Same version already published | Increment `version` in `manifest/manifest.json` and re-run `a365 publish` |
| `Permissions missing` error | Blueprint or MCP permissions incomplete | Run `a365 setup permissions mcp` then `a365 setup permissions bot`, then re-publish |
| Agent not in admin center after 10+ minutes | Publish may be incomplete | Verify all ✅ lines appeared in output; use `admin.cloud.microsoft` not `admin.microsoft.com` |
| `manifest.json` shows placeholder `${{TEAM_APP_ID}}` | Publish ran before setup completed | Verify `a365.generated.config.json` has `agentBlueprintId`, then re-run `a365 publish` |
| Admin can't find agent | Wrong tenant | Verify admin is logged into M365 Tenant (Tenant B) |

### Teams Developer Portal & Instances (Steps 4-6)

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| Agent doesn't appear in Teams search | Developer Portal configuration missing | Go to `dev.teams.microsoft.com/tools/agent-blueprint/<id>/configuration`, set Agent Type = Bot Based, save, wait 5-10 min |
| "Request Instance" button missing or greyed out | Frontier not enabled for user | In M365 admin center → Settings → Copilot → Frontier, verify user inclusion |
| Agent doesn't respond to messages | ACA not running or endpoint wrong | Check `az containerapp show`, verify `/api/messages` path in config, confirm Developer Portal is saved |
| 404 from messaging endpoint | Wrong endpoint path | Verify endpoint in `a365.config.json` includes `/api/messages` |
| Agent responds with error | Azure OpenAI access | Check ACA managed identity has RBAC on Foundry OpenAI |
| Slow responses | Cold start | ACA may be scaling from 0 replicas; set `minReplicas: 1` for always-on availability |
| License assignment fails on approval | Insufficient licenses | Go to M365 admin center → Billing → Licenses; verify Microsoft 365 Copilot license is available |
| Agent user not found in Teams after hours | Entra sync pending | Run `az ad user show --id fin-market-agent@<tenant>.onmicrosoft.com` to verify user exists in Entra |
| `query-entra instance-scopes` returns `Request_ResourceNotFound` | Setup incomplete or no instance yet | Verify `completed: true` in `a365.generated.config.json`; check `AgenticAppId` is not null; re-run setup if needed |

---

## Testing Scenarios

### Scenario 1: Basic financial query

```
You: What's the current price of MSFT?
Agent: [Uses stock price tool, returns price with change data]

You: How does that compare to last week?
Agent: [Uses context from previous turn to answer comparatively]
```

**Verify:** Multi-turn context is maintained.

### Scenario 2: Error handling

| Input | Expected Behavior |
|-------|-------------------|
| Unknown ticker (`XYZINVALID`) | Graceful: "Symbol not found" |
| Vague request (`Is it good?`) | Clarifying: "Which stock are you asking about?" |
| Out-of-scope (`Tell me a joke`) | Redirect: "I specialize in financial information" |

### Scenario 3: Tool execution audit

After sending a request that uses tools (e.g. stock price lookup):

1. Go to admin center → your agent → **Activity** tab
2. Verify tool calls are logged with timestamps and inputs/outputs

---

## Quick Reference

| Command / Action | Purpose |
|---------|---------|
| `a365 setup all` | Register blueprint, configure permissions, register endpoint |
| `a365 setup blueprint --endpoint-only` | Register/update messaging endpoint only |
| `a365 setup permissions mcp` | Configure MCP permissions on blueprint |
| `a365 setup permissions bot` | Configure Bot API permissions on blueprint |
| `a365 publish` | Package and publish agent to M365 admin center |
| `a365 publish --dry-run` | Preview publish changes without executing |
| `a365 config display -g` | Display current config (verify agentBlueprintId) |
| `a365 query-entra blueprint-scopes` | List configured scopes on blueprint |
| `a365 query-entra instance-scopes` | List scopes on agent instance |
| `a365 cleanup blueprint` | Remove blueprint from Entra |
| `a365 cleanup instance` | Remove agent instance/user from Entra |
| Teams Developer Portal | `https://dev.teams.microsoft.com/tools/agent-blueprint/<id>/configuration` |
| Request instance | Microsoft Teams → Apps → Search → Request Instance |
| Approve request | [admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested) |
| View all agents | [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all) |

---

## ❓ Frequently Asked Questions

**Q: Why do we use `needDeployment: false` instead of letting A365 create infrastructure?**
A: Our agent is already deployed to ACA (Lesson 4). A365 only needs to register the blueprint identity in M365 Entra ID and point to the existing ACA endpoint. Setting `needDeployment: true` would create duplicate App Service infrastructure.

**Q: Can Azure Tenant (A) and M365 Tenant (B) be the same tenant?**
A: Yes! Single-tenant is simpler. The cross-tenant scenario is common in enterprises that separate Azure subscriptions from M365 for governance, cost allocation, or acquisition history.

**Q: What if `AgentIdentityBlueprint.*` permissions don't appear in Entra portal?**
A: These are beta permissions. Use the Graph API method (Option B in Prerequisite 3.3) to add them programmatically. Do NOT click "Grant admin consent" in the portal afterwards — it will overwrite the beta permissions.

**Q: What role do I need in the M365 Tenant?**
A: Global Administrator, Agent ID Administrator, or Agent ID Developer. For the full workshop flow (including admin consent), Global Administrator is easiest.

**Q: Do I need to re-publish after changing the agent code?**
A: No. Code changes behind the same messaging endpoint URL take effect immediately with no re-publish required. Re-publish only when the manifest changes (name, icon, permissions) or the endpoint URL changes.

**Q: Can I re-publish without deleting the old version?**
A: Yes. Increment `version` in `manifest/manifest.json` and run `a365 publish` again.

**Q: Why was `a365 create-instance` removed?**
A: It bypassed required registration steps (Developer Portal configuration, admin approval workflow) necessary for agents to receive messages and operate with full governance. Instance creation via Teams ensures these steps are always completed.

**Q: How long does instance creation take?**
A: The admin approval itself is fast (a few minutes). Creating the agentic user in Entra and propagating it through Teams can take a few minutes to a few hours. If not searchable after 2 hours, verify the user was created in Entra.

**Q: How long does admin approval take after publishing?**
A: In the workshop, approval is near-instant (same person). In production, it depends on your organization's approval workflow — hours to days.

**Q: What happens to instances if I redeploy ACA with a new URL?**
A: Update the messaging endpoint and re-publish:
```powershell
a365 setup blueprint --endpoint-only --update-endpoint "https://new-url/api/messages" --config a365.config.json
a365 publish
```

**Q: What if ACA scales to zero (cold start)?**
A: If `minReplicas: 0`, the first message after an idle period triggers a cold start (5–30 seconds). Set `minReplicas: 1` in your Container App for always-on availability.

**Q: Can team members see my personal instance conversations?**
A: No. Each user has a 1:1 chat with the agent. Conversation history is private to that user.

---

## 🏆 Self-Paced Challenges

1. **Multi-Tenant Investigation**: Document your organization's tenant topology. Are Azure and M365 in the same tenant? Map which A365 config fields change for each scenario.
2. **Permission Audit**: Use Graph Explorer to list all permissions granted to your agent's service principal. Compare delegated vs application permissions.
3. **Endpoint Failover**: Configure a secondary ACA deployment and update the messaging endpoint. Test switching between primary and secondary.
4. **Manifest Customization**: Replace the default icons (`color.png` and `outline.png`) in the manifest folder with custom images representing your agent.
5. **Automation Script**: Write a PowerShell script that automates the entire A365 setup (steps 1-3) from a single config file, including error handling and validation.

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
- [Publish Agents to M365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/publish)
- [Agent 365 CLI Reference — publish command](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/publish)
- [Microsoft 365 Admin Center — Agents Registry](https://admin.cloud.microsoft/#/agents/all)

### Instance Management
- [Create Agent Instances](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/create-instance)
- [Teams Developer Portal](https://dev.teams.microsoft.com)
- [Agent 365 GitHub Samples](https://github.com/microsoft/Agent365-Samples)

### Program Access
- [Frontier Preview Program](https://adoption.microsoft.com/copilot/frontier-program/)
