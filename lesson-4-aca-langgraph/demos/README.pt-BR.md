# Demo 4: Implantação no Azure Container Apps (ACA)

> **Tipo de Demo**: Demonstração guiada pelo instrutor. Esta demo referencia o código-fonte em `lesson-4-aca-langgraph/labs/solution/`. O instrutor percorre o código e o template Bicep ao vivo na tela.

## Visão Geral

Demonstra a implantação de agentes na infraestrutura **Azure Container Apps (ACA)** ao invés da plataforma Hosted Agent do Foundry. Apresenta o padrão "Connected Agent" (Agente Conectado) onde você controla a infraestrutura mas registra no Foundry para governança.

## Conceitos-Chave

- ✅ Implantação ACA com Bicep IaC
- ✅ Registro de Connected Agent no Foundry
- ✅ Servidor de agente baseado em FastAPI (alternativa ao agentserver)
- ✅ Managed Identity (Identidade Gerenciada) para pull do ACR e acesso ao Azure OpenAI
- ✅ Controle de infraestrutura vs gerenciamento pelo Foundry

## Arquitetura

```
Your Infrastructure (ACA) + Foundry Control Plane
┌──────────────────────┐
│ User Request         │
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Foundry AI Gateway   │  (optional routing)
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Azure Container Apps │  ← YOUR infrastructure
│  ├─> FastAPI Server  │
│  └─> LangGraph Agent │
└──────┬───────────────┘
       ▼
┌──────────────────────┐
│ Azure OpenAI         │  (YOUR endpoint, YOUR quota)
└──────────────────────┘
```

## Hosted vs Connected Agents

| Aspecto | Hosted (Demo 2-3) | Connected (Esta Demo) |
|--------|------------------|----------------------|
| **Infraestrutura** | Gerenciada pelo Foundry | VOCÊ gerencia (ACA) |
| **Implantação** | `az cognitiveservices agent` | `az containerapp create` |
| **Escala** | Foundry controla | ACA controla |
| **Rede** | VNet do Foundry | SUA VNet |
| **Custo** | Computação do Foundry | SUA computação |
| **Controle** | Baixo | Alto |
| **Compliance** | Responsabilidade compartilhada | Controle total |

## Quando Usar ACA (Connected Agent)

**✅ USE QUANDO:**
- Compliance exige que dados permaneçam na sua VNet
- Necessita de rede personalizada (private endpoints, VPN)
- Quer controle de otimização de custos
- Já possui infraestrutura ACA
- Requer quotas de recursos específicas

**❌ EVITE QUANDO:**
- Necessidades simples de implantação (use Hosted)
- Não quer overhead de gerenciamento de infraestrutura
- Escalabilidade do Foundry é suficiente

## Pré-requisitos

- Assinatura Azure com quota de Container Apps
- ACR para imagens
- Recurso Azure OpenAI
- Conhecimento de Bicep (útil)

## Início Rápido

```powershell
cd demo-4-aca-deployment
.\deploy.ps1
```

O script:
1. Faz build do contêiner do agente LangGraph
2. Faz push para ACR
3. Implanta infraestrutura ACA via Bicep
4. Configura Managed Identity + RBAC
5. Testa o endpoint do agente

## Arquivos Principais

- `aca.bicep` - Definição de infraestrutura ACA
- `main.py` - FastAPI + agente LangGraph
- `Dockerfile` - Imagem de contêiner
- `deploy.ps1` - Script de automação
- `REGISTER.md` - Guia de registro de Connected Agent

## Destaques do Template Bicep

```bicep
// ACA Environment (like ECS Cluster)
resource acaEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${appName}-env'
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

// Container App (like ECS Service)
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    environmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
      registries: [{
        server: acr.properties.loginServer
        identity: containerApp.identity.principalId  // MI auth!
      }]
    }
    template: {
      containers: [{
        name: 'agent'
        image: containerImage
        resources: {
          cpu: json('1.0')
          memory: '2Gi'
        }
        env: [{
          name: 'AZURE_OPENAI_ENDPOINT'
          value: openAIEndpoint
        }]
      }]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

// RBAC: ACA MI → ACR Pull
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, containerApp.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'  // AcrPull
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: ACA MI → Azure OpenAI
resource cognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAI.id, containerApp.id, 'CognitiveServicesUser')
  scope: openAI
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'a97b65f3-24c7-4388-baec-2e87135dc908'  // Cognitive Services User
    )
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

## Servidor de Agente FastAPI

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from langgraph_agent import create_agent

app = FastAPI()
agent = create_agent()

class ChatRequest(BaseModel):
    message: str
    thread_id: str = None

@app.post("/chat")
async def chat(request: ChatRequest):
    try:
        response = await agent.run(request.message)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

## Testes

### Chamada Direta (sem Foundry)
```powershell
# Health check
curl https://aca-lg-agent.nicebeach-abc123.eastus.azurecontainerapps.io/health

# Chat
$body = @{message = "Qual o preco da PETR4?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://aca-lg-agent...azurecontainerapps.io/chat" -Method Post -Body $body -ContentType "application/json"
```

### Via Foundry AI Gateway (Connected Agent)
Após registrar como Connected Agent:
```powershell
# Use Foundry SDK or Responses API
# Foundry routes through AI Gateway to your ACA endpoint
```

## Registrando como Connected Agent

Consulte `REGISTER.md` para os passos detalhados:
1. Obter o FQDN público do ACA
2. Navegar até o Foundry Control Plane
3. Registrar novo Connected Agent
4. Fornecer URL do endpoint e autenticação
5. Testar via Foundry Responses API

## Resolução de Problemas

**Problema: "ACR pull failed: 401 Unauthorized"**  
**Causa**: Role assignment RBAC não propagada (leva 2-5 min)  
**Solução**: Aguarde 5 minutos, então reinicie o container app

**Problema: "Container fails health check"**  
**Causa**: Endpoint `/health` não respondendo  
**Solução**: Verifique os logs: `az containerapp logs show --name aca-lg-agent --resource-group rg-aca`

**Problema: "Azure OpenAI 403 Forbidden"**  
**Causa**: MI não possui a role "Cognitive Services User"  
**Solução**: Verifique se o role assignment RBAC no Bicep foi implantado

## Considerações de Custo

| Serviço | Custo Diário (USD) | Observações |
|---------|-----------------|-------|
| **ACA** | $0.50-2.00 | Depende de CPU/memória, escala |
| **Azure OpenAI** | $10-50 | Depende do uso |
| **ACR** | $0.17 | Tier Basic |
| **Log Analytics** | $0.10-1.00 | Depende da ingestão |
| **Total** | ~$11-53/dia | ~$330-1590/mês |

**Otimização de Custos**:
- Escalar para 0 réplicas fora do horário comercial
- Usar plano de consumo ao invés de dedicado
- Definir limites de recursos apropriados
- Monitorar uso com Cost Management

## Recursos

- [Documentação Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Referência da Linguagem Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Padrão Connected Agent](https://learn.microsoft.com/azure/ai-foundry/concepts/connected-agents)

---

**Nível da Demo**: Avançado  
**Tempo Estimado**: 35-45 minutos  
**Melhor Para**: Implantações de produção que requerem controle de infraestrutura
