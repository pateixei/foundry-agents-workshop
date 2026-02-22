# Lição 4 - Agente LangGraph no Azure Container Apps

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Implantar** agentes conteinerizados na infraestrutura do Azure Container Apps (ACA)
2. **Compreender** a diferença entre Foundry Hosted vs ACA (Connected Agent)
3. **Configurar** ACA com Managed Identity, variáveis de ambiente e auto-scaling
4. **Registrar** agentes externos como Connected Agents no Foundry Control Plane
5. **Implementar** servidor de agente baseado em FastAPI (alternativa ao adaptador agentserver)
6. **Comparar** modelos de implantação: Hosted (Foundry) vs Connected (ACA)
7. **Avaliar** quando implantar em infraestrutura própria vs na infraestrutura do Foundry

---

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-4-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-4-deployment.png) | Fluxo de implantação |
| [📁 Notas da Solução](labs/solution/README.pt-BR.md) | Código da solução e detalhes de deployment |
| [📝 Registro do Agente](REGISTER.pt-BR.md) | Como registrar agente como Connected Agent no Foundry |

---

## Visão Geral

Nesta lição, implantamos o mesmo agente LangGraph das lições anteriores em
infraestrutura própria (**Azure Container Apps**) e o registramos como
**Connected Agent** no Control Plane do Microsoft Foundry.

Veja detalhes completos em [labs/solution/README.pt-BR.md](labs/solution/README.pt-BR.md).

---

## Arquitetura: Hosted Agent vs Connected Agent

Compreender os dois modelos de implantação é essencial para decisões em produção.

### Hosted Agent (Lições 2-3)
```
Requisição do Usuário
    ↓
Foundry Responses API
    ↓
Foundry Capability Host (infra da Microsoft)
    ↓
Seu Container (gerenciado pelo Foundry)
    ↓
Azure OpenAI (via Foundry)
```

### Connected Agent (Esta Lição)
```
Requisição do Usuário
    ↓
Foundry Responses API
    ↓
AI Gateway (APIM) ← Foundry roteia aqui
    ↓
Azure Container Apps (SUA infra)
    ↓
Seu Container (você gerencia)
    ↓
Azure OpenAI (SEU endpoint, SUAS chaves/MI)
```

> **Diferença principal**: Hosted → Foundry gerencia tudo. Connected → Você gerencia a infraestrutura. O Foundry faz proxy das requisições e coleta telemetria.

---

## Comparação dos Três Modelos de Implantação

| Modelo | Onde Executa | Integração com Foundry | Caso de Uso |
|--------|-------------|------------------------|-------------|
| **Declarativo** | Backend do Foundry | Nativa | Protótipos, sem código customizado |
| **Hosted** | Foundry Capability Host | Nativa | Produção, ferramentas customizadas, confia na infra do Foundry |
| **Connected** | Sua infraestrutura (ACA) | Proxy via API Gateway | Produção, precisa de controle de infra, compliance |

### Por que Implantar no ACA (Connected Agent)?

| Motivo | Benefício |
|--------|-----------|
| ✅ **Compliance** | Dados nunca tocam a infra do Foundry (ficam na sua VNet) |
| ✅ **Controle** | Controle total sobre scaling, rede e cotas de recursos |
| ✅ **Custo** | Otimize custos de compute (capacidade reservada, spot instances) |
| ✅ **Infra Existente** | Aproveite ambientes ACA existentes (multi-tenant) |
| ✅ **Rede Customizada** | Private endpoints, DNS customizado, acesso VPN |
| ✅ **Multi-Cloud** | Execute agentes em qualquer plataforma de contêiner, registre no Foundry |

### Por que Permanecer com Foundry Hosted?

| Motivo | Benefício |
|--------|-----------|
| ✅ **Simplicidade** | Sem gerenciamento de infraestrutura |
| ✅ **Deploy Rápido** | 1 comando CLI vs Bicep + configuração de rede |
| ✅ **Monitoramento Integrado** | Telemetria nativa, sem configuração adicional |
| ✅ **Auto-Scaling** | Foundry gerencia a lógica de escalabilidade |
| ✅ **Menor Barreira** | Não requer expertise em infraestrutura Azure |

---

## Conceitos Principais

- **Azure Container Apps (ACA)**: Plataforma serverless para contêineres com auto-scaling
- **Connected Agent**: Agente externo registrado no Control Plane do Foundry para governança
- **AI Gateway (APIM)**: Proxy do Foundry que roteia requisições e coleta telemetria
- **FastAPI**: Framework HTTP que serve o agente (substitui o adaptador agentserver dos agentes hospedados)
- **Managed Identity**: O ACA usa sua própria MI (diferente da MI do projeto Foundry)

---

## Hosted vs Connected: Lado a Lado

| Aspecto | Lições 2-3 (Hosted) | Lição 4 (ACA) |
|---|---|---|
| Infraestrutura | Foundry (Capability Host) | Azure Container Apps (usuário) |
| Servidor HTTP | Adaptador agentserver (porta 8088) | FastAPI + uvicorn (porta 8080) |
| Registro | Hosted Agent (CLI/SDK) | Connected Agent (portal Control Plane) |
| Escalabilidade | Gerenciada pelo Foundry | Gerenciada pelo ACA (minReplicas/maxReplicas) |
| Proxy | Responses API nativa | AI Gateway (APIM) |
| Managed Identity | MI do projeto Foundry | MI do Container App |

---

## Infraestrutura como Código: Walkthrough do Bicep

A diferença principal das Lições 2-3 é que **você** define a infraestrutura com Bicep.

### Estrutura de Arquivos

```
labs/solution/
├── aca.bicep                # Definição de infraestrutura ACA
├── main.py                  # Agente LangGraph (mesmo do Módulo 3)
├── Dockerfile               # Definição do contêiner
├── deploy.ps1               # Automação de implantação
├── REGISTER.md              # Guia de registro do Connected Agent
└── requirements.txt
```

### Componentes Principais do Bicep

**ACA Environment** (base da infraestrutura):
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

**Container App** (o agente propriamente dito):
```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'  // Managed Identity for Azure OpenAI access
  }
  properties: {
    managedEnvironmentId: acaEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080  // FastAPI port (not 8088!)
        transport: 'http'
      }
    }
    template: {
      containers: [{
        name: 'agent'
        image: containerImage
        resources: { cpu: json('0.5'), memory: '1Gi' }
      }]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [{
          name: 'http-scaling'
          http: { metadata: { concurrentRequests: '10' } }
        }]
      }
    }
  }
}
```

**⚠️ CRÍTICO: Atribuição de Role RBAC** (sem isso, seu contêiner não consegue chamar o Azure OpenAI):
```bicep
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerApp.id, 'CognitiveServicesOpenAIUser')
  scope: azureOpenAI
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')  // Cognitive Services OpenAI User
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### Servidor FastAPI vs Adaptador Foundry

**Lição 3 (Foundry Hosted)** — usava o adaptador do Foundry:
```python
# Dockerfile CMD:
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
```

**Lição 4 (ACA Connected)** — você implementa o servidor HTTP:
```python
from fastapi import FastAPI, Request
from langgraph.graph import StateGraph

app = FastAPI()
graph = build_langgraph()

@app.post("/chat")
async def chat(request: Request):
    body = await request.json()
    message = body.get("message")
    result = graph.invoke({"messages": [("user", message)]})
    return {"response": result["messages"][-1][1]}

# Dockerfile CMD:
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
```

> **Mudança principal**: VOCÊ implementa o servidor HTTP. Nenhum adaptador é necessário. Ao registrar como Connected Agent, o Foundry conhece o schema da sua API.

---

## Início Rápido

```powershell
cd labs/solution
.\deploy.ps1
```

O script de implantação automatiza 5 etapas:
1. 🔨 Build da imagem do contêiner no ACR
2. 📦 Deploy da infraestrutura ACA com Bicep
3. 🔐 Configuração de RBAC com Managed Identity
4. 🌐 Teste do endpoint de health
5. 🧪 Validação do endpoint de chat

---

## Registro do Connected Agent

Após a implantação, registre seu agente ACA no Foundry Control Plane:

```powershell
az cognitiveservices connectedagent create \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --foundry-project $foundryProjectName \
  --endpoint "https://$agentFqdn" \
  --description "LangGraph agent deployed on ACA"
```

### Benefícios do Connected Agent

1. **Governança**: O Foundry rastreia todos os agentes (inclusive os externos)
2. **Monitoramento Unificado**: Telemetria flui para o dashboard do Foundry
3. **Controle de Acesso**: Use RBAC do Foundry para acesso ao agente ACA
4. **Descoberta**: Usuários encontram Connected Agents no catálogo do Foundry
5. **AI Gateway**: Roteamento opcional via APIM (rate limiting, autenticação)

> **Connected Agent** = "Ei Foundry, tenho um agente rodando em outro lugar. Por favor, gerencie-o."

---

## Testes: Dois Caminhos

### Caminho 1: Chamada Direta ao ACA (sem passar pelo Foundry)

```powershell
# Chamada HTTP direta ao ACA
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the PETR4 stock price?"}'
```

### Caminho 2: Via Proxy do Foundry (através do AI Gateway)

```powershell
az cognitiveservices agent invoke \
  --name financial-advisor-aca \
  --resource-group $rgName \
  --query "What is the market sentiment for VALE3?"
```

> **Quando usar qual?**
> - **Direto**: Ferramentas internas, alto throughput, menor latência
> - **Proxy**: Acesso externo, rate limiting, governança

---

## Comparação de Custos

| Item | Foundry Hosted | ACA Connected |
|------|----------------|---------------|
| Custo mensal estimado | ~$20-40/mês | ~$15-30/mês (1 réplica) |
| Controle de escalabilidade | Gerenciado pelo Foundry | Você escolhe (min/max replicas) |
| Capacidade reservada | Não disponível | Disponível (economia de custos) |
| Melhor para | Simplicidade, início rápido | Alta utilização, otimização de custos |

---

## Managed Identity em Profundidade

O fluxo de Managed Identity do ACA:
1. O contêiner solicita um token ao endpoint de metadados do Azure
2. O Azure verifica a identidade do contêiner (via MI atribuída pelo sistema)
3. O token é emitido (com escopo para Cognitive Services)
4. O contêiner usa o token para chamar o Azure OpenAI

> Nenhum gerenciamento de credenciais é necessário. A Managed Identity cuida da autenticação automaticamente.

---

## 🔧 Solução de Problemas

| Problema | Causa | Correção |
|----------|-------|----------|
| "Quota exceeded for Managed Environments" | Limite da assinatura | Solicite aumento de cota OU exclua ambientes ACA não utilizados |
| "Container image not found" | Build no ACR falhou | Verifique logs do build no ACR: `az acr task logs` |
| "Role assignment failed" | Permissões insuficientes | Certifique-se de que o usuário tem a role "User Access Administrator" |
| Timeout no health check | Contêiner não está iniciando | Verifique logs do ACA: `az containerapp logs show` |
| Agente retorna 500 em `/chat` | Endpoint do Azure OpenAI mal configurado | Verifique variáveis de ambiente e permissões da MI |
| Contêiner preso em "Provisioning" | Falha no pull da imagem ou timeout de inicialização | Verifique `ImagePullBackOff` nos logs |

### Verificar Status do ACA

```powershell
# Check container status
az containerapp show --name aca-lg-agent --resource-group $rgName \
  --query "properties.runningStatus"

# View real-time logs
az containerapp logs show --name aca-lg-agent --resource-group $rgName --follow

# Query logs in Log Analytics
# ContainerAppConsoleLogs_CL | where TimeGenerated > ago(10m) | project TimeGenerated, Log_s
```

---

## ❓ Perguntas Frequentes

**P: Posso usar Hosted Agent e Connected Agent no mesmo projeto Foundry?**
R: Sim! Você pode combinar modelos de implantação. Use Hosted para agentes simples e Connected para agentes que precisam de controle de infraestrutura.

**P: O Foundry rastreia o uso de Connected Agents?**
R: Sim. O Foundry coleta telemetria através do proxy AI Gateway — contagem de requisições, latência, taxa de sucesso. Útil para chargeback e cotas.

**P: O que acontece se meu ACA ficar fora do ar?**
R: Requisições através do proxy do Foundry falharão com timeout. Configure o ACA com `minReplicas: 1` para evitar cold starts, e configure health probes.

**P: Por que porta 8080 em vez de 8088?**
R: O ACA não usa o adaptador do Foundry (que faz bind na 8088). Você controla o servidor HTTP com FastAPI/uvicorn, e 8080 é a escolha convencional.

**P: Posso usar um private endpoint para o ACA?**
R: Sim. Configure integração com VNet para o ACA e registre o endpoint interno como URL do Connected Agent. O AI Gateway do Foundry precisa de acesso de rede para alcançá-lo.

---

## 🏆 Desafios Autônomos

1. **Domínio Customizado**: Configure um domínio customizado para seu agente ACA (ex.: `agent.contoso.com`)
2. **Integração com VNet**: Implante o ACA com VNet privada e ingress apenas interno
3. **Sistema Multi-Agente**: Implante múltiplos agentes no mesmo ACA Environment e registre cada um como Connected Agent
4. **Ajuste de Auto-Scaling**: Experimente diferentes regras de escalabilidade (KEDA, baseada em CPU, tamanho de fila)
5. **Deploy Blue-Green**: Implemente deploy blue-green baseado em revisões no ACA para atualizações com zero downtime

---

## Referências

- [Documentação do Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Referência da Linguagem Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Guia de Connected Agents do Foundry](https://learn.microsoft.com/azure/ai-services/)
- [Managed Identity para ACA](https://learn.microsoft.com/azure/container-apps/managed-identity)
