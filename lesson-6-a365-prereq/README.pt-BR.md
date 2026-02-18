# Lição 6 - Configuração Completa do Microsoft Agent 365

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Configurar** o CLI e a autenticação do Agent 365 (A365) para cenários cross-tenant
2. **Registrar** Agent Blueprint no Entra ID do Microsoft 365
3. **Compreender** a arquitetura cross-tenant (Azure Tenant A + M365 Tenant B)
4. **Publicar** o Agent Blueprint no M365 Admin Center para aprovação administrativa
5. **Criar** instâncias de agente no Microsoft Teams (pessoal e compartilhada)
6. **Gerenciar** o ciclo de vida completo de desenvolvimento do Agent 365 (config → blueprint → publicar → instâncias)

---

## Visão Geral

Esta lição cobre a configuração e implantação completa de agentes no **Microsoft Agent 365** (A365), desde a configuração até a publicação e criação de instâncias de agente no Microsoft 365.

> **IMPORTANTE**: O Agent 365 requer participação no [programa Frontier preview](https://adoption.microsoft.com/copilot/frontier-program/).

---

## Arquitetura: Fluxo Cross-Tenant

```
Usuário no Tenant M365 (Tenant B)
    ↓ (invoca agente via Teams)
Microsoft Graph (Tenant B)
    ↓ (autentica usando Agent User)
Agent Blueprint (Entra ID do Tenant B)
    ↓ (roteia requisição para)
Messaging Endpoint (ACA no Tenant A)
    ↓ (agente executa)
Resposta retorna via Graph
```

> **Insight chave**: A identidade do agente vive no Tenant M365, mas o código do agente roda no Tenant Azure. O A365 CLI faz a ponte ao registrar a URL do endpoint no Entra ID do M365.

---

## Ciclo de Vida de Desenvolvimento do A365

| Etapa | Fase | Onde | Esta Lição? |
|-------|------|------|:-----------:|
| 1 | Construir e executar o agente | Azure Tenant A | ❌ (Lição 4) |
| 2 | Configurar o A365 | M365 Tenant B | ✅ |
| 3 | Configurar o agent blueprint | M365 Tenant B | ✅ |
| 4 | Implantar infraestrutura | Azure Tenant A | ❌ (Lição 4) |
| 5 | Publicar no M365 admin center | M365 Tenant B | ✅ |
| 6 | Criar instâncias de agente | M365 (Teams/Outlook) | ✅ |

---

## Contexto: Cenário Cross-Tenant

Neste workshop, temos um cenário específico:

| Recurso | Tenant | Descrição |
|---------|--------|-----------|
| **Azure** (Foundry, ACA, ACR) | Tenant A (Azure) | Onde os agentes são implantados |
| **Microsoft 365** (Teams, Outlook) | Tenant B (M365) | Onde os usuários finais interagem com os agentes |

O A365 CLI usa **um único `tenantId`** no `a365.config.json`. Esse tenant é o **tenant do Microsoft 365** (Tenant B), pois é onde:
- O Agent Blueprint é registrado no Entra ID
- O Agent User (service principal) é criado
- O agente aparece no Teams e Outlook dos usuários
- As permissões do Microsoft Graph são concedidas

A assinatura Azure (no Tenant A) é referenciada separadamente no campo `subscriptionId` da configuração. No entanto, `a365 setup` cria recursos Azure (Resource Group, App Service Plan, Web App) **na assinatura do tenant autenticado**.

### Abordagem: `needDeployment: false`

Como o agente já está implantado no ACA (Tenant A, lição 4), não precisamos que o A365 CLI crie infraestrutura Azure. Usaremos `needDeployment: false` para que o CLI apenas:

1. **Registre o Agent Blueprint** no Entra ID do Tenant M365 (Tenant B)
2. **Configure o messaging endpoint** apontando para o ACA no Tenant A
3. **Crie a identidade do agente** (service principal) no Tenant M365

Isso significa:

- `az login` deve autenticar no **Tenant M365** (Tenant B)
- O Custom Client App Registration deve ser feito no **Tenant B** (M365)
- O usuário do CLI precisa de roles no **Tenant B**: Global Administrator, Agent ID Administrator ou Agent ID Developer
- **Nenhuma assinatura Azure é necessária** no Tenant M365 para criar infraestrutura (não criaremos nenhum recurso Azure via CLI)
- Campos de infraestrutura Azure no `a365.config.json` (`resourceGroup`, `appServicePlanName`, etc.) podem conter valores placeholder — não serão utilizados

---

## Ciclo de Desenvolvimento do Agent 365

O ciclo completo possui 6 etapas. **Nesta lição cobrimos as etapas 2-6 (configuração completa do A365)**:

```
1. Construir e executar o agente   <-- já feito (lição 4, ACA no Tenant A)
2. Configurar o Agent 365          <-- ESTA LIÇÃO
3. Configurar o agent blueprint    <-- ESTA LIÇÃO
4. Deploy                          <-- já feito (lição 4, needDeployment: false)
5. Publicar no M365 admin center   <-- ESTA LIÇÃO
6. Criar instâncias de agente      <-- ESTA LIÇÃO
```

Referência: [Ciclo de Vida de Desenvolvimento do Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)

---

## Pré-requisito 0 - Programa Frontier Preview

O Agent 365 requer acesso ao programa Frontier preview:

1. Acesse [https://adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/)
2. Faça login com sua conta do **Tenant M365** (Tenant B)
3. Solicite acesso ao programa
4. Aguarde a aprovação (pode levar alguns dias)

---

## Pré-requisito 1 - Instalar o .NET SDK

O A365 CLI é distribuído como uma ferramenta .NET:

```powershell
# Verifique se o .NET está instalado
dotnet --version
# Recomendado: .NET 8.0+

# Se não estiver instalado, baixe em:
# https://dotnet.microsoft.com/download
```

---

## Pré-requisito 2 - Instalar o Agent 365 CLI

```powershell
# Instalar o CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verificar instalação
a365 -h

# Para atualizar no futuro:
dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease
```

> **Nota**: Sempre use `--prerelease` enquanto o CLI estiver em preview.
> NuGet: [Microsoft.Agents.A365.DevTools.Cli](https://www.nuget.org/packages/Microsoft.Agents.A365.DevTools.Cli)

---

## Pré-requisito 3 - Custom Client App Registration (no Tenant M365)

O CLI precisa de um app registration no Entra ID do **Tenant M365** para autenticação.

### 3.1 - Registrar o aplicativo

1. Acesse o [Centro de administração Microsoft Entra](https://entra.microsoft.com/) do **Tenant B (M365)**
2. Navegue até **App registrations > New registration**
3. Preencha:
   - **Name**: `a365-workshop-cli`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**: Selecione `Public client/native (mobile & desktop)` e insira `http://localhost:8400/`
4. Clique em **Register**

### 3.2 - Configurar Redirect URI adicional

1. Na página **Overview** do aplicativo, copie o **Application (client) ID** (formato GUID)
2. Vá para **Authentication (preview)** > **Add Redirect URI**
3. Selecione **Mobile and desktop applications** e adicione:
   ```
   ms-appx-web://Microsoft.AAD.BrokerPlugin/{YOUR-CLIENT-ID}
   ```
   (substitua `{YOUR-CLIENT-ID}` pelo Application (client) ID copiado)
4. Clique em **Configure**

### 3.3 - Configurar Permissões de API

> **IMPORTANTE**: Use **Delegated permissions** (NÃO Application permissions).

#### Opção A - Via centro de administração Entra (se permissões beta estiverem visíveis)

1. No app registration, vá para **API permissions > Add a permission**
2. Selecione **Microsoft Graph > Delegated permissions**
3. Adicione as 5 permissões:

| Permissão | Descrição |
|-----------|-----------|
| `AgentIdentityBlueprint.ReadWrite.All` | Gerenciar Agent Blueprints (beta) |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Atualizar permissões herdadas do Blueprint (beta) |
| `Application.ReadWrite.All` | Criar e gerenciar aplicativos |
| `DelegatedPermissionGrant.ReadWrite.All` | Conceder permissões para blueprints |
| `Directory.Read.All` | Ler dados do diretório |

4. Clique em **Grant admin consent for [Your Tenant]**
5. Verifique que todas mostram marcas de verificação verdes

#### Opção B - Via Microsoft Graph API (se permissões beta NÃO estiverem visíveis)

Se as permissões `AgentIdentityBlueprint.*` não aparecerem no portal, use o Graph Explorer:

1. Acesse o [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
2. Faça login com a conta de administrador do Tenant M365

**Obter o ID do Service Principal do aplicativo:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{YOUR-CLIENT-ID}'&$select=id
```
O `id` retornado é o `SP_OBJECT_ID`.

Se retornar vazio, crie o service principal:
```http
POST https://graph.microsoft.com/v1.0/servicePrincipals
Body: { "appId": "{YOUR-CLIENT-ID}" }
```

**Obter o Resource ID do Graph:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=id
```
O `id` retornado é o `GRAPH_RESOURCE_ID`.

**Criar as permissões delegadas (com consentimento administrativo automático):**
```http
POST https://graph.microsoft.com/v1.0/oauth2PermissionGrants
Body:
{
  "clientId": "<SP_OBJECT_ID>",
  "consentType": "AllPrincipals",
  "principalId": null,
  "resourceId": "<GRAPH_RESOURCE_ID>",
  "scope": "Application.ReadWrite.All Directory.Read.All DelegatedPermissionGrant.ReadWrite.All AgentIdentityBlueprint.ReadWrite.All AgentIdentityBlueprint.UpdateAuthProperties.All"
}
```

> **ATENÇÃO**: Se você usou a Opção B, **NÃO** clique em "Grant admin consent" no portal Entra depois. O portal não enxerga permissões beta e sobrescreverá o que você criou via API.

### 3.4 - Anotar o Client ID

Salve o **Application (client) ID** — você precisará dele na próxima etapa.

```
Application (client) ID: ________-____-____-____-____________
```

---

## Etapa 2 - Configurar o Agent 365

Como usamos `needDeployment: false`, **não** executaremos o assistente interativo `a365 config init` (ele tenta listar assinaturas Azure e pode falhar sem uma assinatura no Tenant M365). Em vez disso, criaremos o `a365.config.json` manualmente.

### 4.1 - Autenticar no Tenant M365

```powershell
# Login no Tenant M365 (Tenant B)
az login --tenant <TENANT-M365-ID>

# Verificar que estamos no tenant correto
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> `az login` é necessário para o CLI autenticar no Entra ID do Tenant M365. NÃO precisamos de uma assinatura Azure aqui.

### 4.2 - Criar a365.config.json manualmente

Navegue até o diretório da lição 6 e crie o arquivo:

```powershell
cd lesson-5-a365-prereq
```

Crie o arquivo `a365.config.json` com o seguinte conteúdo:

```json
{
  "$schema": "./a365.config.schema.json",
  "tenantId": "<TENANT-M365-ID>",
  "clientAppId": "<CLIENT-APP-ID-FROM-STEP-3>",
  "agentBlueprintDisplayName": "Financial Market Agent Blueprint",
  "agentIdentityDisplayName": "Financial Market Agent Identity",
  "agentUserPrincipalName": "fin-market-agent@<tenant-m365>.onmicrosoft.com",
  "agentUserDisplayName": "Financial Market Agent",
  "managerEmail": "your-email@<tenant-m365>.com",
  "agentUserUsageLocation": "BR",
  "deploymentProjectPath": ".",
  "needDeployment": false,
  "messagingEndpoint": "https://<your-aca-app>.<aca-env-hash>.<region>.azurecontainerapps.io/api/messages",
  "agentDescription": "Financial market agent (LangGraph on ACA) - A365 Workshop"
}
```

**Campos importantes:**

| Campo | Valor | Explicação |
|-------|-------|------------|
| `tenantId` | GUID do Tenant M365 | Onde o blueprint é registrado no Entra ID |
| `clientAppId` | GUID da etapa 3.4 | App registration para autenticação do CLI |
| `needDeployment` | `false` | **Não cria infraestrutura Azure** — agente já roda no ACA |
| `messagingEndpoint` | URL do ACA + `/api/messages` | Endpoint que o A365 usa para enviar mensagens ao agente |
| `agentUserPrincipalName` | `name@tenant.onmicrosoft.com` | UPN do agente no Entra (domínio do Tenant M365) |
| `managerEmail` | Email no Tenant M365 | Gerente responsável pelo agente |

> **Nota**: Campos de infraestrutura Azure (`subscriptionId`, `resourceGroup`, `appServicePlanName`, `webAppName`) foram **omitidos** porque `needDeployment: false`. Se o CLI exigir esses campos, adicione valores placeholder.

### 4.3 - Verificar a configuração

```powershell
# Verificar que o arquivo existe
Test-Path a365.config.json
# Esperado: True

# Exibir a configuração
a365 config display
```

**Checklist de verificação:**
- [ ] `tenantId` é o GUID do Tenant M365 (NÃO do Azure)
- [ ] `clientAppId` é o App Registration da etapa 3
- [ ] `needDeployment` é `false`
- [ ] `messagingEndpoint` aponta para o ACA da lição 4
- [ ] `agentUserPrincipalName` usa o domínio `@<tenant-m365>.onmicrosoft.com`
- [ ] `managerEmail` usa o domínio do Tenant M365

---

## Etapa 3 - Configurar o Agent Blueprint

O blueprint define a identidade e as permissões do agente no Entra ID. Com `needDeployment: false`, o CLI **ignora a criação de infraestrutura Azure** e foca apenas no registro de identidade.

### 5.1 - Executar o setup

```powershell
# Executar o setup completo (dentro de lesson-5-a365-prereq/)
a365 setup all
```

Com `needDeployment: false`, o comando executa **apenas**:

1. **Registra o Agent Blueprint** no Entra ID do Tenant M365:
   - Cria o Agent Identity Blueprint (app registration)
   - Cria o service principal associado
   - Configura a identidade do agente (`agentUserPrincipalName`)

2. **Configura Permissões de API**:
   - Escopos da API Microsoft Graph
   - Permissões da API Messaging Bot
   - Permissões herdadas para instâncias futuras

3. **Registra o messaging endpoint**:
   - Associa o `messagingEndpoint` (ACA da lição 4) ao blueprint

4. **Gera `a365.generated.config.json`**:
   - IDs do blueprint, service principal, client secret, endpoint

> **Nota**: O CLI abre janelas do navegador para consentimento administrativo. Complete todos os fluxos. Leva 3-5 minutos.
>
> **Nenhuma infraestrutura Azure será criada** (Resource Group, App Service Plan, Web App). O agente continua rodando no ACA do Tenant A.

### 5.2 - Verificar o setup

```powershell
# Exibir configuração gerada
a365 config display -g
```

Saída esperada (campos principais):
```json
{
  "agentBlueprintId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "agentBlueprintObjectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "agentBlueprintServicePrincipalObjectId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "agentBlueprintClientSecret": "xxx~xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "botMessagingEndpoint": "https://<your-aca-app>.<aca-env-hash>.<region>.azurecontainerapps.io/api/messages",
  "completed": true
}
```

```powershell
# Verificar que o arquivo gerado existe
Test-Path a365.generated.config.json
# Esperado: True
```

**Verificações no centro de administração Entra** (Tenant M365):
- [ ] App Registration existe (pesquise por `agentBlueprintId`)
- [ ] Enterprise Application correspondente existe
- [ ] Permissões de API mostram marcas de verificação verdes ("Granted for [Your Tenant]")
- [ ] Permissões incluem Microsoft Graph e Messaging Bot API
- [ ] Identidade do Agente visível no [Registro de Agentes do Entra](https://entra.microsoft.com/#view/Microsoft_AAD_IAM/AgentIdentitiesListBlade)

---

## Etapa 5 - Publicar no M365 Admin Center

Após configurar o blueprint, o agente deve ser publicado no M365 admin center para que os administradores do tenant possam disponibilizá-lo aos usuários.

### 5.1 - Entendendo a Publicação de Agentes

A publicação torna o agente disponível no **Microsoft 365 admin center** em **Integrated apps**. Isso permite:
- **Administradores do tenant** revisarem e aprovarem o agente
- **Controles de implantação** para usuários específicos, grupos ou toda a organização
- **Gerenciamento centralizado** da disponibilidade e permissões do agente

### 5.2 - Publicar o Agente

```powershell
# Publicar o agent blueprint no M365 admin center
a365 publish
```

O comando executa estas ações:

1. **Empacota o manifesto do agente** com metadados do blueprint
2. **Envia para o M365 admin center** para revisão do administrador
3. **Cria uma listagem do app** no catálogo de Integrated apps
4. **Gera artefatos de publicação** no `a365.generated.config.json`

Saída esperada:
```
Publishing agent to Microsoft 365...
✓ Agent blueprint validated
✓ Manifest packaged
✓ Submitted to M365 admin center
✓ Agent available for admin approval

Agent publish details:
  Agent Name: Financial Market Agent
  Blueprint ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Status: Pending Admin Approval
  Admin Center URL: https://admin.microsoft.com/AdminPortal/Home#/Settings/IntegratedApps
```

### 5.3 - Aprovação Administrativa (M365 Admin Center)

Após a publicação, um **administrador do tenant** deve aprovar o agente:

1. Acesse o [M365 Admin Center](https://admin.microsoft.com/)
2. Navegue até **Settings > Integrated apps**
3. Encontre **Financial Market Agent** na lista
4. Clique no agente para revisar:
   - Permissões do blueprint (Microsoft Graph, etc.)
   - Messaging endpoint
   - Informações do publicador
5. Clique em **Deploy** e configure:
   - **Users**: Usuários específicos, grupos ou toda a organização
   - **Deployment type**: Opcional ou Obrigatório
6. Clique em **Next** e depois **Finish deployment**

> **Nota**: Apenas Global Administrators podem implantar integrated apps no M365 admin center.

### 5.4 - Verificar Status da Publicação

```powershell
# Verificar status de publicação do agente
a365 publish status

# Saída esperada quando aprovado:
# Status: Deployed
# Availability: Enabled for selected users
# Deployed to: 15 users in "Sales Team" group
```

**Checklist de verificação**:
- [ ] Agente aparece no M365 admin center > Integrated apps
- [ ] Status mostra "Deployed" ou "Available"
- [ ] Escopo de implantação configurado (usuários/grupos)
- [ ] Permissões concedidas pelo administrador

---

## Etapa 6 - Criar Instâncias de Agente

Após a publicação e aprovação administrativa, os usuários podem criar **instâncias de agente** no Teams e Outlook. Cada instância é um bot pessoal ou compartilhado com o qual os usuários interagem.

### 6.1 - Entendendo Instâncias de Agente

- **Agent Blueprint**: O modelo/identidade registrado no Entra ID (Etapa 3)
- **Agent Instance**: Um bot ativo criado a partir do blueprint, aparecendo no Teams/Outlook
- **Tipos de Instância**:
  - **Pessoal**: Agente privado do usuário individual
  - **Compartilhada**: Agente de equipe acessível por múltiplos usuários

### 6.2 - Criar uma Instância via CLI

```powershell
# Criar uma instância pessoal de agente
a365 create-instance `
  --name "My Market Agent" `
  --type personal `
  --deploy-to-teams `
  --deploy-to-outlook

# Criar uma instância compartilhada de equipe
a365 create-instance `
  --name "Sales Team Market Agent" `
  --type shared `
  --team-id "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
  --deploy-to-teams
```

**Parâmetros**:
| Parâmetro | Descrição | Obrigatório |
|-----------|-----------|:-----------:|
| `--name` | Nome de exibição da instância | Sim |
| `--type` | `personal` ou `shared` | Sim |
| `--deploy-to-teams` | Disponibilizar no Teams | Não |
| `--deploy-to-outlook` | Disponibilizar no Outlook | Não |
| `--team-id` | ID do time no Teams (para instâncias compartilhadas) | Para compartilhadas |
| `--description` | Descrição da instância | Não |

Saída esperada:
```
Creating agent instance...
✓ Instance created successfully
✓ Deployed to Microsoft Teams
✓ Deployed to Outlook

Instance details:
  Name: My Market Agent
  Instance ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Type: Personal
  Status: Active
  Teams App ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Outlook Add-in ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 6.3 - Criar Instância via Teams App

Os usuários também podem instalar instâncias de agente diretamente do Teams:

1. Abra o **Microsoft Teams**
2. Clique em **Apps** na barra lateral esquerda
3. Pesquise por **"Financial Market Agent"** (ou navegue por **Built by your org**)
4. Clique em **Add** para criar uma instância pessoal
5. Ou clique em **Add to a team** para criar uma instância compartilhada

O agente aparecerá em:
- **Teams**: Lista de chats ou canais de equipe
- **Outlook**: Painel de add-ins (se implantado)

### 6.4 - Gerenciar Instâncias

```powershell
# Listar todas as instâncias
a365 list-instances

# Obter detalhes da instância
a365 get-instance --instance-id <instance-id>

# Excluir uma instância
a365 delete-instance --instance-id <instance-id>

# Atualizar configurações da instância
a365 update-instance `
  --instance-id <instance-id> `
  --name "Updated Name" `
  --description "New description"
```

### 6.5 - Testar a Instância do Agente

Com a instância criada, teste-a no Teams:

1. **Abra o Teams** e encontre o agente na sua lista de chats
2. **Envie uma mensagem**: `What is the PETR4 stock price?`
3. **Verifique a resposta**: O agente deve chamar seu endpoint ACA e retornar dados do mercado
4. **Verifique a telemetria**: Visualize as requisições no Azure Monitor (logs do ACA)

**Fluxo esperado**:
```
Usuário (Teams) 
  → M365 Agent Service 
  → Messaging Endpoint (ACA) 
  → Agente LangGraph 
  → Azure OpenAI (gpt-4.1) 
  → Resposta → Usuário
```

### 6.6 - Ciclo de Vida das Instâncias

| Estado | Descrição | Ações Disponíveis |
|--------|-----------|-------------------|
| **Active** | Instância rodando e disponível | Chat, atualizar configurações, suspender |
| **Suspended** | Temporariamente desabilitada | Retomar, excluir |
| **Deleted** | Permanentemente removida | Nenhuma (criar nova) |

```powershell
# Suspender uma instância
a365 suspend-instance --instance-id <instance-id>

# Retomar uma instância suspensa
a365 resume-instance --instance-id <instance-id>
```

---

## Resumo dos artefatos gerados

Ao final desta lição, você terá:

| Artefato | Localização | Descrição |
|----------|-------------|-----------|
| `a365.config.json` | `lesson-5-a365-prereq/` | Configuração manual (criada à mão, sem assistente) |
| `a365.generated.config.json` | `lesson-5-a365-prereq/` | Configuração gerada pelo CLI (IDs, secrets, detalhes de publicação) |
| Custom Client App | Entra ID (Tenant M365) | App registration para autenticação do CLI |
| Agent Blueprint | Entra ID (Tenant M365) | Identidade do agente + permissões |
| Service Principal | Entra ID (Tenant M365) | Identidade do agente para autenticação |
| Agente Publicado | M365 Admin Center | Agente disponível no catálogo de Integrated apps |
| Instâncias de Agente | Teams/Outlook | Bots ativos com os quais os usuários podem interagir |

> **O que NÃO foi criado**: Nenhum recurso Azure (Resource Group, App Service Plan, Web App). O agente continua rodando no ACA do Tenant A (lição 4) e o A365 apenas aponta para ele via `messagingEndpoint`.

---

## Troubleshooting

### Etapas 2-3 (Configuração & Blueprint)

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| `az login` não mostra assinatura | Tenant errado | Use `az login --tenant <TENANT-M365-ID>` |
| `a365 config init` falha listando assinaturas | Sem assinatura no Tenant M365 | Não use o assistente. Crie `a365.config.json` manualmente (seção 4.2) |
| CLI exige campos de infraestrutura Azure | Validação de schema | Adicione campos placeholder: `"subscriptionId": "00000000-0000-0000-0000-000000000000"` |
| Client App ID inválido | App ID vs Object ID | Verifique que usou Application (client) ID, não Object ID |
| Permissões beta não visíveis | AgentIdentityBlueprint.* em beta | Use Opção B (Graph API) para adicionar permissões |
| Falha no consentimento admin | Sem role de admin | Peça ao admin do Tenant M365 para completar a etapa 3.3 |
| `a365 setup` falha com permissões | Role insuficiente | Precisa de Global Admin, Agent ID Admin ou Agent ID Developer |
| Blueprint não aparece no Entra | Setup incompleto | Execute `a365 setup all` novamente |
| Endpoint não registrado | needDeployment=false sem messagingEndpoint | Execute `a365 setup blueprint --endpoint-only` |

### Etapa 5 (Publicação)

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| `a365 publish` falha com 403 | Permissões insuficientes | Certifique-se que o usuário do CLI tem role Agent ID Admin ou Global Admin |
| Agente não está no admin center | Publicação incompleta | Execute `a365 publish status` para verificar, tente novamente `a365 publish` |
| Admin não encontra o agente | Tenant errado | Verifique que o admin está logado no Tenant M365 (Tenant B) |
| Falha na implantação no admin center | Problemas de permissão | Revise e conceda todas as permissões do Graph solicitadas |
| Agente mostra "Blocked" | Políticas do tenant | Verifique as políticas do tenant M365 para apps de terceiros |

### Etapa 6 (Criar Instâncias)

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| `a365 create-instance` falha | Agente não publicado/aprovado | Certifique-se que a etapa 5 está completa e o admin aprovou |
| Instância não aparece no Teams | Escopo de implantação | Verifique que o usuário está no escopo de implantação configurado no admin center |
| Agente não responde | Endpoint inacessível | Verifique que o ACA está rodando: `az containerapp show --name aca-lg-agent` |
| 404 do messaging endpoint | Caminho errado do endpoint | Verifique que o endpoint em `a365.config.json` inclui `/api/messages` |
| Agente responde com erro | Acesso ao Azure OpenAI | Verifique que a managed identity do ACA tem RBAC no Foundry OpenAI |
| Respostas lentas | Cold start | O ACA pode estar escalando de 0 réplicas, chamadas subsequentes serão mais rápidas |
| Instância não aparece no Outlook | Não implantado no Outlook | Use a flag `--deploy-to-outlook` ao criar a instância |

---

## ❓ Perguntas Frequentes

**P: Por que usamos `needDeployment: false` em vez de deixar o A365 criar a infraestrutura?**
R: Nosso agente já está implantado no ACA (Lição 4). O A365 precisa apenas registrar a identidade do blueprint no Entra ID do M365 e apontar para o endpoint ACA existente. Configurar `needDeployment: true` criaria infraestrutura duplicada de App Service.

**P: O Tenant Azure (A) e o Tenant M365 (B) podem ser o mesmo tenant?**
R: Sim! Tenant único é mais simples. O cenário cross-tenant é comum em empresas que separam assinaturas Azure do M365 por governança, alocação de custos ou histórico de aquisições.

**P: E se as permissões `AgentIdentityBlueprint.*` não aparecerem no portal do Entra?**
R: Essas são permissões beta. Use o método via Graph API (Opção B na etapa 3.3) para adicioná-las programaticamente. NÃO clique em "Grant admin consent" no portal depois — isso sobrescreverá as permissões beta.

**P: Qual role eu preciso no Tenant M365?**
R: Global Administrator, Agent ID Administrator ou Agent ID Developer. Para o fluxo completo do workshop (incluindo consentimento admin), Global Administrator é o mais fácil.

**P: Quanto tempo leva a aprovação administrativa após a publicação?**
R: No workshop, a aprovação é quase instantânea (mesma pessoa). Em produção, depende do fluxo de aprovação da sua organização — horas a dias.

**P: O que acontece com as instâncias se eu reimplantar o ACA?**
R: As instâncias apontam para a URL do messaging endpoint. Desde que o FQDN permaneça o mesmo após a reimplantação, as instâncias continuam funcionando com a nova versão automaticamente.

---

## 🏆 Desafios Autoguiados

1. **Investigação Multi-Tenant**: Documente a topologia de tenants da sua organização. Azure e M365 estão no mesmo tenant? Mapeie quais campos do A365 config mudam para cada cenário.
2. **Auditoria de Permissões**: Use o Graph Explorer para listar todas as permissões concedidas ao service principal do seu agente. Compare permissões delegadas vs permissões de aplicativo.
3. **Failover de Endpoint**: Configure uma implantação secundária do ACA e atualize o messaging endpoint. Teste a alternância entre primário e secundário.
4. **Governança de Instâncias**: Crie instâncias pessoais e compartilhadas, depois escreva uma política de governança definindo quem deve usar qual tipo e por quê.
5. **Script de Automação**: Escreva um script PowerShell que automatize toda a configuração do A365 (etapas 2-6) a partir de um único arquivo de configuração, incluindo tratamento de erros e validação.

---

## Próximos passos

Com a configuração completa do A365 concluída, agora você pode:

- **Monitorar o uso do agente** no Azure Monitor e análises do M365 admin center
- **Atualizar o agente** implantando novas versões no ACA e atualizando o messaging endpoint
- **Escalar a implantação** para mais usuários, grupos ou toda a organização
- **Integrar recursos avançados** como notificações proativas, adaptive cards e SSO
- **Monitorar conformidade** e governança de dados através dos relatórios do M365 admin center

### Tópicos Avançados (Além do Workshop)

- **Notificações Proativas**: Enviar mensagens do agente aos usuários sem iniciação do usuário
- **Adaptive Cards**: UI interativa rica em mensagens do Teams/Outlook
- **Single Sign-On (SSO)**: Autenticação transparente com a identidade M365 do usuário
- **Suporte Multi-idioma**: Respostas localizadas do agente
- **Análise & Telemetria**: Rastreamento detalhado de uso e métricas de desempenho
- **Gerenciamento de Ciclo de Vida**: Testes automatizados, staging e implantações em produção

---

## Referências

### Documentação Principal
- [Ciclo de Vida de Desenvolvimento do Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Agent 365 CLI](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli)
- [Referência de Configuração do Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/config)

### Setup & Configuração
- [Configurando o Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-config)
- [Custom Client App Registration](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/custom-client-app-registration)
- [Setup do Agent Blueprint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/registration)
- [Messaging Endpoint do Agente](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-messaging-endpoint)

### Publicação & Implantação
- [Publicar Agentes no M365](https://learn.microsoft.com/en-us/microsoft-agent-365/admin/publish-agents)
- [M365 Admin Center - Integrated Apps](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/manage-deployment-of-add-ins)
- [Implantar Apps no M365](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/test-and-deploy-microsoft-365-apps)

### Gerenciamento de Instâncias
- [Criar Instâncias de Agente](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/create-instances)
- [Desenvolvimento de Apps para Teams](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/what-are-bots)
- [Add-ins do Outlook](https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/outlook-add-ins-overview)

### Acesso ao Programa
- [Programa Frontier Preview](https://adoption.microsoft.com/copilot/frontier-program/)
