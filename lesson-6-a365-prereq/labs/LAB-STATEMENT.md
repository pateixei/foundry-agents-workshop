# Lab 6: Register Entra ID Application and Configure Agent 365

> 🇧🇷 **[Leia em Português (pt-BR)](LAB-STATEMENT.pt-BR.md)**

## Objective

Register a **Custom Client Application** in Microsoft Entra ID, configure its authentication settings and API permissions, and create the `a365.config.json` file — the foundation required for publishing agents to Microsoft 365 via Agent 365 CLI.

## Scenario

Your organization wants to make the financial market agent (running in ACA from Lab 4) available to end users in **Microsoft Teams and Outlook**. To do that, you need to:
- Register an application in the M365 Tenant's Entra ID for CLI authentication
- Configure redirect URIs for the OAuth flow
- Grant the correct Microsoft Graph API permissions (including beta permissions)
- Capture the generated Client ID
- Create the `a365.config.json` pointing to your ACA agent endpoint

> [!CAUTION]
> **🔴 MANDATORY PREREQUISITE — Copilot Frontier Program Enrollment**
>
> Your M365 tenant **MUST** be enrolled in the **Microsoft Copilot Frontier preview program** before starting this lab. Without Frontier enrollment, the `a365 setup blueprint` command will fail with **"Forbidden: Access denied by Frontier access control"** and you will be unable to register agent blueprints or messaging endpoints.
>
> **Enroll here → [https://adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/)**
>
> After enrolling, a Global Admin must also **enable Copilot Frontier** in the [Microsoft 365 Admin Center](https://admin.microsoft.com/) → Copilot → Settings → User access → Copilot Frontier.
>
> ⏱️ **Allow up to 24 hours** for Frontier enrollment to propagate fully to your tenant.

## Learning Outcomes

- Register applications in Microsoft Entra ID (Azure AD)
- Configure OAuth redirect URIs for public client apps
- Manage Microsoft Graph API delegated permissions (including beta)
- Understand cross-tenant architecture (Azure Tenant A + M365 Tenant B)
- Create and validate the Agent 365 configuration file
- Differentiate between Application (client) ID and Object ID

## Prerequisites

- [x] Lab 4 completed (ACA agent deployed and running)
- [x] Access to M365 Tenant (Tenant B) with Global Administrator or Agent ID Administrator role
- [x] .NET 8.0+ SDK installed
- [x] Agent 365 CLI installed (`dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease`)
- [x] ACA agent URL from Lab 4 available

## Architecture Context

```
┌──────────────────────────────────────────────────┐
│              M365 Tenant (Tenant B)              │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │ Entra ID                                   │  │
│  │                                            │  │
│  │  ┌──────────────────────┐                  │  │
│  │  │ App Registration     │  ← THIS LAB      │  │
│  │  │ "a365-workshop-cli"  │                  │  │
│  │  │                      │                  │  │
│  │  │ • Client ID          │                  │  │
│  │  │ • Redirect URIs      │                  │  │
│  │  │ • Graph Permissions  │                  │  │
│  │  └──────────────────────┘                  │  │
│  │                                            │  │
│  │  ┌──────────────────────┐                  │  │
│  │  │ Agent Blueprint      │  ← LAB 6         │  │
│  │  │ (created by CLI)     │                  │  │
│  │  └──────────────────────┘                  │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  a365.config.json ──────┐                        │
│    tenantId             │                        │
│    clientAppId          │  ← THIS LAB            │
│    messagingEndpoint ───┼───────────────────┐    │
│                         │                   │    │
└─────────────────────────┼───────────────────┼────┘
                          │                   │
                          │    ┌──────────────┼────┐
                          │    │ Azure (A)     │    │
                          │    │               ▼    │
                          │    │  ┌─────────────┐  │
                          │    │  │ ACA Agent   │  │
                          │    │  │ (Lab 4)     │  │
                          │    │  └─────────────┘  │
                          │    └────────────────────┘
                          │
                     a365.config.json
```

## Tasks

### Task 1: Install Prerequisites (10 minutes)

**1.1 - Verify .NET SDK**

```powershell
dotnet --version
# Expected: 8.0.x or higher
```

If not installed, download from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).

**1.2 - Install Agent 365 CLI**

```powershell
# Install the CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify installation
a365 -h
```

> **Tip**: If already installed, update with `dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease`

**1.3 - Identify your tenants**

Fill in the following before proceeding:

| Field | Value |
|-------|-------|
| Azure Tenant ID (Tenant A) | `________-____-____-____-____________` |
| M365 Tenant ID (Tenant B) | `________-____-____-____-____________` |
| M365 Tenant Domain | `__________.onmicrosoft.com` |
| ACA Agent URL (from Lab 4) | `https://aca-lg-agent.xxxxx.eastus.azurecontainerapps.io` |

> **Note**: If Azure and M365 are in the **same tenant**, both fields will have the same GUID. The cross-tenant scenario is common in enterprises that separate Azure from M365 for governance.

**Success Criteria**:
- ✅ .NET 8.0+ installed
- ✅ `a365 -h` returns CLI help
- ✅ Tenant IDs and ACA URL identified

### Task 2: Register Application in Entra ID (15 minutes)

> **IMPORTANT**: All Entra ID operations must be done in the **M365 Tenant (Tenant B)**, not the Azure Tenant.

**2.1 - Navigate to Entra admin center**

1. Go to the [Microsoft Entra admin center](https://entra.microsoft.com/)
2. **Verify you are in the correct tenant** (M365 Tenant B) — check the tenant name in the top-right
3. Navigate to **Identity** → **Applications** → **App registrations**

**2.2 - Create new registration**

1. Click **+ New registration**
2. Fill in:
   - **Name**: `a365-workshop-cli`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**:
     - Platform: `Public client/native (mobile & desktop)`
     - URI: `http://localhost:8400/`
3. Click **Register**

**2.3 - Capture the Application (client) ID**

On the app's **Overview** page, locate and copy:

| Field | Where to Find | Example |
|-------|---------------|---------|
| **Application (client) ID** | Overview page, top section | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |
| **Directory (tenant) ID** | Overview page, top section | Should match your M365 Tenant ID |

> ⚠️ **Common mistake**: Do NOT confuse **Application (client) ID** with **Object ID**. You need the **Application (client) ID** — the shorter GUID typically shown first.

Record it here:
```
Application (client) ID: ________-____-____-____-____________
```

**Success Criteria**:
- ✅ App registration created in M365 Tenant's Entra ID
- ✅ Name is `a365-workshop-cli`
- ✅ Single tenant selected
- ✅ Redirect URI `http://localhost:8400/` added
- ✅ Application (client) ID copied

### Task 3: Configure Redirect URI (10 minutes)

The Agent 365 CLI requires an additional redirect URI that includes the Client ID.

**3.1 - Add Broker Plugin Redirect URI**

1. In the app registration, go to **Authentication**
2. Under **Mobile and desktop applications**, click **Add URI**
3. Add the following URI (replace `{YOUR-CLIENT-ID}` with the value from Task 2):
   ```
   ms-appx-web://Microsoft.AAD.BrokerPlugin/{YOUR-CLIENT-ID}
   ```
   Example: `ms-appx-web://Microsoft.AAD.BrokerPlugin/a1b2c3d4-e5f6-7890-abcd-ef1234567890`
4. Click **Save**

**3.2 - Verify Redirect URIs**

After saving, under **Platform configurations** → **Mobile and desktop applications**, confirm both URIs:

| # | Redirect URI | Purpose |
|---|-------------|---------|
| 1 | `http://localhost:8400/` | Local CLI authentication |
| 2 | `ms-appx-web://Microsoft.AAD.BrokerPlugin/{CLIENT-ID}` | WAM broker authentication |

**Success Criteria**:
- ✅ Two redirect URIs configured
- ✅ Broker plugin URI includes correct Client ID
- ✅ Both URIs saved successfully

### Task 4: Configure API Permissions (20 minutes)

The Agent 365 CLI needs specific Microsoft Graph delegated permissions. Some are **beta permissions** that may not appear in the portal UI.

> **IMPORTANT**: Use **Delegated** permissions (NOT Application permissions). The CLI authenticates as a user, not as an app.

**4.1 - Determine which method to use**

Try Option A first. If the beta permissions (`AgentIdentityBlueprint.*`) don't appear in the search, use Option B.

#### Option A — Via Entra Admin Center

1. In the app registration, go to **API permissions** → **Add a permission**
2. Select **Microsoft Graph** → **Delegated permissions**
3. Search for and add each of the 5 permissions:

| Permission | Category | Description |
|-----------|----------|-------------|
| `AgentIdentityBlueprint.ReadWrite.All` | Agent Identity (beta) | Manage Agent Blueprints |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Agent Identity (beta) | Update Blueprint's inherited permissions |
| `Application.ReadWrite.All` | Application | Create and manage applications |
| `DelegatedPermissionGrant.ReadWrite.All` | Delegated Permission Grant | Grant permissions for blueprints |
| `Directory.Read.All` | Directory | Read directory data |

4. Click **Add permissions**
5. Click **Grant admin consent for [Your Tenant]**
6. Verify all 5 permissions show green ✅ checkmarks in the "Status" column

#### Option B — Via Microsoft Graph API (if beta permissions not visible)

If `AgentIdentityBlueprint.*` doesn't appear in the portal search:

1. Go to [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
2. Sign in with your M365 Tenant admin account

**Step B.1** — Get the app's Service Principal ID:
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{YOUR-CLIENT-ID}'&$select=id
```
If the result is empty, create it first:
```http
POST https://graph.microsoft.com/v1.0/servicePrincipals
Content-Type: application/json

{ "appId": "{YOUR-CLIENT-ID}" }
```

Record the `id` as `SP_OBJECT_ID`: `________-____-____-____-____________`

**Step B.2** — Get the Microsoft Graph Resource ID:
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=id
```
Record the `id` as `GRAPH_RESOURCE_ID`: `________-____-____-____-____________`

**Step B.3** — Create delegated permissions with automatic admin consent:
```http
POST https://graph.microsoft.com/v1.0/oauth2PermissionGrants
Content-Type: application/json

{
  "clientId": "<SP_OBJECT_ID>",
  "consentType": "AllPrincipals",
  "principalId": null,
  "resourceId": "<GRAPH_RESOURCE_ID>",
  "scope": "Application.ReadWrite.All Directory.Read.All DelegatedPermissionGrant.ReadWrite.All AgentIdentityBlueprint.ReadWrite.All AgentIdentityBlueprint.UpdateAuthProperties.All"
}
```

> ⚠️ **WARNING**: If you used Option B, do **NOT** click "Grant admin consent" in the Entra portal afterwards. The portal doesn't see beta permissions and will **overwrite** what you created via API.

**4.2 - Verify permissions**

After granting (via either option), confirm:

| Permission | Type | Admin Consent | Status |
|-----------|------|:-------------:|:------:|
| `AgentIdentityBlueprint.ReadWrite.All` | Delegated | ✅ | Granted |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Delegated | ✅ | Granted |
| `Application.ReadWrite.All` | Delegated | ✅ | Granted |
| `DelegatedPermissionGrant.ReadWrite.All` | Delegated | ✅ | Granted |
| `Directory.Read.All` | Delegated | ✅ | Granted |

**Success Criteria**:
- ✅ All 5 delegated permissions added
- ✅ Admin consent granted for the tenant
- ✅ All permissions show green checkmarks
- ✅ No application permissions were accidentally added

### Task 5: Create a365.config.json (15 minutes)

Now that the Entra ID application is registered with the correct permissions, create the A365 configuration file.

**5.1 - Authenticate to M365 Tenant**

```powershell
# Login to M365 Tenant (Tenant B)
az login --tenant <M365-TENANT-ID>

# Verify you're in the correct tenant
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> **Note**: `az login` is necessary for CLI authentication to M365's Entra ID. You don't need an Azure subscription in this tenant.

**5.2 - Navigate to lesson directory**

```powershell
cd lesson-6-a365-prereq
```

**5.3 - Create the configuration file**

Create `a365.config.json` with the following content, replacing the placeholders:

```json
{
  "$schema": "./a365.config.schema.json",
  "tenantId": "<M365-TENANT-ID>",
  "clientAppId": "<CLIENT-ID-FROM-TASK-2>",
  "agentBlueprintDisplayName": "Financial Market Agent Blueprint",
  "agentIdentityDisplayName": "Financial Market Agent Identity",
  "agentUserPrincipalName": "fin-market-agent@<M365-DOMAIN>.onmicrosoft.com",
  "agentUserDisplayName": "Financial Market Agent",
  "managerEmail": "<YOUR-EMAIL>@<M365-DOMAIN>.com",
  "agentUserUsageLocation": "BR",
  "deploymentProjectPath": ".",
  "needDeployment": false,
  "messagingEndpoint": "<ACA-URL-FROM-LAB-4>/api/messages",
  "agentDescription": "Financial market agent (LangGraph on ACA) - A365 Workshop"
}
```

**Field reference:**

| Field | Value | Where it Comes From |
|-------|-------|---------------------|
| `tenantId` | M365 Tenant GUID | Task 1 (Entra admin center) |
| `clientAppId` | Application (client) ID | Task 2 (App registration) |
| `agentUserPrincipalName` | `name@domain.onmicrosoft.com` | Your M365 tenant domain |
| `managerEmail` | Admin email in M365 tenant | Your M365 admin account |
| `needDeployment` | `false` | Agent already runs in ACA (Lab 4) |
| `messagingEndpoint` | ACA URL + `/api/messages` | Lab 4 deploy.ps1 output |

> **Key**: Setting `needDeployment: false` tells the CLI to skip Azure infrastructure creation. The agent continues running in ACA (Tenant A). The CLI only registers the identity in M365's Entra ID.

**5.4 - Validate the configuration**

```powershell
# Verify the file exists
Test-Path a365.config.json
# Expected: True

# Display the configuration
a365 config display
```

**Validation checklist:**
- [ ] `tenantId` is the M365 Tenant GUID (NOT the Azure Tenant)
- [ ] `clientAppId` matches the Application (client) ID from Task 2
- [ ] `needDeployment` is `false`
- [ ] `messagingEndpoint` points to ACA from Lab 4 with `/api/messages` suffix
- [ ] `agentUserPrincipalName` uses the domain `@<M365-tenant>.onmicrosoft.com`
- [ ] `managerEmail` uses an email in the M365 Tenant domain

**Success Criteria**:
- ✅ `a365.config.json` created with all required fields
- ✅ `a365 config display` shows the configuration without errors
- ✅ All placeholder values replaced with real values
- ✅ `needDeployment` set to `false`

### Task 6: Compare Hosting & Authentication Models (10 minutes)

**Complete the comparison table:**

| Aspect | Hosted Agent (Lab 2-3) | ACA + A365 (Labs 4-6) |
|--------|------------------------|------------------------|
| **Agent Code Runs On** | ? | ? |
| **Identity Provider** | ? | ? |
| **Authentication Flow** | ? | ? |
| **Config File** | ? | ? |
| **Entra App Registration** | ? | ? |
| **Endpoint Type** | ? | ? |
| **M365 Integration** | ? | ? |
| **When to Use** | ? | ? |

**Reflect on these questions:**
1. Why does A365 require a separate app registration in the M365 Tenant?
2. What is the role of `needDeployment: false` — what does it skip and what does it still do?
3. If Azure and M365 were in the same tenant, which fields in `a365.config.json` would change?

**Success Criteria**:
- ✅ Table completed with accurate information
- ✅ Can explain the cross-tenant architecture
- ✅ Understands why `needDeployment: false` is used

## Deliverables

- [x] .NET SDK and A365 CLI installed
- [x] Entra ID app registration (`a365-workshop-cli`) created
- [x] Redirect URIs configured (localhost + broker plugin)
- [x] 5 delegated Graph permissions granted with admin consent
- [x] Application (client) ID captured
- [x] `a365.config.json` created and validated
- [x] Comparison table completed

## Evaluation Criteria

| Criterion | Points | Description |
|-----------|--------|-------------|
| **App Registration** | 25 pts | Created correctly in M365 Tenant with single-tenant scope |
| **Redirect URIs** | 15 pts | Both URIs configured (localhost + broker plugin with correct Client ID) |
| **API Permissions** | 25 pts | All 5 delegated permissions with admin consent granted |
| **Config File** | 25 pts | Valid `a365.config.json` with correct values and `needDeployment: false` |
| **Architecture Understanding** | 10 pts | Comparison table demonstrates cross-tenant understanding |

**Total**: 100 points

## Troubleshooting

### "AgentIdentityBlueprint permissions not found in portal"
- **Cause**: These are beta permissions not yet GA
- **Fix**: Use Option B (Graph API) from Task 4 to set permissions programmatically

### "Grant admin consent" button is grayed out
- **Cause**: You don't have Global Administrator role in M365 Tenant
- **Fix**: Ask an admin to grant consent, or get the role assigned to you

### "Application (client) ID" vs "Object ID"
- **Cause**: Common confusion — they look similar (both GUIDs)
- **Fix**: Use **Application (client) ID** (shown first on Overview page). Object ID is NOT what the CLI expects.

### `a365 config display` shows errors
- **Cause**: Invalid JSON or missing required fields
- **Fix**: Validate JSON syntax. Ensure all required fields are present. Check for trailing commas.

### `az login --tenant` doesn't work
- **Cause**: Account doesn't have access to M365 Tenant
- **Fix**: Verify your account exists in M365 Tenant. Try authenticating at https://entra.microsoft.com first.

### Redirect URI mismatch errors
- **Cause**: Broker plugin URI doesn't match Client ID
- **Fix**: Verify the URI is exactly `ms-appx-web://Microsoft.AAD.BrokerPlugin/{YOUR-CLIENT-ID}` with the correct Client ID

### "Admin consent was overwritten after using Graph API"
- **Cause**: Clicked "Grant admin consent" in portal after using Option B
- **Fix**: Re-run the Graph API `POST /oauth2PermissionGrants` request from Option B. The portal doesn't see beta permissions and overwrites them.

## Time Estimate

- Task 1: 10 minutes
- Task 2: 15 minutes
- Task 3: 10 minutes
- Task 4: 20 minutes
- Task 5: 15 minutes
- Task 6: 10 minutes
- **Total**: 80 minutes

## Next Steps

- **Lab 5**: Use the Agent 365 SDK to set up the Agent Blueprint, publish to M365 Admin Center, and create agent instances in Teams
- Test the full end-to-end flow: Teams → M365 → ACA → Azure OpenAI → Response

---

**Difficulty**: Intermediate  
**Prerequisites**: Lab 4, access to M365 Tenant with admin privileges  
**Estimated Time**: 80 minutes
