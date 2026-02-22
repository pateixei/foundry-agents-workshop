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
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
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

// Outputs
output acaFqdn string = containerApp.properties.configuration.ingress.fqdn
output acaUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output acaPrincipalId string = containerApp.identity.principalId
output containerAppName string = containerApp.name
