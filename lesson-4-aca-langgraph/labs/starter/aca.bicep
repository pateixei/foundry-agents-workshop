// Lab 4 - Starter: Deploy Agent to Azure Container Apps with Bicep
//
// Complete the TODOs to deploy your LangGraph agent to ACA.

@description('Location for all resources')
param location string = resourceGroup().location

// TODO: Add parameters for:
// - containerAppName (string, default 'aca-financial-agent')
// - acaEnvironmentName (string, existing CAE name)
// - acrName (string, existing ACR name)
// - containerImage (string, full image URI)
// - projectEndpoint (string, Foundry project endpoint)
// - modelDeployment (string, model deployment name)
// - openaiEndpoint (string, OpenAI endpoint)

// TODO: Reference existing ACR resource
// resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = { ... }

// TODO: Reference existing ACA Environment
// resource acaEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = { ... }

// TODO: Create Container App with:
// - SystemAssigned managed identity
// - Public ingress on port 8080
// - ACR registry with system identity auth
// - Environment variables for project endpoint, model deployment, openai endpoint
// - Health probes (liveness + readiness on /health)
// - Scale: 1-3 replicas

// TODO: Add RBAC role assignment for AcrPull
// Role ID: 7f951dda-4ed3-4680-a7ca-43fe172d538d

// TODO: Add outputs:
// - acaFqdn, acaUrl, acaPrincipalId, containerAppName
