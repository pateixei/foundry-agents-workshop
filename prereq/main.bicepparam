using './main.bicep'

param location = 'eastus'
param resourceGroupName = 'rg-ai-agents-workshop'
// Parametros de localizacao e nomes dos recursos
param aiHubName = 'aihub-workshop'
param acrName = 'acrworkshop'
param logAnalyticsName = 'log-workshp'
param appInsightsName = 'appi-workshp'
param aiProjectName = 'aiprj-workshp'

// Storage Account para Capability Host
param storageAccountName = 'stworkshopagents'

// Configuracoes do modelo
param aiModelDeployment = 'gpt-4.1'
param modelVersion = '2024-07-18'
param modelCapacity = 10
