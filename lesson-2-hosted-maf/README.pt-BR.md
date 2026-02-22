# Lição 2: Implantando um Agente de IA no Microsoft Foundry

> 🇺🇸 **[Read in English](README.md)**

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-2-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-2-deployment.png) | Fluxo de implantação |
| [📁 Notas da Solução](labs/solution/README.pt-BR.md) | Código da solução e detalhes de deployment |

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:

1. **Implementar** ferramentas Python customizadas usando Microsoft Agent Framework
2. **Construir** e conteinerizar uma aplicação de agente MAF
3. **Implantar** um agente conteinerizado no Azure Container Registry (ACR)
4. **Registrar** o agente como Hosted Agent no Foundry
5. **Depurar** agentes usando logs de contêiner, telemetria e rastreamento
6. **Comparar** a arquitetura MAF com padrões declarativos e LangGraph
7. **Explicar** quando usar agentes hospedados vs declarativos

## Por que Hosted Agents?

Na Lição 1 você construiu um agente **declarativo** — serverless, sem código customizado, implantado instantaneamente. Mas e se o seu agente precisar:

- Consultar o banco de dados SQL da sua empresa?
- Chamar uma API externa (Bloomberg, Salesforce)?
- Processar arquivos ou executar cálculos complexos?
- Executar lógica Python arbitrária?

**Agentes declarativos não conseguem fazer isso.** Eles são limitados às ferramentas disponíveis no catálogo do Foundry. Hosted Agents superam essas limitações — você executa **qualquer código Python** como ferramentas dentro do seu próprio contêiner.

> Pense desta forma: agentes declarativos são como funções serverless que **orquestram**. Hosted Agents são como contêineres com **lógica de negócio** completa dentro.

## Arquitetura

```
┌─────────────────────────────────────┐
│ Your Code (Python + MAF)            │
│   ├─> Agent definition              │
│   └─> Custom tools (plain functions)│
└───────────┬─────────────────────────┘
            │ (containerized)
            ▼
┌─────────────────────────────────────┐
│ Docker Container in ACR             │
│   ├─> HTTP Server (port 8088)       │
│   └─> Runs with Managed Identity    │
└───────────┬─────────────────────────┘
            │ (registered in)
            ▼
┌─────────────────────────────────────┐
│ Foundry Capability Host             │
│   ├─> Routes requests to container  │
│   └─> Collects telemetry            │
└─────────────────────────────────────┘
```

Seu agente roda dentro do seu próprio contêiner na infraestrutura do Foundry — chamada **Capability Host**. Você escreve funções Python, registra-as como ferramentas, conteineriza tudo, faz push para o ACR, e o Foundry executa. As requisições fluem pela camada de roteamento do Foundry até o seu contêiner e as respostas voltam pelo mesmo caminho.

## O que é o Microsoft Agent Framework (MAF)?

MAF é o framework da Microsoft para construir agentes dentro do Foundry. Se você já conhece LangGraph, veja como eles se comparam:

| Conceito | LangGraph | MAF |
|----------|-----------|-----|
| **Framework** | Orquestração baseada em grafos | Agente baseado em funções |
| **Definição do Agente** | `StateGraph` + nós | `AzureAIClient` + lista de ferramentas |
| **Ferramentas** | Funções em nós do grafo | Funções Python simples passadas como lista |
| **Estado** | Objeto de estado `TypedDict` | Contexto do agente |
| **Orquestração** | Arestas/roteamento explícitos | Chamada automática de ferramentas (loop ReAct) |
| **Melhor Para** | Workflows complexos multi-agente | Agente único com múltiplas ferramentas |

> **Ponto-chave**: MAF simplifica padrões de agentes. LangGraph dá controle fino sobre a orquestração — você define o grafo. MAF faz a orquestração automaticamente usando o padrão ReAct. Ambos rodam em contêineres, ambos suportam ferramentas customizadas. MAF é integrado com o Foundry nativamente, mas também é agnóstico de plataforma — você pode hospedar agentes MAF em qualquer lugar.

## Agente

**Agente de Mercado Financeiro** — Agente Python com Microsoft Agent Framework publicado como Hosted Agent no Foundry.

Recursos:
- Desenvolvido em Python com Microsoft Agent Framework (`agent-framework-azure-ai`)
- Usa o modelo gpt-4.1 provisionado via Microsoft Foundry
- Expõe 3 ferramentas: cotações de ações, taxas de câmbio, resumo de mercado
- Hosted Agent no Foundry com Managed Identity
- OpenTelemetry integrado com Azure Monitor
- Servidor HTTP via `azure-ai-agentserver-agentframework`

## Estrutura da Lição

```
lesson-2-hosted-maf/
  README.md
  demos/                 # Walkthrough de demonstração
  labs/                  # Laboratório prático
    solution/
      agent.yaml           # Manifesto do agente
      app.py               # Servidor HTTP
      deploy.ps1           # Script de implantação automatizada
      Dockerfile           # Imagem do contêiner
      requirements.txt     # Dependências
      src/
        main.py            # Ponto de entrada run()
        agent/
          finance_agent.py # Agente MAF
      tools/
        finance_tools.py   # Ferramentas do agente
  media/                 # Diagramas de arquitetura
```

### Explicação dos Arquivos-Chave

| Arquivo | Função |
|---|---|
| `tools/finance_tools.py` | Lógica de negócio — APIs de ações, cálculos. **Python puro**, sem dependência de framework |
| `src/agent/finance_agent.py` | Definição do agente — registra ferramentas com MAF, define instruções e modelo |
| `app.py` | Wrapper do servidor HTTP — `AgentFrameworkApp` do MAF serve a Responses API na porta 8088 |
| `Dockerfile` | Conteinerização — imagem Python padrão, expõe porta 8088 |
| `deploy.ps1` | Implantação com um clique — build no ACR, registro no Foundry, teste |

## Pré-requisitos
- Pasta `../prereq/` executada para provisionar infraestrutura Azure
- Azure CLI (`az`) instalado e autenticado
- Python 3.10+ com pip

## Passo a Passo Detalhado

### 1. Entenda como Ferramentas Funcionam no MAF

No MAF, ferramentas são **funções Python simples** passadas como lista para o agente. Nenhum decorador especial é necessário — o MAF gera automaticamente JSON schemas a partir das suas type hints e docstrings.

```python
# tools/finance_tools.py — plain Python functions
from typing import Annotated

def get_stock_quote(ticker: Annotated[str, "Stock ticker code"]) -> str:
    """Returns the current price of a stock."""
    # ... your business logic here ...

def get_exchange_rate(pair: Annotated[str, "Currency pair"]) -> str:
    """Returns the current exchange rate."""
    # ... implementation ...

def get_market_summary() -> str:
    """Returns a summary of major market indices."""
    # ... implementation ...
```

```python
# src/agent/finance_agent.py — register tools as a simple list
from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary

TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]

async def create_finance_agent():
    client = AzureAIClient.from_async_credential(credential, project_endpoint)
    agent = await client.agents.create_agent(
        model=model_deployment, instructions=SYSTEM_PROMPT, tools=TOOLS
    )
    return agent
```

**Princípios-chave para escrever boas ferramentas:**

| Princípio | Por que importa |
|---|---|
| **Docstrings são obrigatórias** | O LLM as lê para decidir quando chamar sua ferramenta |
| **Use type hints com `Annotated`** | O MAF gera JSON schemas a partir delas para o LLM |
| **Responsabilidade única** | Uma ferramenta = um propósito claro |
| **Retorne erros úteis** | Não quebre — retorne `{"error": "message"}` em vez disso |
| **Mantenha a execução rápida** | Ferramentas devem rodar em <5 segundos; use `async` para I/O lento |

### 2. Entenda o Servidor HTTP

O MAF fornece `AgentFrameworkApp` que encapsula seu agente em um servidor HTTP implementando a Responses API do Foundry automaticamente — você não escreve handlers HTTP.

```python
# app.py
from azure.ai.agentserver.agentframework import AgentFrameworkApp

app = AgentFrameworkApp(agent)
# Runs on port 8088 — Foundry's standard for hosted agents
```

> A porta **8088** é obrigatória pelo Foundry. Não a altere.

### 3. Configure Seu Ambiente

```bash
# Navigate to lesson folder
cd lesson-2-hosted-maf/labs/solution

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# .\venv\Scripts\activate  # Windows PowerShell

# Install dependencies
pip install -r requirements.txt
```

### 4. Implante o Agente

O script de implantação automatiza tudo:

```powershell
cd lesson-2-hosted-maf/labs/solution
.\deploy.ps1
```

O script executa 5 etapas:
1. **Carrega** a configuração da sua infraestrutura a partir do deployment do prereq
2. **Constrói** a imagem do contêiner **no Azure** (sem Docker local necessário!)
3. **Registra** o contêiner como hosted agent no Foundry
4. **Monitora** até o agente estar em execução
5. **Testa** o agente com uma consulta de exemplo

**Saída esperada:**
```
🔨 Building container image in ACR...
⏳ This may take 8-12 minutes...
✅ Successfully tagged finance-agent-maf:latest

📦 Registering hosted agent in Foundry...
✅ Agent registered: financial-advisor-maf
   Status: Running
   Container: acrworkshopxyz.azurecr.io/finance-agent-maf:latest
```

> O build leva **8–12 minutos**. Isso é normal — o contêiner está sendo construído na nuvem do Azure, não localmente.

### 5. Verifique no Portal

Após a implantação:

1. Abra [portal.azure.com](https://portal.azure.com) → **AI Foundry** → Seu projeto
2. Navegue até **Agents** → Encontre "financial-advisor-maf"
3. Verifique: Imagem do contêiner, status, endpoint, lista de ferramentas

> **Diferença importante da Lição 1:** Você **não pode** editar instruções no portal para hosted agents — elas estão embutidas no contêiner. Para alterar o comportamento: atualize o código → reconstrua o contêiner → reimplante.

### 6. Teste o Agente

```bash
python test_agent.py
```

**Interação esperada:**
```
🤖 Financial Advisor MAF Agent

You: What's the current price of AAPL?

Agent: Let me fetch that for you.
[Calling tool: get_stock_price(symbol="AAPL")]
[Tool result: {"symbol": "AAPL", "price": 175.50, "currency": "USD"}]

The current price of Apple (AAPL) is $175.50 USD.
```

Experimente estas consultas para testar todas as ferramentas:
1. "Compare AAPL and PETR4 prices"
2. "What's the market sentiment for VALE3?"
3. "Give me an overall market summary"

Observe como o agente **decide quais ferramentas chamar** automaticamente — esse é o padrão ReAct em ação.

## 🔧 Depuração e Solução de Problemas

### Lendo Logs do Contêiner

```bash
# View logs
az cognitiveservices agent logs --name financial-advisor-maf

# Real-time tailing
az cognitiveservices agent logs --name financial-advisor-maf --follow

# Filter for errors
az cognitiveservices agent logs --name financial-advisor-maf | grep "ERROR"
```

**Exemplo de saída de log:**
```
2026-02-14 09:25:10 INFO  Starting agent server on port 8088
2026-02-14 09:26:30 INFO  Request received: /v1/chat/completions
2026-02-14 09:26:31 DEBUG Tool call: get_stock_price(symbol="AAPL")
2026-02-14 09:26:31 DEBUG Tool result: {"symbol": "AAPL", "price": 175.50}
2026-02-14 09:26:32 INFO  Response sent: 200 OK
```

### Erros Comuns

| Erro / Sintoma | Causa | Correção |
|----------------|-------|----------|
| Status do agente travado em **"Deploying"** por >20 min | Contêiner não responde na porta 8088 | Verifique logs de inicialização; confirme `EXPOSE 8088` no Dockerfile |
| Agente diz "I don't have access to data" em vez de chamar ferramenta | Ferramenta não está na lista TOOLS, ou docstring ausente | Verifique se a função está em `TOOLS = [...]` e tem docstring + type hints |
| **"requirements.txt not found"** durante o build | Caminho incorreto no Dockerfile | Garanta que `requirements.txt` existe no caminho esperado |
| **Erro de importação** no contêiner | Arquivos `__init__.py` ausentes | Garanta que todos os pacotes tenham `__init__.py` |
| **"Unauthorized"** ao chamar o Foundry | Managed Identity sem RBAC | Atribua a role "Cognitive Services User" à managed identity |
| Build do contêiner falha com erro de autenticação | ACR não acessível | Execute `az acr login --name <acr>` |
| Ferramenta retorna erro para o usuário | Exceção não tratada na ferramenta | Encapsule lógica da ferramenta em try/except, retorne `{"error": "..."}` |

### Depuração: Agente Não Chama Sua Ferramenta

Diagnóstico passo a passo:

1. **Verifique a lista TOOLS** — sua função está registrada?
   ```python
   TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]
   # ← Is your function here?
   ```

2. **Verifique a docstring** — sem ela, o LLM não sabe o que a ferramenta faz

3. **Verifique as instruções** — elas mencionam o uso de ferramentas?
   ```python
   instructions="Use available tools to fetch real-time data. Always call tools instead of making up data."
   ```

4. **Verifique os logs** — procure entradas `Tool call:`. Se ausentes, o LLM optou por não usar a ferramenta

### Dicas de Performance

Se o seu agente está lento:

- **Mensure a execução das ferramentas** — adicione medição de tempo para identificar gargalos
- **Use ferramentas assíncronas** — `asyncio.gather()` para chamadas de API em paralelo
- **Cache resultados** — preços de ações válidos por 1 minuto não precisam ser buscados novamente
- **Retorne mais dados por chamada** — reduz round-trips do LLM

## 🧭 Framework de Decisão de Padrões

```
Need custom Python tools (DB, APIs, file processing)?
    ├─ Yes → Hosted (MAF or LangGraph)
    └─ No → Is data in Azure (AI Search, Cosmos, Blob)?
        ├─ Yes, and Foundry catalog has the tool → Declarative ✅
        └─ No, or need external API → Hosted ✅
```

### Cenários do Mundo Real

| Cenário | Padrão | Justificativa |
|---|---|---|
| Chatbot de Políticas de RH usando Azure AI Search | **Declarativo** | Ferramenta do catálogo do Foundry, sem lógica customizada |
| Agente de CRM de Vendas consultando API do Salesforce | **Hosted (MAF)** | Chamadas de API customizadas necessárias |
| Gerador de Relatórios Financeiros com SQL + Excel | **Hosted (MAF)** | Acesso a banco de dados + geração de arquivos |
| Resumidor de Documentos com Code Interpreter | **Declarativo** | Code Interpreter é uma ferramenta do Foundry |
| Aprovação multi-etapas: inventário + Slack + Jira | **Hosted** | Múltiplas integrações customizadas |

> **Regra prática:** Se você precisa de 2+ APIs externas → provavelmente Hosted. Se o catálogo do Foundry tem as ferramentas → Declarativo é mais rápido.

## Comparação: Declarativo vs Hosted MAF

| Aspecto | Declarativo (Lição 1) | Hosted MAF (Lição 2) |
|---------|------------------------|-----------------------|
| **Complexidade** | Baixa | Média |
| **Tempo de Deploy** | <10 segundos | 10–15 minutos |
| **Ferramentas Customizadas** | Não | Sim (qualquer código Python) |
| **Editável no Portal** | Sim | Não (reconstruir contêiner) |
| **Custo** | Paga apenas por token | Tokens + ~$20–40/mês contêiner |
| **Escalabilidade** | Serverless (automática) | Contêineres com auto-scaling |
| **Controle** | Baixo | Alto |
| **Depuração** | Portal + logs da API | Logs do contêiner + telemetria |
| **Melhor Para** | Protótipos, Q&A simples | Produção, integrações customizadas |

> **Estratégia:** Comece declarativo para ganhos rápidos. Migre para hosted quando precisar de ferramentas customizadas. Essa é a jornada da Lição 1 → Lição 2.

## ❓ Perguntas Frequentes

**P: Posso misturar agentes declarativos e hosted no mesmo projeto?**
R: Sim! Use declarativo para tarefas simples e hosted para as complexas. Eles coexistem no mesmo projeto do Foundry.

**P: Como faço versionamento dos meus hosted agents?**
R: Faça tag das imagens de contêiner (ex: `finance-agent-maf:v1.2.0`). Registre tags específicas no Foundry para capacidade de rollback.

**P: Qual é o custo do contêiner?**
R: ~$20–40/mês para um contêiner sempre ativo (tier Basic). Escala com o número de réplicas.

**P: Hosted agents podem chamar outros agentes?**
R: Sim, via SDK. Você pode criar padrões de orquestração onde um agente delega para outros.

**P: Preciso ter Docker instalado localmente?**
R: Não. O script `deploy.ps1` usa `az acr build` que constrói o contêiner **na nuvem do Azure**. Não é necessário Docker local.

## 🏆 Desafios Autoguiados

| Desafio | Dificuldade | Descrição |
|---|---|---|
| **Adicionar tratamento de erros** | ⭐ | Encapsule todas as ferramentas em try/except e retorne mensagens de erro significativas |
| **Adicionar uma nova ferramenta** | ⭐⭐ | Implemente `get_market_sentiment(symbol)` retornando sentimento, confiança e resumo |
| **Implementar ferramentas assíncronas** | ⭐⭐ | Converta `get_stock_quote` para async com `asyncio` para chamadas de API em paralelo |
| **Adicionar logging estruturado** | ⭐⭐ | Use logs formatados em JSON para facilitar a análise no Application Insights |
| **Versionamento com tags** | ⭐⭐⭐ | Modifique `deploy.ps1` para taguear imagens com semver e registrar versões específicas |
| **Chamada multi-agente** | ⭐⭐⭐ | Crie um segundo agente e faça o primeiro delegar subtarefas via SDK |

## Referências

- [Documentação do Microsoft Agent Framework](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Guia de Hosted Agents no Foundry](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/hosted-agents)
- [Build no Azure Container Registry](https://learn.microsoft.com/azure/container-registry/container-registry-tutorial-quick-task)
- [Visão geral do Capability Host](../capability-host.pt-BR.md)
