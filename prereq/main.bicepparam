using './main.bicep'

// Parametros de localizacao e nomes dos recursos
param resourceGroupName = 'rg-ag365sdk'
param location = 'eastus'
param aiModelDeployment = 'gpt-4.1'
param acrName = 'acrag365wkshp02'
param logAnalyticsName = 'log-ai001'
param appInsightsName = 'appi-ai001'
param aiHubName = 'ai-foundry002'
param aiProjectName = 'ag365-prj002'

// Configuracoes do modelo
param modelVersion = '2024-07-18'
param modelCapacity = 10
