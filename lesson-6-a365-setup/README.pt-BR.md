# Lição 6 - Microsoft Agent 365: Configuração Completa, Publicação e Instâncias

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Configurar** o CLI e a autenticação do Agent 365 (A365) para cenários cross-tenant
2. **Registrar** um Agent Blueprint no Entra ID do Microsoft 365
3. **Compreender** a arquitetura cross-tenant (Azure Tenant A + M365 Tenant B)
4. **Publicar** o Agent Blueprint no M365 Admin Center usando `a365 publish`
5. **Personalizar** o manifesto do agente (nome, versão, descrições, ícones)
6. **Configurar** o agente no Teams Developer Portal para mensagens
7. **Criar** instâncias do agente no Microsoft Teams pelo fluxo oficial de governança
8. **Gerenciar** o ciclo de vida completo de desenvolvimento do Agent 365 (config → blueprint → publicar → instâncias)

---

## Visão Geral

Esta lição cobre a **implantação completa de ponta a ponta** de agentes no **Microsoft Agent 365** (A365): desde a configuração inicial do CLI e o registro do blueprint, passando pela publicação no M365 Admin Center, até a criação e teste de instâncias ao vivo do agente no Microsoft Teams.

> **IMPORTANTE**: O Agent 365 requer pelo menos uma **licença ativa do Microsoft 365 Copilot** no tenant M365 e o Copilot Frontier habilitado no Admin Center. Não é necessário formulário de inscrição separado — o acesso é concedido automaticamente quando uma licença Copilot válida está presente.

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
- Campos de infraestrutura Azure como `appServicePlanName` e `webAppName` não são necessários — nenhuma nova infraestrutura Azure será criada
- `resourceGroup` e `location` **devem** ser configurados com o resource group e região Azure do ACA — o CLI do A365 precisa deles para registrar o messaging endpoint no backend Frontier

---

## Pré-requisito 0 - Licença Microsoft 365 Copilot + Acesso Frontier

O Agent 365 requer uma **licença Microsoft 365 Copilot** no tenant M365. Não é necessário formulário de inscrição separado.

1. Certifique-se de que pelo menos um usuário no tenant M365 tenha uma licença **Microsoft 365 Copilot** (uma avaliação gratuita de 30 dias é suficiente → [Iniciar avaliação gratuita](https://www.microsoft.com/microsoft-365/copilot/microsoft-365-copilot))
2. Entre no [Microsoft 365 Admin Center](https://admin.microsoft.com/) com uma conta de Global Admin
3. Navegue até **Copilot** → **Settings** → **User access** → **Copilot Frontier**
4. Habilite o Frontier para os usuários necessários ou para toda a organização

> **Nota:** A opção **Copilot Frontier** só aparece no Admin Center após uma licença válida do Microsoft 365 Copilot estar ativa no tenant. Se a opção não aparecer, verifique a atribuição de licença primeiro.

---

## Pré-requisito 1 - Instalar .NET SDK

O CLI do Agent 365 é distribuído como uma ferramenta .NET:

```powershell
# Verificar se o .NET está instalado
dotnet --version
# Recomendado: .NET 8.0+

# Se não estiver instalado, baixe em:
# https://dotnet.microsoft.com/download
```

---

## Pré-requisito 2 - Instalar o CLI do Agent 365

```powershell
# Instalar o CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verificar a instalação
a365 -h

# Para atualizar no futuro:
dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease
```

> **Nota**: Sempre use `--prerelease` enquanto o CLI estiver em preview.
> NuGet: [Microsoft.Agents.A365.DevTools.Cli](https://www.nuget.org/packages/Microsoft.Agents.A365.DevTools.Cli)

---

## Pré-requisito 3 - Custom Client App Registration (no Tenant M365)

O CLI precisa de um registro de aplicativo no Entra ID do **Tenant M365** para autenticar.

### 3.1 - Registrar o aplicativo

1. Acesse o [Microsoft Entra admin center](https://entra.microsoft.com/) do **Tenant B (M365)**
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

#### Opção A - Via Entra admin center (se as permissões beta estiverem visíveis)

1. No registro do aplicativo, vá para **API permissions > Add a permission**
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

#### Opção B - Via Microsoft Graph API (se as permissões beta NÃO estiverem visíveis)

Se as permissões `AgentIdentityBlueprint.*` não aparecerem no portal, use o Graph Explorer:

1. Acesse o [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
2. Entre com a conta de admin do Tenant M365

**Obter o Service Principal ID do aplicativo:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{YOUR-CLIENT-ID}'&$select=id
```
O `id` retornado é o `SP_OBJECT_ID`.

Se retornar vazio, crie o service principal:
```http
POST https://graph.microsoft.com/v1.0/servicePrincipals
Body: { "appId": "{YOUR-CLIENT-ID}" }
```

**Obter o Graph Resource ID:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=id
```
O `id` retornado é o `GRAPH_RESOURCE_ID`.

**Criar as permissões delegadas (com consentimento de admin automático):**
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

> **ATENÇÃO**: Se você usou a Opção B, **NÃO** clique em "Grant admin consent" no portal Entra depois. O portal não enxerga permissões beta e vai sobrescrever o que foi criado via API.

### 3.4 - Anotar o Client ID

Salve o **Application (client) ID** — você precisará dele na próxima etapa.

```
Application (client) ID: ________-____-____-____-____________
```

---

## Etapa 1 - Configurar o Agent 365

Como usamos `needDeployment: false`, **não** executaremos o wizard interativo `a365 config init` (ele tenta listar assinaturas Azure e pode falhar sem uma assinatura no Tenant M365). Em vez disso, criaremos o `a365.config.json` manualmente.

### 1.1 - Autenticar no Tenant M365

```powershell
# Login no Tenant M365 (Tenant B)
az login --tenant <TENANT-M365-ID>

# Verificar que estamos no tenant correto
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> `az login` é necessário para o CLI autenticar no Entra ID do Tenant M365. NÃO precisamos de uma assinatura Azure aqui.

### 1.2 - Criar o a365.config.json manualmente

Navegue até o diretório do laboratório da lição 6 e crie o arquivo:

```powershell
cd lesson-6-a365-setup\labs\solution
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
  "agentDescription": "Financial market agent (LangGraph on ACA) - A365 Workshop",
  "resourceGroup": "<RESOURCE-GROUP-FROM-LESSON-4>",
  "location": "<AZURE-REGION-FROM-LESSON-4>"
}
```

**Campos importantes:**

| Campo | Valor | Explicação |
|-------|-------|------------|
| `tenantId` | GUID do Tenant M365 | Onde o blueprint é registrado no Entra ID |
| `clientAppId` | GUID da etapa 3.4 | Registro de aplicativo para autenticação do CLI |
| `needDeployment` | `false` | **Não cria infraestrutura Azure** — agente já roda no ACA |
| `messagingEndpoint` | URL do ACA + `/api/messages` | Endpoint que o A365 usa para enviar mensagens ao agente |
| `agentUserPrincipalName` | `nome@tenant.onmicrosoft.com` | UPN do agente no Entra (domínio do Tenant M365) |
| `managerEmail` | E-mail no Tenant M365 | Responsável pelo agente |
| `resourceGroup` | Nome do resource group da lição 4 | Resource group Azure com a implantação do ACA — **obrigatório** para o registro do endpoint Frontier |
| `location` | Nome da região Azure (ex: `"eastus"`) | Região Azure da implantação do ACA — **obrigatório** para o registro do endpoint Frontier |

> **Nota**: Campos como `subscriptionId`, `appServicePlanName` e `webAppName` podem ser omitidos com `needDeployment: false` — nenhuma infraestrutura Azure será criada. Porém, `resourceGroup` e `location` **devem** ser fornecidos: o CLI do A365 os usa para registrar o messaging endpoint no backend Frontier.

### 1.3 - Verificar a configuração

```powershell
# Verificar se o arquivo existe
Test-Path a365.config.json
# Esperado: True

# Exibir a configuração
a365 config display
```

**Checklist de verificação:**
- [ ] `tenantId` é o GUID do Tenant M365 (NÃO Azure)
- [ ] `clientAppId` é o App Registration da etapa 3
- [ ] `needDeployment` é `false`
- [ ] `messagingEndpoint` aponta para o ACA da lição 4
- [ ] `agentUserPrincipalName` usa o domínio `@<tenant-m365>.onmicrosoft.com`
- [ ] `managerEmail` usa o domínio do Tenant M365
- [ ] `resourceGroup` é o resource group onde o ACA está implantado (da lição 4)
- [ ] `location` é a região Azure da implantação do ACA (ex: `"eastus"`)

---

## Etapa 2 - Configurar o Agent Blueprint

O blueprint define a identidade e as permissões do agente no Entra ID. Com `needDeployment: false`, o CLI **pula a criação de infraestrutura Azure** e foca apenas no registro de identidade.

### 2.1 - Executar o setup

```powershell
# Executar o setup completo (dentro de lesson-6-a365-setup/labs/solution/)
a365 setup all
```

Com `needDeployment: false`, o comando realiza **apenas**:

1. **Registra o Agent Blueprint** no Entra ID do Tenant M365:
   - Cria o Agent Identity Blueprint (registro de aplicativo)
   - Cria o service principal associado
   - Configura a identidade do agente (`agentUserPrincipalName`)

2. **Configura as Permissões de API**:
   - Escopos da Microsoft Graph API
   - Permissões da Messaging Bot API
   - Permissões herdadas para futuras instâncias

3. **Registra o messaging endpoint**:
   - Associa o `messagingEndpoint` (ACA da lição 4) ao blueprint

4. **Gera o `a365.generated.config.json`**:
   - IDs do blueprint, service principal, client secret, endpoint

> **Nota**: O CLI abre janelas do navegador para consentimento de admin. Complete todos os fluxos. Leva 3-5 minutos.
>
> **Nenhuma infraestrutura Azure será criada** (Resource Group, App Service Plan, Web App). O agente já roda no ACA do Tenant A.

### 2.2 - Verificar o setup

```powershell
# Exibir a configuração gerada
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
# Verificar se o arquivo gerado existe
Test-Path a365.generated.config.json
# Esperado: True
```

**Verificações no Entra admin center** (Tenant M365):
- [ ] App Registration existe (pesquise pelo `agentBlueprintId`)
- [ ] Enterprise Application correspondente existe
- [ ] Permissões de API mostram marcas de verificação verdes ("Concedido para [Seu Tenant]")
- [ ] Permissões incluem Microsoft Graph e Messaging Bot API
- [ ] Agent Identity visível no [Entra Agent Registry](https://entra.microsoft.com/#view/Microsoft_AAD_IAM/AgentIdentitiesListBlade)

---

## Etapa 3 - Publicar no M365 Admin Center

Após configurar o blueprint, publique o agente no Microsoft 365 Admin Center. A publicação cria um **pacote de app do Teams** a partir do blueprint e o torna visível no admin center como agente gerenciado. Após a publicação, administradores podem criar instâncias no Microsoft Teams.

> **Importante:** `a365 publish` requer que o programa de preview Frontier esteja habilitado para o tenant e que o usuário tenha a função de **Agent ID Developer**, **Agent ID Administrator** ou **Global Administrator**.

### Pipeline de Publicação

```
Máquina do Desenvolvedor            Serviços Microsoft
        |                                    |
        |  a365 publish                      |
        |  1. Atualiza manifest.json         |
        |  2. Pausa para personalização      |
        |  3. Pacote → manifest.zip          |
        |  4. Adiciona permissões API  ----->|  Microsoft Entra ID
        |  5. Upload do pacote        ------>|  M365 Titles Service
        |  6. Configura acesso de usuários   |
        |  7. Config. identidade federada -->|  Aplicativo Blueprint (Entra)
        |  8. Concede permissões Graph       |
        |       ✅ Publicado                 |
        |                                    |  admin.cloud.microsoft
        |                                    |  Aba Registry: agente visível
```

### Verificação de pré-requisitos

Antes de executar `a365 publish`, certifique-se de que:

```powershell
cd lesson-6-a365-setup\labs\solution

# Exibir configuração atual e confirmar que agentBlueprintId está preenchido
a365 config display -g
```

Procure por `agentBlueprintId` — deve ser um UUID não vazio. Se estiver vazio, reexecute o setup da Etapa 2.

Verifique também se os seguintes comandos de setup executaram com sucesso:
```powershell
a365 setup blueprint --endpoint-only   # ou a365 setup all no primeiro setup
a365 setup permissions mcp
a365 setup permissions bot
```

### 3.1 - Executar `a365 publish`

```powershell
cd lesson-6-a365-setup\labs\solution
a365 publish
```

> **Nota:** `a365 publish` **não** aceita a flag `--config`. Ele sempre detecta automaticamente o `a365.config.json` no diretório de trabalho atual. Certifique-se de usar `cd` para o diretório correto antes de executar.

O que o comando faz (em ordem):

| # | Ação | Resultado |
|---|------|-----------|
| 1 | Atualiza `manifest.json` com o ID do blueprint | `manifest/manifest.json` criado |
| 2 | **Pausa** — solicita para abrir e personalizar o manifesto | (prompt interativo) |
| 3 | Empacota manifesto + ícones em um zip | `manifest/manifest.zip` criado |
| 4 | Adiciona permissões de API necessárias ao app cliente personalizado | Concessão de permissão no Entra |
| 5 | Faz upload do pacote para o serviço M365 Titles | Entrada do agente no Admin Center |
| 6 | Configura acesso ao título para todos os usuários | Disponibilidade: Todos os Usuários |
| 7 | Configura identidade de carga de trabalho / credenciais federadas no app blueprint | 2 FICs no app blueprint |
| 8 | Concede permissões do Microsoft Graph ao service principal do blueprint | Consentimento do Graph |

### 3.2 - Personalizar o Manifesto do Agente

Quando o CLI pausa, exibe saída semelhante a:

```
=== MANIFEST UPDATED ===
Location: ...\manifest\manifest.json

=== CUSTOMIZE YOUR AGENT MANIFEST ===
  Version ('version')          - increment for republishing (e.g. 1.0.0 → 1.0.1)
  Agent Name ('name.short')    - MUST be 30 characters or fewer
  Agent Name ('name.full')     - full descriptive name
  Descriptions                 - 'description.short' and 'description.full'
  Developer Info               - developer.name, websiteUrl, privacyUrl
  Icons                        - replace color.png and outline.png

Open manifest in your default editor now? (Y/n):
```

Abra `manifest/manifest.json` e atualize os campos principais:

```json
{
  "version": "1.0.0",
  "name": {
    "short": "Financial Market Agent",
    "full": "Financial Market Agent (A365 Workshop)"
  },
  "description": {
    "short": "AI agent for real-time stock and financial data.",
    "full": "LangGraph-based agent providing real-time stock prices, financial news, and portfolio insights via the Microsoft Agent 365 platform."
  },
  "developer": {
    "name": "Workshop Developer",
    "websiteUrl": "https://example.com",
    "privacyUrl": "https://example.com/privacy",
    "termsOfUseUrl": "https://example.com/terms"
  }
}
```

> **Regras:**
> - `name.short` deve ter **≤ 30 caracteres**
> - `version` deve ser **maior** que qualquer versão publicada anteriormente
> - **Não** altere os campos `id` ou `bots[0].botId` — foram injetados pelo CLI e devem corresponder ao ID do blueprint

Quando terminar de editar, retorne ao terminal e digite:

```
continue
```

### 3.3 - Verificar a Publicação Bem-sucedida

**Saída esperada do CLI:**

```
✅ Upload succeeded
✅ Title access configured for all users
✅ Microsoft Graph permissions granted successfully
✅ Agent blueprint configuration completed successfully
✅ Publish completed successfully!
```

**Verificar se os arquivos do manifesto foram criados:**

```powershell
Test-Path lesson-6-a365-setup\labs\solution\manifest\manifest.json   # → True
Test-Path lesson-6-a365-setup\labs\solution\manifest\manifest.zip    # → True
```

**Verificar no Microsoft 365 Admin Center:**

1. Acesse [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Abra a aba **Registry**
3. Seu agente (ex: "Financial Market Agent") deve aparecer com **Availability: All Users** ✅

> **Nota:** Pode levar **5–10 minutos** após a publicação para o agente aparecer. Atualize a página se não estiver visível imediatamente.

**Verificar credenciais de identidade federada:**

1. [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations** → pesquise pelo app blueprint
2. **Certificates & secrets** → **Federated credentials**
3. Você deve ver **2 federated identity credentials (FICs)** ✅

### Opções disponíveis do `a365 publish`

```
a365 publish [options]

Options:
  --dry-run         Mostrar alterações sem gravar arquivos ou chamar APIs
  --skip-graph      Pular etapas de identidade federada e atribuição de função Graph
  --mos-env <env>   Identificador do ambiente MOS (ex: prod, dev) [padrão: prod]
  --mos-token <t>   Substituir token MOS — ignora script e cache
  -v, --verbose     Habilitar log detalhado
```

**Exemplo de dry-run** — visualizar o que aconteceria sem executar:

```powershell
a365 publish --dry-run
```

---

## Etapa 4 - Configurar o Agente no Teams Developer Portal

Antes de criar instâncias, você deve configurar o blueprint do agente no Teams Developer Portal para conectá-lo à infraestrutura de mensagens do Microsoft 365. **Sem esta etapa, o agente não receberá mensagens do Teams.**

### 4.1 - Obter o ID do Blueprint

```powershell
cd lesson-6-a365-setup\labs\solution
a365 config display -g
```

Copie o valor de `agentBlueprintId` da saída. Ele se parecerá com:

```
agentBlueprintId: 809bce64-ea7f-4f64-94b1-6f0c582b2f21
```

### 4.2 - Configurar no Developer Portal

1. **Abra a página de configuração do Developer Portal:**

   ```
   https://dev.teams.microsoft.com/tools/agent-blueprint/<seu-blueprint-id>/configuration
   ```

   Substitua `<seu-blueprint-id>` pelo `agentBlueprintId` obtido acima.

2. **Configure o agente:**
   - Defina **Agent Type** → `Bot Based`
   - Defina **Bot ID** → cole seu `agentBlueprintId`
   - Clique em **Save**

3. **Verifique o salvamento:**
   - ✅ Agent Type mostra: `Bot Based`
   - ✅ Bot ID corresponde ao seu `agentBlueprintId`
   - ✅ Página mostra "Saved successfully"

> **Dica:** Se você não tiver acesso ao Teams Developer Portal, entre em contato com o administrador do tenant para concluir esta etapa.

---

## Etapa 5 - Solicitar uma Instância do Agente no Teams

> **Nota de design importante:** O comando CLI `a365 create-instance` foi **removido**. Ele ignorava etapas de registro necessárias para a funcionalidade completa do agente. A criação de instâncias agora é feita exclusivamente pela **UI do Microsoft Teams** e pelo **Microsoft 365 Admin Center**, seguindo o fluxo oficial de governança.

### O que é uma instância de agente?

| Conceito | Descrição |
|----------|-----------|
| **Blueprint** | O registro de app no Entra — o template que define o tipo do agente, permissões e configuração |
| **Instância** | Uma instanciação específica do blueprint — o agente recebe sua própria identidade de usuário no Entra |
| **Usuário agêntico** | Uma conta de usuário Entra para o agente (ex: `fin-market-agent@dominio.com`) — aparece no Teams como uma pessoa |

### 5.1 - Solicitar a instância

1. Abra o **Microsoft Teams** (desktop ou web)
2. Clique no ícone **Apps** na barra lateral esquerda (ou use a barra de pesquisa)
3. Pesquise seu agente pelo nome — ex: `Financial Market Agent`
4. Clique no cartão do agente
5. Clique em **Request Instance** (ou **Create Instance** se disponível diretamente)
6. Opcionalmente, insira um nome de exibição personalizado para sua instância
7. Confirme — isso envia uma **solicitação de aprovação ao admin do tenant**

> **Nota:** O processo de criação de instância é assíncrono. Após a aprovação do admin, a conta de usuário do agente é criada no Entra e o agente fica disponível no Teams. Isso pode levar de alguns minutos a algumas horas.

---

## Etapa 6 - Aprovar a Solicitação de Instância (Admin)

Como admin, aprove a solicitação pendente:

1. Acesse [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
2. Encontre a solicitação pendente do seu agente
3. Revise as permissões e detalhes
4. Clique em **Approve**

Após a aprovação:
- A conta de usuário agêntico é criada no Microsoft Entra
- O agente fica pesquisável e disponível para chat no Teams
- O agente aparece em **All Agents** no admin center

---

## Etapa 7 - Testar o Agente no Teams

> **Nota:** Após a aprovação do admin, pode levar **alguns minutos a algumas horas** para que o usuário agêntico fique pesquisável no Teams. Este é um processo assíncrono em segundo plano.

1. No Microsoft Teams, pesquise o nome do agente na barra de **Search** ou em **New Chat**
2. Abra um chat com o agente
3. Envie uma mensagem de teste — por exemplo:
   ```
   What's the current stock price for MSFT?
   ```
4. Verifique se o agente responde corretamente:
   - O agente mostra indicador de digitação
   - O agente responde em alguns segundos
   - A resposta inclui dados financeiros relevantes

### Exemplo de conversa

```
Você: What's the current price of AAPL?

Financial Market Agent:
📈 Apple Inc. (AAPL)
Current Price: $178.42
Change: +2.34 (+1.33%)
[Last 30 days data retrieval requested...]
```

---

## Etapa 8 - Monitorar a Atividade do Agente

### Verificar no Microsoft 365 Admin Center

1. Acesse [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Selecione seu agente
3. Abra a aba **Activity**

Você deve ver:
- ✅ Sessões listadas com timestamps
- ✅ Cada sessão mostra as ações realizadas
- ✅ Chamadas de tools registradas com timestamps e entradas/saídas

### Verificar logs do Azure Container App

```powershell
az containerapp logs show `
  --name aca-lg-agent `
  --resource-group <your-resource-group> `
  --follow
```

Procure por:
- ✅ Requisições recebidas do Teams (`POST /api/messages`)
- ✅ Autenticação bem-sucedida
- ✅ Chamadas de tools executando
- ❌ Mensagens de erro ou exceções

### Verificar saúde do messaging endpoint

```powershell
curl https://aca-lg-agent.<aca-env-hash>.<region>.azurecontainerapps.io/health
# Esperado: {"status": "ok"} ou HTTP 200
```

### Consultar escopos e status de consentimento no Entra

```powershell
cd lesson-6-a365-setup\labs\solution

# Verificar escopos do blueprint
a365 query-entra blueprint-scopes --config a365.config.json

# Verificar escopos da instância (após a instância ser criada)
a365 query-entra instance-scopes --config a365.config.json
```

---

## Resumo dos Artefatos Gerados

Ao final desta lição, você terá:

| Artefato | Local | Descrição |
|----------|-------|-----------|
| `a365.config.json` | `lesson-6-a365-setup/labs/solution/` | Configuração manual (criada à mão, sem wizard) |
| `a365.generated.config.json` | `lesson-6-a365-setup/labs/solution/` | Configuração gerada pelo CLI (IDs, segredos, detalhes de publicação) |
| `manifest/manifest.json` | `lesson-6-a365-setup/labs/solution/manifest/` | Manifesto do app Teams do agente |
| `manifest/manifest.zip` | `lesson-6-a365-setup/labs/solution/manifest/` | App Teams empacotado e enviado ao admin center |
| Custom Client App | Entra ID (Tenant M365) | Registro de aplicativo para autenticação do CLI |
| Agent Blueprint | Entra ID (Tenant M365) | Identidade + permissões do agente |
| Service Principal | Entra ID (Tenant M365) | Identidade do agente para autenticação |
| Credenciais federadas | App Blueprint (Entra) | 2 FICs para workload identity |
| Agente Publicado | M365 Admin Center | Agente visível na aba Registry |
| Instância do Agente | Teams | Usuário agêntico — disponível para chat no Teams |

> **O que NÃO foi criado**: Nenhum recurso Azure (Resource Group, App Service Plan, Web App). O agente continua rodando no ACA do Tenant A (lição 4) e o A365 apenas aponta para ele via `messagingEndpoint`.

---

## Gerenciamento do Ciclo de Vida das Instâncias

### Comandos CLI (apenas recursos Entra)

```powershell
# Remover identidade e usuário da instância do Entra
a365 cleanup instance --config a365.config.json

# Remover blueprint e service principal do Entra
a365 cleanup blueprint --config a365.config.json

# Remover recursos Azure (App Service, App Service Plan)
a365 cleanup azure --config a365.config.json
```

> **Nota:** Esses comandos CLI removem apenas recursos Entra. Para remover uma instância do agente do Teams de um usuário, o usuário remove o chat (ou o admin remove o app dos apps instalados no Teams Admin Center).

### Gerenciamento pelo admin center

Todas as ações do ciclo de vida de instâncias (suspender, retomar, excluir, revisão de permissões) são gerenciadas pelo admin center:

- **Todos os agentes:** [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
- **Agentes solicitados:** [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
- **Teams Admin Center:** [https://admin.teams.microsoft.com](https://admin.teams.microsoft.com) → Teams apps → Manage apps

---

## Solução de Problemas

### Pré-requisitos e Configuração (Etapas 1-2)

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| `az login` não mostra assinatura | Tenant errado | Use `az login --tenant <TENANT-M365-ID>` |
| `a365 config init` falha ao listar assinaturas | Sem assinatura no Tenant M365 | Não use o wizard. Crie `a365.config.json` manualmente (seção 1.2) |
| CLI exige campos de infraestrutura Azure | Validação de schema | Adicione campos placeholder: `"subscriptionId": "00000000-0000-0000-0000-000000000000"` |
| Client App ID inválido | App ID vs Object ID | Verifique se usou Application (client) ID, não Object ID |
| Permissões beta não visíveis | AgentIdentityBlueprint.* em beta | Use a Opção B (Graph API) para adicionar as permissões |
| Consentimento de admin falha | Sem role de admin | Peça ao admin do Tenant M365 para concluir a etapa 3.3 |
| `a365 setup` falha com permissões | Role insuficiente | Necessário Global Admin, Agent ID Admin ou Agent ID Developer |
| Blueprint não aparece no Entra | Setup incompleto | Execute `a365 setup all` novamente |
| Endpoint não registrado | needDeployment=false sem messagingEndpoint | Execute `a365 setup blueprint --endpoint-only` |
| `a365 setup blueprint --endpoint-only` falha com `400 BadRequest` | `location` ou `resourceGroup` ausente em `a365.config.json` | Adicione `"resourceGroup": "<rg>"` e `"location": "<region>"` — obrigatórios mesmo com `needDeployment: false` |

### Publicação (Etapa 3)

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| `a365 publish` falha com 403 | Permissões insuficientes | Certifique-se de que o usuário do CLI tem role Agent ID Admin ou Global Admin |
| Erro `Agent already exists` | Mesma versão já publicada | Incremente `version` em `manifest/manifest.json` e re-execute `a365 publish` |
| Erro `Permissions missing` | Permissões de blueprint ou MCP incompletas | Execute `a365 setup permissions mcp` e `a365 setup permissions bot`, depois re-publique |
| Agente não aparece no admin center após 10+ minutos | Publicação pode estar incompleta | Verifique se todas as linhas ✅ apareceram na saída; use `admin.cloud.microsoft` e não `admin.microsoft.com` |
| `manifest.json` mostra placeholder `${{TEAM_APP_ID}}` | Publicação executada antes do setup concluir | Verifique se `a365.generated.config.json` tem `agentBlueprintId`, depois re-execute `a365 publish` |
| Admin não encontra o agente | Tenant errado | Verifique se o admin está logado no Tenant M365 (Tenant B) |

### Teams Developer Portal e Instâncias (Etapas 4-6)

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| Agente não aparece na pesquisa do Teams | Configuração do Developer Portal ausente | Acesse `dev.teams.microsoft.com/tools/agent-blueprint/<id>/configuration`, defina Agent Type = Bot Based, salve, aguarde 5-10 min |
| Botão "Request Instance" ausente ou desabilitado | Frontier não habilitado para o usuário | No M365 admin center → Settings → Copilot → Frontier, verifique a inclusão do usuário |
| Agente não responde às mensagens | ACA não está rodando ou endpoint errado | Verifique `az containerapp show`, confirme o caminho `/api/messages` na config, confirme que o Developer Portal foi salvo |
| 404 do messaging endpoint | Caminho do endpoint errado | Verifique que o endpoint em `a365.config.json` inclui `/api/messages` |
| Agente responde com erro | Acesso ao Azure OpenAI | Verifique se a managed identity do ACA tem RBAC no Foundry OpenAI |
| Respostas lentas | Cold start | ACA pode estar escalando de 0 réplicas; defina `minReplicas: 1` para disponibilidade contínua |
| Falha na atribuição de licença na aprovação | Licenças insuficientes | Acesse M365 admin center → Billing → Licenses; verifique se a licença Microsoft 365 Copilot está disponível |
| Usuário agêntico não encontrado no Teams após horas | Sincronização Entra pendente | Execute `az ad user show --id fin-market-agent@<tenant>.onmicrosoft.com` para verificar se o usuário existe no Entra |
| `query-entra instance-scopes` retorna `Request_ResourceNotFound` | Setup incompleto ou instância ainda não criada | Verifique `completed: true` em `a365.generated.config.json`; verifique se `AgenticAppId` não é nulo; re-execute o setup se necessário |

---

## Cenários de Teste

### Cenário 1: Consulta financeira básica

```
Você: What's the current price of MSFT?
Agente: [Usa a tool de preço de ações, retorna preço com dados de variação]

Você: How does that compare to last week?
Agente: [Usa contexto da mensagem anterior para responder comparativamente]
```

**Verifique:** O contexto de múltiplos turnos é mantido.

### Cenário 2: Tratamento de erros

| Entrada | Comportamento Esperado |
|---------|------------------------|
| Ticker desconhecido (`XYZINVALID`) | Gracioso: "Symbol not found" |
| Solicitação vaga (`Is it good?`) | Esclarecimento: "Sobre qual ação você está perguntando?" |
| Fora do escopo (`Tell me a joke`) | Redirecionamento: "Minha especialidade é informações financeiras" |

### Cenário 3: Auditoria de execução de tools

Após enviar uma solicitação que usa tools (ex: consulta de preço de ação):

1. Acesse o admin center → seu agente → aba **Activity**
2. Verifique se as chamadas de tools estão registradas com timestamps e entradas/saídas

---

## Referência Rápida

| Comando / Ação | Finalidade |
|----------------|-----------|
| `a365 setup all` | Registrar blueprint, configurar permissões, registrar endpoint |
| `a365 setup blueprint --endpoint-only` | Registrar/atualizar apenas o messaging endpoint |
| `a365 setup permissions mcp` | Configurar permissões MCP no blueprint |
| `a365 setup permissions bot` | Configurar permissões Bot API no blueprint |
| `a365 publish` | Empacotar e publicar agente no M365 admin center |
| `a365 publish --dry-run` | Visualizar alterações de publicação sem executar |
| `a365 config display -g` | Exibir configuração atual (verificar agentBlueprintId) |
| `a365 query-entra blueprint-scopes` | Listar escopos configurados no blueprint |
| `a365 query-entra instance-scopes` | Listar escopos na instância do agente |
| `a365 cleanup blueprint` | Remover blueprint do Entra |
| `a365 cleanup instance` | Remover instância/usuário do agente do Entra |
| Teams Developer Portal | `https://dev.teams.microsoft.com/tools/agent-blueprint/<id>/configuration` |
| Solicitar instância | Microsoft Teams → Apps → Pesquisar → Request Instance |
| Aprovar solicitação | [admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested) |
| Ver todos os agentes | [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all) |

---

## ❓ Perguntas Frequentes

**P: Por que usamos `needDeployment: false` em vez de deixar o A365 criar a infraestrutura?**
R: Nosso agente já está implantado no ACA (Lição 4). O A365 só precisa registrar a identidade do blueprint no Entra ID do M365 e apontar para o endpoint ACA existente. Definir `needDeployment: true` criaria infraestrutura duplicada no App Service.

**P: O Azure Tenant (A) e o M365 Tenant (B) podem ser o mesmo tenant?**
R: Sim! Tenant único é mais simples. O cenário cross-tenant é comum em empresas que separam assinaturas Azure do M365 por governança, alocação de custos ou histórico de aquisições.

**P: E se as permissões `AgentIdentityBlueprint.*` não aparecerem no portal Entra?**
R: São permissões beta. Use o método Graph API (Opção B no Pré-requisito 3.3) para adicioná-las programaticamente. NÃO clique em "Grant admin consent" no portal depois — isso vai sobrescrever as permissões beta.

**P: Qual role preciso no Tenant M365?**
R: Global Administrator, Agent ID Administrator ou Agent ID Developer. Para o fluxo completo do workshop (incluindo consentimento de admin), Global Administrator é o mais prático.

**P: Preciso re-publicar após alterar o código do agente?**
R: Não. Alterações de código por trás da mesma URL do messaging endpoint entram em vigor imediatamente sem necessidade de re-publicação. Re-publique apenas quando o manifesto mudar (nome, ícone, permissões) ou a URL do endpoint mudar.

**P: Posso re-publicar sem excluir a versão anterior?**
R: Sim. Incremente `version` em `manifest/manifest.json` e execute `a365 publish` novamente.

**P: Por que `a365 create-instance` foi removido?**
R: Ele ignorava etapas de registro necessárias (configuração do Developer Portal, fluxo de aprovação de admin) para que os agentes recebam mensagens e operem com governança completa. A criação de instâncias via Teams garante que essas etapas sejam sempre concluídas.

**P: Quanto tempo leva a criação de instâncias?**
R: A aprovação do admin em si é rápida (alguns minutos). Criar o usuário agêntico no Entra e propagá-lo pelo Teams pode levar de alguns minutos a algumas horas. Se não estiver pesquisável após 2 horas, verifique se o usuário foi criado no Entra.

**P: Quanto tempo leva a aprovação do admin após a publicação?**
R: No workshop, a aprovação é quase imediata (mesma pessoa). Em produção, depende do fluxo de aprovação da sua organização — horas a dias.

**P: O que acontece com as instâncias se eu reimplantar o ACA com uma nova URL?**
R: Atualize o messaging endpoint e re-publique:
```powershell
a365 setup blueprint --endpoint-only --update-endpoint "https://new-url/api/messages" --config a365.config.json
a365 publish
```

**P: E se o ACA escalar para zero (cold start)?**
R: Se `minReplicas: 0`, a primeira mensagem após um período de inatividade aciona um cold start (5–30 segundos). Defina `minReplicas: 1` no Container App para disponibilidade contínua.

**P: Os membros da equipe podem ver as conversas da minha instância pessoal?**
R: Não. Cada usuário tem um chat 1:1 com o agente. O histórico de conversas é privado para aquele usuário.

---

## 🏆 Desafios para Prática Individual

1. **Investigação Multi-Tenant**: Documente a topologia de tenants da sua organização. O Azure e o M365 estão no mesmo tenant? Mapeie quais campos do config do A365 mudam para cada cenário.
2. **Auditoria de Permissões**: Use o Graph Explorer para listar todas as permissões concedidas ao service principal do seu agente. Compare permissões delegadas vs de aplicativo.
3. **Failover de Endpoint**: Configure uma implantação secundária do ACA e atualize o messaging endpoint. Teste a alternância entre primário e secundário.
4. **Personalização do Manifesto**: Substitua os ícones padrão (`color.png` e `outline.png`) na pasta manifest por imagens personalizadas representando seu agente.
5. **Script de Automação**: Escreva um script PowerShell que automatize todo o setup do A365 (etapas 1-3) a partir de um único arquivo de configuração, incluindo tratamento de erros e validação.

---

## Referências

### Documentação Principal
- [Ciclo de Vida de Desenvolvimento do Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [CLI do Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli)
- [Referência de Configuração do Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/config)

### Configuração
- [Configurar o Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-config)
- [Custom Client App Registration](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/custom-client-app-registration)
- [Configurar o Agent Blueprint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/registration)
- [Agent Messaging Endpoint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-messaging-endpoint)

### Publicação e Implantação
- [Publicar Agentes no M365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/publish)
- [Referência CLI do Agent 365 — comando publish](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/publish)
- [Microsoft 365 Admin Center — Registro de Agentes](https://admin.cloud.microsoft/#/agents/all)

### Gerenciamento de Instâncias
- [Criar Instâncias do Agente](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/create-instance)
- [Teams Developer Portal](https://dev.teams.microsoft.com)
- [Exemplos do Agent 365 no GitHub](https://github.com/microsoft/Agent365-Samples)

### Acesso ao Programa
- [Programa Frontier Preview](https://adoption.microsoft.com/copilot/frontier-program/)
