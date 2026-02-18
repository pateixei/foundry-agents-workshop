# Lab 6: Integração Microsoft Agent 365 e Implantação no M365

> 🇺🇸 **[Read in English](LAB-STATEMENT.md)**

## Objetivo

Aprimorar seu agente com o **Microsoft Agent 365 (A365) SDK**, registrar Agent Blueprint no Microsoft 365 e implantar no Teams para acesso dos usuários finais. Este laboratório completa o ciclo completo de implantação corporativa.

## Cenário

Seu agente de consultoria financeira (do Lab 4) está pronto para produção. O negócio requer:
- Implantação no Microsoft Teams para funcionários
- Integração com Bot Framework para conversas ricas
- Adaptive Cards para visualização de dados financeiros
- Suporte cross-tenant (infraestrutura Azure no Tenant A, M365 no Tenant B)
- Processo de publicação com aprovação do admin

## Objetivos de Aprendizagem

- Configurar A365 CLI para cenários cross-tenant
- Registrar Agent Blueprints no Microsoft Entra ID
- Implementar endpoint Bot Framework `/api/messages`
- Criar Adaptive Cards para dados financeiros
- Publicar agentes no M365 Admin Center
- Criar e gerenciar instâncias de agente no Teams
- Entender o modelo de governança M365 para agentes

## Pré-requisitos

- [x] Lab 4 completado (agente implantado em ACA)
- [x] Acesso ao Frontier Program (necessário para A365)
- [x] .NET SDK 8.0+ instalado
- [x] Permissões de Admin M365 (ou simuladas para o workshop)
- [x] Entendimento de cenários cross-tenant

## Tarefas

### Tarefa 1: Instalar e Configurar A365 CLI (15 minutos)

**1.1 - Instalar .NET SDK**

```powershell
# Check version
dotnet --version
# Required: 8.0+

# If missing:
winget install Microsoft.DotNet.SDK.8
```

**1.2 - Instalar A365 CLI**

```powershell
# Install as .NET global tool
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify
a365 --version
# Expected: 1.0.x or higher
```

**1.3 - Configurar A365**

```powershell
cd starter/a365-config
a365 config init
```

**Prompts interativos**:
```
? M365 Tenant ID: <your-m365-tenant-id>
? Azure Subscription ID: <your-azure-subscription-id>
? Agent Name: financial-advisor-teams
? Messaging Endpoint: https://aca-financial-agent.nicebeach-abc123.eastus.azurecontainerapps.io/api/messages
? Create Azure infrastructure (App Service)? No  ← IMPORTANTE: Já temos ACA!
```

**`a365.config.json` gerado**:
```json
{
  "tenantId": "<m365-tenant-id>",
  "subscriptionId": "<azure-subscription-id>",
  "agentName": "financial-advisor-teams",
  "messagingEndpoint": "https://aca-financial-agent...azurecontainerapps.io/api/messages",
  "needDeployment": false
}
```

**Critérios de Sucesso**:
- ✅ A365 CLI instalado e funcionando
- ✅ Arquivo de configuração criado com valores corretos
- ✅ `needDeployment: false` (usando ACA existente)

### Tarefa 2: Registrar Agent Blueprint (20 minutos)

**2.1 - Login no Tenant M365**

```powershell
# Important: Login to M365 tenant (Tenant B), not Azure tenant (Tenant A)
az login --tenant <m365-tenant-id>

# Verify
az account show
# Tenant ID should match M365 tenant
```

**2.2 - Criar Agent Blueprint**

```powershell
a365 setup blueprint --config a365.config.json
```

**Saída Esperada**:
```
🔧 Creating Agent Blueprint...
✅ Blueprint registered in Entra ID
   App ID: f7a3b8e9-1234-5678-abcd-9876543210ef
   Name: financial-advisor-teams
   Messaging Endpoint: https://aca-financial-agent...azurecontainerapps.io/api/messages

🔐 Creating Service Principal (Agent User)...
✅ Service Principal created
   Principal ID: abc12345-...

✅ Configuring permissions...
   - Microsoft.Graph.User.Read
   - Microsoft.Graph.Conversations.Send

✅ Agent Blueprint registration complete
```

**O que aconteceu?**:
- Criou App Registration no Entra ID do Tenant M365
- Criou Service Principal (identidade Agent User)
- Configurou permissões da Graph API
- Vinculou o endpoint de mensagens (seu agente ACA no Azure Tenant)

**2.3 - Verificar no Portal**

1. Navegue até o [Portal Entra ID](https://entra.microsoft.com/)
2. Selecione **App registrations** → **All applications**
3. Busque por "financial-advisor-teams"
4. Verifique o endpoint de mensagens em **Authentication**

**Critérios de Sucesso**:
- ✅ Blueprint visível no Entra ID
- ✅ Service Principal criado
- ✅ Permissões configuradas corretamente
- ✅ Endpoint de mensagens aponta para ACA

### Tarefa 3: Aprimorar Agente com Bot Framework (30 minutos)

**3.1 - Adicionar dependências do Bot Framework**

Atualize `requirements.txt`:
```txt
# Existing dependencies...
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
botframework-connector>=4.16.0
```

**3.2 - Implementar endpoint `/api/messages`**

Abra `starter/main.py` e adicione:

```python
from fastapi import FastAPI, Request, Response
from botbuilder.core import BotFrameworkAdapter, TurnContext
from botbuilder.schema import Activity
from langgraph_agent import create_agent

app = FastAPI()
agent_graph = create_agent()

# Bot Framework Adapter
adapter = BotFrameworkAdapter(
    app_id=os.environ.get("MICROSOFT_APP_ID"),  # From Agent Blueprint
    app_password=os.environ.get("MICROSOFT_APP_PASSWORD", "")  # MI auth
)

async def on_message_activity(turn_context: TurnContext):
    """Handles incoming Bot Framework Activities from M365."""
    user_message = turn_context.activity.text
    
    # Process with LangGraph agent
    result = await agent_graph.ainvoke({
        "messages": [user_message],
        "current_tool": None,
        "tool_result": {}
    })
    
    response_text = result["messages"][-1].content
    
    # Create Adaptive Card for rich display
    card = create_financial_card(response_text)
    
    await turn_context.send_activity(
        Activity(
            type="message",
            attachments=[card]
        )
    )

@app.post("/api/messages")
async def handle_messages(request: Request):
    """Bot Framework messaging endpoint for M365."""
    auth_header = request.headers.get("Authorization", "")
    body = await request.json()
    
    activity = Activity().deserialize(body)
    
    # Process with Bot Framework adapter
    await adapter.process_activity(activity, auth_header, on_message_activity)
    
    return Response(status_code=200)
```

**3.3 - Criar helper de Adaptive Card**

```python
def create_financial_card(text: str, data: dict = None) -> dict:
    """Creates an Adaptive Card for financial information."""
    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.4",
            "body": [
                {
                    "type": "ColumnSet",
                    "columns": [
                        {
                            "type": "Column",
                            "width": "auto",
                            "items": [{
                                "type": "Image",
                                "url": "https://example.com/finance-icon.png",
                                "size": "Small"
                            }]
                        },
                        {
                            "type": "Column",
                            "width": "stretch",
                            "items": [{
                                "type": "TextBlock",
                                "text": "Financial Advisor",
                                "weight": "Bolder",
                                "size": "Large"
                            }]
                        }
                    ]
                },
                {
                    "type": "TextBlock",
                    "text": text,
                    "wrap": True
                }
            ]
        }
    }
```

**3.4 - Reimplantar no ACA**

```powershell
# Rebuild container with Bot Framework support
docker build -t langgraph-financial-agent:v2 .
docker tag langgraph-financial-agent:v2 YOUR-ACR.azurecr.io/langgraph-financial-agent:v2
docker push YOUR-ACR.azurecr.io/langgraph-financial-agent:v2

# Update ACA to use new image
az containerapp update \
  --name aca-financial-agent \
  --resource-group rg-aca \
  --image YOUR-ACR.azurecr.io/langgraph-financial-agent:v2
```

**3.5 - Testar endpoint Bot Framework**

```powershell
# Simulate Bot Framework Activity
$activity = @{
    type = "message"
    text = "Qual o preco da PETR4?"
    from = @{ id = "user123"; name = "Test User" }
    conversation = @{ id = "conv123" }
    channelId = "test"
    serviceUrl = "https://test.botframework.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://aca-financial-agent...azurecontainerapps.io/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

**Critérios de Sucesso**:
- ✅ Endpoint `/api/messages` implementado
- ✅ Activities do Bot Framework processadas
- ✅ Adaptive Cards renderizados
- ✅ Agente reimplantado com sucesso

### Tarefa 4: Publicar no M365 Admin Center (20 minutos)

**4.1 - Criar manifesto de publicação**

Crie `publication-manifest.json`:
```json
{
  "name": "Financial Advisor Agent",
  "shortDescription": "AI-powered financial market insights for Brazilian and international markets",
  "longDescription": "Leverages LangGraph orchestration with real-time market data tools. Provides stock quotes, exchange rates, and market summaries. Includes appropriate disclaimers for educational purposes.",
  "developer": {
    "name": "Contoso Financial Services",
    "websiteUrl": "https://contoso.com",
    "privacyUrl": "https://contoso.com/privacy",
    "termsOfUseUrl": "https://contoso.com/terms"
  },
  "icons": {
    "color": "icon-color.png",
    "outline": "icon-outline.png"
  },
  "categories": ["Finance", "AI Assistant", "Productivity"],
  "isPrivate": true,
  "permissions": [
    "Microsoft.Graph.User.Read",
    "Microsoft.Graph.Conversations.Send"
  ]
}
```

**4.2 - Submeter para publicação**

```powershell
a365 publish --manifest publication-manifest.json
```

**Saída Esperada**:
```
📤 Submitting agent for publication...
   Blueprint: financial-advisor-teams
   App ID: f7a3b8e9-...
   
✅ Submission successful!
   
📋 Publication Details:
   Submission ID: sub-abc123
   Status: Pending Admin Approval
   Submitted: 2026-02-14 15:30 UTC
   
⏳ Next Steps:
   1. M365 Admin reviews in Admin Center
   2. You'll receive email when status changes
   3. After approval, agent appears in Teams app catalog
```

**4.3 - Aprovação do Admin (Simulada para o Workshop)**

Em produção:
1. Admin M365 recebe notificação
2. Admin Center → **Apps** → **Manage apps** → **financial-advisor-teams**
3. Revisa metadados, permissões, política de privacidade
4. Clica em **Approve** ou **Reject**
5. Se aprovado, define visibilidade: Org privada / Pública / Usuários específicos

**Critérios de Sucesso**:
- ✅ Manifesto de publicação é JSON válido
- ✅ Submetido com sucesso ao Admin Center
- ✅ (Em produção) Aprovação do admin obtida

### Tarefa 5: Criar Instância do Agente no Teams (15 minutos)

**Premissa**: Agente está aprovado e publicado (ou usando agente de teste pré-aprovado)

**5.1 - Criar instância pessoal**

```powershell
# Personal agent (private to one user)
a365 instance create \
  --type personal \
  --agent-id f7a3b8e9-1234-5678-abcd-9876543210ef \
  --user-id <your-m365-user-id>
```

**5.2 - Testar no Teams**

1. Abra o Microsoft Teams (desktop ou web)
2. Vá para **Apps** → **Built for your org**
3. Busque "Financial Advisor"
4. Clique em **Add**
5. Inicie conversa:
   - "Qual é o preço da PETR4?"
   - "Calcule valor: 100 PETR4, 50 VALE3"
   - "Resumo do mercado brasileiro"

**Comportamento Esperado**:
- Agente responde com Adaptive Cards (UI rica)
- Dados financeiros formatados profissionalmente
- Disclaimers incluídos
- Contexto da conversa mantido

**5.3 - Criar instância compartilhada (Opcional)**

```powershell
# Shared agent for entire team
a365 instance create \
  --type shared \
  --agent-id f7a3b8e9-... \
  --team-id <teams-team-id>
```

**Critérios de Sucesso**:
- ✅ Agente visível no catálogo de apps do Teams
- ✅ Instância pessoal criada
- ✅ Conversas funcionam no Teams
- ✅ Adaptive Cards renderizados corretamente

## Entregáveis

- [x] A365 CLI configurado
- [x] Agent Blueprint registrado no Entra ID
- [x] Integração Bot Framework implementada
- [x] Agente aprimorado com Adaptive Cards
- [x] Manifesto de publicação criado
- [x] Instância do agente funcionando no Teams

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|-----------|--------|-------------|
| **Configuração A365** | 15 pts | Setup do CLI e arquivo de configuração |
| **Registro do Blueprint** | 20 pts | Registrado com sucesso no Entra ID |
| **Bot Framework** | 30 pts | Endpoint `/api/messages` funcional |
| **Adaptive Cards** | 15 pts | Cards ricas implementadas e renderizando |
| **Publicação** | 10 pts | Manifesto válido, submetido ao Admin Center |
| **Integração Teams** | 10 pts | Agente funcionando no Teams |

**Total**: 100 pontos

## Resolução de Problemas

### "A365 CLI not found"
- Caminho das .NET tools não está no PATH
- Solução: Adicione `~/.dotnet/tools` ao PATH, reinicie o terminal

### "Blueprint registration failed: tenant mismatch"
- Logado no tenant errado
- Solução: `az login --tenant <m365-tenant-id>` explicitamente

### "/api/messages returns 400"
- Formato JSON da Activity inválido
- Solução: Certifique-se de que o schema da Activity corresponde à especificação do Bot Framework

### "Adaptive Card not rendering in Teams"
- Schema inválido ou versão incompatível
- Solução: Valide em https://adaptivecards.io/designer
- Certifique-se de que a versão é 1.4 ou inferior (limite do Teams)

### "Frontier Program access denied"
- Não inscrito no preview
- Solução: Inscreva-se em https://adoption.microsoft.com/copilot/frontier-program/

## Estimativa de Tempo

- Tarefa 1: 15 minutos
- Tarefa 2: 20 minutos
- Tarefa 3: 30 minutos
- Tarefa 4: 20 minutos
- Tarefa 5: 15 minutos
- **Total**: 100 minutos

## Parabéns! 🎉

Você completou o ciclo completo de implantação corporativa de agentes:
1. ✅ Construiu agente declarativo (Lab 1)
2. ✅ Implementou tools personalizadas com MAF (Lab 2)
3. ✅ Implantou agente LangGraph no Foundry (Lab 3)
4. ✅ Implantou em ACA com Bicep (Lab 4)
5. ✅ Integrou A365 e publicou no Teams (Lab 6)

Seu agente agora está acessível para usuários finais no Microsoft 365!

---

**Dificuldade**: Avançado  
**Pré-requisitos**: Todos os labs anteriores, acesso ao Frontier Program  
**Tempo Estimado**: 100 minutos
