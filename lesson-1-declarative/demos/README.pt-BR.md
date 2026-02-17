# Demo 1: Padrão de Agente Declarativo

> 🇺🇸 **[Read in English](README.md)**

## Visão Geral

Esta demo apresenta a criação de um **agente declarativo (baseado em prompt) de consultoria financeira** no Azure AI Foundry utilizando o SDK `azure-ai-projects` (nova experiência Foundry). Agentes declarativos são o padrão mais simples — executam no lado do servidor no Foundry sem necessidade de contêineres personalizados.

## O Que Esta Demo Demonstra

- ✅ Criação de agentes com `PromptAgentDefinition`
- ✅ Configuração de system prompts e seleção de modelo
- ✅ Registro de agentes no Foundry para disponibilidade imediata
- ✅ Teste de agentes programaticamente via SDK
- ✅ Modificação de parâmetros do agente no Portal do Foundry (sem necessidade de reimplantação)
- ✅ Entendimento de quando usar padrões declarativos vs hospedados

## Arquitetura

```
┌─────────────────────────────────┐
│ Your Code (create_agent.py)    │
│   └─> PromptAgentDefinition     │
└────────────┬────────────────────┘
             │ (registers agent)
             ▼
┌─────────────────────────────────┐
│ Azure AI Foundry (Backend)      │
│   ├─> Agent Runtime (serverless)│
│   ├─> Model (GPT-4)             │
│   └─> Tools (optional catalog)  │
└────────────┬────────────────────┘
             │ (accessed via SDK)
             ▼
┌─────────────────────────────────┐
│ Client Application              │
│   (test_agent.py - console)     │
└─────────────────────────────────┘
```

## Pré-requisitos

1. **Recursos Azure Implantados**:
   - Projeto Azure AI Foundry criado
   - Modelo GPT-4 implantado no Foundry
   - Azure CLI autenticado: `az login`

2. **Variáveis de Ambiente**:
   - `PROJECT_ENDPOINT` - URL do endpoint do projeto Foundry
   - `MODEL_DEPLOYMENT_NAME` - Nome da implantação do modelo (ex.: `gpt-4.1`)

3. **Ambiente Python**:
   - Python 3.10 ou superior
   - Dependências instaladas: `pip install -r requirements.txt`

4. **Permissões Azure**:
   - Role "Azure AI User" no projeto Foundry

## Como Executar

### Passo 1: Configurar Variáveis de Ambiente

Crie um arquivo `.env`:
```bash
PROJECT_ENDPOINT=https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
MODEL_DEPLOYMENT_NAME=gpt-4.1
```

Ou configure no PowerShell:
```powershell
$env:PROJECT_ENDPOINT="https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT"
$env:MODEL_DEPLOYMENT_NAME="gpt-4.1"
```

### Passo 2: Criar o Agente

```powershell
python create_agent.py
```

**Saída Esperada**:
```
Endpoint: https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT
Agente:   fin-market-declarative
Modelo:   gpt-4.1

Agente criado com sucesso!
  Nome:    fin-market-declarative
  Versao:  1
  ID:      fin-market-declarative:1
  
O agente esta visivel e editavel no portal do Foundry.
Acesse: https://ai.azure.com/ para editar instructions, model, etc.
```

### Passo 3: Testar o Agente

```powershell
python test_agent.py
```

**Exemplo de Interação**:
```
🤖 Financial Advisor Agent (Declarative)
Type 'quit' to exit

You: Qual é a cotação da PETR4?

Agent: Petrobras PN (PETR4) não possui cotação em tempo real disponível. 
Para informações atualizadas, recomendo consultar sites de notícias financeiras 
como InfoMoney, Valor Econômico, ou dados diretamente da B3.

Esta informação é apenas para fins educativos e não constitui recomendação de investimento.

────────────────────────────────

You: quit
```

### Passo 4: Modificar Agente no Portal (Opcional)

1. Navegue até o [Portal Azure AI Foundry](https://ai.azure.com/)
2. Selecione seu projeto
3. Vá para **Agents** → **fin-market-declarative**
4. Clique em **Edit**
5. Modifique o system prompt (ex.: altere tom, adicione capacidades)
6. Clique em **Save**
7. Teste novamente com `test_agent.py` — as alterações são imediatas!

## Estrutura de Arquivos

```
demo-1-declarative-agent/
├── README.md                  # This file
├── create_agent.py            # Agent creation script
├── test_agent.py              # Console test client
├── requirements.txt           # Python dependencies
├── .env.example               # Environment template
└── architecture-diagram.png   # Visual architecture
```

## Explicação do Código

### create_agent.py

```python
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential

# Authenticate using Azure CLI credentials
credential = DefaultAzureCredential()

# Connect to Foundry project
project_client = AIProjectClient(
    endpoint=os.environ["PROJECT_ENDPOINT"],
    credential=credential,
)

# Define the agent
agent = project_client.agents.create_version(
    agent_name="fin-market-declarative",
    definition=PromptAgentDefinition(
        model="gpt-4.1",  # Use deployed model name
        instructions="""
You are a financial market advisor specializing in Brazilian and international markets.

## Your Objective
Help investors with stock information, exchange rates, and market trends.

## Guidelines
- Always respond in Brazilian Portuguese
- Explain you don't have real-time data
- Include disclaimer: "This information is for educational purposes only"
- Be objective and direct
        """,
    ),
)

print(f"✅ Agent created: {agent.name} (version {agent.version})")
```

**Pontos-Chave**:
- `PromptAgentDefinition`: O tipo de agente declarativo
- `instructions`: System prompt que define o comportamento do agente
- `model`: Referencia a implantação do modelo no Foundry
- Nenhuma tool especificada inicialmente (pode adicionar depois no Portal)

### test_agent.py

```python
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=os.environ["PROJECT_ENDPOINT"],
    credential=credential,
)

# Get OpenAI client from the project
openai_client = project_client.get_openai_client()

# Create a conversation for multi-turn chat
conversation = openai_client.conversations.create()

# Chat loop
while True:
    user_input = input("You: ")
    if user_input.lower() == "quit":
        break
    
    # Send message via Responses API with agent_reference
    response = openai_client.responses.create(
        conversation=conversation.id,
        extra_body={
            "agent": {
                "name": "fin-market-declarative",
                "type": "agent_reference",
            }
        },
        input=user_input,
    )

    print(response.output_text)
    print("\n" + "─" * 40 + "\n")
```

**Pontos-Chave**:
- `get_openai_client()`: Obtém um client compatível com OpenAI a partir do projeto
- `conversations.create()`: Cria um contexto de conversa multi-turn
- `responses.create()`: Envia mensagens via Responses API usando `agent_reference`
- A conversa persiste entre múltiplas mensagens (memória de conversa)

## Entendendo Agentes Declarativos

### Vantagens ✅
- **Implantação instantânea**: Não requer build de contêiner ou push para ACR
- **Editável no portal**: Modifique instruções, tools e modelo sem alterações no código
- **Infraestrutura zero**: Foundry gerencia todos os recursos de execução
- **Iteração rápida**: Teste alterações de prompt em segundos, não minutos
- **Escala automática**: Foundry gerencia picos de tráfego

### Limitações ⚠️
- **Sem código Python personalizado**: Tools limitadas ao catálogo do Foundry
- **Apenas server-side**: Não executa lógica de negócios local
- **Integrações limitadas**: Sem acesso direto a banco de dados ou APIs personalizadas
- **Dependente do Foundry**: Execução vinculada à disponibilidade do Foundry

### Quando Usar Agentes Declarativos

**✅ USE QUANDO**:
- Prototipação rápida e POCs
- Engenharia de prompt e testes
- Agentes precisam apenas de tools do catálogo Foundry (Bing, Azure AI Search, Code Interpreter)
- Sem lógica de negócios personalizada necessária
- Iterações rápidas são prioridade

**❌ EVITE QUANDO**:
- Necessita de tools Python personalizadas (consultas a banco, chamadas de API)
- Requer processamento local de arquivos ou cálculos complexos
- Necessita de controle completo sobre o ambiente de execução
- Lógica personalizada de autenticação ou autorização necessária

## Adicionando Tools do Catálogo Foundry

Para adicionar tools como Bing Search ou Code Interpreter:

```python
from azure.ai.projects.models import (
    PromptAgentDefinition,
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
)

# Get Bing connection from Foundry
bing_connection = project_client.connections.get("bing-connection-name")

# Create agent with Bing tool
agent = project_client.agents.create_version(
    agent_name="fin-market-with-bing",
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="You are a financial advisor. Use Bing for real-time data.",
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

**Tools Disponíveis no Foundry**:
- **Bing Grounding Search**: Busca web com grounding
- **Azure AI Search**: Busca vetorial e por palavras-chave nos seus dados
- **Code Interpreter**: Executa código Python em sandbox
- **OpenAPI Tools**: Chama APIs externas via especificações OpenAPI
- **Microsoft Fabric**: Consulta dados em Fabric lakehouses

## Comparação: Agentes Declarativos vs Hospedados

| Funcionalidade | Declarativo (Esta Demo) | Hosted Agent (Demo 2-3) |
|---------|------------------------|-------------------|
| Implantação | Apenas chamada SDK | Build de contêiner + push para ACR |
| Tools Personalizadas | Apenas catálogo | Qualquer código Python |
| Modificação | Portal (instantâneo) | Código + reimplantação |
| Infraestrutura | Nenhuma (Foundry) | Contêiner necessário |
| Velocidade de Iteração | Segundos | Minutos (rebuild) |
| Flexibilidade | Baixa | Alta |
| Caso de Uso | Prototipação | Produção |

## Resolução de Problemas

### Problema: "Authentication failed"
**Causa**: Azure CLI não autenticado ou tenant incorreto  
**Solução**:
```powershell
az login
az account show  # Verify correct subscription
```

### Problema: "Model deployment not found"
**Causa**: Nome do modelo não corresponde à implantação no Foundry  
**Solução**:
1. Vá para Portal Foundry → Models
2. Copie o nome exato da implantação (sensível a maiúsculas/minúsculas)
3. Atualize a variável de ambiente `MODEL_DEPLOYMENT_NAME`

### Problema: "Access denied to Foundry project"
**Causa**: Role "Azure AI User" ausente  
**Solução**:
1. Portal → Projeto Foundry → Access Control (IAM)
2. Adicione role assignment: "Azure AI User"
3. Atribua à sua conta de usuário
4. Aguarde 2-3 minutos para propagação

### Problema: Agente retorna respostas genéricas (sem conhecimento do domínio)
**Causa**: System prompt muito vago  
**Solução**: Melhore as `instructions` com:
- Conhecimento específico do domínio
- Diretrizes de formato de resposta
- Exemplos de saída
- Restrições e disclaimers

### Problema: "Agent version already exists"
**Causa**: Executando `create_agent.py` novamente com mesmo nome  
**Solução**: Cada execução de `create_version()` cria uma nova versão (v1, v2, etc.). Se quiser começar do zero, delete o agente no Portal do Foundry ou use um `agent_name` diferente:
```python
# Opção 1: Use um nome diferente
agent_name="fin-market-declarative-v2"

# Opção 2: Delete o agente no Portal do Foundry e recrie
```

## Próximos Passos

Após dominar agentes declarativos, prossiga para:
- **Demo 2**: Hosted Agent (Agente Hospedado) com MAF e tools Python personalizadas
- **Demo 3**: Hosted Agent com LangGraph para workflows complexos
- **Demo 4**: Deploy em ACA para controle de infraestrutura
- **Demo 5**: SDK Agent 365 para integração com M365

## Recursos Adicionais

- [Documentação Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/)
- [Guia de Engenharia de Prompt](https://learn.microsoft.com/azure/ai-services/openai/concepts/prompt-engineering)
- [Referência da API PromptAgentDefinition](https://learn.microsoft.com/python/api/azure-ai-projects/)
- [Catálogo de Tools do Foundry](https://learn.microsoft.com/azure/ai-studio/how-to/tools-catalog)

---

**Nível da Demo**: Iniciante  
**Tempo Estimado**: 15-20 minutos  
**Pré-requisitos**: Recursos Azure implantados, ambiente Python pronto
