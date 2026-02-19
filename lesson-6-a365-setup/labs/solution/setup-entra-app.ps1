# setup-entra-app.ps1 - Register Entra ID Application and Configure Agent 365
#
# Lesson 5 - A365 Prerequisites (SOLUTION)
#
# Usage:
#   .\setup-entra-app.ps1 -M365TenantId <GUID> -M365Domain <domain> -AcaUrl <URL> -ManagerEmail <email>
#   .\setup-entra-app.ps1 -M365TenantId <GUID> -M365Domain <domain> -AcaUrl <URL> -ManagerEmail <email> -ResourceGroup rg-ai-agents-workshop -AzureLocation eastus
#
# What this script does:
#   1. Validates prerequisites (.NET SDK, Agent 365 CLI, Azure CLI login)
#   2. Registers an application in Entra ID (M365 Tenant)
#   3. Configures redirect URIs (localhost + WAM broker plugin)
#   4. Creates a service principal for the app
#   5. Grants 5 delegated Microsoft Graph permissions with admin consent
#   6. Generates a365.config.json
#   7. Pre-caches MgGraph token via device code (avoids hidden WAM dialog)
#   8. Runs 'a365 setup all --skip-infrastructure' (blueprint + permissions)
#
# Prerequisites:
#   - .NET 8.0+ SDK installed
#   - Agent 365 CLI installed (dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease)
#   - Azure CLI logged in to M365 Tenant (az login --tenant <M365-TENANT-ID> --use-device-code)
#   - Global Administrator or Agent ID Administrator role in M365 Tenant
#
# NOTE: Uses --use-device-code for WSL2 / headless environments where
#       browser-based login is not available.

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
    [string]$OutputDir = ".",

    [Parameter(Mandatory = $false, HelpMessage = "Azure resource group where the ACA agent is deployed (from prereq/main.bicepparam)")]
    [string]$ResourceGroup = "rg-ai-agents-workshop",

    [Parameter(Mandatory = $false, HelpMessage = "Azure region where the ACA agent is deployed (from prereq/main.bicepparam)")]
    [string]$AzureLocation = "eastus"
)

$ErrorActionPreference = "Stop"

# Microsoft Graph well-known app ID
$GRAPH_APP_ID = "00000003-0000-0000-c000-000000000000"

# Required delegated permissions (space-separated scope string)
$REQUIRED_SCOPES = "Application.ReadWrite.All Directory.Read.All DelegatedPermissionGrant.ReadWrite.All AgentIdentityBlueprint.ReadWrite.All AgentIdentityBlueprint.UpdateAuthProperties.All"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Lesson 5 - A365 Prerequisites"
Write-Host " Entra ID App Registration"
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------
# 1. Validate Prerequisites
# -----------------------------------------------------------
Write-Host "[1/8] Validating prerequisites..." -ForegroundColor Yellow

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
Write-Host "[2/8] Registering application in Entra ID..." -ForegroundColor Yellow

# Check if app already exists
$existingApp = az ad app list --display-name $AppDisplayName --query "[0].appId" -o tsv 2>$null

if ($existingApp) {
    Write-Host "  App '$AppDisplayName' already exists with Client ID: $existingApp" -ForegroundColor Yellow
    $CLIENT_ID = $existingApp
} else {
    # Create the app registration
    # - Single tenant (AzureADMyOrg)
    # - Public client with localhost redirect URI
    $appJson = az ad app create `
        --display-name $AppDisplayName `
        --sign-in-audience AzureADMyOrg `
        --public-client-redirect-uris "http://localhost:8400/" `
        --query "{appId:appId, objectId:id}" `
        -o json | ConvertFrom-Json

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
Write-Host "[3/8] Configuring redirect URIs..." -ForegroundColor Yellow

$BROKER_URI = "ms-appx-web://Microsoft.AAD.BrokerPlugin/$CLIENT_ID"

# Update the app to include both redirect URIs
az ad app update `
    --id $CLIENT_ID `
    --public-client-redirect-uris "http://localhost:8400/" $BROKER_URI

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
Write-Host "[4/8] Creating service principal..." -ForegroundColor Yellow

# Check if SP already exists
$spId = az ad sp list --filter "appId eq '$CLIENT_ID'" --query "[0].id" -o tsv 2>$null

if ($spId) {
    Write-Host "  Service principal already exists: $spId" -ForegroundColor Yellow
} else {
    $spJson = az ad sp create --id $CLIENT_ID --query "id" -o tsv 2>$null
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
#    Uses az rest to call Microsoft Graph directly.
#    This is equivalent to Option B in the lab statement,
#    which handles beta permissions (AgentIdentityBlueprint.*)
#    that may not be visible in the Entra portal UI.
# -----------------------------------------------------------
Write-Host "[5/8] Granting delegated permissions via Graph API..." -ForegroundColor Yellow

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

# Use a temp file for the request body to avoid az rest JSON parsing issues on Windows
$tmpBody = Join-Path $env:TEMP "az_rest_body_$([System.IO.Path]::GetRandomFileName()).json"

if ($existingGrant) {
    # Check consentType — can only PATCH grants of the same consentType
    $grantDetails = az rest --method GET `
        --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$existingGrant" `
        -o json 2>$null | ConvertFrom-Json
    $existingConsentType = $grantDetails.consentType

    if ($existingConsentType -eq "AllPrincipals") {
        Write-Host "  Permission grant already exists (AllPrincipals). Updating scopes..." -ForegroundColor Yellow

        @{ scope = $REQUIRED_SCOPES } | ConvertTo-Json -Compress | Set-Content $tmpBody -Encoding UTF8
        az rest `
            --method PATCH `
            --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$existingGrant" `
            --headers "Content-Type=application/json" `
            --body "@$tmpBody" 2>$null

        if ($LASTEXITCODE -ne 0) {
            Write-Host "  WARN: PATCH failed. Deleting and recreating..." -ForegroundColor Yellow
            az rest --method DELETE --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$existingGrant" 2>$null
            $existingGrant = $null
        } else {
            Write-Host "  Scopes updated successfully." -ForegroundColor Green
        }
    } else {
        # consentType mismatch (e.g. "Principal" vs "AllPrincipals") — delete and recreate
        Write-Host "  Existing grant has consentType '$existingConsentType'. Deleting to recreate as AllPrincipals..." -ForegroundColor Yellow
        az rest --method DELETE --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$existingGrant" 2>$null
        $existingGrant = $null
    }
}

if (-not $existingGrant) {
    # Create new oauth2PermissionGrant with admin consent for all principals
    @{
        clientId    = $spId
        consentType = "AllPrincipals"
        resourceId  = $graphSpId
        scope       = $REQUIRED_SCOPES
    } | ConvertTo-Json -Compress | Set-Content $tmpBody -Encoding UTF8

    az rest `
        --method POST `
        --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants" `
        --headers "Content-Type=application/json" `
        --body "@$tmpBody" 2>$null

    if ($LASTEXITCODE -ne 0) {
        Remove-Item $tmpBody -ErrorAction SilentlyContinue
        Write-Host "  ERRO: Failed to create permission grant." -ForegroundColor Red
        Write-Host "  Ensure you have Global Administrator or Privileged Role Administrator role." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Permission grant created." -ForegroundColor Green
}

Remove-Item $tmpBody -ErrorAction SilentlyContinue

# 5c. Display granted permissions
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
Write-Host "[6/8] Generating a365.config.json..." -ForegroundColor Yellow

# Ensure ACA URL doesn't have a trailing slash
$AcaUrlClean = $AcaUrl.TrimEnd('/')

$config = @{
    '$schema'                   = "./a365.config.schema.json"
    tenantId                    = $M365TenantId
    clientAppId                 = $CLIENT_ID
    agentBlueprintDisplayName   = "$AgentDisplayName Blueprint"
    agentIdentityDisplayName    = "$AgentDisplayName Identity"
    agentUserPrincipalName      = "$AgentUpnPrefix@$M365Domain"
    agentUserDisplayName        = $AgentDisplayName
    managerEmail                = $ManagerEmail
    agentUserUsageLocation      = "BR"
    deploymentProjectPath       = "."
    needDeployment              = $false
    messagingEndpoint           = "$AcaUrlClean/api/messages"
    agentDescription            = "$AgentDisplayName (LangGraph on ACA) - A365 Workshop"
    resourceGroup               = $ResourceGroup
    location                    = $AzureLocation
}

$configPath = Join-Path $OutputDir "a365.config.json"
$config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

Write-Host "  Created: $configPath" -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------
# 7. Pre-cache MgGraph Token (avoid hidden WAM dialog)
#
#    a365 setup blueprint spawns a pwsh -NonInteractive subprocess that
#    calls Connect-MgGraph. On Windows, MSAL defaults to WAM (Windows
#    Web Account Manager) which shows a Win32 dialog hidden behind VS Code.
#    Pre-authenticating here with -UseDeviceAuthentication caches the token
#    on disk so the subprocess reuses it silently.
# -----------------------------------------------------------
Write-Host "[7/8] Pre-caching Microsoft Graph token (device code)..." -ForegroundColor Yellow
Write-Host "  This avoids the hidden WAM dialog in the next step." -ForegroundColor White
Write-Host ""

$mgScopes = @(
    'Application.ReadWrite.All',
    'Directory.Read.All',
    'DelegatedPermissionGrant.ReadWrite.All',
    'AgentIdentityBlueprint.ReadWrite.All'
)

try {
    pwsh -NoProfile -Command "
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Connect-MgGraph -TenantId '$M365TenantId' -ClientId '$CLIENT_ID' -Scopes @('$($mgScopes -join "','")')  -UseDeviceAuthentication -NoWelcome -ErrorAction Stop
        Write-Host 'MgGraph token cached OK'
    "
    if ($LASTEXITCODE -ne 0) { throw "Connect-MgGraph failed" }
    Write-Host "  MgGraph token cached." -ForegroundColor Green
} catch {
    Write-Host "  WARN: Could not pre-cache MgGraph token: $_" -ForegroundColor Yellow
    Write-Host "  The next step may show a browser/WAM login prompt - complete it when it appears." -ForegroundColor Yellow
}
Write-Host ""

# -----------------------------------------------------------
# 8. Run a365 setup all --skip-infrastructure
#
#    --skip-infrastructure: skips Azure resource provisioning
#    (App Service, storage, etc.) — not needed here since the
#    agent is already deployed on ACA from Lesson 4.
#    Only creates the Agent Blueprint in Entra ID, sets up OAuth
#    permissions, and registers the messaging endpoint.
# -----------------------------------------------------------
Write-Host "[8/8] Running a365 setup all --skip-infrastructure..." -ForegroundColor Yellow
Write-Host "  Config: $configPath" -ForegroundColor White
Write-Host ""

Push-Location (Split-Path $configPath -Parent)
try {
    a365 setup all --skip-infrastructure --config (Split-Path $configPath -Leaf) -v
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "  WARN: a365 setup exited with code $LASTEXITCODE." -ForegroundColor Yellow
        Write-Host "  Review the output above and the log at:" -ForegroundColor Yellow
        Write-Host "  %LOCALAPPDATA%\Microsoft.Agents.A365.DevTools.Cli\logs\a365.setup.log" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  To retry only the endpoint registration:" -ForegroundColor Yellow
        Write-Host "    a365 setup blueprint --endpoint-only --config $(Split-Path $configPath -Leaf)" -ForegroundColor Cyan
    } else {
        Write-Host "  a365 setup completed successfully." -ForegroundColor Green
    }
} finally {
    Pop-Location
}
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
Write-Host "  Redirect URIs:" -ForegroundColor White
Write-Host "    1. http://localhost:8400/" -ForegroundColor Cyan
Write-Host "    2. $BROKER_URI" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Delegated Permissions (admin-consented):" -ForegroundColor White
$REQUIRED_SCOPES.Split(' ') | ForEach-Object {
    Write-Host "    - $_" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host " Validate the configuration:"
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Display effective config" -ForegroundColor White
Write-Host "  cd $OutputDir && a365 config display" -ForegroundColor Cyan
Write-Host ""
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host " If endpoint registration failed (Frontier):"
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Ensure the 'Agent ID Developer' role is assigned to your admin" -ForegroundColor White
Write-Host "  account in Entra ID, and that Copilot Frontier is enabled in" -ForegroundColor White
Write-Host "  M365 Admin Center -> Copilot -> Settings -> User access." -ForegroundColor White
Write-Host ""
Write-Host "  # Retry endpoint only:" -ForegroundColor White
Write-Host "  a365 setup blueprint --endpoint-only --config a365.config.json" -ForegroundColor Cyan
Write-Host ""
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host " Next Steps (Lab 7/8):"
Write-Host "--------------------------------------" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Publish agent to M365 Admin Center" -ForegroundColor White
Write-Host "  a365 publish" -ForegroundColor Cyan
Write-Host ""
