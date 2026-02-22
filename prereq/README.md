# Prerequisites - Azure Infrastructure

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

This folder contains Infrastructure as Code (IaC) scripts using Bicep to provision all required resources for the workshop.

## Provisioned Resources

- **Azure AI Services (Foundry Account)** - With GPT-4o-mini model deployment
- **Azure Container Registry** - To store agent Docker images
- **AI Project** - Microsoft Foundry project to host agents
- **Log Analytics Workspace** - For logs and monitoring
- **Application Insights** - For telemetry and observability

## 🚀 Quick Deploy (Recommended)

Use the automated script for complete deployment:

**Windows (PowerShell)**:
```powershell
.\deploy.ps1 -ResourceGroupName "rg-agent365-workshop" -Location "eastus"
```

**Linux / WSL (Bash)**:
```bash
chmod +x deploy.sh
./deploy.sh --resource-group "rg-agent365-workshop" --location "eastus"
```

### Script Parameters

**Windows (PowerShell)**:
```powershell
# Basic deploy
.\deploy.ps1

# Deploy with specific subscription
.\deploy.ps1 -SubscriptionId "your-subscription-id"

# Custom deploy
.\deploy.ps1 `
  -ResourceGroupName "my-rg" `
  -Location "westus2" `
  -DeploymentName "workshop-deployment"

# Simulate deployment (WhatIf)
.\deploy.ps1 -WhatIf

# Deploy without automatic validation
.\deploy.ps1 -SkipValidation
```

**Linux / WSL (Bash)**:
```bash
# Basic deploy
./deploy.sh

# Deploy with specific subscription
./deploy.sh --subscription "your-subscription-id"

# Custom deploy
./deploy.sh \
  --resource-group "my-rg" \
  --location "westus2" \
  --deployment-name "workshop-deployment"

# Simulate deployment (what-if)
./deploy.sh --what-if

# Deploy without automatic validation
./deploy.sh --skip-validation
```

The script will:
- ✓ Check prerequisites (Azure CLI, authentication)
- ✓ Install required extensions
- ✓ Create the Resource Group if it doesn't exist
- ✓ Validate the Bicep template
- ✓ Execute the deployment
- ✓ Display the outputs
- ✓ Execute validation automatically

## 📋 Manual Deploy (Alternative)

### 1. Define your environment variables

**Windows (PowerShell)**:
```powershell
$RESOURCE_GROUP = "rg-agent365-workshop"
$LOCATION = "eastus"
$SUBSCRIPTION_ID = "your-subscription-id"
```

**Linux / WSL (Bash)**:
```bash
RESOURCE_GROUP="rg-agent365-workshop"
LOCATION="eastus"
SUBSCRIPTION_ID="your-subscription-id"
```

### 2. Login to Azure

```bash
az login
az account set --subscription $SUBSCRIPTION_ID
```

### 3. Install required extensions

```bash
az extension add --name containerapp
az extension add --name ml
```

### 4. Create the Resource Group

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5. Deploy the infrastructure

**Windows (PowerShell)**:
```powershell
az deployment group create `
  --resource-group $RESOURCE_GROUP `
  --template-file main.bicep `
  --parameters main.bicepparam
```

**Linux / WSL (Bash)**:
```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters main.bicepparam
```

Or with inline parameters:

```bash
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters location=$LOCATION \
  --parameters acrName="acrworkshop123" \
  --parameters logAnalyticsName="log-workshop" \
  --parameters appInsightsName="appi-workshop" \
  --parameters aiHubName="aihub-workshop" \
  --parameters aiProjectName="aiproj-workshop"
```

### 6. Capture the outputs

```bash
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query properties.outputs
```

## ✅ Validation

### 7. Validate the deployment

Execute the validation script to ensure all resources were created correctly:

**Windows (PowerShell)**:
```powershell
.\validate-deployment.ps1 -ResourceGroupName $RESOURCE_GROUP -DeploymentName "main"
```

**Linux / WSL (Bash)**:
```bash
./validate-deployment.sh --resource-group $RESOURCE_GROUP --deployment-name "main"
```

The script will:
- ✓ Verify the existence of all resources
- ✓ Validate provisioning status
- ✓ Test configurations and connections
- ✓ Generate a detailed JSON report
- ✓ Display important information (endpoints, URLs, etc.)

**Expected success rate:** ≥ 90%

## Customizable Parameters

Edit the `main.bicepparam` file to customize:

- `location` - Azure region (default: eastus)
- `aiHubName` - AI Services / Foundry account name
- `aiProjectName` - AI Project name
- `aiModelDeployment` - Model deployment name (default: gpt-4o-mini)
- `acrName` - Azure Container Registry name
- `logAnalyticsName` - Log Analytics workspace name
- `appInsightsName` - Application Insights name
- `modelVersion` - Model version
- `modelCapacity` - Model TPM capacity (default: 100)

## 📝 Files

- **deploy.ps1** - Automated deployment script (Windows/PowerShell)
- **deploy.sh** - Automated deployment script (Linux/WSL/macOS)
- **validate-deployment.ps1** - Post-deployment validation script (Windows/PowerShell)
- **validate-deployment.sh** - Post-deployment validation script (Linux/WSL/macOS)
- **main.bicep** - Main infrastructure template
- **main.bicepparam** - Parameters file

## 🎯 Next Steps

After successful deployment:
1. Note the output values (endpoints, keys, URLs)
2. Configure environment variables in agent projects
3. Build and push Docker images to ACR
4. Update Container Apps with the correct images
