# Lição 1 - Agente Declarativo (Baseado em Prompt)

> 🇺🇸 **[Read in English](README.md)**

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código, saída esperada e troubleshooting |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-1-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-1-deployment.png) | Fluxo de implantação |

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:

1. **Criar** um agente declarativo usando o SDK `PromptAgentDefinition`
2. **Configurar** instruções, ferramentas e seleção de modelo do agente
3. **Testar** o agente no playground do portal do Foundry
4. **Modificar** a configuração do agente no portal sem reimplantação
5. **Explicar** quando usar padrões declarativos vs hospedados
6. **Comparar** agentes declarativos com outros padrões de hospedagem de agentes

Cria um agente financeiro **declarativo** no Azure AI Foundry usando o SDK `azure-ai-projects` (nova experiência Foundry).

## O que é um agente declarativo?

Um agente declarativo é um **"agente serverless"** — você o define via `PromptAgentDefinition` e o registra diretamente no Foundry. O Foundry gerencia as chamadas ao modelo, execução de funções e escalonamento em seu nome. Você não constrói contêineres nem gerencia infraestrutura.

Pense nele como uma **função serverless que orquestra IA**: seu código apenas **define** o agente, mas o agente **roda** no backend do Foundry.

```
┌─────────────────────────────────────────────┐
│ Your Code (create_agent.py)                 │
│   └─> PromptAgentDefinition (SDK)           │
└─────────────────┬───────────────────────────┘
                  │
                  ▼ (register agent)
┌─────────────────────────────────────────────┐
│ Azure AI Foundry (Backend)                  │
│   ├─> Agent Runtime (serverless)            │
│   ├─> Model (GPT-4)                         │
│   └─> Tools (Bing, Code Interpreter, etc.)  │
└─────────────────┬───────────────────────────┘
                  │
                  ▼ (invoke via API)
┌─────────────────────────────────────────────┐
│ Client Application (chat interface)         │
└─────────────────────────────────────────────┘
```

Diferente dos agentes **hospedados** (lições 2 e 3), agentes declarativos não requerem contêineres Docker ou ACR.

### Vantagens & Limitações

| Vantagem ✅ | Limitação ⚠️ |
|-------------|---------------|
| Não precisa construir/implantar contêiner | Sem ferramentas Python customizadas (funções locais) |
| Instruções, modelo e ferramentas editáveis no portal | Ferramentas limitadas ao catálogo do Foundry |
| Implantação instantânea (<10 segundos) | Menor controle sobre o fluxo de execução |
| Foundry gerencia escalonamento automaticamente | Não ideal para workflows complexos de múltiplas etapas |
| Ótimo para protótipos e iteração rápida | |

> **Regra prática:** Se seu agente precisa de Bing search, Azure AI Search ou Code Interpreter — declarativo é perfeito. Você atingirá limitações quando precisar de chamadas a APIs customizadas, consultas a banco de dados ou orquestração de múltiplas etapas — aí é hora de usar hospedado (lições 2 e 3).

## Estrutura

```
lesson-1-declarative/
  README.md              # Este arquivo (teoria + navegação)
  demos/                 # Walkthrough da demo
    create_agent.py      # Demo: cria o agente
    test_agent.py        # Demo: testa o agente
    README.md            # Explicação do código & troubleshooting
  labs/                  # Lab prático
    LAB-STATEMENT.md     # Enunciado do exercício
    starter/             # Código inicial (TODOs)
    solution/            # Solução de referência
  media/                 # Diagramas de arquitetura
```

## Pré-requisitos

1. Recursos Azure provisionados (veja `prereq/`)
2. Role "Azure AI User" no projeto Foundry
3. Python 3.10+

## Passo a Passo

### 1. Configure Seu Ambiente

```bash
# Navegue até a pasta da lição
cd lesson-1-declarative

# Crie o ambiente virtual
python -m venv venv

# Ative (Linux/Mac)
source venv/bin/activate

# Ative (Windows PowerShell)
# .\venv\Scripts\activate

# Instale as dependências
pip install -r requirements.txt
```

**Verifique a instalação:**
```bash
python -c "import azure.ai.agents; print('✅ SDK installed')"
```

### 2. Configure as Variáveis de Ambiente

Obtenha seu endpoint a partir das saídas da implantação (veja `prereq/`):

```bash
# Linux/Mac
export AZURE_AI_PROJECT_ENDPOINT="https://<your-foundry-account>.cognitiveservices.azure.com"

# Windows PowerShell
# $env:AZURE_AI_PROJECT_ENDPOINT="https://<your-foundry-account>.cognitiveservices.azure.com"
```

> **Dica:** Crie um arquivo `.env` no diretório da lição e use `python-dotenv`:
> ```env
> AZURE_AI_PROJECT_ENDPOINT=https://<your-foundry-account>.cognitiveservices.azure.com
> ```

### 3. Entenda o Código

Os componentes principais do SDK:

```python
from azure.ai.agents import AgentsClient
from azure.ai.agents.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential
```

- **`DefaultAzureCredential`** — Cadeia de autenticação: tenta credenciais CLI → managed identity → variáveis de ambiente
- **`PromptAgentDefinition`** — O núcleo dos agentes declarativos. Defina instruções, modelo e ferramentas aqui
- **`agent_name`** — Identificador único dentro do seu projeto Foundry
- **`instructions`** — System prompt: a "personalidade" do seu agente (injetado em cada requisição)
- **`temperature`** — Controla criatividade: 0 = determinístico, 1 = criativo. Para finanças, 0.3–0.7 é uma boa faixa

### 4. Crie e Teste o Agente

```bash
# Criar o agente
python create_agent.py

# Testar o agente
python test_agent.py
```

**Saída esperada:**
```
🔄 Creating declarative agent...
✅ Agent created successfully!
   Name: financial-advisor
   ID: asst_AbC123XyZ
   Version: 1
   Model: gpt-4
   Status: active
```

> Em cerca de 3 segundos você implantou um agente de IA. Sem Docker, sem container registry — apenas uma chamada ao SDK. Compare isso com uma implantação tradicional onde você precisaria construir um contêiner, configurar triggers e definir políticas de IAM.

### 5. Explore no Portal do Foundry

Após criar o agente, verifique-o no portal:

1. Abra [portal.azure.com](https://portal.azure.com)
2. Navegue até **AI Foundry** → Seu projeto
3. Menu esquerdo → **Agents** → Encontre seu agente
4. Clique em **Playground** para testar interativamente

**Experimente estas ações no portal** (sem necessidade de código):

| Experimento | O que fazer | O que você aprenderá |
|---|---|---|
| **Editar instruções** | Adicione uma linha: *"Sempre responda em português ao discutir mercados brasileiros."* → Salvar | Atualizações instantâneas de prompt sem reimplantação |
| **Trocar modelo** | Mude `gpt-4` → `gpt-4-turbo` → Salvar → Teste novamente | Tradeoffs de custo/latência em segundos |
| **Rollback de versão** | Vá à aba Versions → Defina a Versão 1 como ativa | Versionamento imutável e rollback integrados |

> Esses experimentos mostram a vantagem central dos agentes declarativos: **três mudanças, zero builds de contêiner**. Seu gerente de produto pode ajustar prompts sem suporte de engenharia.

## 🧭 Framework de Decisão de Padrões

Use esta árvore de decisão para escolher o padrão de agente correto:

```
START: I need an AI agent
           │
           ▼
     Does it need custom Python tools?
     (API calls, DB queries, file processing)
           │
      Yes ─┤── No
      │    │      │
      ▼    │      ▼
   Hosted  │  Does it need complex multi-step workflows?
           │      │
           │ Yes ─┤── No
           │  │   │      │
           │  ▼   │      ▼
           │ Hosted│   Declarative ✅
```

### Teste Sua Intuição

| Cenário | Resposta | Por quê |
|---|---|---|
| Agente consulta banco de dados SQL da empresa e analisa os dados | **Hosted** | Requer ferramenta customizada de conexão ao banco |
| Agente ajuda funcionários a encontrar documentos via Azure AI Search | **Declarative** ✅ | Azure AI Search é uma ferramenta integrada do Foundry |
| Agente agenda reuniões via API de calendário e envia e-mails | **Hosted** | APIs de calendário/e-mail requerem ferramentas customizadas |
| Agente responde perguntas de RH a partir de documentos PDF (RAG) | **Declarative** ✅ | Se usar Azure AI Search para recuperação |
| Agente busca preços de ações em tempo real da API Bloomberg e armazena no PostgreSQL | **Hosted** | Bloomberg API + PostgreSQL = ferramentas customizadas |

## Comparação com as Lições 2 e 3

| Recurso | Lição 1 (Declarativo) | Lição 2 (MAF Hospedado) | Lição 3 (LangGraph Hospedado) |
|---|---|---|---|
| Tipo | Baseado em prompt | Hospedado (contêiner) | Hospedado (contêiner) |
| Framework | SDK azure-ai-projects | Microsoft Agent Framework | LangGraph |
| Contêiner | Não | Sim (Docker/ACR) | Sim (Docker/ACR) |
| Ferramentas customizadas | Não (apenas server-side) | Sim (Python local) | Sim (Python local) |
| Editável no portal | Sim | Não | Não |
| Tempo de deploy | <10 segundos | ~5 minutos (build de contêiner) | ~5 minutos (build de contêiner) |
| Modelo de custo | Pagamento por token (sem compute) | Compute de contêiner + tokens | Compute de contêiner + tokens |
| Manutenção | Baixa (gerenciado) | Média (atualizar contêineres) | Média (atualizar contêineres) |
| Melhor para | Protótipos, workflows simples | Produção, lógica complexa | Expertise existente em LangGraph |

> **Estratégia:** Comece com declarativo. Migre para hospedado quando atingir limitações. Essa é a jornada da Lição 1 → Lições 2 e 3.

## Usando Ferramentas do Catálogo Foundry via SDK

Uma das maiores vantagens do agente declarativo é a capacidade de usar **ferramentas do catálogo do Foundry** (as mesmas disponíveis no portal) diretamente via código SDK.

### Como funciona?

- **Agente Declarativo** (`PromptAgentDefinition`): roda **server-side** no Foundry. As ferramentas (Bing, Azure AI Search, OpenAPI, Code Interpreter, etc.) são executadas pelo próprio runtime do Foundry. Você define as ferramentas no SDK e elas aparecem no portal (e vice-versa).
- **Agente Hospedado** (MAF/LangGraph): roda dentro de um **contêiner**. O contêiner gerencia suas próprias ferramentas via código Python. O runtime do Foundry apenas encaminha a requisição para o contêiner — não injeta ferramentas do portal.

### Exemplo: agente com Bing Grounding Search

```python
import os
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    PromptAgentDefinition,
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
    BingGroundingSearchConfiguration,
)

credential = DefaultAzureCredential()
project_client = AIProjectClient(
    endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"],
    credential=credential,
)

# 1. Get the connection ID of the Bing resource (created in the portal)
bing_connection = project_client.connections.get("bing-connection-name")

# 2. Create declarative agent WITH the Bing tool
agent = project_client.agents.create_version(
    agent_name="fin-market-with-bing",
    definition=PromptAgentDefinition(
        model="gpt-4.1",
        instructions="You are a financial market assistant. Use Bing for real-time data.",
        tools=[
            BingGroundingAgentTool(
                bing_grounding=BingGroundingSearchToolParameters(
                    search_configurations=[
                        BingGroundingSearchConfiguration(
                            project_connection_id=bing_connection.id
                        )
                    ]
                )
            )
        ],
    ),
    description="Agent with Bing Grounding",
)

# 3. Call the agent via Responses API
openai_client = project_client.get_openai_client()
response = openai_client.responses.create(
    input="What is the dollar exchange rate today?",
    tool_choice="required",  # force tool use
    extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
)
print(response.output_text)
```

### Ferramentas disponíveis via SDK (mesmas do portal)

| Ferramenta | Classe SDK (`azure.ai.projects.models`) |
|------|---------------------------------------------|
| Bing Grounding | `BingGroundingAgentTool` |
| Bing Custom Search | `BingCustomSearchAgentTool` |
| Azure AI Search | `AzureAISearchAgentTool` |
| OpenAPI 3.0 | `OpenApiAgentTool` |
| Code Interpreter | `CodeInterpreterAgentTool` |
| File Search | `FileSearchAgentTool` |
| MCP (preview) | `McpAgentTool` |
| Azure Functions | `AzureFunctionAgentTool` |

### Comparação: Ferramentas declarativas vs hospedadas

| | Declarativo (SDK/Portal) | Hospedado (MAF/LangGraph) |
|---|---|---|
| Usar ferramentas do catálogo Foundry | **Sim** — via `tools=[]` em `PromptAgentDefinition` | **Não** — contêiner gerencia suas próprias ferramentas |
| Editável no portal | **Sim** | **Não** |
| Ferramentas Python customizadas | **Não** (apenas Function Calling com schema) | **Sim** — código Python livre |

> **Resumo**: se o objetivo é usar ferramentas do catálogo do Foundry (Bing, AI Search, etc.), o caminho é o **agente declarativo**. Basta adicionar as ferramentas ao array `tools` em `PromptAgentDefinition`.

## 🔧 Troubleshooting

| Erro | Causa | Correção |
|------|-------|----------|
| `Authentication failed` | Azure CLI não logado ou token expirado | Execute `az login` e depois `az account show` |
| `Endpoint not found` | Variável de ambiente incorreta | Verifique se `AZURE_AI_PROJECT_ENDPOINT` corresponde ao seu projeto Foundry |
| `Agent name already exists` | Colisão de nome no projeto compartilhado | Adicione sufixo único: `agent_name=f"financial-advisor-{your_initials}"` |
| `Insufficient permissions` | Role RBAC ausente | Verifique se você possui a role "Azure AI User" ou "Cognitive Services User" |
| `python not found` | Não está no PATH | Tente `python3` ou `py -m venv venv` |
| Playground não responde | Cota do modelo esgotada | Verifique o Azure Service Health; tente `gpt-35-turbo` como alternativa |
| Agente não visível no portal | Cache do navegador ou projeto errado | Atualize a página (Ctrl+F5); verifique se o endpoint corresponde ao projeto no portal |

> **Conflitos de ambiente?** Delete e recrie seu venv:
> ```bash
> deactivate
> rm -rf venv
> python -m venv venv
> source venv/bin/activate
> pip install -r requirements.txt
> ```

## ❓ Perguntas Frequentes

**P: Posso usar agentes declarativos e hospedados no mesmo projeto?**
R: Sim! Combine conforme os requisitos. Cada padrão é adequado para diferentes casos de uso.

**P: Como faço controle de versão de agentes declarativos?**
R: Exporte a configuração do agente via SDK, faça commit no Git e recrie via CI/CD. O Foundry também mantém versões imutáveis internamente.

**P: Qual é o modelo de custo?**
R: Pagamento por token (apenas uso do modelo). Sem custos de compute de contêiner — diferente dos agentes hospedados.

**P: Posso usar modelos além do OpenAI?**
R: Sim. O Foundry suporta Azure OpenAI, Meta Llama, Mistral e outros. Configure o modelo no portal ou via SDK.

**P: O que acontece quando eu edito um agente no portal?**
R: Cada edição cria uma nova versão imutável. Você pode fazer rollback para qualquer versão anterior com um clique.

## 🏆 Desafios Autônomos

Após concluir o lab, experimente estes desafios para aprofundar seu conhecimento:

| Desafio | Dificuldade | Descrição |
|---|---|---|
| **Adicionar Bing Grounding** | ⭐ | Adicione `BingGroundingAgentTool` ao seu agente e faça perguntas em tempo real |
| **Adicionar Code Interpreter** | ⭐ | Habilite `CodeInterpreterAgentTool` e peça ao agente para gerar gráficos |
| **Prompts multi-idioma** | ⭐⭐ | Modifique as instruções para que o agente detecte automaticamente o idioma do usuário e responda de acordo |
| **Exportar & controle de versão** | ⭐⭐ | Exporte a configuração do seu agente via SDK e faça commit em um repositório Git |
| **Comparação multi-agente** | ⭐⭐⭐ | Crie dois agentes com temperaturas diferentes (0.2 vs 0.9) e compare os estilos de resposta |

## Referência

- [Quickstart do Microsoft Foundry](https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code)
- [Visão geral do Foundry Agent Service](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Ferramentas Bing Grounding](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/bing-tools)
- [Visão geral de ferramentas](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/overview)
- [Referência do SDK PromptAgentDefinition](https://learn.microsoft.com/python/api/azure-ai-agents/)
- [Guia de seleção de modelos](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/model-region-support)
