@description('Localizacao dos recursos')
param location string = resourceGroup().location

@description('Nome do ACA Environment existente (criado no prereq)')
param acaEnvironmentName string = 'cae-rg-ai-agents-workshop'

@description('Nome do Container App')
param containerAppName string = 'aca-lg-agent'

@description('Nome do ACR existente')
param acrName string

@description('Imagem completa do container (acr.azurecr.io/image:tag)')
param containerImage string

@description('Endpoint do projeto Foundry')
param projectEndpoint string

@description('Nome do deployment do modelo')
param modelDeployment string

@description('Endpoint OpenAI do Foundry')
param openaiEndpoint string

@description('Connection string do Application Insights')
param appInsightsConnectionString string = ''

@description('Microsoft App ID do Agent Blueprint (A365)')
param microsoftAppId string = ''

// Referenciar recursos existentes no mesmo Resource Group
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// ACA Environment existente (criado no prereq/)
resource acaEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: acaEnvironmentName
}

// Container App com managed identity e ingress publico
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: 'system'
        }
      ]
      secrets: []
    }
    template: {
      containers: [
        {
          name: 'agent'
          image: containerImage
          resources: {
            cpu: json('1.0')
            memory: '2Gi'
          }
          env: [
            {
              name: 'AZURE_AI_PROJECT_ENDPOINT'
              value: projectEndpoint
            }
            {
              name: 'AZURE_AI_MODEL_DEPLOYMENT_NAME'
              value: modelDeployment
            }
            {
              name: 'AZURE_OPENAI_ENDPOINT'
              value: openaiEndpoint
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'MICROSOFT_APP_ID'
              value: microsoftAppId
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8080
              }
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: 8080
              }
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// RBAC: Grant ACA Managed Identity permission to pull images from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerApp.id, acr.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')  // AcrPull role
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// CRITICAL: RBAC Role Assignment for Azure OpenAI Access
// The Managed Identity created above needs the "Cognitive Services OpenAI User" role
// to call Azure OpenAI. This must be assigned AFTER deployment.
//
// Run this command AFTER deployment completes:
// 
// az role assignment create \
//   --assignee <managed-identity-principal-id> \
//   --role "Cognitive Services OpenAI User" \
//   --scope <azure-openai-resource-id>
//
// Example:
// MI_PRINCIPAL_ID=$(az containerapp show --name aca-a365-agent --resource-group $RG_NAME --query identity.principalId -o tsv)
// OPENAI_ID=$(az cognitiveservices account show --name <openai-account-name> --resource-group $RG_NAME --query id -o tsv)
// az role assignment create --assignee $MI_PRINCIPAL_ID --role "Cognitive Services OpenAI User" --scope $OPENAI_ID

// Outputs
output acaFqdn string = containerApp.properties.configuration.ingress.fqdn
output acaUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output acaPrincipalId string = containerApp.identity.principalId
output containerAppName string = containerApp.name
output rbacInstructions string = 'CRITICAL: Run RBAC role assignment command from comments above using MI Principal ID: ${containerApp.identity.principalId}'
