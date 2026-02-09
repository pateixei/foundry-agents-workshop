# Pré-requisitos - Infraestrutura Azure

Esta pasta contém os scripts de infraestrutura como código (IaC) usando Bicep para provisionar todos os recursos necessários para o workshop.

## Recursos Provisionados

- **Azure OpenAI Service** - Com deployment do modelo GPT-5.2
- **Azure Container Registry** - Para armazenar as imagens Docker dos agentes
- **Container Apps Environment** - Ambiente para executar o LangGraph Agent
- **Container App** - Para o LangGraph Agent
- **AI Hub** - Workspace do Microsoft Foundry
- **AI Project** - Para hospedar o Agent Framework Agent
- **Log Analytics Workspace** - Para logs e monitoramento
- **Application Insights** - Para telemetria e observabilidade
- **Storage Account** - Para o AI Hub
- **Key Vault** - Para o AI Hub

## 🚀 Deploy Rápido (Recomendado)

Use o script automatizado para fazer o deployment completo:

```powershell
.\deploy.ps1 -ResourceGroupName "rg-agent365-workshop" -Location "eastus"
```

### Parâmetros do Script

```powershell
# Deploy básico
.\deploy.ps1

# Deploy com subscription específica
.\deploy.ps1 -SubscriptionId "sua-subscription-id"

# Deploy personalizado
.\deploy.ps1 `
  -ResourceGroupName "meu-rg" `
  -Location "westus2" `
  -DeploymentName "workshop-deployment"

# Simular deployment (WhatIf)
.\deploy.ps1 -WhatIf

# Deploy sem validação automática
.\deploy.ps1 -SkipValidation
```

O script irá:
- ✓ Verificar pré-requisitos (Azure CLI, autenticação)
- ✓ Instalar extensões necessárias
- ✓ Criar o Resource Group se não existir
- ✓ Validar o template Bicep
- ✓ Executar o deployment
- ✓ Exibir os outputs
- ✓ Executar a validação automaticamente

## 📋 Deploy Manual (Alternativo)

### 1. Defina suas variáveis de ambiente

```powershell
$RESOURCE_GROUP = "rg-agent365-workshop"
$LOCATION = "eastus"
$SUBSCRIPTION_ID = "sua-subscription-id"
```

### 2. Faça login no Azure

```powershell
az login
az account set --subscription $SUBSCRIPTION_ID
```

### 3. Instale as extensões necessárias

```powershell
az extension add --name containerapp
az extension add --name ml
```

### 4. Crie o Resource Group

```powershell
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5. Deploy da infraestrutura

```powershell
az deployment group create `
  --resource-group $RESOURCE_GROUP `
  --template-file main.bicep `
  --parameters main.bicepparam
```

Ou com parâmetros inline:

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

### 6. Capture os outputs

```powershell
az deployment group show `
  --resource-group $RESOURCE_GROUP `
  --name main `
  --query properties.outputs
```

## ✅ Validação

### 7. Valide o deployment

Execute o script de validação para garantir que todos os recursos foram criados corretamente:

```powershell
.\validate-deployment.ps1 -ResourceGroupName $RESOURCE_GROUP -DeploymentName "main"
```

O script irá:
- ✓ Verificar a existência de todos os recursos
- ✓ Validar o status de provisionamento
- ✓ Testar configurações e connections
- ✓ Gerar um relatório detalhado em JSON
- ✓ Exibir informações importantes (endpoints, URLs, etc.)

**Taxa de sucesso esperada:** ≥ 90%

## ⚙️ Parâmetros Personalizáveis

Edite o arquivo `main.bicepparam` para customizar:

- `location` - Região do Azure (padrão: eastus)
- `openAIServiceName` - Nome do serviço Azure OpenAI
- `gpt52DeploymentName` - Nome do deployment GPT-5.2
- `acrName` - Nome do Azure Container Registry
- `langgraphAgentName` - Nome do Container App para LangGraph
- `agentFrameworkAgentName` - Nome do Container App para Agent Framework
- `gpt52Capacity` - Capacidade TPM do modelo (padrão: 100)
- `gpt52ModelVersion` - Versão do modelo GPT-5.2
- `aiHubName` - Nome do AI Hub (Microsoft Foundry)
- `aiProjectName` - Nome do AI Project

## 📝 Arquivos

- **deploy.ps1** - Script automatizado de deployment
- **validate-deployment.ps1** - Script de validação pós-deployment
- **main.bicep** - Template principal de infraestrutura
- **main.bicepparam** - Arquivo de parâmetros

## 🎯 Próximos Passos

Após o deployment bem-sucedido:
1. Anote os valores dos outputs (endpoints, chaves, URLs)
2. Configure as variáveis de ambiente nos projetos dos agentes
3. Build e push das imagens Docker para o ACR
4. Update dos Container Apps com as imagens corretas
