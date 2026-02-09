using './main.bicep'

// Parametros de localizacao e nomes dos recursos
param resourceGroupName = 'rg-ag365sdk'
param location = 'eastus'
param aiModelDeployment = 'gpt-4.1'
param acrName = 'acr123'
param logAnalyticsName = 'log-ai001'
param appInsightsName = 'appi-ai001'
param aiHubName = 'ai-foundry001'
param aiProjectName = 'ag365-prj001'

// Configuracoes do modelo
param modelVersion = '2024-07-18'
param modelCapacity = 10
