# Lesson 5 - Prerequisites for Microsoft Agent 365

This lesson prepares the environment to integrate the workshop agents with **Microsoft Agent 365** (A365). We won't create agents here - only configure the prerequisites for the A365 development cycle.

> **IMPORTANT**: Agent 365 requires participation in the [Frontier preview program](https://adoption.microsoft.com/copilot/frontier-program/).

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

The complete cycle has 6 steps. **In this lesson we cover steps 2-3 (config + blueprint)**:

```
1. Build and run agent          <-- already done (lesson 4, ACA in Tenant A)
2. Setup Agent 365 config       <-- THIS LESSON
3. Setup agent blueprint        <-- THIS LESSON
4. Deploy                       <-- already done (lesson 4, needDeployment: false)
5. Publish to M365 admin center <-- future lesson
6. Create agent instances       <-- future lesson
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

## Summary of artifacts generated

At the end of this lesson, you will have:

| Artifact | Location | Description |
|----------|-------------|-----------|
| `a365.config.json` | `lesson-5-a365-prereq/` | Manual configuration (created by hand, no wizard) |
| `a365.generated.config.json` | `lesson-5-a365-prereq/` | Configuration generated by CLI (IDs, secrets) |
| Custom Client App | Entra ID (M365 Tenant) | App registration for CLI authentication |
| Agent Blueprint | Entra ID (M365 Tenant) | Agent identity + permissions |
| Service Principal | Entra ID (M365 Tenant) | Agent identity for authentication |

> **What was NOT created**: No Azure resources (Resource Group, App Service Plan, Web App). The agent continues running in ACA of Tenant A (lesson 4) and A365 only points to it via `messagingEndpoint`.

---

## Troubleshooting

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

---

## Next steps

With the prerequisites configured, the next steps in the A365 cycle are:

- **Lesson 6 (future)**: Adapt agent code with A365 SDK (observability, tooling, notifications)
- **Lesson 7 (future)**: Publish agent to M365 admin center (`a365 publish`)
- **Lesson 8 (future)**: Create agent instances in Teams (`a365 create-instance` or via Teams Apps)

---

## References

- [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Agent 365 CLI](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli)
- [Setting up Agent 365 Config](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-config)
- [Custom Client App Registration](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/custom-client-app-registration)
- [Setup Agent Blueprint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/registration)
- [Agent Messaging Endpoint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-messaging-endpoint)
- [Agent 365 Config Reference](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/config)
- [Frontier Preview Program](https://adoption.microsoft.com/copilot/frontier-program/)
