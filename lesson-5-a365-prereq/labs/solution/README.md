# Lesson 5 - A365 Prerequisites: Entra ID App Registration

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

This script automates the **Entra ID Application Registration** and **a365.config.json** setup required for publishing agents to Microsoft 365 via the Agent 365 CLI.

## Architecture

```
┌──────────────────────────────────────────────────┐
│ Script: setup-entra-app.ps1                      │
│                                                  │
│  1. Validate prerequisites                       │
│  2. az ad app create ──────► Entra ID App Reg    │
│  3. az ad app update ──────► Redirect URIs       │
│  4. az ad sp create  ──────► Service Principal   │
│  5. az rest POST     ──────► Graph Permissions   │
│  6. ConvertTo-Json   ──────► a365.config.json    │
└──────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ M365 Tenant (Entra ID)                           │
│                                                  │
│  App: a365-workshop-cli                          │
│  - Client ID captured                            │
│  - Redirect URIs: localhost + broker plugin      │
│  - 5 delegated Graph permissions (admin consent) │
│                                                  │
│  a365.config.json → messagingEndpoint → ACA URL  │
└──────────────────────────────────────────────────┘
```

## File Structure

```
lesson-5-a365-prereq/labs/
  LAB-STATEMENT.md         # Lab instructions (English)
  LAB-STATEMENT.pt-BR.md   # Lab instructions (Portuguese)
  solution/
    setup-entra-app.ps1    # Complete solution script
    README.md              # This file
    README.pt-BR.md        # Portuguese README
  starter/
    setup-entra-app.ps1    # Starter with TODOs for students
```

## Prerequisites

- .NET 8.0+ SDK
- Azure CLI (`az`) installed and logged in
- Agent 365 CLI (`dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease`)
- Global Administrator or Agent ID Administrator role in M365 Tenant
- ACA agent URL from Lab 4

## Usage

```powershell
.\setup-entra-app.ps1 `
    -M365TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -M365Domain "contoso.onmicrosoft.com" `
    -AcaUrl "https://aca-lg-agent.xxxxx.eastus.azurecontainerapps.io" `
    -ManagerEmail "admin@contoso.com"
```

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-AppDisplayName` | `a365-workshop-cli` | Entra ID app registration name |
| `-AgentDisplayName` | `Financial Market Agent` | Agent display name in A365 config |
| `-AgentUpnPrefix` | `fin-market-agent` | Agent UPN prefix (before @domain) |
| `-OutputDir` | `.` | Directory where a365.config.json is created |

## What the Script Does

| Step | Action | Azure CLI Command |
|------|--------|-------------------|
| 1 | Validate prerequisites | `dotnet --version`, `a365 -h`, `az account show` |
| 2 | Register Entra ID app | `az ad app create --sign-in-audience AzureADMyOrg` |
| 3 | Configure redirect URIs | `az ad app update --public-client-redirect-uris` |
| 4 | Create service principal | `az ad sp create --id <client-id>` |
| 5 | Grant Graph permissions | `az rest POST /oauth2PermissionGrants` |
| 6 | Generate a365.config.json | `ConvertTo-Json \| Set-Content` |

## Permissions Granted

The script grants 5 **delegated** permissions with admin consent:

| Permission | Purpose |
|-----------|---------|
| `AgentIdentityBlueprint.ReadWrite.All` | Manage Agent Blueprints |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Update Blueprint auth properties |
| `Application.ReadWrite.All` | Create/manage applications |
| `DelegatedPermissionGrant.ReadWrite.All` | Grant permissions for blueprints |
| `Directory.Read.All` | Read directory data |

> **Note**: `AgentIdentityBlueprint.*` are beta permissions. The script uses the Graph API directly (`az rest`) to handle these, since they may not appear in the Entra admin portal UI.

## Starter vs Solution

| Aspect | Starter | Solution |
|--------|---------|----------|
| **Parameter validation** | ✅ Provided | ✅ Provided |
| **Prerequisite checks** | ✅ Provided | ✅ Provided |
| **App registration** | ❌ TODO | ✅ Implemented |
| **Redirect URIs** | ❌ TODO | ✅ Implemented |
| **Service principal** | ❌ TODO | ✅ Implemented |
| **Permission grants** | ❌ TODO | ✅ Implemented |
| **Config generation** | ❌ TODO | ✅ Implemented |

The starter has **7 TODOs** for students to implement, with detailed hints for each.

## Validation

After running the script:

```powershell
# Verify the config file
a365 config display

# Verify the app in Entra
az ad app show --id <CLIENT_ID> --query "{name:displayName, signInAudience:signInAudience}" -o table

# Verify redirect URIs
az ad app show --id <CLIENT_ID> --query "publicClient.redirectUris" -o json

# Verify permissions
az rest --method GET --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?\$filter=clientId eq '<SP_ID>'" --query "value[0].scope" -o tsv
```

## Idempotency

The script is **idempotent** — it can be run multiple times safely:
- Checks if the app registration already exists before creating
- Checks if the service principal already exists before creating
- Updates existing permission grants instead of failing on duplicates

## Next Steps

After completing this lab, proceed to **Lab 6** to:
1. Create the Agent Blueprint: `a365 agent-identity create-blueprint`
2. Publish to M365 Admin Center: `a365 agent-identity publish`
3. Create agent instances in Teams
