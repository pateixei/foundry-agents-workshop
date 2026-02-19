# Lição 7: Publicação do Agente no Microsoft 365 Admin Center

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Executar** `a365 publish` para empacotar e enviar o agente ao Microsoft 365 Admin Center
2. **Personalizar** o manifesto do agente (nome, versão, descrições, ícones)
3. **Verificar** a publicação bem-sucedida no registro do Microsoft 365 Admin Center
4. **Compreender** o pipeline completo de publicação: manifesto → pacote → upload → acesso → federação → permissões Graph
5. **Solucionar** problemas comuns de publicação

---

## Visão Geral

Após concluir as etapas de configuração da Lição 6 (criação do blueprint, permissões, registro do endpoint), você publica o agente no Microsoft 365 Admin Center usando o comando `a365 publish`.

A publicação cria um **pacote de app do Teams** a partir do blueprint do agente e o torna visível no Microsoft 365 Admin Center como um agente gerenciado. Após a publicação, os administradores podem criar instâncias do agente no Microsoft Teams.

> **Importante:** `a365 publish` requer que o programa de preview Frontier esteja habilitado para o tenant e que o usuário tenha a função de **Agent ID Developer**, **Agent ID Administrator** ou **Global Administrator**.

---

## Arquitetura: Pipeline de Publicação

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

---

## Pré-requisitos

Antes de executar `a365 publish`, certifique-se de que:

1. ✅ **Lição 6 concluída** — os seguintes comandos de setup executaram com sucesso:
   ```powershell
   a365 setup blueprint --endpoint-only   # ou a365 setup all no primeiro setup
   a365 setup permissions mcp
   a365 setup permissions bot
   ```
2. ✅ **Blueprint do agente existe** — `a365.generated.config.json` contém um `agentBlueprintId` não vazio
3. ✅ **Endpoint de mensagens acessível** — endpoint retorna HTTP 200
4. ✅ **Autenticado** — sessão ativa de `az login` para o tenant M365
5. ✅ **Função necessária** — Global Administrator, Agent ID Administrator ou Agent ID Developer
6. ✅ **Arquivos de configuração presentes** — `a365.config.json` e `a365.generated.config.json` no diretório de trabalho

### Verificar prontidão

```powershell
cd lesson-6-a365-prereq\labs\solution

# Exibir a configuração atual e confirmar que agentBlueprintId está preenchido
a365 config display -g
```

Procure por `agentBlueprintId` — deve ser um UUID não vazio. Se estiver vazio, reexecute a configuração da Lição 6.

---

## Etapa 1: Executar `a365 publish`

Execute o comando de publicação a partir do diretório que contém o `a365.config.json`:

```powershell
cd lesson-6-a365-prereq\labs\solution
a365 publish
```

> **Nota:** `a365 publish` **não** aceita a flag `--config`. Ele sempre detecta automaticamente o `a365.config.json` no diretório de trabalho atual. Certifique-se de usar `cd` para o diretório correto antes de executar.

### O que o comando faz (em ordem)

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

---

## Etapa 2: Personalizar o Manifesto do Agente

Quando o CLI pausar, ele exibe saída semelhante a:

```
=== MANIFESTO ATUALIZADO ===
Localização: ...\manifest\manifest.json

=== PERSONALIZE O MANIFESTO DO SEU AGENTE ===
  Version ('version')          - incremente para republicar (ex: 1.0.0 → 1.0.1)
  Agent Name ('name.short')    - DEVE ter no máximo 30 caracteres
  Agent Name ('name.full')     - nome descritivo completo
  Descriptions                 - 'description.short' e 'description.full'
  Developer Info               - developer.name, websiteUrl, privacyUrl
  Icons                        - substitua color.png e outline.png

Abrir manifesto no editor padrão agora? (Y/n):
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
    "short": "Agente de IA para dados financeiros em tempo real.",
    "full": "Agente baseado em LangGraph que fornece preços de ações, notícias financeiras e insights de portfólio via plataforma Microsoft Agent 365."
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

Quando terminar de editar, volte ao terminal e digite:

```
continue
```

---

## Etapa 3: Verificar Publicação Bem-sucedida

### Saída esperada do CLI

```
✅ Upload succeeded
✅ Title access configured for all users
✅ Microsoft Graph permissions granted successfully
✅ Agent blueprint configuration completed successfully
✅ Publish completed successfully!
```

### Verificar arquivos de manifesto criados

```powershell
Test-Path lesson-6-a365-prereq\labs\solution\manifest\manifest.json   # → True
Test-Path lesson-6-a365-prereq\labs\solution\manifest\manifest.zip    # → True
```

### Verificar no Microsoft 365 Admin Center

1. Acesse [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Abra a aba **Registry**
3. Seu agente (ex: "Financial Market Agent") deve aparecer com **Disponibilidade: Todos os Usuários** ✅

> **Nota:** Pode levar **5–10 minutos** após a publicação para o agente aparecer. Atualize a página se não estiver visível.

### Verificar credenciais de identidade federada

1. [Portal Azure](https://portal.azure.com) → **Microsoft Entra ID** → **Registros de aplicativo** → buscar o app blueprint
2. **Certificados e segredos** → **Credenciais federadas**
3. Você deve ver **2 credenciais de identidade federada (FICs)** ✅

---

## Opções Disponíveis do `a365 publish`

```
a365 publish [opções]

Opções:
  --dry-run         Mostra alterações sem gravar arquivos ou chamar APIs
  --skip-graph      Pula identidade federada Graph e atribuições de função
  --mos-env <env>   Identificador de ambiente MOS (ex: prod, dev) [padrão: prod]
  --mos-token <t>   Substitui token pessoal MOS — ignora script e cache
  -v, --verbose     Habilita logging detalhado
```

**Exemplo dry-run** — visualizar o que aconteceria sem fazer alterações:

```powershell
a365 publish --dry-run
```

---

## Solução de Problemas

### Erro `Agent already exists`

**Causa:** O mesmo número de versão já está publicado.  
**Correção:** Incremente `version` em `manifest/manifest.json` e execute `a365 publish` novamente.

```json
"version": "1.0.1"
```

### Erro `Permissions missing`

**Causa:** Permissões do blueprint ou MCP não foram concluídas na configuração.  
**Correção:**
```powershell
cd lesson-6-a365-prereq\labs\solution
a365 setup permissions mcp --config a365.config.json
a365 setup permissions bot --config a365.config.json
a365 publish
```

### Agente não aparece no Admin Center após 10+ minutos

1. Verifique se todas as linhas ✅ apareceram na saída do CLI — se não, reexecute `a365 publish`
2. Use `admin.cloud.microsoft` (não `admin.microsoft.com`) — o registro de Agents está na nova URL
3. Confirme que está conectado ao tenant M365 correto no navegador
4. Verifique se `agentBlueprintId` em `a365.generated.config.json` não está vazio

### `manifest.json` com ID do blueprint faltando (mostra placeholder)

**Causa:** `a365 publish` foi executado antes de `a365 setup all` concluir com sucesso.  
**Correção:** Verifique se `a365.generated.config.json` tem `agentBlueprintId`, depois reexecute `a365 publish`.

---

## Comandos de Limpeza

```powershell
# Remove a identidade da instância do agente do Entra (se instâncias foram criadas na Lição 8)
a365 cleanup instance --config a365.config.json

# Remove o registro do blueprint do Entra (também remove do Admin Center)
a365 cleanup blueprint --config a365.config.json

# Remove recursos Azure (App Service, App Service Plan)
a365 cleanup azure --config a365.config.json
```

---

## Referência Rápida

| Comando | Finalidade |
|---------|------------|
| `a365 publish` | Empacotar e publicar agente no M365 Admin Center |
| `a365 publish --dry-run` | Visualizar alterações de publicação sem executar |
| `a365 config display -g` | Exibir configuração atual (verificar agentBlueprintId) |
| `a365 query-entra blueprint-scopes` | Listar escopos e status de consentimento do blueprint |
| `a365 cleanup blueprint` | Remover blueprint do Entra |
| `a365 cleanup instance` | Remover instância/usuário do agente do Entra |

---

## ❓ Perguntas Frequentes

**P: Preciso publicar novamente após alterar o código do agente?**  
R: Não. Alterações de código atrás da mesma URL de endpoint de mensagens têm efeito imediato. Republique apenas quando o manifesto mudar (nome, ícone, permissões) ou a URL do endpoint mudar.

**P: Preciso de aprovação de administrador antes que o agente apareça no Admin Center?**  
R: Não — `a365 publish` envia diretamente ao registro do Admin Center do tenant. No workshop, você é o administrador. A aprovação do administrador ocorre na *criação de instâncias* (Lição 8).

**P: Posso republicar sem deletar a versão antiga?**  
R: Sim. Incremente `version` em `manifest/manifest.json` e execute `a365 publish` novamente.

**P: E se eu precisar alterar a URL do endpoint de mensagens?**  
R: Execute o comando de atualização do endpoint primeiro, depois republique:
```powershell
a365 setup blueprint --endpoint-only --update-endpoint "https://nova-url/api/messages" --config a365.config.json
a365 publish
```

---

## Próximos Passos

**Lição 8**: Configure o agente no Teams Developer Portal, solicite uma instância do agente no Teams e comece a interagir com seu agente.

---

## Referências

- [Microsoft Agent 365 — Publicar no Admin Center](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/publish)
- [Ciclo de Vida do Desenvolvimento Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Referência CLI Agent 365 — comando publish](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/publish)
- [Microsoft 365 Admin Center — Registro de Agents](https://admin.cloud.microsoft/#/agents/all)
