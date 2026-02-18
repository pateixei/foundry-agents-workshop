# Demo 5: Integração com Microsoft Agent 365 SDK

> 🇺🇸 **[Read in English](README.md)**

> **Tipo de Demo**: Demonstração guiada pelo instrutor. Esta demo referencia o código-fonte em `lesson-5-a365-langgraph/`. O instrutor percorre a configuração do A365 CLI, integração com Bot Framework e implantação ao vivo na tela.

## Visão Geral

Demonstra a integração do **Microsoft Agent 365 (A365) SDK** com agentes implantados para habilitar funcionalidades do Microsoft 365: protocolo Bot Framework, Adaptive Cards e observabilidade para implantação no Teams/Outlook.

## Conceitos-Chave

- ✅ Arquitetura cross-tenant (Azure Tenant A + M365 Tenant B)
- ✅ Registro de Agent Blueprint no Entra ID
- ✅ Endpoint Bot Framework `/api/messages`
- ✅ Adaptive Cards para UI rica no M365
- ✅ Integração OpenTelemetry com Application Insights
- ✅ Publicação no M365 Admin Center
- ✅ Criação de instâncias de agente no Teams

## Arquitetura

```
┌────────────────────────────────────┐
│ M365 Tenant (Tenant B)             │
│  ├─> Agent Blueprint (Entra ID)    │
│  ├─> Agent User (Service Principal)│
│  └─> Teams/Outlook interface       │
└─────────┬──────────────────────────┘
          │ (routes to)
          ▼
┌────────────────────────────────────┐
│ Azure Tenant (Tenant A)            │
│  ├─> ACA with agent code           │
│  ├─> /api/messages endpoint        │
│  └─> Managed Identity auth         │
└────────────────────────────────────┘
```

## Pré-requisitos

1. **Acesso ao Frontier Program**: Necessário para registro A365
2. **.NET SDK 8.0+**: Para a ferramenta A365 CLI
3. **Acesso Admin M365**: Para aprovação de publicação
4. **Agente Existente**: Implantado em ACA (da Demo 4) ou Foundry

## Início Rápido

### Fase 1: Configuração do A365 CLI

```powershell
# Install A365 CLI
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify installation
a365 --version

# Initialize config (interactive)
cd lesson-6-a365-prereq
a365 config init
```

### Fase 2: Registro do Blueprint

```powershell
# Login to M365 tenant (Tenant B)
az login --tenant <m365-tenant-id>

# Create Agent Blueprint
a365 setup blueprint --config a365.config.json
```

Saída esperada:
```
✅ Agent Blueprint registered
  App ID: f7a3b8e9-...
  Name: financial-advisor-aca
  Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
```

### Fase 3: Aprimorar Agente com A365 SDK

O código do agente agora inclui o tratamento do Bot Framework:

```python
# Enhanced main.py with Bot Framework
from botbuilder.core import BotFrameworkAdapter, TurnContext
from botbuilder.schema import Activity
from langgraph_agent import create_agent

agent = create_agent()

async def on_message_activity(turn_context: TurnContext):
    """Handles incoming Bot Framework Activities."""
    user_message = turn_context.activity.text
    
    # Process with LangGraph agent
    response = await agent.run(user_message)
    
    # Return Adaptive Card (rich UI)
    card = create_adaptive_card(response)
    await turn_context.send_activity(Activity(attachments=[card]))

def create_adaptive_card(text: str) -> dict:
    """Creates an Adaptive Card for M365."""
    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "version": "1.4",
            "body": [
                {
                    "type": "TextBlock",
                    "text": "Financial Advisor",
                    "weight": "Bolder",
                    "size": "Large"
                },
                {
                    "type": "TextBlock",
                    "text": text,
                    "wrap": True
                }
            ]
        }
    }

# FastAPI endpoint for Bot Framework
@app.post("/api/messages")
async def handle_messages(request: Request):
    body = await request.json()
    activity = Activity().deserialize(body)
    
    auth_header = request.headers.get("Authorization", "")
    await adapter.process_activity(activity, auth_header, on_message_activity)
    
    return {"status": "ok"}
```

### Fase 4: Implantar Agente Aprimorado

```powershell
cd lesson-5-a365-langgraph
.\deploy.ps1
```

### Fase 5: Publicar no M365 Admin Center

```powershell
cd lesson-7-publish

# Submit for publication
a365 publish --manifest publication-manifest.json
```

**publication-manifest.json**:
```json
{
  "name": "Financial Advisor Agent",
  "shortDescription": "AI agent providing stock insights",
  "longDescription": "Leverages LangGraph with real-time market data tools...",
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
  "categories": ["Finance", "AI Assistant"],
  "isPrivate": true,
  "permissions": [
    "Microsoft.Graph.User.Read",
    "Microsoft.Graph.Conversations.Send"
  ]
}
```

### Fase 6: Criar Instância do Agente no Teams

```powershell
# After admin approval
cd lesson-8-instances

# Create personal instance
a365 instance create --type personal --agent-id <blueprint-app-id>

# Create shared instance (team/channel)
a365 instance create --type shared --team-id <teams-team-id> --agent-id <blueprint-app-id>
```

## Fluxo de Activity do Bot Framework

```
Teams User → Message
    ↓
Microsoft Graph API (M365 Tenant)
    ↓
Agent Blueprint (Entra ID)
    ↓
Messaging Endpoint (ACA in Azure Tenant)
    ↓
/api/messages endpoint
    ↓
BotFrameworkAdapter
    ↓
on_message_activity handler
    ↓
LangGraph agent processes
    ↓
Adaptive Card response
    ↓
Response flows back to Teams
```

## Exemplos de Adaptive Cards

### Card de Cotação de Ação

```json
{
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
            "type": "TextBlock",
            "text": "📈 PETR4",
            "size": "Large",
            "weight": "Bolder"
          }]
        },
        {
          "type": "Column",
          "width": "stretch",
          "items": [{
            "type": "TextBlock",
            "text": "R$ 35,42",
            "size": "Large",
            "horizontalAlignment": "Right",
            "color": "Good"
          }]
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Variação: +1.23% (alta)",
      "color": "Good"
    },
    {
      "type": "TextBlock",
      "text": "Informação apenas para fins educativos.",
      "size": "Small",
      "isSubtle": True,
      "wrap": True
    }
  ]
}
```

## Fluxo de Autenticação Cross-Tenant

1. **Desenvolvedor** (Azure Tenant A): Implanta infraestrutura do agente
2. **A365 CLI** (via login M365 Tenant B): Cria Blueprint no Tenant B
3. **Agent Blueprint** (M365 Tenant B): Referencia o endpoint de mensagens no Tenant A
4. **Runtime**: M365 autentica usuário → Agent Blueprint → roteia para endpoint no Azure Tenant A

## Resolução de Problemas

**Problema: "A365 CLI command not found"**  
**Causa**: Caminho das .NET tools não está no PATH  
**Solução**: Adicione `~/.dotnet/tools` ao PATH ou reinicie o terminal

**Problema: "Frontier Program access denied"**  
**Causa**: Não inscrito no programa de preview  
**Solução**: Inscreva-se em https://adoption.microsoft.com/copilot/frontier-program/

**Problema: "Blueprint registration failed: tenant mismatch"**  
**Causa**: Logado no tenant errado com `az login`  
**Solução**: `az login --tenant <m365-tenant-id>` explicitamente

**Problema: "/api/messages returns 404"**  
**Causa**: Endpoint do Bot Framework não implementado ou rota mal configurada  
**Solução**: Verifique se a rota FastAPI existe: `@app.post("/api/messages")`

**Problema: "Adaptive Card not rendering in Teams"**  
**Causa**: Schema JSON inválido ou incompatibilidade de versão  
**Solução**: Valide em https://adaptivecards.io/designer

## Tipos de Instância de Agente

| Tipo | Escopo | Caso de Uso |
|------|-------|----------|
| **Personal** | Usuário individual | Agente privado para uso pessoal |
| **Shared** | Equipe/Canal | Agente colaborativo para a equipe |
| **Org-wide** | Organização inteira | Implantação em toda a empresa |

## Recursos

- [Guia do Desenvolvedor Microsoft Agent 365](https://learn.microsoft.com/microsoft-agent-365/developer/)
- [SDK do Bot Framework](https://learn.microsoft.com/azure/bot-service/)
- [Designer de Adaptive Cards](https://adaptivecards.io/designer/)
- [Frontier Program](https://adoption.microsoft.com/copilot/frontier-program/)

---

**Nível da Demo**: Avançado  
**Tempo Estimado**: 45-60 minutos (inclui espera de aprovação do admin)  
**Melhor Para**: Implantações corporativas no ecossistema M365 (Teams, Outlook, Copilot)
