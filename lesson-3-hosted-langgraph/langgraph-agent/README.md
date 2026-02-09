# Lesson 2 - Hosted Agent com LangGraph no Azure AI Foundry

Nesta licao, criamos um **agente hospedado (hosted agent)** no Azure AI Foundry
usando o framework **LangGraph** do LangChain.

## Arquitetura

O agente segue o padrao **ReAct** (Reason + Act):

1. O LLM recebe a mensagem do usuario
2. Decide se precisa chamar uma ferramenta (tool) ou responder diretamente
3. Se chamou uma tool, executa e retorna o resultado ao LLM
4. O ciclo repete ate o LLM produzir uma resposta final

```
START -> llm_call -> [tool_calls?] -> environment -> llm_call -> ... -> END
```

## Ferramentas Disponiveis

| Ferramenta | Descricao |
|---|---|
| `get_stock_price` | Consulta preco de acoes (PETR4, VALE3, AAPL, etc.) |
| `get_market_summary` | Resumo dos principais indices (Ibovespa, S&P 500, etc.) |
| `get_exchange_rate` | Taxa de cambio (USD/BRL, EUR/BRL, BTC/USD, etc.) |

> **Nota:** As ferramentas usam dados simulados para fins didaticos.

## Estrutura de Arquivos

```
lesson-2/langgraph-agent/
  main.py                  # Agente LangGraph + servidor hosted agent
  # create_hosted_agent.py movido para prereq/
  test_agent.py            # Script de teste do agente em execucao
  deploy.ps1               # Script de deploy completo (CLI)
  requirements.txt         # Dependencias Python
  Dockerfile               # Container para hosted agent
  README.md                # Este arquivo
```

## Como Funciona o Hosted Agent

O pacote `azure-ai-agentserver-langgraph` fornece o adapter que:

1. Recebe um grafo LangGraph compilado
2. Expoe a **Responses API** na porta 8088
3. O Foundry roteia chamadas dos clientes para o container

```python
from azure.ai.agentserver.langgraph import from_langgraph
agent = build_agent()          # StateGraph compilado
adapter = from_langgraph(agent)
adapter.run()                  # Inicia servidor na porta 8088
```

## Pre-requisitos

- Infraestrutura da pasta `prereq/` ja deployada
- Azure CLI com extensao `cognitiveservices` (`az extension add --name cognitiveservices --upgrade`)
- Python 3.12+
- `az login` realizado

## Deploy Passo a Passo

O script `deploy.ps1` automatiza os passos abaixo, mas caso precise fazer
manualmente ou entender o que acontece, siga a sequencia:

### 1. Capability Host (uma unica vez por account)

Hosted agents exigem um **Capability Host** no nivel do account.
Se ainda nao foi criado, execute:

```powershell
az rest --method put `
    --url "https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY_NAME>/capabilityHosts/accountcaphost?api-version=2025-04-01-preview" `
    --body '{\"properties\":{\"capabilityHostKind\":\"Agents\",\"enablePublicHostingEnvironment\":true}}'
```

### 2. Build da Imagem no ACR

```powershell
cd lesson-2/langgraph-agent
az acr build --registry <ACR_NAME> --image lg-market-agent:v1 --file Dockerfile . --no-logs
```

> **Nota Windows:** Use `--no-logs` para evitar `UnicodeEncodeError` causado pelo
> colorama/cp1252 ao exibir logs do ACR build no PowerShell 5.1.

### 3. Permissoes RBAC (managed identity do projeto)

O projeto do Foundry tem uma managed identity que precisa de duas roles:

| Role | Scope | Motivo |
|---|---|---|
| **AcrPull** | Container Registry | Para baixar a imagem do container |
| **Cognitive Services OpenAI User** | AI Foundry Account | Para o container chamar o modelo GPT |

```powershell
# Obter o principal ID do projeto
$PRINCIPAL = az resource show `
    --ids "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>/projects/<PROJECT>" `
    --query "identity.principalId" -o tsv

# AcrPull no ACR
az role assignment create --assignee $PRINCIPAL --role "AcrPull" `
    --scope $(az acr show --name <ACR> --query id -o tsv)

# OpenAI User no Foundry account
az role assignment create --assignee $PRINCIPAL --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>"
```

> **Importante:** O resource type do projeto Foundry e
> `Microsoft.CognitiveServices/accounts/projects` (NAO `MachineLearningServices`).

### 4. Criar e iniciar o agente

```powershell
# Criar versao (sem iniciar)
az cognitiveservices agent create `
    --account-name <FOUNDRY> --project-name <PROJECT> `
    --name lg-market-agent `
    --image <ACR>.azurecr.io/lg-market-agent:v1 `
    --cpu 1 --memory 2Gi `
    --protocol responses --protocol-version v1 `
    --env AZURE_AI_PROJECT_ENDPOINT=<PROJECT_ENDPOINT> `
         AZURE_AI_MODEL_DEPLOYMENT_NAME=<MODEL> `
         AZURE_OPENAI_ENDPOINT=https://<FOUNDRY>.openai.azure.com/ `
    --no-start

# Iniciar o agente
az cognitiveservices agent start `
    --account-name <FOUNDRY> --project-name <PROJECT> `
    --name lg-market-agent --agent-version 1
```

O ciclo de vida do agente e: `Stopped -> Starting -> Started (Running)`.
Aguarde ~2 minutos ate o status mudar para Running.

### 5. Testar o agente

```powershell
python test_agent.py
```

## Deploy Automatizado

```powershell
cd lesson-2/langgraph-agent
.\deploy.ps1
```

## Invocacao do Agente (Detalhes Tecnicos)

Hosted agents sao invocados via **Responses API** com um campo `agent`
no body que identifica o agente e a versao.

### Usando o SDK `azure-ai-projects`

```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

endpoint = "https://<foundry>.services.ai.azure.com/api/projects/<project>"

with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=endpoint, credential=credential) as client,
    client.get_openai_client() as oai,
):
    response = oai.responses.create(
        input=[{"role": "user", "content": "Qual o preco da PETR4?"}],
        extra_body={
            "agent": {
                "id": "lg-market-agent",
                "name": "lg-market-agent",
                "version": "3",
                "type": "agent_reference",
            }
        },
    )
    print(response.output_text)
```

### Usando REST direto

```python
import requests
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
token = credential.get_token("https://ai.azure.com/.default").token

url = "https://<foundry>.services.ai.azure.com/api/projects/<project>/openai/responses?api-version=2025-11-15-preview"
body = {
    "input": [{"role": "user", "content": "Qual o preco da PETR4?"}],
    "agent": {
        "id": "lg-market-agent",
        "name": "lg-market-agent",
        "version": "3",
        "type": "agent_reference",
    },
}
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

r = requests.post(url, headers=headers, json=body, timeout=120)
# Extrair texto da resposta
for item in r.json().get("output", []):
    if item.get("type") == "message":
        for c in item.get("content", []):
            if c.get("type") == "output_text":
                print(c["text"])
```

## Workarounds e Bugs Conhecidos

### 1. AgentReference sem campo `id` (SDK)

O `AgentReference` do SDK `azure-ai-projects==2.0.0b3` nao inclui o campo `id`,
mas o servico Foundry exige esse campo. Workaround: montar o dict manualmente
com `id`, `name`, `version` e `type` (veja exemplos acima).

### 2. AgentReference no container (agentserver-core)

O servico Foundry envia um campo `id` ao rotear requests para o container, mas
`azure-ai-agentserver-core==1.0.0b10` rejeita campos desconhecidos em
`AgentReference`. O `main.py` inclui um monkey-patch em
`_patch_agent_reference()` para lidar com isso.

### 3. `init_chat_model` requer `azure_endpoint` e `api_version`

Ao usar `init_chat_model("azure_openai:...")` com LangChain, os parametros
`azure_endpoint` e `api_version` sao obrigatorios. O container recebe o
endpoint via variavel de ambiente `AZURE_OPENAI_ENDPOINT`.

### 4. `az acr build` UnicodeEncodeError no Windows

O `az acr build` falha com `UnicodeEncodeError: 'charmap' codec` no
PowerShell 5.1 devido ao colorama. Use `--no-logs` para contornar:

```powershell
az acr build --registry <ACR> --image <TAG> --file Dockerfile . --no-logs
```

### 5. Audience do token para invocacao

- Endpoint `*.services.ai.azure.com` (projeto): audience `https://ai.azure.com/.default`
- Endpoint `*.openai.azure.com` (OpenAI): audience `https://cognitiveservices.azure.com/.default`

O `client.get_openai_client()` do SDK `AIProjectClient` ja configura isso
automaticamente (api-version `2025-11-15-preview`).

## Diferenca da Lesson 1

| Aspecto | Lesson 1 | Lesson 2 |
|---|---|---|
| Tipo | Prompt-based agent | Hosted agent (container) |
| Framework | SDK direto (`azure-ai-agents`) | LangGraph + adapter |
| Execucao | Serverless no Foundry | Container proprio no Foundry |
| Tools | Code Interpreter (built-in) | Custom tools (Python) |
| Complexidade | Simples | Media |

## Versoes de SDK Utilizadas

| Pacote | Versao |
|---|---|
| `azure-ai-agentserver-langgraph` | 1.0.0b10 |
| `azure-ai-agentserver-core` | 1.0.0b10 (dependencia) |
| `azure-ai-projects` | 2.0.0b3 (cliente local) |
| `azure-ai-agents` | 1.2.0b5 (dependencia) |
| `langchain` / `langgraph` | Instalados pelo agentserver |
