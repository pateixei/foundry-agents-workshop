# Lição 8: Criando Instâncias do Agente no Microsoft Teams

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Configurar** o blueprint do agente no Teams Developer Portal
2. **Solicitar** uma instância do agente pelo Microsoft Teams
3. **Aprovar** a solicitação de instância como administrador M365
4. **Interagir** com o agente em um chat do Teams
5. **Monitorar** a atividade do agente no Microsoft 365 Admin Center
6. **Solucionar** problemas comuns de criação de instâncias

---

## Visão Geral

Após publicar o agente (Lição 7), os usuários podem solicitar **instâncias do agente** pelo Microsoft Teams. Uma instância do agente fornece ao agente sua própria identidade no Microsoft Entra (um "usuário agêntico") e o torna disponível como participante de chat no Teams — como um colega humano.

> **Mudança de design importante:** O comando CLI `a365 create-instance` foi **removido**. Ele ignorava etapas de registro necessárias para a funcionalidade completa do agente. A criação de instâncias agora é feita exclusivamente pela **UI do Microsoft Teams** e pelo **Microsoft 365 Admin Center**, seguindo o fluxo oficial de governança.

### O que é uma instância de agente?

| Conceito | Descrição |
|----------|-----------|
| **Blueprint** | O registro de app no Entra — o template que define o tipo do agente, permissões e configuração |
| **Instância** | Uma instanciação específica do blueprint — o agente recebe sua própria identidade de usuário no Entra |
| **Usuário agêntico** | Uma conta de usuário Entra para o agente (ex: `fin-market-agent@dominio.com`) — aparece no Teams como uma pessoa |

---

## Pré-requisitos

✅ **Lição 7 concluída** — `a365 publish` executou com sucesso  
✅ **Agente aparece no Admin Center** — visível em [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)  
✅ **`manifest/manifest.json`** existe em `lesson-6-a365-prereq\labs\solution\manifest\`  
✅ **Frontier habilitado** — seu tenant tem o preview Frontier habilitado para sua conta  
✅ **Microsoft Teams** instalado (desktop ou web)  
✅ **Acesso de Global Administrator** (necessário para aprovar solicitações de instâncias)

---

## Etapa 1: Obter o ID do Blueprint

Você precisará do ID do blueprint em vários lugares nesta lição.

```powershell
cd lesson-6-a365-prereq\labs\solution
a365 config display -g
```

Copie o valor de `agentBlueprintId` da saída. Ele se parecerá com:

```
agentBlueprintId: 809bce64-ea7f-4f64-94b1-6f0c582b2f21
```

---

## Etapa 2: Configurar o Agente no Teams Developer Portal

Antes de criar instâncias, você deve configurar o blueprint do agente no Teams Developer Portal para conectá-lo à infraestrutura de mensagens do Microsoft 365. Sem esta etapa, o agente não receberá mensagens do Teams.

1. **Abra a página de configuração do Developer Portal:**

   ```
   https://dev.teams.microsoft.com/tools/agent-blueprint/<seu-blueprint-id>/configuration
   ```

   Substitua `<seu-blueprint-id>` pelo `agentBlueprintId` copiado na Etapa 1.

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

## Etapa 3: Solicitar uma Instância do Agente no Teams

1. Abra o **Microsoft Teams** (desktop ou web)

2. Clique no ícone **Apps** na barra lateral esquerda (ou use a barra de pesquisa)

3. Pesquise seu agente pelo nome — ex: `Financial Market Agent`

4. Clique no cartão do agente

5. Clique em **Request Instance** (ou **Create Instance** se disponível diretamente)

6. Opcionalmente, insira um nome de exibição personalizado para sua instância

7. Confirme — isso envia uma **solicitação de aprovação ao administrador do tenant**

> **Nota:** O processo de criação de instâncias é assíncrono. Após a aprovação do administrador, a conta de usuário do agente é criada no Entra e o agente fica disponível no Teams. Pode levar alguns minutos a algumas horas.

---

## Etapa 4: Aprovar a Solicitação de Instância (Admin)

Como administrador, aprove a solicitação pendente:

1. Acesse [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
2. Encontre a solicitação pendente do seu agente
3. Revise as permissões e detalhes
4. Clique em **Approve**

Após a aprovação:
- A conta de usuário agêntico é criada no Microsoft Entra
- O agente torna-se pesquisável e disponível para chat no Teams
- O agente aparece em **All Agents** no Admin Center

---

## Etapa 5: Testar o Agente no Teams

> **Nota:** Após a aprovação do administrador, pode levar **alguns minutos a algumas horas** para que o usuário agêntico fique pesquisável no Teams. Este é um processo assíncrono em segundo plano.

1. No Microsoft Teams, pesquise o nome de exibição do agente na barra de **Pesquisa** ou em **Novo Chat**

2. Abra um chat com o agente

3. Envie uma mensagem de teste — por exemplo:
   ```
   Qual é a cotação atual da MSFT?
   ```

4. Verifique se o agente responde corretamente:
   - O agente mostra indicador de digitação
   - O agente responde em alguns segundos
   - A resposta inclui dados financeiros relevantes

### Exemplo de conversa

```
Você: Qual é o preço atual da AAPL?

Financial Market Agent:
📈 Apple Inc. (AAPL)
Preço atual: US$ 178,42
Variação: +2,34 (+1,33%)
[Dados dos últimos 30 dias solicitados...]
```

---

## Etapa 6: Monitorar no Admin Center

Após sua instância do agente estar criada e ativa:

1. Acesse [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Selecione seu agente
3. Abra a aba **Activity**

Você deverá ver:
- ✅ Sessões listadas com timestamps
- ✅ Cada sessão mostra gatilhos e ações executadas
- ✅ Chamadas de ferramentas registradas com timestamps

---

## Monitoramento da Saúde do Agente

### Verificar logs do Azure Container App

```powershell
az containerapp logs show `
  --name aca-lg-agent `
  --resource-group <seu-resource-group> `
  --follow
```

Procure por:
- ✅ Requisições recebidas do Teams (`POST /api/messages`)
- ✅ Autenticação bem-sucedida
- ✅ Chamadas de ferramentas sendo executadas
- ❌ Mensagens de erro ou exceções

### Verificar saúde do endpoint de mensagens

```powershell
curl https://aca-lg-agent.purplerock-e895e6b1.eastus.azurecontainerapps.io/health
# Esperado: {"status": "ok"} ou HTTP 200
```

### Consultar escopos e status de consentimento no Entra

```powershell
cd lesson-6-a365-prereq\labs\solution

# Verificar escopos do blueprint
a365 query-entra blueprint-scopes --config a365.config.json

# Verificar escopos da instância (após criação)
a365 query-entra instance-scopes --config a365.config.json
```

---

## Gerenciamento do Ciclo de Vida das Instâncias

### Comandos CLI (apenas recursos Entra)

```powershell
# Remove identidade e usuário da instância do Entra
a365 cleanup instance --config a365.config.json

# Remove blueprint e service principal do Entra
a365 cleanup blueprint --config a365.config.json
```

> **Nota:** Esses comandos CLI removem apenas recursos do Entra. Para remover a instância do agente do Teams de um usuário, o usuário deve remover o chat (ou o admin pode remover o app de todos os usuários pelo Teams Admin Center).

### Gerenciamento pelo Admin Center

Todas as ações do ciclo de vida das instâncias (suspender, retomar, excluir, revisar permissões) são gerenciadas pelo Admin Center:

- **Todos os agentes:** [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
- **Agentes solicitados:** [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
- **Teams Admin Center:** [https://admin.teams.microsoft.com](https://admin.teams.microsoft.com) → Apps do Teams → Gerenciar apps

---

## Solução de Problemas

### Agente não aparece na pesquisa do Teams

**Sintoma:** Agente publicado com sucesso, mas não aparece na pesquisa de Apps do Teams.

**Causa raiz:** Configuração do Developer Portal ausente ou não salva.

**Solução:**
1. Obtenha o ID do blueprint:
   ```powershell
   a365 config display -g
   # Copie agentBlueprintId
   ```
2. Acesse `https://dev.teams.microsoft.com/tools/agent-blueprint/<blueprint-id>/configuration`
3. Defina Agent Type → `Bot Based`, Bot ID → blueprint ID, clique em **Save**
4. Aguarde 5–10 minutos e pesquise novamente no Teams

---

### Botão "Request Instance" não funciona

**Sintoma:** Agente aparece em Apps do Teams, mas não pode ser adicionado; botão está desativado.

**Causa raiz:** Microsoft Agent 365 Frontier não está habilitado para o tenant ou usuário.

**Solução:**
1. No Admin Center M365, acesse **Configurações** → **Copilot** → **Frontier**
2. Verifique se seu usuário está incluído na lista de acesso ao Frontier
3. Entre em contato com o administrador do tenant se o acesso precisar ser concedido

---

### Agente não responde a mensagens

**Sintoma:** Instância criada, agente visível no Teams, mas mensagens ficam sem resposta.

**Checklist:**
1. Verifique se o Azure Container App está em execução:
   ```powershell
   az containerapp show `
     --name aca-lg-agent `
     --resource-group <seu-resource-group> `
     --query "properties.runningStatus"
   # Esperado: "Running"
   ```
2. Confirme que o endpoint está acessível:
   ```powershell
   curl https://aca-lg-agent.purplerock-e895e6b1.eastus.azurecontainerapps.io/health
   ```
3. Verifique os logs do Container App em busca de erros
4. Verifique se a configuração do Developer Portal foi salva (Etapa 2)

---

### Atribuição de licença falha

**Sintoma:** Admin Center mostra erro ao aprovar solicitação de instância — licença não pode ser atribuída.

**Causa:** Licenças insuficientes ou tipo de licença incorreto.

**Solução:**
1. Verifique **Admin Center M365** → **Cobrança** → **Licenças** — confirme licenças disponíveis
2. Certifique-se de que **Microsoft 365 Copilot** está licenciado para o tenant (necessário para Frontier/Agent 365)
3. Atribua licença manualmente ao usuário agêntico: **Usuários** → encontre o usuário do agente → atribua Microsoft 365 E5 / Teams Enterprise / M365 Copilot

---

### `query-entra instance-scopes` retorna `Request_ResourceNotFound`

**Sintoma:** Ao executar `a365 query-entra instance-scopes --config a365.config.json`, a saída exibe:

```
ERROR: Not Found({"error":{"code":"Request_ResourceNotFound","message":"Resource '' does not exist..."}})
No OAuth2 permission grants found
```

**Causa raiz:** O usuário agêntico ou service principal encontrado no Entra não possui registros de concessão de permissão OAuth2. Isso acontece quando o setup do A365 não foi concluído (`botMessagingEndpoint: null`, `completed: false`). Causas comuns:

1. **`location` ou `resourceGroup` ausentes no `a365.config.json`** — o backend Frontier requer esses campos para registrar o messaging endpoint, mesmo com `needDeployment: false`. Sem eles, `a365 setup blueprint --endpoint-only` falha com `400 BadRequest: Location is required`, deixando `botMessagingEndpoint: null` e `completed: false`.
2. **Consentimento do administrador nunca foi concedido** durante o setup — o service principal foi criado mas as permissões não foram aplicadas.
3. **Nenhuma instância criada ainda** — `AgenticAppId` e `AgenticUserId` são `null` em `a365.generated.config.json`. Este comando só é relevante após a criação de uma instância pela UI do Teams.

**Solução:**

1. Primeiro, verifique se `a365.config.json` contém os campos obrigatórios:
   ```json
   "resourceGroup": "<seu-resource-group>",
   "location": "<sua-regiao-azure>"
   ```
   Se estiverem ausentes, adicione-os — obrigatórios mesmo com `needDeployment: false`.

2. Confirme o status de conclusão do setup:
   ```powershell
   a365 config display -g
   # Verifique: completed: true e botMessagingEndpoint não é nulo
   ```
3. Se `completed: false`, re-execute o registro do endpoint e as permissões:
   ```powershell
   a365 setup blueprint --endpoint-only
   a365 setup permissions mcp
   a365 setup permissions bot
   ```
4. Se o setup foi concluído mas o consentimento ainda está ausente, conceda manualmente:
   - Acesse o [Portal do Azure](https://portal.azure.com) → **Microsoft Entra ID** → **Registros de aplicativo**
   - Localize o app **Financial Market Agent Blueprint**
   - Vá em **Permissões de API** → clique em **Conceder consentimento do administrador para \<tenant\>**
5. Execute o comando novamente para confirmar que as concessões estão presentes:
   ```powershell
   a365 query-entra instance-scopes --config a365.config.json
   ```

> **Observação:** Se nenhuma instância foi criada ainda (`AgenticAppId: null` em `a365.generated.config.json`), esse erro é esperado — o comando retornará dados significativos somente após a criação de uma instância pela UI do Teams e aprovação pelo administrador (Etapas 3–4).

---

## Cenários de Teste

### Cenário 1: Consulta financeira básica

```
Você: Qual é o preço atual da MSFT?
Agente: [Usa ferramenta de preço de ações, retorna dados de preço e variação]

Você: Como isso se compara à semana passada?
Agente: [Usa contexto do turno anterior para responder comparativamente]
```

**Verificar:** Contexto de múltiplos turnos é mantido.

### Cenário 2: Tratamento de erros

| Entrada | Comportamento Esperado |
|---------|----------------------|
| Ticker desconhecido (`XYZINVALID`) | Gracioso: "Símbolo não encontrado" |
| Solicitação vaga (`Está bom?`) | Esclarecimento: "Sobre qual ação você está perguntando?" |
| Fora do escopo (`Conte uma piada`) | Redirecionamento: "Especializo-me em informações financeiras" |

### Cenário 3: Auditoria de execução de ferramentas

Após enviar uma solicitação que usa ferramentas (consulta de preço de ações):

1. Acesse Admin Center → seu agente → aba **Activity**
2. Verifique se as chamadas de ferramentas estão registradas com timestamps e entradas/saídas

---

## Referência Rápida

| Ação | Onde |
|------|------|
| Obter ID do blueprint | `a365 config display -g` |
| Configurar para Teams | `https://dev.teams.microsoft.com/tools/agent-blueprint/<id>/configuration` |
| Solicitar instância | Microsoft Teams → Apps → Pesquisar → Request Instance |
| Aprovar solicitação | [admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested) |
| Ver todos os agentes | [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all) |
| Verificar escopos | `a365 query-entra blueprint-scopes` |
| Remover instância | `a365 cleanup instance --config a365.config.json` |
| Remover blueprint | `a365 cleanup blueprint --config a365.config.json` |

---

## ❓ Perguntas Frequentes

**P: Por que `a365 create-instance` foi removido?**  
R: Ele ignorava etapas de registro necessárias (configuração do Developer Portal, fluxo de aprovação do administrador) para que os agentes recebam mensagens e operem com governança completa. A criação de instâncias pelo Teams garante que essas etapas sejam sempre concluídas. O comando pode retornar em versão futura.

**P: Quanto tempo leva a criação da instância?**  
R: A aprovação do administrador é rápida (alguns minutos). Criar o usuário agêntico no Entra e propagá-lo pelo Teams pode levar alguns minutos a algumas horas. Se não estiver pesquisável após 2 horas, verifique se o usuário foi criado no Entra.

**P: Os membros da equipe podem ver minhas conversas?**  
R: Não. Cada usuário tem um chat 1 a 1 com o agente. O histórico de conversa é privado para aquele usuário.

**P: O que acontece se eu reimplantar o Azure Container Apps com uma nova URL?**  
R: Você precisa atualizar o endpoint de mensagens e republicar:
```powershell
a365 setup blueprint --endpoint-only --update-endpoint "https://nova-url/api/messages" --config a365.config.json
a365 publish
```

**P: E se o ACA escalar para zero (cold start)?**  
R: Se `minReplicas: 0`, a primeira mensagem após um período inativo aciona um cold start (5–30 segundos). Defina `minReplicas: 1` para disponibilidade contínua.

**P: Como remover completamente uma instância do agente?**  
R: Use `a365 cleanup instance` para remover a identidade do Entra. Os usuários também precisam remover o chat do Teams manualmente (ou o admin pode remover o app de todos os usuários pelo Teams Admin Center).

---

## Próximos Passos

🎉 **Parabéns — seu agente está ativo no Microsoft Teams!**

Continue explorando:
- Adicione mais ferramentas ao agente (calendário, SharePoint, email via servidores MCP)
- Configure CI/CD com `a365 deploy` para implantações automatizadas
- Explore dashboards de observabilidade na aba Activity do Admin Center
- Adicione o Agent 365 SDK ao agente para notificações e telemetria mais rica

---

## Referências

- [Microsoft Agent 365 — Criar Instâncias de Agentes](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/create-instance)
- [Ciclo de Vida do Desenvolvimento Agent 365](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [CLI Agent 365 — Remoção do `create-instance`](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli#important-updates)
- [Microsoft 365 Admin Center — Agents](https://admin.cloud.microsoft/#/agents/all)
- [Teams Developer Portal](https://dev.teams.microsoft.com)
- [Agent 365 GitHub Samples](https://github.com/microsoft/Agent365-Samples)
