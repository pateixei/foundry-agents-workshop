# Lab 1: Criar Agente Declarativo de Consultoria Financeira

## Objetivo

Criar e implantar um **Agente Declarativo** no Azure AI Foundry usando o SDK `azure-ai-agents`. Você criará um agente que pode responder sobre mercados financeiros brasileiros usando apenas configuração de prompt — sem contêineres, sem infraestrutura.

## Cenário

Sua empresa de serviços financeiros precisa de um agente de IA prototipo que:
- Responda perguntas sobre ações brasileiras (PETR4, VALE3, ITUB4)
- Forneça informações sobre câmbio (USD/BRL, EUR/BRL)
- Responda em português brasileiro
- Inclua disclaimers educativos apropriados

Como este é um protótipo, você usará o padrão mais simples: **Agente Declarativo** (baseado em prompt, sem código personalizado).

## Objetivos de Aprendizagem

- Criar agentes declarativos com `PromptAgentDefinition`
- Configurar system prompts eficazes para agentes financeiros
- Testar agentes programaticamente via SDK
- Modificar agentes no Portal Foundry sem reimplantação
- Entender quando agentes declarativos são apropriados vs hospedados

## Pré-requisitos

- [x] Recursos Azure implantados (passo `prereq/`)
- [x] Python 3.10+ com ambiente virtual
- [x] Azure CLI autenticado (`az login`)
- [x] Variáveis de ambiente configuradas (`PROJECT_ENDPOINT`, `MODEL_DEPLOYMENT_NAME`)

## Tarefas

### Tarefa 1: Configurar Ambiente (5 minutos)

1. Navegue até `starter/`:
```powershell
cd lesson-1-declarative/starter
```

2. Crie e ative ambiente virtual:
```powershell
python -m venv .venv
.\.venv\Scripts\Activate
pip install -r requirements.txt
```

3. Crie o arquivo `.env`:
```bash
PROJECT_ENDPOINT=https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
MODEL_DEPLOYMENT_NAME=gpt-4.1
```

**Critérios de Sucesso**:
- ✅ Ambiente virtual ativo
- ✅ Dependências instaladas sem erros
- ✅ Variáveis de ambiente configuradas

### Tarefa 2: Implementar Script de Criação do Agente (15 minutos)

Abra `starter/create_agent.py` e implemente:

1. **Importar módulos necessários**:
```python
from azure.ai.agents import AIProjectClient
from azure.ai.agents.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential
```

2. **Criar conexão com cliente**:
```python
credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=os.environ["PROJECT_ENDPOINT"],
    credential=credential,
)
```

3. **Definir system prompt financeiro** (seja criativo!):
   - Role: Consultor financeiro especializado em mercados brasileiros
   - Idioma: Português brasileiro
   - Disclaimer: Informação apenas para fins educativos
   - Formato: Respostas objetivas e diretas

4. **Criar o agente**:
```python
agent = project_client.agents.create_version(
    agent_name="fin-market-declarative",
    definition=PromptAgentDefinition(
        model=os.environ["MODEL_DEPLOYMENT_NAME"],
        instructions="YOUR SYSTEM PROMPT HERE",
    ),
)
```

**Critérios de Sucesso**:
- ✅ Script executa sem erros
- ✅ Agente criado com sucesso no Foundry
- ✅ System prompt inclui instruções financeiras em português

### Tarefa 3: Criar Cliente de Teste (20 minutos)

Abra `starter/test_agent.py` e implemente:

1. **Conectar ao agente existente**:
```python
agent = project_client.agents.get_agent("fin-market-declarative")
```

2. **Criar thread de conversa**:
```python
thread = project_client.agents.create_thread()
```

3. **Implementar loop de chat com streaming**:
```python
while True:
    user_input = input("You: ")
    if user_input.lower() == "quit":
        break
    
    for chunk in project_client.agents.send_message_stream(
        agent_id=agent.id,
        thread_id=thread.id,
        message=user_input,
    ):
        if chunk.text:
            print(chunk.text, end="", flush=True)
    print()
```

**Critérios de Sucesso**:
- ✅ Cliente conecta ao agente com sucesso
- ✅ Mensagens são enviadas e respostas recebidas
- ✅ Contexto da conversa é mantido entre mensagens
- ✅ Agente responde em português com conhecimento financeiro

### Tarefa 4: Testar Capacidades do Agente (10 minutos)

Teste o agente com estas perguntas:
1. "Qual é a cotação da PETR4?"
2. "Como está o câmbio USD/BRL hoje?"
3. "Me dê um resumo do mercado brasileiro"
4. "Explique o que é o Ibovespa"

**Comportamento Esperado**:
- Agente reconhece a falta de dados em tempo real
- Fornece informações educacionais sobre os tópicos
- Inclui disclaimer: "Esta informação é apenas para fins educativos..."
- Responde em português brasileiro
- Usa formatação apropriada (R$ para valores em BRL)

**Critérios de Sucesso**:
- ✅ Agente responde de forma relevante a cada pergunta
- ✅ Disclaimers são incluídos
- ✅ Linguagem e tom são apropriados

### Tarefa 5: Modificar Agente no Portal (10 minutos)

1. Navegue até o [Portal Azure AI Foundry](https://ai.azure.com/)
2. Selecione seu projeto → **Agents** → Seu agente
3. Clique em **Edit**
4. Modifique o system prompt:
   - Adicione: "Always start responses with an appropriate emoji related to finance (📈, 📉, 💰, 💹)"
   - Adicione: "Keep responses to maximum 3 paragraphs"
5. Clique em **Save** (as alterações são imediatas, sem reimplantação!)

6. Teste novamente com `test_agent.py`

**Critérios de Sucesso**:
- ✅ Respostas do agente agora incluem emojis
- ✅ Respostas são mais concisas (≤3 parágrafos)
- ✅ Alterações aplicadas instantaneamente sem reimplantação

### Tarefa 6: Adicionar Tool do Catálogo Foundry (Opcional - Avançado, 15 minutos)

**Desafio**: Aprimore seu agente com a tool Bing Grounding Search para dados em tempo real.

1. No Portal Foundry:
   - Vá para **Connections** → Adicione conexão **Bing Search**
   - Anote o nome da conexão

2. Modifique `create_agent.py` para incluir a tool Bing:
   ```python
   from azure.ai.agents.models import (
       BingGroundingAgentTool,
       BingGroundingSearchToolParameters,
   )
   
   bing_connection = project_client.connections.get("bing-connection-name")
   
   agent = project_client.agents.create_version(
       agent_name="fin-market-with-bing",
       definition=PromptAgentDefinition(
           model="gpt-4.1",
           instructions="...",
           tools=[
               BingGroundingAgentTool(
                   bing_grounding=BingGroundingSearchToolParameters(
                       search_configurations=[{
                           "project_connection_id": bing_connection.id
                       }]
                   )
               )
           ],
       ),
   )
   ```

3. Teste: Pergunte "latest PETR4 stock price"

**Critérios de Sucesso**:
- ✅ Agente pesquisa no Bing por dados atuais
- ✅ Respostas incluem informações de mercado em tempo real

## Entregáveis

- [x] Script `create_agent.py` funcional
- [x] Cliente `test_agent.py` funcional
- [x] Agente visível e testável no Portal Foundry
- [x] Screenshot de conversa bem-sucedida com o agente
- [x] (Opcional) Agente aprimorado com tool Bing Search

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|-----------|--------|-------------|
| **Criação do Agente** | 25 pts | Agente criado com sucesso via SDK |
| **Qualidade do System Prompt** | 20 pts | Conhecimento de domínio e diretrizes apropriadas |
| **Cliente de Teste** | 25 pts | Loop de conversa funcional com streaming |
| **Testes** | 15 pts | Múltiplos cenários testados, comportamento verificado |
| **Modificação no Portal** | 10 pts | Alterações e testes realizados com sucesso |
| **Qualidade do Código** | 5 pts | Limpo, documentado, segue convenções Python |
| **Bônus: Tool Bing** | +10 pts | Tool do catálogo Foundry integrada com sucesso |

**Total**: 100 pontos (+10 bônus)

## Resolução de Problemas

### "Authentication failed"
- Verifique se `az login` foi bem-sucedido
- Confira se `PROJECT_ENDPOINT` no `.env` está correto
- Certifique-se de ter a role "Azure AI User"

### "Model deployment not found"
- Verifique se o nome do modelo corresponde à implantação no Foundry (sensível a maiúsculas/minúsculas)
- Confirme que o modelo está implantado em Portal → Models

### "Agent returns generic responses"
- System prompt pode estar muito vago
- Adicione instruções e exemplos mais específicos
- Inclua restrições de domínio

## Estimativa de Tempo

- Tarefa 1: 5 minutos
- Tarefa 2: 15 minutos
- Tarefa 3: 20 minutos
- Tarefa 4: 10 minutos
- Tarefa 5: 10 minutos
- Tarefa 6: 15 minutos (opcional)
- **Total**: 60-75 minutos

## Próximos Passos

Após completar este laboratório:
- Prossiga para o **Lab 2** para aprender tools personalizadas com MAF
- Compare padrões declarativos vs hospedados
- Entenda quando escolher cada abordagem

---

**Dificuldade**: Iniciante  
**Pré-requisitos**: Python básico, fundamentos de Azure  
**Tempo Estimado**: 60 minutos
