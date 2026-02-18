# Lição 5 - Pré-requisitos A365: Registro de Aplicação no Entra ID

> 🇺🇸 **[Read in English](README.md)**

Este script automatiza o **Registro de Aplicação no Entra ID** e a configuração do **a365.config.json** necessários para publicar agentes no Microsoft 365 via Agent 365 CLI.

## Arquitetura

```
┌──────────────────────────────────────────────────┐
│ Script: setup-entra-app.ps1                      │
│                                                  │
│  1. Validar pré-requisitos                       │
│  2. az ad app create ──────► App Reg no Entra ID │
│  3. az ad app update ──────► Redirect URIs       │
│  4. az ad sp create  ──────► Service Principal   │
│  5. az rest POST     ──────► Permissões Graph    │
│  6. ConvertTo-Json   ──────► a365.config.json    │
└──────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Tenant M365 (Entra ID)                           │
│                                                  │
│  App: a365-workshop-cli                          │
│  - Client ID capturado                           │
│  - Redirect URIs: localhost + broker plugin      │
│  - 5 permissões delegadas Graph (consent admin)  │
│                                                  │
│  a365.config.json → messagingEndpoint → URL ACA  │
└──────────────────────────────────────────────────┘
```

## Estrutura de Arquivos

```
lesson-5-a365-prereq/labs/
  LAB-STATEMENT.md         # Instruções do lab (Inglês)
  LAB-STATEMENT.pt-BR.md   # Instruções do lab (Português)
  solution/
    setup-entra-app.ps1    # Script solução completo
    README.md              # README em inglês
    README.pt-BR.md        # Este arquivo
  starter/
    setup-entra-app.ps1    # Starter com TODOs para alunos
```

## Pré-requisitos

- .NET 8.0+ SDK
- Azure CLI (`az`) instalado e autenticado
- Agent 365 CLI (`dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease`)
- Role de Global Administrator ou Agent ID Administrator no Tenant M365
- URL do agente ACA do Lab 4

## Uso

```powershell
.\setup-entra-app.ps1 `
    -M365TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -M365Domain "contoso.onmicrosoft.com" `
    -AcaUrl "https://aca-lg-agent.xxxxx.eastus.azurecontainerapps.io" `
    -ManagerEmail "admin@contoso.com"
```

### Parâmetros Opcionais

| Parâmetro | Padrão | Descrição |
|-----------|--------|-----------|
| `-AppDisplayName` | `a365-workshop-cli` | Nome do app registration no Entra ID |
| `-AgentDisplayName` | `Financial Market Agent` | Nome do agente no config A365 |
| `-AgentUpnPrefix` | `fin-market-agent` | Prefixo do UPN do agente (antes do @domínio) |
| `-OutputDir` | `.` | Diretório onde a365.config.json será criado |

## O que o Script Faz

| Passo | Ação | Comando Azure CLI |
|-------|------|-------------------|
| 1 | Validar pré-requisitos | `dotnet --version`, `a365 -h`, `az account show` |
| 2 | Registrar app no Entra ID | `az ad app create --sign-in-audience AzureADMyOrg` |
| 3 | Configurar redirect URIs | `az ad app update --public-client-redirect-uris` |
| 4 | Criar service principal | `az ad sp create --id <client-id>` |
| 5 | Conceder permissões Graph | `az rest POST /oauth2PermissionGrants` |
| 6 | Gerar a365.config.json | `ConvertTo-Json \| Set-Content` |

## Permissões Concedidas

O script concede 5 permissões **delegadas** com consentimento admin:

| Permissão | Propósito |
|-----------|-----------|
| `AgentIdentityBlueprint.ReadWrite.All` | Gerenciar Agent Blueprints |
| `AgentIdentityBlueprint.UpdateAuthProperties.All` | Atualizar propriedades de auth do Blueprint |
| `Application.ReadWrite.All` | Criar/gerenciar aplicações |
| `DelegatedPermissionGrant.ReadWrite.All` | Conceder permissões para blueprints |
| `Directory.Read.All` | Ler dados do diretório |

> **Nota**: `AgentIdentityBlueprint.*` são permissões beta. O script usa a Graph API diretamente (`az rest`) para lidar com elas, já que podem não aparecer na UI do portal Entra.

## Starter vs Solution

| Aspecto | Starter | Solution |
|---------|---------|----------|
| **Validação de parâmetros** | ✅ Fornecido | ✅ Fornecido |
| **Verificação de pré-requisitos** | ✅ Fornecido | ✅ Fornecido |
| **Registro do app** | ❌ TODO | ✅ Implementado |
| **Redirect URIs** | ❌ TODO | ✅ Implementado |
| **Service principal** | ❌ TODO | ✅ Implementado |
| **Concessão de permissões** | ❌ TODO | ✅ Implementado |
| **Geração do config** | ❌ TODO | ✅ Implementado |

O starter tem **7 TODOs** para os alunos implementarem, com dicas detalhadas em cada um.

## Validação

Após executar o script:

```powershell
# Verificar o arquivo de config
a365 config display

# Verificar o app no Entra
az ad app show --id <CLIENT_ID> --query "{name:displayName, signInAudience:signInAudience}" -o table

# Verificar redirect URIs
az ad app show --id <CLIENT_ID> --query "publicClient.redirectUris" -o json

# Verificar permissões
az rest --method GET --url "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?\$filter=clientId eq '<SP_ID>'" --query "value[0].scope" -o tsv
```

## Idempotência

O script é **idempotente** — pode ser executado múltiplas vezes com segurança:
- Verifica se o app registration já existe antes de criar
- Verifica se o service principal já existe antes de criar
- Atualiza grants de permissão existentes em vez de falhar em duplicatas

## Próximos Passos

Após completar este lab, siga para o **Lab 6** para:
1. Criar o Agent Blueprint: `a365 agent-identity create-blueprint`
2. Publicar no M365 Admin Center: `a365 agent-identity publish`
3. Criar instâncias do agente no Teams
