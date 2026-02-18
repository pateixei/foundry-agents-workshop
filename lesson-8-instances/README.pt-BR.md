# Lição 8: Criando Instâncias de Agente no Microsoft Teams

> 🇺🇸 **[Read in English](README.md)**

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:
1. **Criar** instâncias de agente no Microsoft Teams (pessoal e compartilhada)
2. **Compreender** a diferença entre instâncias pessoal, compartilhada e organizacional
3. **Testar** a experiência do usuário final com conversas multi-turno no Teams
4. **Gerenciar** o ciclo de vida da instância (criar, suspender, retomar, excluir)
5. **Configurar** definições da instância e personalizar o comportamento
6. **Resolver problemas** comuns de criação e interação de instâncias

---

## Visão Geral

Após publicar seu agente no M365 Admin Center (Lição 7), os usuários podem criar **instâncias** do seu agente no Microsoft Teams. Uma instância de agente é uma implantação dedicada do seu agente com a qual os usuários interagem por meio da interface do Teams.

> **Pense assim**: Agente publicado = App na loja de aplicativos. Instância = App instalado no seu celular.

Nesta lição, você aprenderá como:
- Criar instâncias de agente pessoais e compartilhadas
- Configurar as definições da instância
- Testar seu agente no Teams
- Gerenciar o ciclo de vida da instância (suspender, retomar, excluir)
- Resolver problemas comuns na criação de instâncias

---

## Tipos de Instância

| Tipo | Escopo | Caso de Uso | Quem Cria | Isolamento |
|------|--------|-------------|-----------|------------|
| **Personal** | Usuário individual | Pesquisa privada, tarefas pessoais | Usuário final | Histórico de conversas totalmente isolado |
| **Shared** | Equipe/Canal | Fluxos de trabalho colaborativos, visibilidade da equipe | Proprietário da equipe | Contexto compartilhado entre membros da equipe |
| **Org-wide** | Todos os usuários | Serviços de toda a empresa (helpdesk de TI, RH) | Administrador M365 | Acesso em nível organizacional |

> Cada instância é **isolada** — histórico de conversas separado, identidade separada. Uma Personal instance não sabe sobre conversas do canal, e vice-versa.

## Pré-requisitos

✅ **Lições 1-7 concluídas**
✅ **Agente Publicado** no M365 Admin Center e aprovado pelo administrador
✅ **Agente Implantado** para usuários ou grupos
✅ **Microsoft Teams** instalado (desktop ou web)
✅ **A365 CLI** instalado e configurado
✅ **Permissões** para criar instâncias de agente na sua organização

## O que é uma Instância de Agente?

Uma **instância de agente** é uma implantação dedicada do seu agente publicado que:
- Executa dentro do Microsoft Teams
- Possui suas próprias configurações e definições
- Pode ser pessoal (para uso individual) ou compartilhada (para colaboração em equipe)
- Mantém histórico de conversação e estado separados
- Pode ser suspensa, retomada ou excluída independentemente

### Instância Pessoal vs. Instância Compartilhada

| Recurso | Instância Pessoal | Instância Compartilhada |
|---------|-------------------|-------------------------|
| **Visibilidade** | Visível apenas para o criador | Visível para membros da equipe |
| **Caso de Uso** | Produtividade individual | Colaboração em equipe |
| **Conversas** | Privadas para o usuário | Acessíveis pela equipe |
| **Gerenciamento** | Apenas o usuário | Proprietários da equipe |
| **Comando de Criação** | `a365 create-instance` | `a365 create-instance --shared` |

## Guia Passo a Passo

### Passo 1: Verificar o Status de Publicação do Agente

Antes de criar instâncias, verifique se seu agente está publicado e implantado:

```powershell
# Switch to PowerShell 7 (required for A365 CLI)
pwsh

# Navigate to your A365 config directory
cd c:\Cloud\Code\a365-workshop\lesson-5-a365-prereq

# Check publication status
a365 publish status
```

**Saída Esperada:**
```
Agent Blueprint: Financial Market Agent Blueprint
Status: Published
Published Date: 2025-01-15T10:30:00Z
Approval Status: Approved
Deployment Scope: All Users
```

Se o status mostrar `Not Published` ou `Pending Approval`, conclua a Lição 7 primeiro.

---

### Passo 2: Listar Blueprints de Agente Disponíveis

Veja todos os agentes publicados disponíveis na sua organização:

```powershell
# List all published agents
a365 list blueprints
```

**Saída Esperada:**
```
Agent Blueprints:
1. Financial Market Agent Blueprint
   - ID: 856d0c29-2359-4401-955f-b6f7e4396c58
   - Status: Published
   - Deployment: All Users
   
2. HR Assistant Agent
   - ID: 7a8b9c0d-1234-5678-90ab-cdef12345678
   - Status: Published
   - Deployment: HR Department
```

Anote o **Blueprint ID** do seu agente — você precisará dele para a criação da instância.

---

### Passo 3: Criar uma Instância Pessoal de Agente

Crie uma instância pessoal para uso individual:

```powershell
# Create personal instance
a365 create-instance `
  --blueprint-id "856d0c29-2359-4401-955f-b6f7e4396c58" `
  --display-name "My Financial Market Agent" `
  --description "Personal agent for stock market research" `
  --instance-type personal
```

**Parâmetros do Comando:**
- `--blueprint-id`: O ID do blueprint do seu agente publicado
- `--display-name`: Nome amigável para sua instância (aparece no Teams)
- `--description`: Breve descrição do propósito da instância
- `--instance-type`: `personal` para uso individual

**Saída Esperada:**
```
Creating agent instance...
✓ Instance created successfully

Instance Details:
- Instance ID: 3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f
- Display Name: My Financial Market Agent
- Type: Personal
- Status: Active
- Created: 2025-01-15T14:30:00Z

Next Steps:
1. Open Microsoft Teams
2. Search for "My Financial Market Agent" in the Apps section
3. Start chatting with your agent
```

---

### Passo 4: Criar uma Instância Compartilhada de Agente (Opcional)

Para colaboração em equipe, crie uma instância compartilhada:

```powershell
# Create shared instance
a365 create-instance `
  --blueprint-id "856d0c29-2359-4401-955f-b6f7e4396c58" `
  --display-name "Team Financial Research Agent" `
  --description "Shared agent for team market analysis" `
  --instance-type shared `
  --team-id "19:abc123def456@thread.tacv2"
```

**Parâmetros Adicionais para Instâncias Compartilhadas:**
- `--team-id`: O ID do canal do Teams onde o agente ficará disponível
- `--team-owners`: (Opcional) Lista separada por vírgulas de IDs de usuários que podem gerenciar a instância

**Para Obter o Team ID:**
1. Abra o Microsoft Teams
2. Navegue até sua equipe
3. Clique nos três pontos (...) ao lado do nome do canal
4. Selecione "Obter link para o canal"
5. Extraia o team ID da URL

**Saída Esperada:**
```
Creating shared agent instance...
✓ Instance created successfully
✓ Agent added to team channel

Instance Details:
- Instance ID: 8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f
- Display Name: Team Financial Research Agent
- Type: Shared
- Team: Marketing Team
- Status: Active
- Created: 2025-01-15T14:45:00Z

All team members can now access the agent in the channel.
```

---

### Passo 5: Verificar Criação da Instância

Liste todas as instâncias criadas:

```powershell
# List all instances
a365 list instances
```

**Saída Esperada:**
```
Agent Instances:
1. My Financial Market Agent
   - Instance ID: 3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f
   - Type: Personal
   - Status: Active
   - Created: 2025-01-15T14:30:00Z
   
2. Team Financial Research Agent
   - Instance ID: 8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f
   - Type: Shared
   - Team: Marketing Team
   - Status: Active
   - Created: 2025-01-15T14:45:00Z
```

**Obter informações detalhadas sobre uma instância específica:**

```powershell
# Get instance details
a365 get-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

---

### Passo 6: Testar Seu Agente no Microsoft Teams

#### Testando a Instância Pessoal

1. **Abra o Microsoft Teams** (aplicativo desktop ou web)

2. **Navegue até Aplicativos:**
   - Clique no ícone **Aplicativos** na barra lateral esquerda
   - Ou pesquise diretamente na barra de pesquisa do Teams

3. **Encontre Seu Agente:**
   - Pesquise por "My Financial Market Agent"
   - Clique no cartão do agente

4. **Comece a Conversar:**
   - Clique em "Adicionar" para adicionar o agente à sua lista de chats
   - Clique em "Chat" para abrir uma conversa
   - Digite sua primeira mensagem: `What's the current price of AAPL stock?`

5. **Verifique a Resposta do Agente:**
   - O agente deve responder com dados de preço da ação
   - A resposta pode incluir Adaptive Card com formatação rica
   - Verifique a execução adequada da ferramenta (consulta de preço de ação)

**Exemplo de Conversa:**

```
You: What's the current price of AAPL stock?

Financial Market Agent:
📈 Apple Inc. (AAPL)
Current Price: $178.42
Change: +2.34 (+1.33%)
Last Updated: 2025-01-15 14:50 EST

[View Chart] [Get Details]
```

#### Testando a Instância Compartilhada

1. **Navegue até o Canal da Sua Equipe:**
   - Abra a equipe onde você criou a instância compartilhada
   - Selecione o canal

2. **Acesse o Agente:**
   - O agente deve aparecer na lista de aplicativos do canal
   - Ou mencione o agente: `@Team Financial Research Agent`

3. **Colaboração em Equipe:**
   - Todos os membros da equipe podem interagir com o mesmo agente
   - O histórico de conversas é visível para a equipe
   - O agente mantém contexto entre as conversas da equipe

---

### Passo 7: Configurar Definições da Instância (Avançado)

Personalize o comportamento da sua instância:

```powershell
# Update instance display name
a365 update-instance `
  --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f" `
  --display-name "Financial Markets AI Assistant"

# Update instance description
a365 update-instance `
  --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f" `
  --description "AI-powered agent for real-time financial data and analysis"

# Configure instance settings (if supported)
a365 configure-instance `
  --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f" `
  --settings '{"max_conversation_length": 100, "enable_notifications": true}'
```

**Configurações Disponíveis** (podem variar por agente):
- `max_conversation_length`: Número máximo de mensagens a reter no contexto
- `enable_notifications`: Permitir notificações proativas
- `response_timeout`: Tempo limite para respostas do agente (segundos)
- `tool_settings`: Configuração para ferramentas específicas

---

## Gerenciamento do Ciclo de Vida da Instância

### Suspender Instância

Desabilite temporariamente uma instância sem excluí-la:

```powershell
# Suspend instance
a365 suspend-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Quando suspender:**
- Manutenção temporária
- Atualizações do endpoint do agente
- Teste de nova versão do agente
- Investigação de problemas

**Saída Esperada:**
```
Suspending agent instance...
✓ Instance suspended successfully

Instance Status: Suspended
Users cannot interact with the agent until it's resumed.
```

---

### Retomar Instância

Reative uma instância suspensa:

```powershell
# Resume instance
a365 resume-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Saída Esperada:**
```
Resuming agent instance...
✓ Instance resumed successfully

Instance Status: Active
Users can now interact with the agent.
```

---

### Excluir Instância

Remova permanentemente uma instância:

```powershell
# Delete instance
a365 delete-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Aviso:** Esta ação é **permanente** e irá:
- Excluir todo o histórico de conversas
- Remover o agente do Teams
- Revogar o acesso dos usuários
- Não pode ser desfeita

**Saída Esperada:**
```
⚠️  Warning: This will permanently delete the instance and all data.
Type 'yes' to confirm: yes

Deleting agent instance...
✓ Instance deleted successfully

The agent has been removed from Teams.
```

---

## Troubleshooting

### Problema 1: Não é Possível Encontrar o Agente no Teams

**Sintomas:**
- O agente não aparece na seção Aplicativos do Teams
- A pesquisa não retorna resultados
- O botão "Adicionar" está desabilitado

**Soluções:**

1. **Verificar Implantação:**
   ```powershell
   a365 publish status
   ```
   - Certifique-se de que o status é `Published` e `Approved`
   - Verifique se o escopo de implantação inclui você ou seu grupo

2. **Verificar Status da Instância:**
   ```powershell
   a365 list instances
   ```
   - Verifique se o status da instância é `Active` (não `Suspended`)

3. **Atualizar o Teams:**
   - Saia do Teams
   - Entre novamente
   - Limpe o cache do Teams: `%appdata%\Microsoft\Teams\Cache`

4. **Aguardar Propagação:**
   - Novas instâncias podem levar de 5 a 10 minutos para aparecer
   - Atrasos na sincronização do diretório M365 podem estender esse tempo

5. **Verificar Permissões:**
   - Verifique com o administrador do M365 se você tem acesso
   - Confirme se as políticas organizacionais permitem agentes personalizados

---

### Problema 2: Agente Não Responde

**Sintomas:**
- O agente aparece no Teams, mas não responde
- Mensagens mostram "Falha ao enviar"
- Erros de tempo limite

**Soluções:**

1. **Verificar Endpoint de Mensagens:**
   ```powershell
   # Verify endpoint is accessible
   curl https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/health
   ```
   - Deve retornar `{"status": "ok"}`

2. **Verificar Azure Container App:**
   ```powershell
   az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.runningStatus"
   ```
   - Deve retornar `"Running"`

3. **Verificar Application Insights:**
   - Navegue até Application Insights no Azure Portal
   - Procure por requisições com falha em `/api/messages`
   - Revise os rastreamentos de exceção

4. **Verificar Logs do Agente:**
   ```powershell
   az containerapp logs show --name aca-lg-agent --resource-group rg-ag365sdk --follow
   ```

5. **Verificar Configuração do Bot Framework:**
   - Certifique-se de que o endpoint `/api/messages` está implementado
   - Verifique o tratamento de Activity do Bot Framework
   - Confirme a geração de Adaptive Card

---

### Problema 3: Falha na Criação da Instância

**Sintomas:**
- O comando `a365 create-instance` falha
- Erro: "Blueprint not found"
- Erro: "Insufficient permissions"

**Soluções:**

1. **Verificar Blueprint ID:**
   ```powershell
   a365 list blueprints
   ```
   - Certifique-se de que o blueprint ID corresponde ao agente publicado

2. **Verificar Permissões:**
   - Confirme que você possui a permissão `Agent.Create`
   - Entre em contato com o administrador do M365 para conceder permissões

3. **Validar Configuração:**
   ```powershell
   a365 config display
   ```
   - Certifique-se de que o tenant ID e o client app ID estão corretos

4. **Verificar Versão do PowerShell:**
   ```powershell
   $PSVersionTable.PSVersion
   ```
   - Deve ser PowerShell 7.0 ou superior

5. **Reautenticar:**
   ```powershell
   az logout
   az login --tenant 08f651c3-3144-498c-a5e3-9345be97f2e3 --allow-no-subscriptions
   ```

---

### Problema 4: Instância Compartilhada Não Visível para a Equipe

**Sintomas:**
- Instância compartilhada criada com sucesso
- Apenas o criador pode ver o agente
- Membros da equipe não conseguem acessar

**Soluções:**

1. **Verificar Team ID:**
   - Certifique-se de que o team ID correto foi usado durante a criação
   - Verifique se o canal existe e está ativo

2. **Verificar Permissões da Equipe:**
   - Confirme que os membros da equipe possuem as funções apropriadas
   - Certifique-se de que as políticas organizacionais permitem agentes compartilhados

3. **Adicionar Agente ao Canal:**
   ```powershell
   a365 add-to-channel `
     --instance-id "8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f" `
     --channel-id "19:abc123def456@thread.tacv2"
   ```

4. **Notificar Membros da Equipe:**
   - Envie um anúncio no canal do Teams
   - Inclua instruções para acessar o agente

---

## Melhores Práticas

### 1. Convenções de Nomenclatura
- Use nomes claros e descritivos: `Team Sales Agent` em vez de `Agent 1`
- Inclua o propósito na descrição: `Analisa dados de vendas e gera relatórios`
- Siga os padrões de nomenclatura da organização

### 2. Gerenciamento de Instâncias
- **Comece Pequeno:** Crie instâncias pessoais primeiro para teste
- **Monitore o Uso:** Acompanhe instâncias ativas para evitar proliferação
- **Faça Limpeza:** Exclua instâncias não utilizadas para liberar recursos
- **Documente:** Mantenha uma lista de instâncias e seus propósitos

### 3. Integração de Usuários
- **Forneça Treinamento:** Crie guias de início rápido para os usuários
- **Defina Expectativas:** Explique as capacidades e limitações do agente
- **Colete Feedback:** Recolha feedback dos usuários para melhorias
- **Canais de Suporte:** Estabeleça um processo de suporte para problemas

### 4. Segurança e Conformidade
- **Revise Permissões:** Audite regularmente quem pode criar instâncias
- **Monitore Conversas:** Implemente registro para conformidade
- **Privacidade de Dados:** Garanta que o agente trate dados sensíveis adequadamente
- **Controle de Acesso:** Use instâncias compartilhadas apenas quando apropriado

### 5. Otimização de Desempenho
- **Monitore Latência:** Acompanhe tempos de resposta no Application Insights
- **Escale Recursos:** Aumente réplicas do ACA se necessário
- **Cache de Dados:** Implemente cache para dados acessados frequentemente
- **Otimize Ferramentas:** Profile e otimize funções de ferramentas lentas

---

## Monitoramento e Análise

### Visualizar Uso da Instância

Acompanhe como os usuários interagem com seu agente:

```powershell
# Get usage statistics
a365 get-usage --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Métricas Disponíveis:**
- Total de conversas
- Total de mensagens enviadas/recebidas
- Tempo médio de resposta
- Ferramentas/recursos mais utilizados
- Taxas de erro
- Usuários ativos

### Application Insights

Monitore o desempenho do agente no Azure Portal:

1. **Navegue até Application Insights:**
   - Azure Portal → Resource Groups → `rg-ag365sdk`
   - Selecione o recurso Application Insights

2. **Métricas Principais a Monitorar:**
   - **Requests:** Total de requisições para `/api/messages`
   - **Response Time:** Latências P50, P95, P99
   - **Failures:** Requisições com falha e exceções
   - **Dependencies:** Chamadas de API externas (preços de ações, etc.)
   - **Custom Events:** Execuções de ferramentas, gerações de Adaptive Card

3. **Criar Alertas:**
   - Taxa de erro alta (>5%)
   - Tempo de resposta lento (>2 segundos)
   - Disponibilidade do serviço (<99%)

### Teams Admin Center

Visualize o uso organizacional do agente:

1. Navegue até [Teams Admin Center](https://admin.teams.microsoft.com)
2. Vá para **Teams apps → Manage apps**
3. Encontre seu agente
4. Visualize a análise:
   - Usuários ativos
   - Total de instalações
   - Tendências de uso
   - Feedback dos usuários

---

## Próximos Passos

Parabéns! Você concluiu o Workshop de Agentes do Azure AI Foundry. 🎉

### Continue Aprendendo

1. **Explore Recursos Avançados:**
   - Conversas multi-turno com memória
   - Notificações proativas
   - Integração com outros serviços M365 (SharePoint, Outlook)
   - Adaptive Cards personalizados

2. **Melhore Seu Agente:**
   - Adicione mais ferramentas (clima, notícias, calendário)
   - Implemente tratamento de erros e lógica de retry
   - Adicione autenticação para operações sensíveis
   - Otimize desempenho e custos

3. **Escale Sua Implantação:**
   - Implante múltiplos agentes para diferentes casos de uso
   - Implemente pipeline de CI/CD para implantações automatizadas
   - Crie templates de agente para implantação rápida
   - Construa governança empresarial de agentes

4. **Saiba Mais:**
   - [Microsoft Agent 365 Documentation](https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/agents)
   - [Azure AI Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-services/)
   - [Bot Framework Documentation](https://learn.microsoft.com/en-us/azure/bot-service/)
   - [Teams App Development](https://learn.microsoft.com/en-us/microsoftteams/platform/)

---

## Cenários de Teste para Usuário Final

Após criar instâncias, simule o uso real para validar o fluxo completo.

### Cenário 1: Fluxo de Pesquisa Pessoal

Teste pesquisa em múltiplos passos na sua Personal instance:

```
You: I'm considering investing in cloud computing stocks.
     Can you provide prices for MSFT, GOOGL, and AMZN?

Agent: [Calls tools for each stock, returns prices]

You: Which has the best growth potential?

Agent: [Provides comparative analysis using context from previous question]
```

**Verificar**: O agente recupera múltiplos preços, fornece comparação e mantém o contexto da conversa.

### Cenário 2: Colaboração em Equipe

Em uma Shared instance de canal, faça múltiplos membros da equipe interagirem:

```
Member 1: @Financial Advisor What are the top 3 tech stocks by market cap?
Member 2: @Financial Advisor What's the PE ratio for these stocks?
Member 3: @Financial Advisor Based on current trends, which would you recommend?
```

**Verificar**: O agente responde a diferentes membros e mantém o contexto compartilhado.

### Cenário 3: Tratamento de Erros

Teste a robustez do agente com casos extremos:

| Entrada | Comportamento Esperado |
|---------|------------------------|
| Símbolo de ação inválido (`INVALID`) | Erro gracioso: "I couldn't find that symbol" |
| Solicitação ambígua (`Is it good?`) | Pergunta de esclarecimento: "What stock are you asking about?" |
| Fora do escopo (`Tell me a joke`) | Redirecionamento: "I specialize in financial information" |
| Mensagem vazia | Tratamento gracioso sem falha |

### Cenário 4: Adaptive Cards (se implementado na Lição 6)

```
You: Show me a dashboard for AAPL
```

**Verificar**: O agente retorna Adaptive Card com ticker da ação, preço, variação % e botões de ação.

---

## ❓ Perguntas Frequentes

**P: Qual a diferença entre excluir uma instância e despublicar?**
R: Excluir uma instância remove a implantação de um usuário/equipe (histórico de conversas é perdido). Despublicar remove o agente do catálogo globalmente (nenhuma nova instância pode ser criada, as existentes continuam funcionando).

**P: Posso atualizar o código do meu agente sem afetar as instâncias?**
R: Sim! As instâncias apontam para o endpoint de mensagens. Quando você reimplanta o ACA com novo código (mesmo FQDN), todas as instâncias recebem automaticamente a nova versão.

**P: Quanto tempo leva para uma nova instância aparecer no Teams?**
R: Instâncias pessoais aparecem em 1-2 minutos. Instâncias compartilhadas podem levar de 5 a 10 minutos devido à sincronização do diretório M365. Se não estiver visível após 15 minutos, tente sair e entrar novamente no Teams.

**P: Membros da equipe podem ver as conversas da minha Personal instance?**
R: Não. Instâncias pessoais são totalmente isoladas. Apenas você pode ver seu histórico de conversas. Instâncias compartilhadas são visíveis para todos os membros da equipe.

**P: Quantas instâncias posso criar?**
R: Não há limite fixo por usuário, mas políticas organizacionais podem restringir a quantidade. Cada instância consome recursos mínimos — o trabalho pesado fica no backend do ACA.

**P: O que acontece quando o ACA escala para zero?**
R: Se seu ACA tem `minReplicas: 0`, a primeira requisição terá um cold start (5-15 segundos). Configure `minReplicas: 1` para disponibilidade sempre ativa.

---

## 🏆 Desafios Autônomos

1. **Instância Org-Wide**: Se você tem direitos de administrador, crie uma instância org-wide e verifique se todos os usuários do seu tenant podem descobri-la
2. **Comparação de Instâncias**: Crie uma instância pessoal e uma compartilhada com o mesmo blueprint. Envie a mesma pergunta para ambas e documente como o isolamento de contexto funciona
3. **Exercício de Ciclo de Vida**: Criar → Testar → Suspender → Retomar → Excluir → Recriar uma instância. Documente o estado em cada etapa e quais dados persistem
4. **Personalização por Canal**: Crie instâncias compartilhadas em 3 canais diferentes com nomes de exibição distintos. Verifique se cada uma mantém contexto independente
5. **Perfil de Desempenho**: Envie 10 perguntas em sequência rápida para sua instância e monitore os tempos de resposta no Application Insights. Identifique se o escalonamento do ACA é acionado
6. **Guia do Usuário**: Escreva um guia de 1 página para o usuário final explicando como encontrar, instalar e interagir com o Financial Advisor Agent no Teams — como se fosse para um colega não técnico

---

## Referência Rápida

### Comandos Comuns

```powershell
# List published agents
a365 list blueprints

# Create personal instance
a365 create-instance --blueprint-id <ID> --display-name "My Agent" --instance-type personal

# Create shared instance
a365 create-instance --blueprint-id <ID> --display-name "Team Agent" --instance-type shared --team-id <TEAM_ID>

# List all instances
a365 list instances

# Get instance details
a365 get-instance --instance-id <ID>

# Suspend instance
a365 suspend-instance --instance-id <ID>

# Resume instance
a365 resume-instance --instance-id <ID>

# Delete instance
a365 delete-instance --instance-id <ID>

# Check publication status
a365 publish status

# View usage statistics
a365 get-usage --instance-id <ID>
```

### Endpoints

- **Health Check:** `https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/health`
- **Bot Framework:** `https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/api/messages`
- **REST API:** `https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/chat`

### Arquivos Principais

- **Configuração A365:** `lesson-5-a365-prereq/a365.config.json`
- **Código do Agente:** `lesson-6-a365-langgraph/main.py`
- **Requisitos:** `lesson-6-a365-langgraph/requirements.txt`

---

## Recursos

- [Repositório do Workshop](https://github.com/pateixei/foundry-agents-workshop)
- [Lição 6: Integração com SDK A365](../lesson-6-a365-langgraph/README.pt-BR.md)
- [Lição 5: Pré-requisitos A365](../lesson-5-a365-prereq/README.pt-BR.md)
- [Lição 7: Guia de Publicação](../lesson-7-publish/README.pt-BR.md)
- [Microsoft Learn: Construa Agentes M365](https://learn.microsoft.com/en-us/training/paths/build-microsoft-365-agents/)

---

**Dúvidas ou Problemas?** Abra uma issue no [repositório do GitHub](https://github.com/pateixei/foundry-agents-workshop/issues).

Boas Construções! 🚀
