# Prerequisites - Azure Infrastructure

This folder contains Infrastructure as Code (IaC) scripts using Bicep to provision all required resources for the workshop.

## Provisioned Resources

- **Azure OpenAI Service** - With GPT-5.2 model deployment
- **Azure Container Registry** - To store agent Docker images
- **Container Apps Environment** - Environment to run the LangGraph Agent
- **Container App** - For the LangGraph Agent
- **AI Hub** - Microsoft Foundry workspace
- **AI Project** - To host the Agent Framework Agent
- **Log Analytics Workspace** - For logs and monitoring
- **Application Insights** - For telemetry and observability
- **Storage Account** - For the AI Hub
- **Key Vault** - For the AI Hub

## 🚀 Quick Deploy (Recommended)

Use the automated script for complete deployment:

```powershell
.\deploy.ps1 -ResourceGroupName "rg-agent365-workshop" -Location "eastus"
```

### Script Parameters

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

```powershell
$RESOURCE_GROUP = "rg-agent365-workshop"
$LOCATION = "eastus"
$SUBSCRIPTION_ID = "your-subscription-id"
```

### 2. Login to Azure

```powershell
az login
az account set --subscription $SUBSCRIPTION_ID
```

### 3. Install required extensions

```powershell
az extension add --name containerapp
az extension add --name ml
```

### 4. Create the Resource Group

```powershell
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5. Deploy the infrastructure

```powershell
az deployment group create `
  --resource-group $RESOURCE_GROUP `
  --template-file main.bicep `
  --parameters main.bicepparam
```

Or with inline parameters:

```powershell
az deployment group create `
  --resource-group $RESOURCE_GROUP `
  --template-file main.bicep `
  --parameters location=$LOCATION `
  --parameters openAIServiceName="openai-workshop-demo" `
  --parameters acrName="acrworkshop123" `
  --parameters logAnalyticsName="log-workshop" `
  --parameters appInsightsName="appi-workshop" `
  --parameters containerAppsEnvName="cae-workshop" `
  --parameters langgraphAgentName="ca-langgraph-agent" `
  --parameters agentFrameworkAgentName="ca-agent-framework"
```

### 6. Capture the outputs

```powershell
az deployment group show `
  --resource-group $RESOURCE_GROUP `
  --name main `
  --query properties.outputs
```

## ✅ Validation

### 7. Validate the deployment

Execute the validation script to ensure all resources were created correctly:

```powershell
.\validate-deployment.ps1 -ResourceGroupName $RESOURCE_GROUP -DeploymentName "main"
```

The script will:
- ✓ Verify the existence of all resources
- ✓ Validate provisioning status
- ✓ Test configurations and connections
- ✓ Generate a detailed JSON report
- ✓ Display important information (endpoints, URLs, etc.)

**Expected success rate:** ≥ 90%

## ⚙️ Customizable Parameters

Edit the `main.bicepparam` file to customize:

- `location` - Azure region (default: eastus)
- `openAIServiceName` - Azure OpenAI service name
- `gpt52DeploymentName` - GPT-5.2 deployment name
- `acrName` - Azure Container Registry name
- `langgraphAgentName` - Container App name for LangGraph
- `agentFrameworkAgentName` - Container App name for Agent Framework
- `gpt52Capacity` - Model TPM capacity (default: 100)
- `gpt52ModelVersion` - GPT-5.2 model version
- `aiHubName` - AI Hub name (Microsoft Foundry)
- `aiProjectName` - AI Project name

## 📝 Files

- **deploy.ps1** - Automated deployment script
- **validate-deployment.ps1** - Post-deployment validation script
- **main.bicep** - Main infrastructure template
- **main.bicepparam** - Parameters file

## 🎯 Next Steps

After successful deployment:
1. Note the output values (endpoints, keys, URLs)
2. Configure environment variables in agent projects
3. Build and push Docker images to ACR
4. Update Container Apps with the correct images
