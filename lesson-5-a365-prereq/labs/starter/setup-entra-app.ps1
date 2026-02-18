# setup-entra-app.ps1 - Register Entra ID Application and Configure Agent 365
#
# Lesson 6 - A365 Prerequisites (STARTER)
#
# Usage:
#   .\setup-entra-app.ps1 -M365TenantId <GUID> -M365Domain <domain> -AcaUrl <URL> -ManagerEmail <email>
#
# What this script does:
#   1. Validates prerequisites (.NET SDK, Agent 365 CLI, Azure CLI login)
#   2. Registers an application in Entra ID (M365 Tenant)
#   3. Configures redirect URIs (localhost + WAM broker plugin)
#   4. Creates a service principal for the app
#   5. Grants 5 delegated Microsoft Graph permissions with admin consent
#   6. Generates a365.config.json
#
# Prerequisites:
#   - .NET 8.0+ SDK installed
#   - Agent 365 CLI installed (dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease)
#   - Azure CLI logged in to M365 Tenant (az login --tenant <M365-TENANT-ID> --use-device-code)
#   - Global Administrator or Agent ID Administrator role in M365 Tenant
#
# NOTE: Uses --use-device-code for WSL2 / headless environments where
#       browser-based login is not available.
#
# INSTRUCTIONS:
#   Search for "TODO" comments and implement each step.
#   Each TODO has hints to guide you. Run the script after each step to test incrementally.

param(
    [Parameter(Mandatory = $true, HelpMessage = "M365 Tenant ID (Tenant B) - GUID")]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$M365TenantId,

    [Parameter(Mandatory = $true, HelpMessage = "M365 Tenant domain (e.g., contoso.onmicrosoft.com)")]
    [string]$M365Domain,

    [Parameter(Mandatory = $true, HelpMessage = "ACA agent URL from Lab 4 (e.g., https://aca-lg-agent.xxx.eastus.azurecontainerapps.io)")]
    [ValidatePattern('^https://')]
    [string]$AcaUrl,

    [Parameter(Mandatory = $true, HelpMessage = "Manager email in M365 Tenant")]
    [ValidatePattern('.+@.+\..+')]
    [string]$ManagerEmail,

    [Parameter(Mandatory = $false, HelpMessage = "App registration display name")]
    [string]$AppDisplayName = "a365-workshop-cli",

    [Parameter(Mandatory = $false, HelpMessage = "Agent display name for A365")]
    [string]$AgentDisplayName = "Financial Market Agent",

    [Parameter(Mandatory = $false, HelpMessage = "Agent UPN prefix (without domain)")]
    [string]$AgentUpnPrefix = "fin-market-agent",

    [Parameter(Mandatory = $false, HelpMessage = "Output directory for a365.config.json")]
    [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"

# Microsoft Graph well-known app ID
$GRAPH_APP_ID = "00000003-0000-0000-c000-000000000000"

# TODO 5a: Define the 5 required delegated permission scopes as a space-separated string.
# Hint: The permissions needed are:
#   - Application.ReadWrite.All
#   - Directory.Read.All
#   - DelegatedPermissionGrant.ReadWrite.All
#   - AgentIdentityBlueprint.ReadWrite.All
#   - AgentIdentityBlueprint.UpdateAuthProperties.All
$REQUIRED_SCOPES = ""  # <-- Fill in the scopes

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Lesson 6 - A365 Prerequisites"
Write-Host " Entra ID App Registration"
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 1. Validate Prerequisites
# -----------------------------------------------------------
Write-Host "[1/6] Validating prerequisites..." -ForegroundColor Yellow

# 1a. Check .NET SDK
$dotnetVersion = $null
try {
    $dotnetVersion = dotnet --version 2>$null
} catch {}

if (-not $dotnetVersion) {
    Write-Host "  ERRO: .NET SDK not found. Install from https://dotnet.microsoft.com/download" -ForegroundColor Red
    exit 1
}

$majorVersion = [int]($dotnetVersion.Split('.')[0])
if ($majorVersion -lt 8) {
    Write-Host "  ERRO: .NET SDK 8.0+ required. Found: $dotnetVersion" -ForegroundColor Red
    exit 1
}
Write-Host "  .NET SDK:    $dotnetVersion" -ForegroundColor Green

# 1b. Check A365 CLI
$a365Available = $false
try {
    $a365Help = a365 -h 2>$null
    $a365Available = $true
} catch {}

if (-not $a365Available) {
    Write-Host "  WARN: A365 CLI not found. Installing..." -ForegroundColor Yellow
    dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO: Failed to install A365 CLI." -ForegroundColor Red
        exit 1
    }
    Write-Host "  A365 CLI installed." -ForegroundColor Green
} else {
    Write-Host "  A365 CLI:    Installed" -ForegroundColor Green
}

# 1c. Login to Azure CLI on M365 Tenant
#
#     Logic:
#     - Check if already logged into the correct M365 tenant → skip login.
#     - If logged into a different tenant → logout, then login to correct one.
#     - If not logged in at all → login directly.
#     - Uses --allow-no-subscriptions (M365 tenant may have no Azure subscription).
#     - Uses --use-device-code for WSL2 / headless environments.

$currentTenant = $null
try {
    $currentTenant = az account show --query tenantId -o tsv 2>$null
} catch {}

if ($currentTenant -eq $M365TenantId) {
    Write-Host "  Azure CLI:   Already logged in to tenant $M365TenantId" -ForegroundColor Green
} else {
    if ($currentTenant) {
        Write-Host "  Current tenant ($currentTenant) differs from M365 Tenant ($M365TenantId)." -ForegroundColor Yellow
        Write-Host "  Logging out from current session..." -ForegroundColor White
        az logout 2>$null
    } else {
        Write-Host "  Azure CLI not logged in." -ForegroundColor Yellow
    }

    Write-Host "  Logging in to M365 Tenant ($M365TenantId)..." -ForegroundColor Yellow
    Write-Host "  (Using device code flow — follow the instructions below)" -ForegroundColor White
    Write-Host "  NOTE: 'No subscriptions found' is EXPECTED if the M365 tenant has no Azure subscription." -ForegroundColor DarkYellow
    Write-Host ""

    az login --tenant $M365TenantId --use-device-code --allow-no-subscriptions
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO: Failed to log in." -ForegroundColor Red
        Write-Host "  Run manually: az login --tenant $M365TenantId --use-device-code --allow-no-subscriptions" -ForegroundColor Yellow
        exit 1
    }

    # Verify we're in the correct tenant
    $currentTenant = az account show --query tenantId -o tsv 2>$null
    if ($currentTenant -ne $M365TenantId) {
        Write-Host "  ERRO: Logged into tenant $currentTenant but expected $M365TenantId." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Azure CLI:   Logged in to tenant $M365TenantId" -ForegroundColor Green
}
Write-Host ""

# -----------------------------------------------------------
# 2. Register Application in Entra ID
# -----------------------------------------------------------
Write-Host "[2/6] Registering application in Entra ID..." -ForegroundColor Yellow

# Check if app already exists
$existingApp = az ad app list --display-name $AppDisplayName --query "[0].appId" -o tsv 2>$null

if ($existingApp) {
    Write-Host "  App '$AppDisplayName' already exists with Client ID: $existingApp" -ForegroundColor Yellow
    $CLIENT_ID = $existingApp
} else {
    # TODO 2: Create the app registration using "az ad app create".
    # Requirements:
    #   - Display name: $AppDisplayName
    #   - Sign-in audience: Single tenant (AzureADMyOrg)
    #   - Public client redirect URI: http://localhost:8400/
    #   - Query output: appId and id fields
    #
    # Hint: Use these az ad app create flags:
    #   --display-name <name>
    #   --sign-in-audience AzureADMyOrg
    #   --public-client-redirect-uris "http://localhost:8400/"
    #   --query "{appId:appId, objectId:id}"
    #   -o json

    $appJson = $null  # <-- Replace with az ad app create command

    if ($LASTEXITCODE -ne 0 -or -not $appJson) {
        Write-Host "  ERRO: Failed to create app registration." -ForegroundColor Red
        exit 1
    }

    $CLIENT_ID = $appJson.appId
    Write-Host "  App registration created." -ForegroundColor Green
}

Write-Host "  Application (client) ID: $CLIENT_ID" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 3. Configure Redirect URIs
# -----------------------------------------------------------
Write-Host "[3/6] Configuring redirect URIs..." -ForegroundColor Yellow

# TODO 3: Build the broker plugin redirect URI.
# The format is: ms-appx-web://Microsoft.AAD.BrokerPlugin/{CLIENT-ID}
# Hint: Concatenate the base URI with the $CLIENT_ID variable.
$BROKER_URI = ""  # <-- Build the broker URI

# TODO 3b: Update the app to include BOTH redirect URIs using "az ad app update".
# Hint: Use these flags:
#   --id $CLIENT_ID
#   --public-client-redirect-uris "http://localhost:8400/" $BROKER_URI

# <-- Add your az ad app update command here

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERRO: Failed to update redirect URIs." -ForegroundColor Red
    exit 1
}

Write-Host "  URI 1: http://localhost:8400/" -ForegroundColor Green
Write-Host "  URI 2: $BROKER_URI" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------
# 4. Create Service Principal
# -----------------------------------------------------------
Write-Host "[4/6] Creating service principal..." -ForegroundColor Yellow

# Check if SP already exists
$spId = az ad sp list --filter "appId eq '$CLIENT_ID'" --query "[0].id" -o tsv 2>$null

if ($spId) {
    Write-Host "  Service principal already exists: $spId" -ForegroundColor Yellow
} else {
    # TODO 4: Create the service principal using "az ad sp create".
    # Hint: Use --id $CLIENT_ID and query the "id" field.
    $spJson = $null  # <-- Replace with az ad sp create command

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO: Failed to create service principal." -ForegroundColor Red
        exit 1
    }
    $spId = $spJson
    Write-Host "  Service principal created." -ForegroundColor Green
}
Write-Host "  SP Object ID: $spId" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 5. Grant Delegated Permissions via Graph API
#
#    Uses "az rest" to call Microsoft Graph directly.
#    This handles beta permissions (AgentIdentityBlueprint.*)
#    that may not be visible in the Entra portal UI.
# -----------------------------------------------------------
Write-Host "[5/6] Granting delegated permissions via Graph API..." -ForegroundColor Yellow

# 5a. Get Microsoft Graph service principal ID
$graphSpId = az ad sp list `
    --filter "appId eq '$GRAPH_APP_ID'" `
    --query "[0].id" `
    -o tsv 2>$null

if (-not $graphSpId) {
    Write-Host "  ERRO: Could not find Microsoft Graph service principal." -ForegroundColor Red
    exit 1
}
Write-Host "  Graph SP ID: $graphSpId"

# 5b. Check if oauth2PermissionGrant already exists
#     Note: Build URL in a variable to avoid PowerShell $-expansion issues
#     with OData $filter in different pwsh invocation modes.
$filterUrl = "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" + '?$filter=' + "clientId eq '$spId' and resourceId eq '$graphSpId'"

$existingGrant = az rest `
    --method GET `
    --url $filterUrl `
    --query "value[0].id" `
    -o tsv 2>$null

if ($existingGrant) {
    Write-Host "  Permission grant already exists. Updating scopes..." -ForegroundColor Yellow

    # TODO 5b: Update the existing grant with $REQUIRED_SCOPES using az rest PATCH.
    # Hint:
    #   - Method: PATCH
    #   - URL: https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$existingGrant
    #   - Body: JSON with the "scope" field set to $REQUIRED_SCOPES
    #   - Use ConvertTo-Json to serialize the body

    # <-- Add your az rest PATCH command here

    Write-Host "  Scopes updated successfully." -ForegroundColor Green
} else {
    # TODO 5c: Create a new oauth2PermissionGrant using az rest POST.
    # This grants delegated permissions with admin consent for all principals.
    #
    # Hint:
    #   - Method: POST
    #   - URL: https://graph.microsoft.com/v1.0/oauth2PermissionGrants
    #   - Body JSON fields:
    #       clientId    = $spId              (your app's service principal)
    #       consentType = "AllPrincipals"    (admin consent for all users)
    #       resourceId  = $graphSpId         (Microsoft Graph's service principal)
    #       scope       = $REQUIRED_SCOPES  (space-separated permission scopes)
    #   - Use ConvertTo-Json -Compress to serialize

    # <-- Add your az rest POST command here

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO: Failed to create permission grant." -ForegroundColor Red
        Write-Host "  Ensure you have Global Administrator or Privileged Role Administrator role." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Permission grant created." -ForegroundColor Green
}

# Display granted permissions
Write-Host ""
Write-Host "  Granted delegated permissions (with admin consent):" -ForegroundColor White
$REQUIRED_SCOPES.Split(' ') | ForEach-Object {
    Write-Host "    [OK] $_" -ForegroundColor Green
}

Write-Host ""
Write-Host "  WARNING: Do NOT click 'Grant admin consent' in the Entra portal." -ForegroundColor Yellow
Write-Host "           The portal may overwrite beta permissions (AgentIdentityBlueprint.*)." -ForegroundColor Yellow
Write-Host ""

# -----------------------------------------------------------
# 6. Generate a365.config.json
# -----------------------------------------------------------
Write-Host "[6/6] Generating a365.config.json..." -ForegroundColor Yellow

# Ensure ACA URL doesn't have a trailing slash
$AcaUrlClean = $AcaUrl.TrimEnd('/')

# TODO 6: Build the $config hashtable with the following fields:
#   - $schema:                    "./a365.config.schema.json"
#   - tenantId:                   $M365TenantId
#   - clientAppId:                $CLIENT_ID
#   - agentBlueprintDisplayName:  "$AgentDisplayName Blueprint"
#   - agentIdentityDisplayName:   "$AgentDisplayName Identity"
#   - agentUserPrincipalName:     "$AgentUpnPrefix@$M365Domain"
#   - agentUserDisplayName:       $AgentDisplayName
#   - managerEmail:               $ManagerEmail
#   - agentUserUsageLocation:     "BR"
#   - deploymentProjectPath:      "."
#   - needDeployment:             $false   <-- IMPORTANT: must be boolean false
#   - messagingEndpoint:          "$AcaUrlClean/api/messages"
#   - agentDescription:           "$AgentDisplayName (LangGraph on ACA) - A365 Workshop"
#
# Hint: Use @{ key = value } syntax to create a PowerShell hashtable,
#       then pipe it to ConvertTo-Json and Set-Content to write the file.

$config = @{}  # <-- Fill in the hashtable fields

$configPath = Join-Path $OutputDir "a365.config.json"

# TODO 6b: Write $config to $configPath as JSON.
# Hint: $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

# <-- Add your ConvertTo-Json | Set-Content command here

Write-Host "  Created: $configPath" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------
# Summary
# -----------------------------------------------------------
Write-Host "======================================" -ForegroundColor Green
Write-Host " Setup Complete!"
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "  App Name:           $AppDisplayName" -ForegroundColor Cyan
Write-Host "  Client ID:          $CLIENT_ID" -ForegroundColor Cyan
Write-Host "  Tenant ID:          $M365TenantId" -ForegroundColor Cyan
Write-Host "  Service Principal:  $spId" -ForegroundColor Cyan
Write-Host "  Config File:        $configPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host " Validate the configuration:"
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Display config" -ForegroundColor White
Write-Host "  cd $OutputDir && a365 config display" -ForegroundColor Cyan
Write-Host ""
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host " Next Steps (Lab 6):"
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Create Agent Blueprint" -ForegroundColor White
Write-Host "  a365 agent-identity create-blueprint" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Publish to M365 Admin Center" -ForegroundColor White
Write-Host "  a365 agent-identity publish" -ForegroundColor Cyan
Write-Host ""
