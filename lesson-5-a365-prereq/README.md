# Licao 5 - Pre-requisitos para Microsoft Agent 365

Esta licao prepara o ambiente para integrar os agentes do workshop com o **Microsoft Agent 365** (A365). Nao criaremos agentes aqui - apenas configuraremos os pre-requisitos do ciclo de desenvolvimento A365.

> **IMPORTANTE**: O Agent 365 requer participacao no [Frontier preview program](https://adoption.microsoft.com/copilot/frontier-program/).

---

## Contexto: Cenario Cross-Tenant

Neste workshop, temos um cenario especifico:

| Recurso | Tenant | Descricao |
|---------|--------|-----------|
| **Azure** (Foundry, ACA, ACR) | Tenant A (Azure) | Onde os agentes estao implantados |
| **Microsoft 365** (Teams, Outlook) | Tenant B (M365) | Onde os usuarios finais interagem com os agentes |

O Agent 365 CLI usa **um unico `tenantId`** no `a365.config.json`. Esse tenant e o **tenant do Microsoft 365** (Tenant B), pois e la que:
- O Agent Blueprint e registrado no Entra ID
- O Agent User (service principal) e criado
- O agente aparece no Teams e Outlook dos usuarios
- As permissoes do Microsoft Graph sao concedidas

A subscription Azure (no Tenant A) e referenciada separadamente no campo `subscriptionId` do config. No entanto, o `a365 setup` cria recursos Azure (Resource Group, App Service Plan, Web App) **na subscription do tenant logado**.

### Abordagem: `needDeployment: false`

Como o agente ja esta implantado no ACA (Tenant A, licao 4), nao precisamos que o A365 CLI crie infraestrutura Azure. Usaremos `needDeployment: false` para que o CLI apenas:

1. **Registre o Agent Blueprint** no Entra ID do Tenant M365 (Tenant B)
2. **Configure o messaging endpoint** apontando para o ACA no Tenant A
3. **Crie a identidade do agente** (service principal) no Tenant M365

Isso significa:

- O `az login` deve autenticar no **Tenant M365** (Tenant B)
- O Custom Client App Registration deve ser feito no **Tenant B** (M365)
- O usuario do CLI precisa de roles no **Tenant B**: Global Administrator, Agent ID Administrator, ou Agent ID Developer
- **NAO e necessaria** uma subscription Azure no Tenant M365 para criar infra (nao criaremos nenhum recurso Azure via CLI)
- Os campos de infra Azure no `a365.config.json` (`resourceGroup`, `appServicePlanName`, etc.) podem conter valores placeholder - nao serao usados

---

## Ciclo de Desenvolvimento Agent 365

O ciclo completo possui 6 etapas. **Nesta licao cobrimos as etapas 2-3 (config + blueprint)**:

```
1. Build and run agent          <-- ja feito (licao 4, ACA no Tenant A)
2. Setup Agent 365 config       <-- ESTA LICAO
3. Setup agent blueprint        <-- ESTA LICAO
4. Deploy                       <-- ja feito (licao 4, needDeployment: false)
5. Publish to M365 admin center <-- licao futura
6. Create agent instances       <-- licao futura
```

Referencia: [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)

---

## Pre-requisito 0 - Frontier Preview Program

O Agent 365 requer acesso ao Frontier preview program:

1. Acesse [https://adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/)
2. Faca login com sua conta do **Tenant M365** (Tenant B)
3. Solicite acesso ao programa
4. Aguarde a aprovacao (pode levar alguns dias)

---

## Pre-requisito 1 - Instalar o .NET SDK

O Agent 365 CLI e distribuido como ferramenta .NET:

```powershell
# Verificar se o .NET esta instalado
dotnet --version
# Recomendado: .NET 8.0+

# Se nao estiver instalado, baixe de:
# https://dotnet.microsoft.com/download
```

---

## Pre-requisito 2 - Instalar o Agent 365 CLI

```powershell
# Instalar o CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verificar instalacao
a365 -h

# Para atualizar futuramente:
dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease
```

> **Nota**: Sempre use `--prerelease` enquanto o CLI estiver em preview.
> NuGet: [Microsoft.Agents.A365.DevTools.Cli](https://www.nuget.org/packages/Microsoft.Agents.A365.DevTools.Cli)

---

## Pre-requisito 3 - Custom Client App Registration (no Tenant M365)

O CLI precisa de um app registration no Entra ID do **Tenant M365** para autenticar.

### 3.1 - Registrar o aplicativo

1. Acesse o [Microsoft Entra admin center](https://entra.microsoft.com/) do **Tenant B (M365)**
2. Navegue para **App registrations > New registration**
3. Preencha:
   - **Name**: `a365-workshop-cli`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**: Selecione `Public client/native (mobile & desktop)` e insira `http://localhost:8400/`
4. Clique em **Register**

### 3.2 - Configurar Redirect URI adicional

1. Na pagina **Overview** do app, copie o **Application (client) ID** (formato GUID)
2. Va para **Authentication (preview)** > **Add Redirect URI**
3. Selecione **Mobile and desktop applications** e adicione:
   ```
   ms-appx-web://Microsoft.AAD.BrokerPlugin/{SEU-CLIENT-ID}
   ```
   (substitua `{SEU-CLIENT-ID}` pelo Application (client) ID copiado)
4. Clique em **Configure**

### 3.3 - Configurar API Permissions

> **IMPORTANTE**: Use **Delegated permissions** (NAO Application permissions).

#### Opcao A - Via Entra admin center (se permissoes beta estiverem visiveis)

1. No app registration, va para **API permissions > Add a permission**
2. Selecione **Microsoft Graph > Delegated permissions**
3. Adicione as 5 permissoes:

| Permissao | Descricao |
|-----------|-----------|
| `AgentIdentityBlueprint.ReadWrite.All` | Gerenciar Agent Blueprints (beta) |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Atualizar permissoes hereditarias do Blueprint (beta) |
| `Application.ReadWrite.All` | Criar e gerenciar aplicacoes |
| `DelegatedPermissionGrant.ReadWrite.All` | Conceder permissoes para blueprints |
| `Directory.Read.All` | Ler dados do diretorio |

4. Clique em **Grant admin consent for [Seu Tenant]**
5. Verifique que todas mostram checks verdes

#### Opcao B - Via Microsoft Graph API (se permissoes beta NAO estiverem visiveis)

Se as permissoes `AgentIdentityBlueprint.*` nao aparecerem no portal, use o Graph Explorer:

1. Acesse [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
2. Faca login com conta admin do Tenant M365

**Obter o Service Principal ID do app:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{SEU-CLIENT-ID}'&$select=id
```
O `id` retornado e o `SP_OBJECT_ID`.

Se retornar vazio, crie o service principal:
```http
POST https://graph.microsoft.com/v1.0/servicePrincipals
Body: { "appId": "{SEU-CLIENT-ID}" }
```

**Obter o Graph Resource ID:**
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=id
```
O `id` retornado e o `GRAPH_RESOURCE_ID`.

**Criar as permissoes delegadas (com admin consent automatico):**
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

> **ATENCAO**: Se usou a Opcao B, **NAO** clique em "Grant admin consent" no portal Entra depois. O portal nao ve permissoes beta e sobrescreve as que voce criou via API.

### 3.4 - Anotar o Client ID

Guarde o **Application (client) ID** - voce vai precisar dele no proximo passo.

```
Application (client) ID: ________-____-____-____-____________
```

---

## Etapa 2 - Setup Agent 365 Config

Como usamos `needDeployment: false`, **nao** executaremos o wizard interativo `a365 config init` (ele tenta listar subscriptions Azure e pode falhar sem subscription no Tenant M365). Em vez disso, criaremos o `a365.config.json` manualmente.

### 4.1 - Autenticar no Tenant M365

```powershell
# Login no Tenant M365 (Tenant B)
az login --tenant <TENANT-M365-ID>

# Verificar que estamos no tenant correto
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> O `az login` e necessario para que o CLI autentique no Entra ID do Tenant M365. NAO precisamos de uma subscription Azure aqui.

### 4.2 - Criar o a365.config.json manualmente

Navegue para o diretorio da licao 5 e crie o arquivo:

```powershell
cd lesson-5-a365-prereq
```

Crie o arquivo `a365.config.json` com o seguinte conteudo:

```json
{
  "$schema": "./a365.config.schema.json",
  "tenantId": "<TENANT-M365-ID>",
  "clientAppId": "<CLIENT-APP-ID-DO-PASSO-3>",
  "agentBlueprintDisplayName": "Financial Market Agent Blueprint",
  "agentIdentityDisplayName": "Financial Market Agent Identity",
  "agentUserPrincipalName": "fin-market-agent@<tenant-m365>.onmicrosoft.com",
  "agentUserDisplayName": "Financial Market Agent",
  "managerEmail": "seu-email@<tenant-m365>.com",
  "agentUserUsageLocation": "BR",
  "deploymentProjectPath": ".",
  "needDeployment": false,
  "messagingEndpoint": "https://<your-aca-app>.<aca-env-hash>.<region>.azurecontainerapps.io/api/messages",
  "agentDescription": "Agente de mercado financeiro (LangGraph no ACA) - Workshop A365"
}
```

**Campos importantes:**

| Campo | Valor | Explicacao |
|-------|-------|------------|
| `tenantId` | GUID do Tenant M365 | Onde o blueprint e registrado no Entra ID |
| `clientAppId` | GUID do passo 3.4 | App registration para autenticacao do CLI |
| `needDeployment` | `false` | **Nao cria infra Azure** - agente ja roda no ACA |
| `messagingEndpoint` | URL do ACA + `/api/messages` | Endpoint que o A365 usa para enviar mensagens ao agente |
| `agentUserPrincipalName` | `nome@tenant.onmicrosoft.com` | UPN do agente no Entra (dominio do Tenant M365) |
| `managerEmail` | Email no Tenant M365 | Gerente responsavel pelo agente |

> **Nota**: Campos de infra Azure (`subscriptionId`, `resourceGroup`, `appServicePlanName`, `webAppName`) foram **omitidos** pois `needDeployment: false`. Se o CLI exigir esses campos, adicione valores placeholder.

### 4.3 - Verificar a configuracao

```powershell
# Verificar que o arquivo existe
Test-Path a365.config.json
# Esperado: True

# Exibir a configuracao
a365 config display
```

**Checklist de verificacao:**
- [ ] `tenantId` e o GUID do Tenant M365 (NAO do Azure)
- [ ] `clientAppId` e o App Registration do passo 3
- [ ] `needDeployment` esta como `false`
- [ ] `messagingEndpoint` aponta para o ACA da licao 4
- [ ] `agentUserPrincipalName` usa o dominio `@<tenant-m365>.onmicrosoft.com`
- [ ] `managerEmail` usa o dominio do Tenant M365

---

## Etapa 3 - Setup Agent Blueprint

O blueprint define a identidade e permissoes do agente no Entra ID. Com `needDeployment: false`, o CLI **pula a criacao de infra Azure** e foca apenas no registro da identidade.

### 5.1 - Executar o setup

```powershell
# Executar o setup completo (dentro de lesson-5-a365-prereq/)
a365 setup all
```

Com `needDeployment: false`, o comando realiza **apenas**:

1. **Registra o Agent Blueprint** no Entra ID do Tenant M365:
   - Cria o Agent Identity Blueprint (app registration)
   - Cria o service principal associado
   - Configura a identidade do agente (`agentUserPrincipalName`)

2. **Configura API Permissions**:
   - Microsoft Graph API scopes
   - Messaging Bot API permissions
   - Permissoes hereditarias para instancias futuras

3. **Registra o messaging endpoint**:
   - Associa o `messagingEndpoint` (ACA da licao 4) ao blueprint

4. **Gera `a365.generated.config.json`**:
   - IDs do blueprint, service principal, client secret, endpoint

> **Nota**: O CLI abre janelas do browser para admin consent. Complete todos os fluxos. Leva 3-5 minutos.
>
> **NAO sera criada** nenhuma infra Azure (Resource Group, App Service Plan, Web App). O agente ja roda no ACA do Tenant A.

### 5.2 - Verificar o setup

```powershell
# Exibir configuracao gerada
a365 config display -g
```

Saida esperada (campos-chave):
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

**Verificacoes no Entra admin center** (Tenant M365):
- [ ] App Registration existe (buscar pelo `agentBlueprintId`)
- [ ] Enterprise Application correspondente existe
- [ ] API permissions mostram checks verdes ("Granted for [Seu Tenant]")
- [ ] Permissoes incluem Microsoft Graph e Messaging Bot API
- [ ] Agent Identity visivel em [Entra Agent Registry](https://entra.microsoft.com/#view/Microsoft_AAD_IAM/AgentIdentitiesListBlade)

---

## Resumo dos artefatos gerados

Ao final desta licao, voce tera:

| Artefato | Localizacao | Descricao |
|----------|-------------|-----------|
| `a365.config.json` | `lesson-5-a365-prereq/` | Configuracao manual (criada a mao, sem wizard) |
| `a365.generated.config.json` | `lesson-5-a365-prereq/` | Configuracao gerada pelo CLI (IDs, secrets) |
| Custom Client App | Entra ID (Tenant M365) | App registration para autenticacao do CLI |
| Agent Blueprint | Entra ID (Tenant M365) | Identidade + permissoes do agente |
| Service Principal | Entra ID (Tenant M365) | Identidade do agente para autenticacao |

> **O que NAO foi criado**: Nenhum recurso Azure (Resource Group, App Service Plan, Web App). O agente continua rodando no ACA do Tenant A (licao 4) e o A365 apenas aponta para ele via `messagingEndpoint`.

---

## Troubleshooting

| Problema | Causa provavel | Solucao |
|----------|---------------|---------|
| `az login` nao mostra subscription | Tenant errado | Use `az login --tenant <TENANT-M365-ID>` |
| `a365 config init` falha ao listar subscriptions | Sem subscription no Tenant M365 | Nao use o wizard. Crie o `a365.config.json` manualmente (secao 4.2) |
| CLI exige campos de infra Azure | Schema validation | Adicione campos placeholder: `"subscriptionId": "00000000-0000-0000-0000-000000000000"` |
| Client App ID invalido | App ID vs Object ID | Verifique se usou Application (client) ID, nao Object ID |
| Permissoes beta nao visiveis | AgentIdentityBlueprint.* em beta | Use a Opcao B (Graph API) para adicionar permissoes |
| Admin consent falha | Sem role de admin | Peca ao admin do Tenant M365 para completar o passo 3.3 |
| `a365 setup` falha com permissoes | Role insuficiente | Precisa de Global Admin, Agent ID Admin ou Agent ID Developer |
| Blueprint nao aparece no Entra | Setup incompleto | Execute `a365 setup all` novamente |
| Endpoint nao registrado | needDeployment=false sem messagingEndpoint | Execute `a365 setup blueprint --endpoint-only` |

---

## Proximos passos

Com os pre-requisitos configurados, as proximas etapas do ciclo A365 sao:

- **Licao 6 (futura)**: Adaptar o codigo do agente com o A365 SDK (observabilidade, tooling, notificacoes)
- **Licao 7 (futura)**: Publicar o agente no M365 admin center (`a365 publish`)
- **Licao 8 (futura)**: Criar instancias do agente no Teams (`a365 create-instance` ou via Teams Apps)

---

## Referencias

- [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Agent 365 CLI](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli)
- [Setting up Agent 365 Config](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-config)
- [Custom Client App Registration](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/custom-client-app-registration)
- [Setup Agent Blueprint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/registration)
- [Agent Messaging Endpoint](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-messaging-endpoint)
- [Agent 365 Config Reference](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/config)
- [Frontier Preview Program](https://adoption.microsoft.com/copilot/frontier-program/)
