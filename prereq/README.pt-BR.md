# Pré-requisitos - Infraestrutura Azure

> 🇺🇸 **[Read in English](README.md)**

Esta pasta contém scripts de Infraestrutura como Código (IaC) usando Bicep para provisionar todos os recursos necessários para o workshop.

## Recursos Provisionados

- **Azure AI Services (Foundry Account)** - Com implantação do modelo GPT-4o-mini
- **Azure Container Registry** - Para armazenar imagens Docker dos agentes
- **AI Project** - Projeto Microsoft Foundry para hospedar agentes
- **Log Analytics Workspace** - Para logs e monitoramento
- **Application Insights** - Para telemetria e observabilidade

## 🚀 Deploy Rápido (Recomendado)

Use o script automatizado para implantação completa:

**Windows (PowerShell)**:
```powershell
.\deploy.ps1 -ResourceGroupName "rg-agent365-workshop" -Location "eastus"
```

**Linux / WSL (Bash)**:
```bash
chmod +x deploy.sh
./deploy.sh --resource-group "rg-agent365-workshop" --location "eastus"
```

### Parâmetros do Script

**Windows (PowerShell)**:
```powershell
# Deploy básico
.\deploy.ps1

# Deploy com assinatura específica
.\deploy.ps1 -SubscriptionId "your-subscription-id"

# Deploy personalizado
.\deploy.ps1 `
  -ResourceGroupName "my-rg" `
  -Location "westus2" `
  -DeploymentName "workshop-deployment"

# Simular implantação (WhatIf)
.\deploy.ps1 -WhatIf

# Deploy sem validação automática
.\deploy.ps1 -SkipValidation
```

**Linux / WSL (Bash)**:
```bash
# Deploy básico
./deploy.sh

# Deploy com assinatura específica
./deploy.sh --subscription "your-subscription-id"

# Deploy personalizado
./deploy.sh \
  --resource-group "my-rg" \
  --location "westus2" \
  --deployment-name "workshop-deployment"

# Simular implantação (what-if)
./deploy.sh --what-if

# Deploy sem validação automática
./deploy.sh --skip-validation
```

O script irá automaticamente:
- ✓ Verificar pré-requisitos (Azure CLI, autenticação)
- ✓ Instalar extensões necessárias
- ✓ Criar o Resource Group se não existir
- ✓ Validar o template Bicep
- ✓ Executar a implantação
- ✓ Exibir os outputs
- ✓ Executar validação automaticamente

## 📋 Deploy Manual (Alternativa)

### 1. Defina suas variáveis de ambiente

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

### 2. Faça login no Azure

```bash
az login
az account set --subscription $SUBSCRIPTION_ID
```

### 3. Instale as extensões necessárias

```bash
az extension add --name containerapp
az extension add --name ml
```

### 4. Crie o Resource Group

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5. Implante a infraestrutura

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

Ou com parâmetros inline:

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

### 6. Capture os outputs

```bash
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query properties.outputs
```

## ✅ Validação

### 7. Valide a implantação

Execute o script de validação para garantir que todos os recursos foram criados corretamente:

**Windows (PowerShell)**:
```powershell
.\validate-deployment.ps1 -ResourceGroupName $RESOURCE_GROUP -DeploymentName "main"
```

**Linux / WSL (Bash)**:
```bash
./validate-deployment.sh --resource-group $RESOURCE_GROUP --deployment-name "main"
```

O script irá:
- ✓ Verificar a existência de todos os recursos
- ✓ Validar o status de provisionamento
- ✓ Testar configurações e conexões
- ✓ Gerar um relatório JSON detalhado
- ✓ Exibir informações importantes (endpoints, URLs, etc.)

**Taxa de sucesso esperada:** ≥ 90%

## Parâmetros Personalizáveis

Edite o arquivo `main.bicepparam` para personalizar:

- `location` - Região Azure (padrão: eastus)
- `aiHubName` - Nome do AI Services / Foundry account
- `aiProjectName` - Nome do AI Project
- `aiModelDeployment` - Nome da implantação do modelo (padrão: gpt-4o-mini)
- `acrName` - Nome do Azure Container Registry
- `logAnalyticsName` - Nome do workspace Log Analytics
- `appInsightsName` - Nome do Application Insights
- `modelVersion` - Versão do modelo
- `modelCapacity` - Capacidade TPM do modelo (padrão: 100)

## 📝 Arquivos

- **deploy.ps1** - Script de implantação automatizada (Windows/PowerShell)
- **deploy.sh** - Script de implantação automatizada (Linux/WSL/macOS)
- **validate-deployment.ps1** - Script de validação pós-implantação (Windows/PowerShell)
- **validate-deployment.sh** - Script de validação pós-implantação (Linux/WSL/macOS)
- **main.bicep** - Template principal de infraestrutura
- **main.bicepparam** - Arquivo de parâmetros

## 🎯 Próximos Passos

Após implantação bem-sucedida:
1. Anote os valores de output (endpoints, chaves, URLs)
2. Configure variáveis de ambiente nos projetos dos agentes
3. Construa e envie imagens Docker para o ACR
4. Atualize os Container Apps com as imagens corretas
