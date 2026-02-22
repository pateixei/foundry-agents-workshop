# Lab 6: Registrar Aplicação no Entra ID e Configurar Agent 365

> 🇺🇸 **[Read in English](LAB-STATEMENT.md)**

## Objetivo

Registrar uma **Aplicação de Cliente Personalizada** no Microsoft Entra ID, configurar suas definições de autenticação e permissões de API, e criar o arquivo `a365.config.json` — a base necessária para publicar agentes no Microsoft 365 via Agent 365 CLI.

## Cenário

Sua organização deseja disponibilizar o agente de mercado financeiro (rodando no ACA do Lab 4) para usuários finais no **Microsoft Teams e Outlook**. Para isso, você precisa:
- Registrar uma aplicação no Entra ID do Tenant M365 para autenticação do CLI
- Configurar redirect URIs para o fluxo OAuth
- Conceder as permissões corretas da API Microsoft Graph (incluindo permissões beta)
- Capturar o Client ID gerado
- Criar o `a365.config.json` apontando para o endpoint do agente no ACA

> [!CAUTION]
> **🔴 PRÉ-REQUISITO OBRIGATÓRIO — Licença do Microsoft 365 Copilot + Acesso ao Frontier**
>
> Seu tenant M365 precisa de **pelo menos uma licença ativa do Microsoft 365 Copilot** para usar o Agent 365. Sem ela, o comando `a365 setup blueprint` falhará com **"Forbidden: Access denied by Frontier access control"**.
>
> > **Nota:** O programa Frontier não requer mais um formulário de inscrição separado. O acesso é concedido automaticamente a tenants com uma licença válida do Microsoft 365 Copilot.
>
> **Passos para habilitar:**
> 1. No tenant, certifique-se de que pelo menos um usuário tem uma licença do **Microsoft 365 Copilot** atribuída (trial é suficiente → [Iniciar trial gratuito](https://www.microsoft.com/microsoft-365/copilot/microsoft-365-copilot))
> 2. Um Global Admin deve acessar o [Centro de Administração do Microsoft 365](https://admin.microsoft.com/) → **Copilot** → **Configurações** → **Acesso de usuários** → **Copilot Frontier** e habilitar para os usuários necessários ou para toda a organização
>
> A opção **Copilot → Configurações → Copilot Frontier** só aparecerá quando houver uma licença Copilot ativa no tenant.

## Resultados de Aprendizagem

- Registrar aplicações no Microsoft Entra ID (Azure AD)
- Configurar redirect URIs OAuth para apps de cliente público
- Gerenciar permissões delegadas da API Microsoft Graph (incluindo beta)
- Compreender a arquitetura cross-tenant (Azure Tenant A + M365 Tenant B)
- Criar e validar o arquivo de configuração do Agent 365
- Diferenciar entre Application (client) ID e Object ID

## Pré-requisitos

- [x] Lab 4 concluído (agente ACA implantado e rodando)
- [x] Acesso ao Tenant M365 (Tenant B) com role de Global Administrator ou Agent ID Administrator
- [x] .NET 8.0+ SDK instalado
- [x] Agent 365 CLI instalado (`dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease`)
- [x] URL do agente ACA do Lab 4 disponível

## Contexto Arquitetural

```
┌──────────────────────────────────────────────────┐
│              Tenant M365 (Tenant B)              │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │ Entra ID                                   │  │
│  │                                            │  │
│  │  ┌──────────────────────┐                  │  │
│  │  │ App Registration     │  ← ESTE LAB      │  │
│  │  │ "a365-workshop-cli"  │                  │  │
│  │  │                      │                  │  │
│  │  │ • Client ID          │                  │  │
│  │  │ • Redirect URIs      │                  │  │
│  │  │ • Permissões Graph   │                  │  │
│  │  └──────────────────────┘                  │  │
│  │                                            │  │
│  │  ┌──────────────────────┐                  │  │
│  │  │ Agent Blueprint      │  ← LAB 6         │  │
│  │  │ (criado pelo CLI)    │                  │  │
│  │  └──────────────────────┘                  │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  a365.config.json ──────┐                        │
│    tenantId             │                        │
│    clientAppId          │  ← ESTE LAB            │
│    messagingEndpoint ───┼───────────────────┐    │
│                         │                   │    │
└─────────────────────────┼───────────────────┼────┘
                          │                   │
                          │    ┌──────────────┼────┐
                          │    │ Azure (A)     │    │
                          │    │               ▼    │
                          │    │  ┌─────────────┐  │
                          │    │  │ Agente ACA  │  │
                          │    │  │ (Lab 4)     │  │
                          │    │  └─────────────┘  │
                          │    └────────────────────┘
                          │
                     a365.config.json
```

## Tarefas

### Tarefa 1: Instalar Pré-requisitos (10 minutos)

**1.1 - Verificar .NET SDK**

```powershell
dotnet --version
# Esperado: 8.0.x ou superior
```

Se não estiver instalado, baixe de [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).

**1.2 - Instalar Agent 365 CLI**

```powershell
# Instalar o CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verificar instalação
a365 -h
```

> **Dica**: Se já instalado, atualize com `dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease`

**1.3 - Identificar seus tenants**

Preencha os campos a seguir antes de prosseguir:

| Campo | Valor |
|-------|-------|
| Azure Tenant ID (Tenant A) | `________-____-____-____-____________` |
| M365 Tenant ID (Tenant B) | `________-____-____-____-____________` |
| Domínio do Tenant M365 | `__________.onmicrosoft.com` |
| URL do Agente ACA (do Lab 4) | `https://aca-lg-agent.xxxxx.eastus.azurecontainerapps.io` |

> **Nota**: Se Azure e M365 estão no **mesmo tenant**, ambos os campos terão o mesmo GUID. O cenário cross-tenant é comum em empresas que separam Azure do M365 por governança.

**Critérios de Sucesso**:
- ✅ .NET 8.0+ instalado
- ✅ `a365 -h` retorna a ajuda do CLI
- ✅ IDs dos tenants e URL do ACA identificados

### Tarefa 2: Registrar Aplicação no Entra ID (15 minutos)

> **IMPORTANTE**: Todas as operações no Entra ID devem ser feitas no **Tenant M365 (Tenant B)**, não no Tenant Azure.

**2.1 - Navegar até o Entra admin center**

1. Acesse o [Microsoft Entra admin center](https://entra.microsoft.com/)
2. **Verifique que está no tenant correto** (Tenant M365 B) — confira o nome do tenant no canto superior direito
3. Navegue para **Identity** → **Applications** → **App registrations**

**2.2 - Criar novo registro**

1. Clique em **+ New registration**
2. Preencha:
   - **Name**: `a365-workshop-cli`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**:
     - Platform: `Public client/native (mobile & desktop)`
     - URI: `http://localhost:8400/`
3. Clique em **Register**

**2.3 - Capturar o Application (client) ID**

Na página **Overview** do app, localize e copie:

| Campo | Onde Encontrar | Exemplo |
|-------|---------------|---------|
| **Application (client) ID** | Página Overview, seção superior | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |
| **Directory (tenant) ID** | Página Overview, seção superior | Deve corresponder ao seu M365 Tenant ID |

> ⚠️ **Erro comum**: NÃO confunda **Application (client) ID** com **Object ID**. Você precisa do **Application (client) ID** — o GUID normalmente mostrado primeiro.

Registre aqui:
```
Application (client) ID: ________-____-____-____-____________
```

**Critérios de Sucesso**:
- ✅ App registration criado no Entra ID do Tenant M365
- ✅ Nome é `a365-workshop-cli`
- ✅ Single tenant selecionado
- ✅ Redirect URI `http://localhost:8400/` adicionada
- ✅ Application (client) ID copiado

### Tarefa 3: Configurar Redirect URI (10 minutos)

O Agent 365 CLI requer uma redirect URI adicional que inclui o Client ID.

**3.1 - Adicionar Redirect URI do Broker Plugin**

1. No app registration, vá para **Authentication**
2. Em **Mobile and desktop applications**, clique em **Add URI**
3. Adicione a seguinte URI (substitua `{YOUR-CLIENT-ID}` pelo valor da Tarefa 2):
   ```
   ms-appx-web://Microsoft.AAD.BrokerPlugin/{YOUR-CLIENT-ID}
   ```
   Exemplo: `ms-appx-web://Microsoft.AAD.BrokerPlugin/a1b2c3d4-e5f6-7890-abcd-ef1234567890`
4. Clique em **Save**

**3.2 - Verificar Redirect URIs**

Após salvar, em **Platform configurations** → **Mobile and desktop applications**, confirme ambas as URIs:

| # | Redirect URI | Propósito |
|---|-------------|-----------|
| 1 | `http://localhost:8400/` | Autenticação local do CLI |
| 2 | `ms-appx-web://Microsoft.AAD.BrokerPlugin/{CLIENT-ID}` | Autenticação via WAM broker |

**Critérios de Sucesso**:
- ✅ Duas redirect URIs configuradas
- ✅ URI do broker plugin inclui o Client ID correto
- ✅ Ambas as URIs salvas com sucesso

### Tarefa 4: Configurar Permissões de API (20 minutos)

O Agent 365 CLI precisa de permissões delegadas específicas do Microsoft Graph. Algumas são **permissões beta** que podem não aparecer na UI do portal.

> **IMPORTANTE**: Use permissões **Delegadas** (NÃO permissões de Aplicação). O CLI autentica como usuário, não como app.

**4.1 - Determinar qual método usar**

Tente a Opção A primeiro. Se as permissões beta (`AgentIdentityBlueprint.*`) não aparecerem na busca, use a Opção B.

#### Opção A — Via Entra Admin Center

1. No app registration, vá para **API permissions** → **Add a permission**
2. Selecione **Microsoft Graph** → **Delegated permissions**
3. Busque e adicione cada uma das 5 permissões:

| Permissão | Categoria | Descrição |
|-----------|----------|-----------|
| `AgentIdentityBlueprint.ReadWrite.All` | Agent Identity (beta) | Gerenciar Agent Blueprints |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Agent Identity (beta) | Atualizar permissões herdadas do Blueprint |
| `Application.ReadWrite.All` | Application | Criar e gerenciar aplicações |
| `DelegatedPermissionGrant.ReadWrite.All` | Delegated Permission Grant | Conceder permissões para blueprints |
| `Directory.Read.All` | Directory | Ler dados do diretório |

4. Clique em **Add permissions**
5. Clique em **Grant admin consent for [Seu Tenant]**
6. Verifique que todas as 5 permissões mostram ✅ verde na coluna "Status"

#### Opção B — Via Microsoft Graph API (se permissões beta não aparecerem)

Se `AgentIdentityBlueprint.*` não aparece na busca do portal:

1. Acesse o [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer)
2. Faça login com a conta admin do Tenant M365

**Passo B.1** — Obter o Service Principal ID do app:
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{YOUR-CLIENT-ID}'&$select=id
```
Se o resultado for vazio, crie-o primeiro:
```http
POST https://graph.microsoft.com/v1.0/servicePrincipals
Content-Type: application/json

{ "appId": "{YOUR-CLIENT-ID}" }
```

Registre o `id` como `SP_OBJECT_ID`: `________-____-____-____-____________`

**Passo B.2** — Obter o Resource ID do Microsoft Graph:
```http
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'&$select=id
```
Registre o `id` como `GRAPH_RESOURCE_ID`: `________-____-____-____-____________`

**Passo B.3** — Criar permissões delegadas com consentimento admin automático:
```http
POST https://graph.microsoft.com/v1.0/oauth2PermissionGrants
Content-Type: application/json

{
  "clientId": "<SP_OBJECT_ID>",
  "consentType": "AllPrincipals",
  "principalId": null,
  "resourceId": "<GRAPH_RESOURCE_ID>",
  "scope": "Application.ReadWrite.All Directory.Read.All DelegatedPermissionGrant.ReadWrite.All AgentIdentityBlueprint.ReadWrite.All AgentIdentityBlueprint.UpdateAuthProperties.All"
}
```

> ⚠️ **AVISO**: Se usou a Opção B, **NÃO** clique em "Grant admin consent" no portal Entra depois. O portal não enxerga permissões beta e vai **sobrescrever** o que você criou via API.

**4.2 - Verificar permissões**

Após conceder (via qualquer opção), confirme:

| Permissão | Tipo | Consentimento Admin | Status |
|-----------|------|:-------------------:|:------:|
| `AgentIdentityBlueprint.ReadWrite.All` | Delegada | ✅ | Concedida |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Delegada | ✅ | Concedida |
| `Application.ReadWrite.All` | Delegada | ✅ | Concedida |
| `DelegatedPermissionGrant.ReadWrite.All` | Delegada | ✅ | Concedida |
| `Directory.Read.All` | Delegada | ✅ | Concedida |

**Critérios de Sucesso**:
- ✅ Todas as 5 permissões delegadas adicionadas
- ✅ Consentimento admin concedido para o tenant
- ✅ Todas as permissões mostram checkmarks verdes
- ✅ Nenhuma permissão de aplicação foi adicionada acidentalmente

### Tarefa 5: Criar a365.config.json (15 minutos)

Agora que a aplicação no Entra ID está registrada com as permissões corretas, crie o arquivo de configuração do A365.

**5.1 - Autenticar no Tenant M365**

```powershell
# Login no Tenant M365 (Tenant B)
az login --tenant <M365-TENANT-ID>

# Verificar que está no tenant correto
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

> **Nota**: `az login` é necessário para autenticação do CLI no Entra ID do M365. Você não precisa de uma assinatura Azure neste tenant.

**5.2 - Navegar até o diretório da lição**

```powershell
cd lesson-6-a365-setup
```

**5.3 - Criar o arquivo de configuração**

Crie `a365.config.json` com o seguinte conteúdo, substituindo os placeholders:

```json
{
  "$schema": "./a365.config.schema.json",
  "tenantId": "<M365-TENANT-ID>",
  "clientAppId": "<CLIENT-ID-DA-TAREFA-2>",
  "agentBlueprintDisplayName": "Financial Market Agent Blueprint",
  "agentIdentityDisplayName": "Financial Market Agent Identity",
  "agentUserPrincipalName": "fin-market-agent@<DOMINIO-M365>.onmicrosoft.com",
  "agentUserDisplayName": "Financial Market Agent",
  "managerEmail": "<SEU-EMAIL>@<DOMINIO-M365>.com",
  "agentUserUsageLocation": "BR",
  "deploymentProjectPath": ".",
  "needDeployment": false,
  "messagingEndpoint": "<URL-ACA-DO-LAB-4>/api/messages",
  "agentDescription": "Financial market agent (LangGraph on ACA) - A365 Workshop"
}
```

**Referência dos campos:**

| Campo | Valor | De Onde Vem |
|-------|-------|-------------|
| `tenantId` | GUID do Tenant M365 | Tarefa 1 (Entra admin center) |
| `clientAppId` | Application (client) ID | Tarefa 2 (App registration) |
| `agentUserPrincipalName` | `nome@dominio.onmicrosoft.com` | Domínio do seu tenant M365 |
| `managerEmail` | Email do admin no tenant M365 | Sua conta admin M365 |
| `needDeployment` | `false` | Agente já roda no ACA (Lab 4) |
| `messagingEndpoint` | URL do ACA + `/api/messages` | Output do deploy.ps1 do Lab 4 |

> **Chave**: Configurar `needDeployment: false` diz ao CLI para pular a criação de infraestrutura Azure. O agente continua rodando no ACA (Tenant A). O CLI apenas registra a identidade no Entra ID do M365.

**5.4 - Validar a configuração**

```powershell
# Verificar se o arquivo existe
Test-Path a365.config.json
# Esperado: True

# Exibir a configuração
a365 config display
```

**Checklist de validação:**
- [ ] `tenantId` é o GUID do Tenant M365 (NÃO o Tenant Azure)
- [ ] `clientAppId` corresponde ao Application (client) ID da Tarefa 2
- [ ] `needDeployment` é `false`
- [ ] `messagingEndpoint` aponta para o ACA do Lab 4 com sufixo `/api/messages`
- [ ] `agentUserPrincipalName` usa o domínio `@<tenant-m365>.onmicrosoft.com`
- [ ] `managerEmail` usa um email no domínio do Tenant M365

**Critérios de Sucesso**:
- ✅ `a365.config.json` criado com todos os campos obrigatórios
- ✅ `a365 config display` mostra a configuração sem erros
- ✅ Todos os valores placeholder substituídos por valores reais
- ✅ `needDeployment` definido como `false`

### Tarefa 6: Comparar Modelos de Hospedagem e Autenticação (10 minutos)

> **Nota**: As Tarefas 7 e 8 (instalação do A365 CLI + registro do Agent Blueprint) estão logo após esta tarefa.

**Complete a tabela de comparação:**

| Aspecto | Hosted Agent (Lab 2-3) | ACA + A365 (Labs 4-6) |
|---------|------------------------|------------------------|
| **Código do Agente Roda Em** | ? | ? |
| **Provedor de Identidade** | ? | ? |
| **Fluxo de Autenticação** | ? | ? |
| **Arquivo de Configuração** | ? | ? |
| **App Registration no Entra** | ? | ? |
| **Tipo de Endpoint** | ? | ? |
| **Integração M365** | ? | ? |
| **Quando Usar** | ? | ? |

**Reflita sobre estas questões:**
1. Por que o A365 requer um app registration separado no Tenant M365?
2. Qual o papel do `needDeployment: false` — o que ele pula e o que ainda faz?
3. Se Azure e M365 estivessem no mesmo tenant, quais campos no `a365.config.json` mudariam?

**Critérios de Sucesso**:
- ✅ Tabela preenchida com informações precisas
- ✅ Consegue explicar a arquitetura cross-tenant
- ✅ Entende por que `needDeployment: false` é usado

### Tarefa 7: Instalar o A365 CLI (15 minutos)

Com a aplicação no Entra ID registrada e o `a365.config.json` configurado, instale o tooling do Agent 365 CLI que será usado para registrar o Agent Blueprint.

**7.1 - Verificar .NET SDK (se não feito na Tarefa 1)**

```powershell
dotnet --version
# Esperado: 8.0.x ou superior
```

**7.2 - Instalar o Agent 365 CLI**

```powershell
# Instalar o CLI (preview)
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Se já instalado, atualize em vez disso
dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verificar
a365 -h
```

**7.3 - Exibir a configuração**

```powershell
cd lesson-6-a365-setup
a365 config display
```

Esperado: Mostra o conteúdo do seu `a365.config.json` sem erros de validação. Todos os campos devem estar preenchidos.

**Critérios de Sucesso**:
- ✅ .NET 8.0+ instalado
- ✅ `a365 -h` retorna ajuda do CLI
- ✅ `a365 config display` mostra a configuração sem erros

---

### Tarefa 8: Registrar o Agent Blueprint (20 minutos)

Use o A365 CLI para criar o **Agent Blueprint** no tenant M365. Isso registra a identidade do agente, o endpoint de mensagens e as permissões no Entra ID —  habilitando o Teams e o Outlook a rotearem mensagens para seu agente no ACA.

**8.1 - Login no Tenant M365**

```powershell
# Autenticar no Tenant M365 (Tenant B)
az login --tenant <M365-TENANT-ID>

# Verificar tenant correto
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

**8.2 - Executar o comando de configuração do Blueprint**

```powershell
cd lesson-6-a365-setup
a365 setup blueprint --config a365.config.json
```

Saída esperada:
```
[INFO] Authenticating to tenant <M365-TENANT-ID>...
[INFO] Creating Agent Blueprint: Financial Market Agent Blueprint
[INFO] Agent Blueprint created successfully
[INFO] App ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
[INFO] Setup complete.
```

> Se você ver **"Forbidden: Access denied by Frontier access control"**, seu tenant M365 não possui uma licença ativa do Microsoft 365 Copilot ou o Copilot Frontier não foi habilitado no Admin Center (veja o bloco de Cuidado no início deste lab).

**8.3 - Capturar o App ID da saída do Blueprint**

DA saída do CLI, copie o **App ID** (um GUID) gerado para a identidade do agente. Você definirá isso no container app do ACA como `MICROSOFT_APP_ID`.

**8.4 - Definir MICROSOFT_APP_ID no ACA**

```powershell
$RG       = "rg-ai-agents-workshop"
$ACA_NAME = "aca-lg-agent"
$APP_ID   = "<APP-ID-DA-SAIDA-DO-BLUEPRINT>"

az containerapp update `
  --name $ACA_NAME `
  --resource-group $RG `
  --set-env-vars "MICROSOFT_APP_ID=$APP_ID"
```

**8.5 - Verificar no portal do Entra ID**

1. Acesse o [Microsoft Entra admin center](https://entra.microsoft.com/) no Tenant M365
2. Navegue para **Identity** → **Applications** → **App registrations** → **All applications**
3. Busque por "Financial Market Agent Blueprint"
4. Confirme que o registro existe com o App ID correto

**Critérios de Sucesso**:
- ✅ `a365 setup blueprint` concluído sem erros
- ✅ App ID do Blueprint capturado
- ✅ `MICROSOFT_APP_ID` definido no container app do ACA
- ✅ Blueprint visível no portal do Entra ID

---

## Entregáveis

- [x] .NET SDK e A365 CLI instalados
- [x] App registration no Entra ID (`a365-workshop-cli`) criado
- [x] Redirect URIs configuradas (localhost + broker plugin)
- [x] 5 permissões delegadas do Graph concedidas com consentimento admin
- [x] Application (client) ID capturado
- [x] `a365.config.json` criado e validado
- [x] Tabela de comparação preenchida
- [x] A365 CLI instalado e verificado
- [x] Agent Blueprint registrado no Tenant M365
- [x] `MICROSOFT_APP_ID` definido no ACA

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|----------|--------|-----------|
| **App Registration** | 20 pts | Criado corretamente no Tenant M365 com escopo single-tenant |
| **Redirect URIs** | 10 pts | Ambas URIs configuradas (localhost + broker plugin com Client ID correto) |
| **Permissões de API** | 20 pts | Todas as 5 permissões delegadas com consentimento admin concedido |
| **Arquivo de Config** | 20 pts | `a365.config.json` válido com valores corretos e `needDeployment: false` |
| **Entendimento Arquitetural** | 10 pts | Tabela de comparação demonstra compreensão cross-tenant |
| **Instalação do A365 CLI** | 10 pts | CLI instalado e `a365 config display` funciona |
| **Registro do Blueprint** | 10 pts | Blueprint criado, App ID definido no ACA |

**Total**: 100 pontos

## Resolução de Problemas

### "Permissões AgentIdentityBlueprint não encontradas no portal"
- **Causa**: São permissões beta que ainda não estão GA
- **Solução**: Use a Opção B (Graph API) da Tarefa 4 para definir permissões via API

### Botão "Grant admin consent" está acinzentado
- **Causa**: Você não tem a role de Global Administrator no Tenant M365
- **Solução**: Peça a um admin para conceder o consentimento, ou solicite a role

### "Application (client) ID" vs "Object ID"
- **Causa**: Confusão comum — ambos são GUIDs semelhantes
- **Solução**: Use o **Application (client) ID** (mostrado primeiro na página Overview). Object ID NÃO é o que o CLI espera.

### `a365 config display` mostra erros
- **Causa**: JSON inválido ou campos obrigatórios ausentes
- **Solução**: Valide a sintaxe JSON. Certifique-se que todos os campos obrigatórios estão presentes. Verifique vírgulas extras.

### `az login --tenant` não funciona
- **Causa**: A conta não tem acesso ao Tenant M365
- **Solução**: Verifique se sua conta existe no Tenant M365. Tente autenticar em https://entra.microsoft.com primeiro.

### Erros de redirect URI não corresponde
- **Causa**: URI do broker plugin não corresponde ao Client ID
- **Solução**: Verifique que a URI é exatamente `ms-appx-web://Microsoft.AAD.BrokerPlugin/{YOUR-CLIENT-ID}` com o Client ID correto

### "Consentimento admin foi sobrescrito após usar Graph API"
- **Causa**: Clicou em "Grant admin consent" no portal após usar a Opção B
- **Solução**: Execute novamente a requisição `POST /oauth2PermissionGrants` da Opção B via Graph API. O portal não enxerga permissões beta e as sobrescreve.

## Estimativa de Tempo

- Tarefa 1: 10 minutos
- Tarefa 2: 15 minutos
- Tarefa 3: 10 minutos
- Tarefa 4: 20 minutos
- Tarefa 5: 15 minutos
- Tarefa 6: 10 minutos
- Tarefa 7: 15 minutos
- Tarefa 8: 20 minutos
- **Total**: ~115 minutos

## Próximos Passos

- **Lab 7**: Publicar o agente no Microsoft 365 Admin Center e disponibilizá-lo para usuários
- Testar o fluxo completo end-to-end: Teams → M365 → ACA → Azure OpenAI → Resposta

---

**Dificuldade**: Intermediário  
**Pré-requisitos**: Lab 5 concluído (endpoint Bot Framework `/api/messages` implantado no ACA), acesso ao Tenant M365 com privilégios de admin  
**Tempo Estimado**: ~115 minutos
