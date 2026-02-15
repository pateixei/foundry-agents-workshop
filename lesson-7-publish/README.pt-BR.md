# Lição 7: Publicação do Agente no Microsoft 365 Admin Center

## Visão Geral

Esta lição orienta você na publicação do seu Agent Blueprint registrado no Microsoft 365 Admin Center, tornando-o disponível para implantação a usuários e grupos na sua organização.

## Pré-requisitos

Antes de publicar, certifique-se de que você:

1. ✅ Concluiu a configuração da Lição 5 (`a365 setup all`)
2. ✅ Agent Blueprint registrado no Entra ID
3. ✅ Agente implantado e saudável no ACA
4. ✅ Endpoint de mensagens acessível
5. ✅ Função de Global Administrator ou Agent Administrator

## Processo de Publicação

### Etapa 1: Verificar Status do Agent Blueprint

```powershell
cd lesson-5-a365-prereq
a365 blueprint list
```

**Saída esperada**:
```
Agent Blueprint: Financial Market Agent Blueprint
ID: <blueprint-id>
Status: Registered
Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
```

### Etapa 2: Publicar no M365

```powershell
a365 publish
```

**O que isso faz**:
- Envia o agent blueprint para o M365 Admin Center
- Cria o pacote do agente
- Inicia o fluxo de aprovação
- Define a prontidão para implantação

**Saída esperada**:
```
Publishing agent blueprint...
✓ Agent package created
✓ Submitted to M365 Admin Center
✓ Approval request sent to administrators

Status: Pending Admin Approval
Agent ID: <agent-id>
```

### Etapa 3: Aprovação de Administrador no M365 Admin Center

1. Navegue até o [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Vá em **Settings** → **Integrated apps**
3. Encontre "Financial Market Agent Blueprint"
4. Clique em **Review** e verifique:
   - Permissões solicitadas
   - Acesso a dados
   - Endpoint de mensagens
5. Clique em **Approve**

**Prazo**: A aprovação normalmente leva de 2 a 5 minutos para se propagar.

### Etapa 4: Verificar Status da Publicação

```powershell
a365 status
```

**Saída esperada**:
```
Agent: Financial Market Agent Blueprint
Publication Status: Published
Approval Status: Approved
Available for Deployment: Yes
```

### Etapa 5: Implantar para Usuários/Grupos

#### Opção A: Implantar para Todos os Usuários

No M365 Admin Center:
1. Selecione seu agente aprovado
2. Clique em **Deploy**
3. Escolha "Deploy to everyone"
4. Confirme a implantação

#### Opção B: Implantar para Grupos Específicos

1. Selecione seu agente
2. Clique em **Deploy**
3. Escolha "Deploy to specific groups"
4. Selecione os grupos (Finance Team, IT Department, etc.)
5. Confirme a implantação

#### Opção C: Testar com Usuários Específicos Primeiro

```powershell
# Deploy to specific users via CLI (if available)
a365 deploy --users "user1@domain.com,user2@domain.com"
```

### Etapa 6: Verificar Implantação

```powershell
a365 deployment status
```

**Verifique o progresso da implantação**:
```
Deployment Status: Active
Deployed to: 15 users
Groups: Finance Team, Management
Last Updated: 2026-02-13 23:15:00
```

## Configuração Pós-Publicação

### Atualizar Metadados do Agente

```powershell
a365 blueprint update --display-name "Financial Market Assistant" --description "Updated description"
```

### Atualizar Endpoint de Mensagens

Se você reimplantar seu ACA:
```powershell
a365 blueprint update --messaging-endpoint "https://new-endpoint/api/messages"
```

### Gerenciar Escopo de Implantação

```powershell
# Add users
a365 deploy add-users --users "user3@domain.com"

# Add groups
a365 deploy add-groups --groups "Sales Team"

# Remove users
a365 deploy remove-users --users "user1@domain.com"
```

## Troubleshooting

### Falha na Publicação

**Sintoma**: `a365 publish` retorna erro

**Causas comuns**:
1. Blueprint não registrado → Execute `a365 setup blueprint`
2. Permissões ausentes → Verifique a função de Global Admin
3. Endpoint não acessível → Teste o endpoint de saúde
4. Configuração inválida → Verifique `a365.config.json`

**Solução**:
```powershell
# Verify setup
a365 config display
a365 blueprint list

# Re-register if needed
a365 setup blueprint --skip-infrastructure
```

### Aprovação Pendente por Muito Tempo

**Sintoma**: Status travado em "Pending Approval" por mais de 30 minutos

**Soluções**:
1. Verifique o M365 Admin Center para solicitações pendentes
2. Confirme que o administrador possui as permissões necessárias
3. Limpe o cache do navegador e tente novamente a aprovação
4. Entre em contato com o suporte da Microsoft para aprovações travadas

### Agente Não Aparece no Admin Center

**Sintoma**: Agente publicado não está visível

**Soluções**:
1. Aguarde 5-10 minutos para sincronização
2. Atualize a página do Admin Center
3. Verifique o status da publicação: `a365 status`
4. Confirme que está logado no tenant correto

### Implantação Não Chega aos Usuários

**Sintoma**: Usuários não veem o agente no Teams/Outlook

**Soluções**:
1. Verifique o status da implantação: `a365 deployment status`
2. Confirme que o usuário está no grupo implantado
3. Aguarde 10-15 minutos para propagação
4. Peça ao usuário para reiniciar o Teams/Outlook
5. Verifique se o usuário possui as licenças M365 necessárias

## Monitoramento do Agente Publicado

### Visualizar Análises de Uso

M365 Admin Center → Integrated apps → Seu Agente → Analytics:
- Total de mensagens
- Usuários ativos
- Taxas de erro
- Tempos de resposta

### Verificar Saúde pelo M365

A plataforma M365 faz ping periodicamente no seu endpoint `/health`. Monitore:
```powershell
az containerapp logs show --name aca-lg-agent --resource-group rg-ag365sdk --follow
```

### Revisar Application Insights

Para telemetria detalhada:
1. Azure Portal → Application Insights
2. Verifique **Live Metrics** para atividade em tempo real
3. Revise **Failures** para erros
4. Analise **Performance** para requisições lentas

## Despublicação / Remoção do Agente

### Despublicar do M365

```powershell
a365 unpublish
```

**O que isso faz**:
- Remove o agente do catálogo do M365
- Interrompe novas implantações
- Instâncias existentes permanecem ativas

### Limpeza Completa

```powershell
# Delete all instances first (Lesson 8)
a365 instance delete-all

# Then unpublish
a365 unpublish

# Finally remove blueprint
a365 blueprint delete
```

## Melhores Práticas

1. **Teste Antes da Implantação Ampla**
   - Implante primeiro para um grupo de teste
   - Verifique a funcionalidade
   - Colete feedback
   - Depois implante para toda a organização

2. **Comunique aos Usuários**
   - Anuncie a disponibilidade do novo agente
   - Forneça instruções de uso
   - Compartilhe exemplos de consultas
   - Ofereça um canal de suporte

3. **Monitore Após a Publicação**
   - Observe as taxas de erro
   - Acompanhe a adoção pelos usuários
   - Revise o feedback
   - Itere com base no uso

4. **Mantenha o Endpoint Saudável**
   - Monitore o endpoint `/health`
   - Configure alertas para indisponibilidade
   - Mantenha o SLA de disponibilidade

5. **Controle de Versão**
   - Marque versões do agente com tags
   - Documente alterações
   - Teste antes de atualizar o endpoint
   - Comunique atualizações aos usuários

## Próximos Passos

- **Lição 8**: Criando instâncias do agente no Teams para usuários
- Aprenda sobre gerenciamento do ciclo de vida de instâncias
- Explore instâncias pessoais vs compartilhadas

## Referências

- [M365 Admin Center](https://admin.microsoft.com)
- [Microsoft Agent 365 Publishing](https://learn.microsoft.com/microsoft-agent-365/developer/)
- [Integrated Apps Management](https://learn.microsoft.com/microsoft-365/admin/manage/manage-deployment-of-add-ins)
