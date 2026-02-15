# Lab 4: Implantar Agente no Azure Container Apps (ACA) com Bicep

## Objetivo

Implantar infraestrutura usando **Bicep IaC** e registrar o agente como **Connected Agent (Agente Conectado)** no Foundry, proporcionando controle total de infraestrutura enquanto mantém a integração de governança do Foundry.

## Cenário

Sua empresa requer:
- Dados devem permanecer na VNet corporativa (compliance)
- Políticas de escala personalizadas (otimização de custos)
- Integração com ambiente ACA existente
- Governança do Foundry para gerenciamento de ciclo de vida do agente

Solução: Implantar em ACA (sua infraestrutura) + registrar como Connected Agent no Foundry.

## Objetivos de Aprendizagem

- Implantar Azure Container Apps com Bicep IaC
- Configurar Managed Identity (Identidade Gerenciada) para acesso ao ACR e Azure OpenAI
- Implementar role assignments RBAC no Bicep
- Registrar Connected Agents no Foundry Control Plane
- Entender padrões de agentes Hosted vs Connected
- Tomar decisões de infraestrutura baseadas em necessidades de compliance

## Pré-requisitos

- [x] Lab 3 completado (agente LangGraph)
- [x] Assinatura Azure com quota de Container Apps
- [x] ACR com imagem do agente já enviada
- [x] Conhecimento de Bicep (útil mas não obrigatório)

## Tarefas

### Tarefa 1: Revisar Requisitos de Infraestrutura (10 minutos)

**Estude a arquitetura**:

```
┌─────────────────────────────────┐
│ User Request via Foundry API    │
└──────────┬──────────────────────┘
           ▼
┌─────────────────────────────────┐
│ Foundry AI Gateway (optional)   │
└──────────┬──────────────────────┘
           ▼
┌─────────────────────────────────┐
│ Azure Container Apps (YOUR VNet)│
│  ├─> Load Balancer (public)     │
│  ├─> Container Instances (1-10) │
│  └─> Managed Identity (MI)      │
└──────────┬──────────────────────┘
           ▼
┌─────────────────────────────────┐
│ Azure OpenAI (YOUR endpoint)    │
└─────────────────────────────────┘
```

**O que você vai implantar**:
1. Log Analytics Workspace (telemetria)
2. ACA Environment (similar a um cluster)
3. Container App (runtime do agente)
4. Managed Identity (para autenticação)
5. Roles RBAC (ACR Pull + Cognitive Services User)

**Critérios de Sucesso**:
- ✅ Entender diferenças ACA vs Foundry Hosted
- ✅ Identificar requisitos RBAC
- ✅ Reconhecer padrão de uso de Managed Identity

### Tarefa 2: Completar Template Bicep (30 minutos)

Navegue até `starter/aca.bicep` e implemente:

**2.1 - Definir Parâmetros**

```bicep
@description('Name of the Container App')
param containerAppName string = 'aca-financial-agent'

@description('Container image from ACR')
param containerImage string

@description('Azure OpenAI endpoint')
param azureOpenAIEndpoint string

@description('Azure OpenAI deployment name')
param openAIDeploymentName string = 'gpt-4'

@description('Location for all resources')
param location string = resourceGroup().location
```

**2.2 - Criar Log Analytics Workspace**

```bicep
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${containerAppName}-logs'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}
```

**2.3 - Criar ACA Environment**

```bicep
resource acaEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${containerAppName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}
```

**2.4 - Criar Container App com Managed Identity**

```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'  // Creates Managed Identity
  }
  properties: {
    environmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true  // Public endpoint
        targetPort: 8080
        transport: 'http'
        allowInsecure: true  // HTTPS termination at gateway
      }
      registries: [
        {
          server: 'YOUR-ACR.azurecr.io'
          identity: 'system'  // Use MI for ACR auth (not admin password!)
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
              name: 'AZURE_OPENAI_ENDPOINT'
              value: azureOpenAIEndpoint
            }
            {
              name: 'AZURE_OPENAI_DEPLOYMENT'
              value: openAIDeploymentName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
```

**2.5 - Adicionar Role Assignments RBAC**

```bicep
// ACR Pull Role (7f951dda-4ed3-4680-a7ca-43fe172d538d)
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerApp.id, 'AcrPull')
  scope: resourceGroup()  // Or specific ACR resource
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Cognitive Services User for Azure OpenAI (a97b65f3-24c7-4388-baec-2e87135dc908)
resource cognitiveServicesRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, containerApp.id, 'CognitiveServicesUser')
  scope: resourceGroup()  // Or specific OpenAI resource
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'a97b65f3-24c7-4388-baec-2e87135dc908'
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

**2.6 - Adicionar Outputs**

```bicep
output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
output containerAppPrincipalId string = containerApp.identity.principalId
output acaEnvironmentId string = acaEnvironment.id
```

**Critérios de Sucesso**:
- ✅ Template Bicep sem erros de sintaxe (`az bicep build`)
- ✅ Todos os recursos definidos com dependências corretas
- ✅ Managed Identity configurada
- ✅ Roles RBAC atribuídas
- ✅ Outputs configurados para próximos passos

### Tarefa 3: Implantar Infraestrutura (15 minutos)

**3.1 - Validar template Bicep**

```powershell
az bicep build --file aca.bicep
```

**3.2 - Criar arquivo de parâmetros** (`aca.bicepparam`)

```bicep
using './aca.bicep'

param containerAppName = 'aca-financial-agent'
param containerImage = 'YOUR-ACR.azurecr.io/langgraph-financial-agent:v1'
param azureOpenAIEndpoint = 'https://YOUR-OPENAI.openai.azure.com/'
param openAIDeploymentName = 'gpt-4'
```

**3.3 - Implantar**

```powershell
az deployment group create \
  --resource-group rg-aca-agents \
  --template-file aca.bicep \
  --parameters aca.bicepparam
```

**Saída Esperada**:
```
Deployment 'aca' succeeded.
Outputs:
  containerAppFQDN: aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io
  containerAppPrincipalId: 12345678-abcd-...
```

**Aguarde a propagação RBAC** (2-5 minutos):
- Role assignments RBAC levam tempo para propagar
- O contêiner pode inicialmente falhar ao fazer pull do ACR (erro 401)
- Isso é esperado — terá sucesso após a propagação

**Critérios de Sucesso**:
- ✅ Implantação completada sem erros
- ✅ App ACA mostra status "Running"
- ✅ FQDN é acessível: `curl https://FQDN/health`

### Tarefa 4: Testar Acesso Direto (10 minutos)

**4.1 - Health check**

```powershell
$fqdn = "aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io"
Invoke-RestMethod "https://$fqdn/health"
# Expected: { "status": "healthy" }
```

**4.2 - Endpoint de chat**

```powershell
$body = @{ message = "Qual o preco da PETR4?" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://$fqdn/chat" -Method Post -Body $body -ContentType "application/json"
```

**Critérios de Sucesso**:
- ✅ Health check retorna 200 OK
- ✅ Endpoint de chat processa requisições
- ✅ Respostas do agente estão corretas

### Tarefa 5: Registrar como Connected Agent (15 minutos)

**5.1 - Navegar até o Foundry Control Plane**

1. Acesse o [Portal Azure AI Foundry](https://ai.azure.com/)
2. Selecione seu projeto
3. Vá para **Agents** → **Register Connected Agent**

**5.2 - Preencher formulário de registro**

- **Name**: financial-advisor-aca
- **Description**: Financial advisor agent on ACA infrastructure
- **Endpoint URL**: `https://aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io`
- **Authentication**: None (public endpoint) ou Managed Identity
- **Protocol**: HTTP REST

**5.3 - Testar via Foundry**

```python
# Use Foundry SDK to call Connected Agent
from azure.ai.agents import AIProjectClient
from azure.identity import DefaultAzureCredential

client = AIProjectClient(
    endpoint="FOUNDRY_ENDPOINT",
    credential=DefaultAzureCredential()
)

# Foundry routes request through AI Gateway to your ACA
response = client.agents.invoke_connected_agent(
    agent_name="financial-advisor-aca",
    message="How is the Brazilian market today?"
)
print(response)
```

**Critérios de Sucesso**:
- ✅ Agente registrado no Foundry
- ✅ Visível na lista de Agents (mostra badge "Connected")
- ✅ Invocações roteiam através do Foundry até o ACA
- ✅ Telemetria coletada pelo Foundry

### Tarefa 6: Comparar Modelos de Hospedagem (10 minutos)

**Complete a tabela de comparação**:

| Funcionalidade | Hosted (Lab 2-3) | Connected (Este Lab) |
|---------|------------------|----------------------|
| **Proprietário da Infraestrutura** | ? | ? |
| **Comando de Implantação** | ? | ? |
| **Controle de Escala** | ? | ? |
| **Modelo de Custo** | ? | ? |
| **Integração VNet** | ? | ? |
| **Compliance** | ? | ? |
| **Complexidade de Setup** | ? | ? |
| **Quando Usar** | ? | ? |

**Framework de Decisão**:

Use **Hosted** quando:
- [ ] Implantação rápida é prioridade
- [ ] Sem requisitos especiais de compliance
- [ ] Escalabilidade do Foundry é suficiente
- [ ] Não quer overhead de infraestrutura

Use **Connected (ACA)** quando:
- [ ] Necessita de dados na VNet corporativa
- [ ] Escala/rede personalizada necessária
- [ ] Otimização de custos é importante
- [ ] Já possui ambiente ACA
- [ ] Compliance exige controle de infraestrutura

**Critérios de Sucesso**:
- ✅ Tabela preenchida com informações precisas
- ✅ Framework de decisão reflete entendimento
- ✅ Pode justificar escolha de modelo de implantação

## Entregáveis

- [x] Template Bicep completo (aca.bicep)
- [x] Infraestrutura ACA implantada
- [x] Agente em execução e acessível
- [x] Registrado como Connected Agent no Foundry
- [x] Documento de comparação: Hosted vs Connected
- [x] Estimativa de custo para implantação ACA

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|-----------|--------|-------------|
| **Template Bicep** | 30 pts | IaC completo e correto com dependências adequadas |
| **Configuração RBAC** | 20 pts | Managed Identity + role assignments |
| **Implantação** | 20 pts | Implantado e em execução com sucesso |
| **Testes** | 15 pts | Acesso direto e roteamento Foundry funcionam |
| **Connected Agent** | 10 pts | Registrado no Foundry Control Plane |
| **Análise** | 5 pts | Comparação criteriosa dos modelos de hospedagem |

**Total**: 100 pontos

## Resolução de Problemas

### "ACR pull failed: 401 Unauthorized"
- **Causa**: Role RBAC ainda não propagada
- **Solução**: Aguarde 5 minutos, reinicie o container app

### "Container fails to start: health check timeout"
- **Causa**: Endpoint `/health` não respondendo
- **Solução**: Verifique os logs: `az containerapp logs show --name aca-financial-agent --resource-group rg-aca`

### "Azure OpenAI 403 Forbidden"
- **Causa**: MI sem a role Cognitive Services User
- **Solução**: Verifique se o role assignment RBAC foi implantado, aguarde propagação

### "Bicep deployment failed: QuotaExceeded"
- **Causa**: Quota de Container Apps excedida na região
- **Solução**: Solicite aumento de quota ou use região diferente

## Estimativa de Tempo

- Tarefa 1: 10 minutos
- Tarefa 2: 30 minutos
- Tarefa 3: 15 minutos
- Tarefa 4: 10 minutos
- Tarefa 5: 15 minutos
- Tarefa 6: 10 minutos
- **Total**: 90 minutos

## Próximos Passos

- **Lab 5**: Integrar Microsoft Agent 365 SDK para implantação M365
- Aprender arquitetura cross-tenant
- Publicar no Teams e Outlook

---

**Dificuldade**: Avançado  
**Pré-requisitos**: Labs 1-3, conhecimento básico de Bicep/IaC  
**Tempo Estimado**: 90 minutos
