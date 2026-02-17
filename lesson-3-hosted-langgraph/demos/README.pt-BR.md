# Demo 3: Hosted Agent com LangGraph no Azure Foundry

> **Tipo de Demo**: Demonstração guiada pelo instrutor. Esta demo referencia o código-fonte em `lesson-3-hosted-langgraph/labs/solution/`. O instrutor percorre o código ao vivo na tela.

## Visão Geral

Demonstra a implantação de um **agente LangGraph como Hosted Agent (Agente Hospedado)** no Azure Foundry. Mostra como equipes que já utilizam LangGraph podem trazer seu código existente para o Foundry com alterações mínimas, aproveitando a infraestrutura gerenciada e a governança corporativa do Azure.

## Conceitos-Chave

- ✅ Arquitetura StateGraph do LangGraph
- ✅ Integração com Azure OpenAI via `AzureChatOpenAI`  
- ✅ Padrão de adaptador Foundry (`caphost.json`)
- ✅ Implantação de contêiner no Foundry
- ✅ Flexibilidade de implantação multiplataforma

## Arquitetura

```
LangGraph Code (portable) + Adapter Config → Azure Foundry Hosted Agent
```

## Pré-requisitos

- Projeto Azure Foundry com modelo
- ACR para armazenamento de contêineres
- Docker Desktop
- Conhecimento de LangGraph (recomendado)

## Início Rápido

```powershell
cd demo-3-hosted-langgraph
.\deploy.ps1
```

## Arquivos Principais

- `main.py` - Agente LangGraph com StateGraph
- `caphost.json` - Configuração do adaptador Foundry
- `Dockerfile` - Definição do contêiner
- `deploy.ps1` - Implantação automatizada

## Exemplo de Código: Agente LangGraph

```python
from langgraph.graph import StateGraph, END
from langchain_openai import AzureChatOpenAI
from typing import TypedDict, Annotated

class AgentState(TypedDict):
    messages: Annotated[list, "conversation history"]
    next_action: str

# Define tools (same as MAF)
def get_stock_price(symbol: str) -> dict:
    # Implementation...
    pass

# Create Azure OpenAI model
model = AzureChatOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-05-01-preview",
    azure_deployment="gpt-4",
    temperature=0.7,
)

# Build LangGraph graph
workflow = StateGraph(AgentState)
workflow.add_node("agent", lambda state: agent_node(state, model, tools))
workflow.add_node("tools", lambda state: tool_node(state, tools))
workflow.add_edge("agent", "tools")
workflow.add_edge("tools", "agent")
workflow.set_entry_point("agent")

app = workflow.compile()
```

## Configuração do caphost.json

```json
{
  "name": "langgraph-financial-agent",
  "version": "1.0",
  "entry": "main:app",
  "runtime": "python",
  "port": 8080,
  "health_check": "/health"
}
```

## Comparação: LangGraph vs MAF

| Funcionalidade | LangGraph (Esta Demo) | MAF (Demo 2) |
|---------|----------------------|--------------|
| **Framework** | Baseado em grafo | Baseado em decorators |
| **Orquestração** | Manual (edges, nodes) | Automática (ReAct) |
| **Gerenciamento de Estado** | TypedDict | Contexto integrado |
| **Melhor Para** | Workflows complexos | Agente único + tools |
| **Portabilidade** | Alta (baseado em grafo) | Nativo Azure |

## Quando Usar LangGraph vs MAF

**Use LangGraph quando:**
- A equipe já possui expertise ou código existente em LangGraph
- Necessita de controle explícito sobre o fluxo do agente
- Construindo workflows multi-agente
- Gerenciamento de estado complexo necessário

**Use MAF quando:**
- Iniciando novo agente do zero no Azure
- Padrões simples de chamada de tools
- Quer integração nativa com Foundry
- Prefere simplicidade sobre controle

## Resolução de Problemas

**Problema: "caphost.json not found"**  
**Solução**: Verifique se o arquivo existe no diretório raiz do contêiner e se o comando COPY no Dockerfile o inclui

**Problema: "Model authentication failed"**  
**Solução**: Verifique `AZURE_OPENAI_ENDPOINT` e se a Managed Identity (Identidade Gerenciada) possui a role "Cognitive Services User"

**Problema: "Graph compilation error"**  
**Solução**: Verifique se todos os nodes possuem edges definidos; o entry point deve estar definido

## Checklist de Implantação (LangGraph → Foundry)

- [x] Configurar `AzureChatOpenAI` como provedor de modelo
- [x] Configurar Managed Identity para autenticação segura
- [x] Adicionar `caphost.json` para adaptador Foundry
- [x] Configurar contêiner para expor porta 8080
- [x] Configurar roles RBAC para acesso ao Azure OpenAI
- [x] Habilitar Application Insights para observabilidade
- [x] Fazer push da imagem de contêiner para ACR

## Recursos

- [Documentação LangGraph](https://langchain-ai.github.io/langgraph/)
- [Referência AzureChatOpenAI](https://python.langchain.com/docs/integrations/chat/azure_chat_openai)
- [Azure AI Foundry Hosted Agents](https://learn.microsoft.com/azure/ai-foundry/concepts/hosted-agents)

---

**Nível da Demo**: Intermediário-Avançado  
**Tempo Estimado**: 25-30 minutos  
**Melhor Para**: Equipes com experiência em LangGraph implantando no Azure Foundry
