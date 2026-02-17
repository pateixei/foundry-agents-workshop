# Lição 3 - Agente Hospedado com LangGraph

> 🇺🇸 **[Read in English](README.md)**

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-3-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-3-deployment.png) | Fluxo de implantação |
| [📁 Notas da Solução](labs/solution/README.pt-BR.md) | Código da solução e detalhes de deployment |
| [📚 Guia LangGraph + Foundry](langgraph-foundry-guide.pt-BR.md) | Deep-dive na integração LangGraph + Foundry |

## 🎯 Objetivos de Aprendizagem

Ao final desta lição, você será capaz de:

1. **Implantar** agentes LangGraph no Azure Foundry usando o padrão adapter
2. **Implementar** agentes LangGraph com ferramentas customizadas e orquestração baseada em grafos
3. **Comparar** as arquiteturas LangGraph e MAF lado a lado
4. **Registrar** agentes LangGraph como Hosted Agents no Foundry
5. **Decidir** quando usar LangGraph vs MAF para casos de uso específicos
6. **Mapear** implantações LangGraph em diferentes ambientes de nuvem

## Por que LangGraph no Foundry?

Na Lição 2, você construiu um Hosted Agent com MAF. Mas e se você já possui agentes LangGraph rodando em outro lugar, ou precisa de controle refinado sobre a orquestração?

**LangGraph é agnóstico de plataforma** — seu código principal do grafo (nós, arestas, estado) permanece o mesmo, independentemente de onde você implanta. Migrar para o Foundry requer mudanças mínimas: trocar o provedor de modelo e adicionar um arquivo de configuração.

> Suas definições de grafo, nós, arestas — **tudo inalterado**. O padrão adapter cuida da integração com a plataforma.

### Por que Implantar no Foundry em vez de Outras Plataformas?

- **Plataforma unificada** — O Foundry integra agentes com Copilot, Teams e M365
- **Governança corporativa** — Gerenciamento centralizado de agentes, RBAC, auditoria
- **Otimização de custos** — Contratos Azure EA, instâncias reservadas
- **Conformidade** — Requisitos de residência de dados via regiões Azure
- **Ecossistema** — Integração nativa com serviços Azure (Cosmos DB, Key Vault, etc.)

> Implantar no Foundry não é apenas sobre hospedagem — é **posicionamento estratégico** para IA corporativa.

## Arquitetura

**Implantação LangGraph tradicional:**
```
┌──────────────────────────┐
│ Container / Function     │
│  ├─> LangGraph code      │
│  └─> LLM API client      │
└──────────┬───────────────┘
           │ (triggered by)
           ▼
┌──────────────────────────┐
│ API Gateway              │
└──────────────────────────┘
```

**No Azure Foundry:**
```
┌──────────────────────────────────┐
│ Foundry Hosted Agent             │
│  ├─> Container (same LangGraph!) │
│  └─> Azure OpenAI via Foundry    │
└──────────┬───────────────────────┘
           │ (accessed via)
           ▼
┌──────────────────────────────────┐
│ Foundry Responses API            │
└──────────────────────────────────┘
```

A diferença principal: Hosted Agents no Foundry são **contêineres always-on** projetados para cargas de trabalho persistentes de agentes. Se você já rodou LangGraph em contêineres antes, a implantação no Foundry é direta.

## Conceitos Principais

| Conceito | Descrição |
|---|---|
| **Hosted Agent** | Contêiner próprio registrado no Foundry que expõe a Responses API |
| **LangGraph** | Framework de grafos para orquestração de agentes — você define nós, arestas e roteamento condicional |
| **Adapter** | `azure-ai-agentserver-langgraph` converte um grafo LangGraph em um servidor HTTP compatível com o Foundry |
| **caphost.json** | Arquivo de configuração que indica ao adapter como carregar seu grafo e expô-lo ao Foundry |
| **Capability Host** | Recurso no nível do Foundry account que habilita Hosted Agents |
| **Managed Identity** | O contêiner roda com a identidade do projeto (necessita roles RBAC) — sem chaves de API no código |

## Estrutura da Lição

```
lesson-3-hosted-langgraph/
  README.md
  langgraph-foundry-guide.md     # Deep-dive guide
  demos/                          # Demo walkthrough
  labs/                           # Hands-on lab
    solution/
      main.py                     # LangGraph agent definition
      Dockerfile                  # Container (similar to MAF)
      requirements.txt            # Dependencies
      deploy.ps1                  # Deployment script
      caphost.json                # Foundry adapter config
      README.md                   # Solution notes
  media/                          # Architecture diagrams
```

### Arquivos Principais Explicados

| Arquivo | Função |
|---|---|
| `main.py` | Agente LangGraph — definição de estado, ferramentas, nós/arestas do grafo, app compilado |
| `caphost.json` | A "cola" entre LangGraph e Foundry — indica ao adapter onde está seu app |
| `Dockerfile` | Definição do contêiner — executa o adapter (não `main.py` diretamente) |
| `deploy.ps1` | Implantação com um clique — faz build no ACR, registra no Foundry, testa |

> **Mais simples que MAF**: Sem pastas `src/`, sem abstração de agent server. LangGraph + arquivo de configuração + adapter.

## Walkthrough Passo a Passo

### 1. Entender o Código do Agente LangGraph

O código do agente é **LangGraph puro** — nada específico do Foundry, exceto o provedor de modelo:

**Definição de estado:**
```python
class AgentState(TypedDict):
    messages: Annotated[list, "conversation history"]
    next_action: str
```

**Ferramentas (funções Python simples):**
```python
def get_stock_price(symbol: str) -> dict:
    """Fetch stock price."""
    prices = {"AAPL": 175.50, "PETR4": 38.20, "VALE3": 65.80}
    return {
        "symbol": symbol.upper(),
        "price": prices.get(symbol.upper(), 0.0),
        "currency": "USD" if not symbol.endswith("3") else "BRL"
    }
```

**Inicialização do modelo (a parte específica da plataforma):**
```python
# Azure OpenAI model via Foundry
model = AzureChatOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    api_version="2024-02-01",
    deployment_name="gpt-4",
    azure_ad_token_provider=get_bearer_token_provider(
        DefaultAzureCredential(),
        "https://cognitiveservices.azure.com/.default"
    )
)
```

> Se você já usou LangGraph com outros provedores, esta é a única mudança no código — trocar `ChatOpenAI` por `AzureChatOpenAI` e usar **Managed Identity** (`DefaultAzureCredential`) em vez de chaves de API.

**Definição do grafo (LangGraph inalterado):**
```python
workflow = StateGraph(AgentState)

workflow.add_node("agent", agent_node)
workflow.add_node("tool_executor", tool_executor_node)

workflow.set_entry_point("agent")
workflow.add_conditional_edges(
    "agent",
    should_continue,
    {"continue": "tool_executor", "end": END}
)
workflow.add_edge("tool_executor", "agent")

app = workflow.compile()
```

### 2. Entender o Adapter do Foundry (`caphost.json`)

Este arquivo de configuração é a "cola" entre LangGraph e o Foundry:

```json
{
  "version": "1.0",
  "agent": {
    "name": "financial-advisor-langgraph",
    "description": "Financial market agent built with LangGraph",
    "entry_point": "main:app",
    "port": 8088,
    "protocol": "responses-api"
  },
  "environment": {
    "AZURE_OPENAI_ENDPOINT": "${AZURE_OPENAI_ENDPOINT}",
    "AZURE_OPENAI_API_VERSION": "2024-02-01"
  }
}
```

| Campo | Significado |
|---|---|
| `entry_point` | Aponta para a variável do grafo compilado: `arquivo:variável` (ou seja, `main.py` → `app`) |
| `port` | Deve ser **8088** — padrão do Foundry para Hosted Agents |
| `protocol` | `responses-api` — o adapter traduz LangGraph para este protocolo do Foundry |
| `environment` | Variáveis injetadas pelo Foundry em tempo de execução (endpoint do modelo, etc.) |

### 3. Entender o Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .
COPY caphost.json .

EXPOSE 8088

# Entry point: the ADAPTER runs, not main.py directly
CMD ["python", "-m", "azure.ai.agentserver.langgraph", "--config", "caphost.json"]
```

> **Importante:** O contêiner executa o **adapter** (`azure.ai.agentserver.langgraph`), não seu `main.py` diretamente. O adapter lê o `caphost.json`, carrega seu `app` compilado e o encapsula em um servidor HTTP. Isso é diferente do MAF, onde o SDK do MAF fornece o servidor.

### 4. Configurar Seu Ambiente

```bash
cd lesson-3-hosted-langgraph/labs/solution

# Install dependencies
pip install -r requirements.txt
```

Pacotes principais:
- `langgraph` — O framework de grafos
- `langchain-openai` — Integração com Azure OpenAI
- `azure-identity` — Autenticação via Managed Identity
- `azure-ai-agentserver-langgraph` — **Adapter do Foundry** (encapsula LangGraph na Responses API do Foundry)

> Sem `azure-ai-agentserver-langgraph`, o Foundry não saberia como se comunicar com seu agente LangGraph.

### 5. (Opcional) Testar Localmente

Você pode testar o grafo antes de implantar:

```python
python -c "
from main import app

state = {'messages': [('user', 'What is AAPL price?')], 'next_action': ''}
result = app.invoke(state)
print(result)
"
```

> LangGraph suporta invocação direta — sem necessidade de servidor HTTP para testes. Isso torna os testes unitários muito mais simples comparados ao MAF.

### 6. Implantar o Agente

```powershell
cd labs/solution
.\deploy.ps1
```

O script faz o build do contêiner no Azure, registra o Hosted Agent no Foundry e o testa. O build leva **8–12 minutos**.

**Saída esperada:**
```
🔨 Building LangGraph agent container...
✅ Image built: acrworkshopxyz.azurecr.io/finance-agent-lg:latest

📦 Registering Hosted Agent in Foundry...
✅ Agent registered!
   Status: Running ✅

🧪 Testing agent...
Response: The current price of VALE (VALE3) is R$ 65.80 BRL.
🎉 Agent is live and responding!
```

### 7. Testar o Agente

```bash
cd labs/solution
python test_agent.py
```

Experimente estas consultas:
1. "What's the current price of AAPL?"
2. "Compare PETR4 and VALE3"
3. "Give me a full market summary"

## MAF vs LangGraph: Comparação Lado a Lado

### Definição de Ferramentas

| MAF | LangGraph |
|-----|-----------|
| Funções simples em uma lista: `tools=[fn1, fn2]` | Funções simples registradas como nós do grafo |
| Docstrings usadas para schema da ferramenta | Docstrings usadas para schema da ferramenta |
| Type hints com `Annotated` para parâmetros | Type hints padrão |

### Orquestração

| MAF | LangGraph |
|-----|-----------|
| Loop ReAct automático — o framework decide | Grafo explícito com arestas condicionais — **você** decide |
| Menos código, menos controle | Mais código, controle total |
| Melhor para padrões convencionais | Melhor para fluxos multi-etapa complexos |

### Gerenciamento de Estado

| MAF | LangGraph |
|-----|-----------|
| Abstraído — gerenciado internamente pelo MAF | `TypedDict` explícito — você define cada campo |
| Menos controle, mais simples | Controle total, mais código |

### Testes

| MAF | LangGraph |
|-----|-----------|
| Requer agent server para testes | Grafo pode ser invocado diretamente (sem servidor) |
| Foco em testes de integração | Amigável a testes unitários |

### Matriz de Comparação Completa

| Aspecto | MAF | LangGraph |
|---------|-----|-----------|
| **Curva de Aprendizado** | Baixa | Média |
| **Verbosidade do Código** | Baixa (decorators) | Média (grafo explícito) |
| **Controle de Orquestração** | Baixo (ReAct automático) | Alto (roteamento customizado) |
| **Gerenciamento de Estado** | Abstraído | TypedDict explícito |
| **Multi-Agent** | Mais difícil (agentes aninhados) | Natural (composição de grafos) |
| **Testes** | Via HTTP | Invocação direta |
| **Esforço de Adoção** | Moderado (framework novo) | Baixo (se você já conhece LangGraph) |
| **Lock-in de Plataforma** | Nativo do Azure | Agnóstico de framework (funciona em qualquer lugar) |
| **Melhor Para** | Projetos novos, agentes simples | Fluxos complexos, times com experiência em LangGraph |

> **Escolha MAF** para projetos greenfield com padrões convencionais. **Escolha LangGraph** para orquestração complexa ou quando você já tem experiência com LangGraph. Ambos são válidos — coexistem no mesmo projeto Foundry.

## 🧭 Avaliação de Implantação

Use este checklist para estimar o esforço de migração dos seus agentes LangGraph existentes:

| Fator | Baixo Esforço (1–2 dias) | Médio (1–2 semanas) | Alto (1+ mês) |
|---|---|---|---|
| **Complexidade do grafo** | 1–3 nós | 4–10 nós | 10+ nós, subgrafos |
| **Provedor de modelo** | Já usa Azure OpenAI | Precisa trocar provedor | Múltiplos provedores |
| **Serviços da plataforma** | Apenas APIs genéricas | Alguns equivalentes Azure necessários | Integrações profundas específicas da plataforma |
| **Estado/checkpointing** | Stateless | Precisa de backend Azure Storage | Lógica de checkpointing customizada |
| **Carga de trabalho** | Dev/teste | Staging | Produção crítica |

**Árvore de decisão:**
```
Devo implantar meu agente LangGraph no Foundry?

Minha organização usa M365/Azure?
    ├─ Sim → Forte valor estratégico → Avaliar esforço
    │   ├─ Baixo  → Implantar agora
    │   ├─ Médio  → POC primeiro, depois implantar
    │   └─ Alto   → Faseado: rodar em paralelo, validar, migrar
    └─ Não → Avaliar se os recursos corporativos justificam a mudança
        └─ Considerar: entrega via Teams, integração com Copilot, governança
```

## 🔧 Solução de Problemas

| Erro / Sintoma | Causa | Correção |
|-----------------|-------|---------|
| `Entry point 'main:app' not found` | Nome da variável não confere | Verifique que `app = workflow.compile()` existe em `main.py` e corresponde ao `caphost.json` |
| `caphost.json not found` | Não foi copiado no Dockerfile | Adicione `COPY caphost.json .` ao Dockerfile |
| Grafo funciona localmente mas não no Foundry | Adapter ausente ou porta errada | Verifique que o CMD do Dockerfile usa o adapter: `python -m azure.ai.agentserver.langgraph --config caphost.json` |
| Falha de autenticação Azure OpenAI | Managed Identity não configurada | Atribua a role "Cognitive Services User" à Managed Identity |
| Porta 8088 já em uso | Contêiner conflitante | Pare outros agentes ou verifique conflitos de porta |
| Checkpoints não persistem | Usando checkpointer em memória | Troque para armazenamento persistente (Cosmos DB ou Table Storage) |
| Status do agente preso em "Deploying" | Falha na inicialização do contêiner | Verifique os logs: `az cognitiveservices agent logs --name <agent>` |

### Checkpointing Persistente

Se você precisa de persistência de estado entre sessões, substitua o armazenamento em memória pelo Azure Table Storage:

```python
from langgraph.checkpoint.azure import AzureTableCheckpointer

checkpointer = AzureTableCheckpointer(
    connection_string=os.getenv("AZURE_STORAGE_CONNECTION_STRING")
)
app = workflow.compile(checkpointer=checkpointer)
```

## ❓ Perguntas Frequentes

**P: Preciso reescrever meu agente LangGraph para o Foundry?**
R: Não. Seu código do grafo (nós, arestas, estado) permanece o mesmo. Você apenas troca o provedor de modelo para `AzureChatOpenAI` e adiciona um arquivo de configuração `caphost.json`.

**P: Posso rodar o mesmo agente no Foundry e em outras plataformas simultaneamente?**
R: Sim. Mantenha o código principal do grafo compartilhado e troque apenas o provedor de modelo e a configuração de implantação por plataforma.

**P: Qual é a diferença entre o servidor MAF e o adapter do LangGraph?**
R: O MAF fornece `AgentFrameworkApp` como um servidor HTTP embutido. O LangGraph usa um adapter separado (`azure-ai-agentserver-langgraph`) que encapsula seu grafo compilado. Ambos expõem a mesma Responses API do Foundry na porta 8088.

**P: Posso usar checkpointing do LangGraph no Foundry?**
R: Sim. Use Azure Table Storage ou Cosmos DB como backend de checkpoint em vez de armazenamento em memória.

**P: Quando devo escolher LangGraph em vez de MAF?**
R: Escolha LangGraph quando precisar de controle refinado de orquestração, tiver fluxos multi-etapa complexos, quiser composição de grafos para padrões multi-agent, ou já possuir código LangGraph existente.

## 🏆 Desafios Autônomos

| Desafio | Dificuldade | Descrição |
|---|---|---|
| **Adicionar uma ferramenta customizada** | ⭐ | Adicione `get_market_sentiment(symbol)` ao grafo e teste |
| **Migrar um agente existente** | ⭐⭐ | Pegue um dos seus agentes LangGraph e implante-o no Foundry |
| **Implementar checkpointing** | ⭐⭐ | Adicione o Azure Table Storage checkpointer para estado persistente |
| **Construir o mesmo agente em ambos** | ⭐⭐⭐ | Implemente o mesmo agente financeiro em MAF e LangGraph, compare o tempo de desenvolvimento |
| **Grafo multi-agent** | ⭐⭐⭐ | Crie um LangGraph com subgrafos que delegam para sub-agentes especializados |

## Referências

- [Documentação LangGraph](https://langchain-ai.github.io/langgraph/)
- [Guia LangGraph + Foundry](langgraph-foundry-guide.pt-BR.md)
- [Referência do adapter Azure LangGraph](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/hosted-agents)
- [Guia de checkpointing LangGraph](https://langchain-ai.github.io/langgraph/concepts/persistence/)
- [Visão geral do Capability Host](../capability-host.pt-BR.md)
