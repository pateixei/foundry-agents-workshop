@description('Nome do Resource Group')
param resourceGroupName string

@description('Região do Azure onde os recursos serão criados')
param location string

@description('Nome do deployment do modelo de AI')
param aiModelDeployment string = 'gpt-4o-mini'

@description('Nome do Azure Container Registry para armazenar imagens dos agentes')
param acrName string

@description('Nome do Log Analytics Workspace')
param logAnalyticsName string

@description('Nome do Application Insights')
param appInsightsName string

@description('Nome do Microsoft Foundry account (AI Foundry)')
param aiHubName string

@description('Nome do Microsoft Foundry project para hospedar o Agent Framework Agent')
param aiProjectName string

@description('Versão do modelo')
param modelVersion string = '2025-01-15'

@description('Capacidade do deployment (TPM em milhares)')
param modelCapacity int = 100

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// Model Deployment no Foundry account (visivel no portal do Foundry)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: aiModelDeployment
  sku: {
    name: 'Standard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: modelVersion
    }
  }
}


// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}



// Microsoft Foundry account (AI Foundry)
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiHubName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true
    customSubDomainName: aiHubName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// Microsoft Foundry project (para hospedar o Agent Framework Agent)
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// Outputs
output openAIEndpoint string = aiFoundry.properties.endpoint
output openAIServiceName string = aiFoundry.name
output aiModelDeployment string = aiModelDeployment
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
output aiFoundryName string = aiFoundry.name
output aiFoundryEndpoint string = aiFoundry.properties.endpoint
output aiProjectName string = aiProject.name
output aiProjectEndpoint string = 'https://${aiFoundry.properties.customSubDomainName}.services.ai.azure.com/api/projects/${aiProject.name}'
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output resourceGroupName string = resourceGroupName
