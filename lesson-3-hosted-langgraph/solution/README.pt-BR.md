# Lição 2 - Agente Hospedado com LangGraph no Azure AI Foundry

Nesta lição, criamos um **agente hospedado** no Azure AI Foundry
usando o framework **LangGraph** do LangChain.

## Arquitetura

O agente segue o padrão **ReAct** (Reason + Act):

1. O LLM recebe a mensagem do usuário
2. Decide se precisa chamar uma ferramenta ou responder diretamente
3. Se chamou uma ferramenta, executa e retorna o resultado ao LLM
4. O ciclo se repete até o LLM produzir uma resposta final

```
START -> llm_call -> [tool_calls?] -> environment -> llm_call -> ... -> END
```

## Ferramentas Disponíveis

| Ferramenta | Descrição |
|---|---|
| `get_stock_price` | Consulta preços de ações (PETR4, VALE3, AAPL, etc.) |
| `get_market_summary` | Resumo dos principais índices (Ibovespa, S&P 500, etc.) |
| `get_exchange_rate` | Taxa de câmbio (USD/BRL, EUR/BRL, BTC/USD, etc.) |

> **Nota:** As ferramentas usam dados simulados para fins educacionais.

## Estrutura de Arquivos

```
lesson-3-hosted-langgraph/solution/
  main.py                  # Agente LangGraph + servidor do agente hospedado
  # create_hosted_agent.py movido para prereq/
  test_agent.py            # Script de teste para executar o agente
  deploy.ps1               # Script completo de implantação (CLI)
  requirements.txt         # Dependências Python
  Dockerfile               # Contêiner para agente hospedado
  README.md                # Este arquivo
```

## Como o Agente Hospedado Funciona

O pacote `azure-ai-agentserver-langgraph` fornece o adaptador que:

1. Recebe um grafo LangGraph compilado
2. Expõe a **Responses API** na porta 8088
3. O Foundry roteia chamadas do cliente para o contêiner

```python
from azure.ai.agentserver.langgraph import from_langgraph
agent = build_agent()          # StateGraph compilado
adapter = from_langgraph(agent)
adapter.run()                  # Inicia servidor na porta 8088
```

## Pré-requisitos

- Infraestrutura da pasta `prereq/` já implantada
- Azure CLI com extensão `cognitiveservices` (`az extension add --name cognitiveservices --upgrade`)
- Python 3.12+
- `az login` completado

## Implantação Passo a Passo

O script `deploy.ps1` automatiza os passos abaixo, mas se você precisar fazer
manualmente ou entender o que acontece, siga a sequência:

### 1. Capability Host (uma vez por conta)

Agentes hospedados requerem um **Capability Host** no nível da conta.
Se ainda não criado, execute:

```powershell
az rest --method put `
    --url "https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY_NAME>/capabilityHosts/accountcaphost?api-version=2025-04-01-preview" `
    --body '{\"properties\":{\"capabilityHostKind\":\"Agents\",\"enablePublicHostingEnvironment\":true}}'
```

### 2. Construir Imagem no ACR

```powershell
cd lesson-2/langgraph-agent
az acr build --registry <ACR_NAME> --image lg-market-agent:v1 --file Dockerfile . --no-logs
```

> **Nota Windows:** Use `--no-logs` para evitar `UnicodeEncodeError` causado por
> colorama/cp1252 ao exibir logs de build do ACR no PowerShell 5.1.

### 3. Permissões RBAC (managed identity do projeto)

O projeto Foundry tem uma managed identity que precisa de duas roles:

| Role | Escopo | Motivo |
|---|---|---|
| **AcrPull** | Container Registry | Para puxar a imagem do contêiner |
| **Cognitive Services OpenAI User** | AI Foundry Account | Para o contêiner chamar o modelo GPT |

```powershell
# Obter o principal ID do projeto
$PRINCIPAL = az resource show `
    --ids "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>/projects/<PROJECT>" `
    --query "identity.principalId" -o tsv

# AcrPull no ACR
az role assignment create --assignee $PRINCIPAL --role "AcrPull" `
    --scope $(az acr show --name <ACR> --query id -o tsv)

# OpenAI User na conta Foundry
az role assignment create --assignee $PRINCIPAL --role "Cognitive Services OpenAI User" `
    --scope "/subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.CognitiveServices/accounts/<FOUNDRY>"
```

> **Importante:** O tipo de recurso do projeto Foundry é
> `Microsoft.CognitiveServices/accounts/projects` (NÃO `MachineLearningServices`).

### 4. Criar e iniciar o agente

```powershell
# Criar versão (sem iniciar)
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

O ciclo de vida do agente é: `Stopped -> Starting -> Started (Running)`.
Aguarde ~2 minutos para o status mudar para Running.

### 5. Testar o agente

```powershell
python test_agent.py
```

## Implantação Automatizada

```powershell
cd lesson-2/langgraph-agent
.\deploy.ps1
```

## Invocação do Agente (Detalhes Técnicos)

Agentes hospedados são invocados via **Responses API** com um campo `agent`
no body que identifica o agente e a versão.

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
        input=[{"role": "user", "content": "What's the price of PETR4?"}],
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

### Usando REST diretamente

```python
import requests
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
token = credential.get_token("https://ai.azure.com/.default").token

url = "https://<foundry>.services.ai.azure.com/api/projects/<project>/openai/responses?api-version=2025-11-15-preview"
body = {
    "input": [{"role": "user", "content": "What's the price of PETR4?"}],
    "agent": {
        "id": "lg-market-agent",
        "name": "lg-market-agent",
        "version": "3",
        "type": "agent_reference",
    },
}
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

r = requests.post(url, headers=headers, json=body, timeout=120)
# Extract response text
for item in r.json().get("output", []):
    if item.get("type") == "message":
        for c in item.get("content", []):
            if c.get("type") == "output_text":
                print(c["text"])
```

## Workarounds e Bugs Conhecidos

### 1. AgentReference sem campo `id` (SDK)

O `AgentReference` do SDK `azure-ai-projects==2.0.0b3` não inclui o campo `id`,
mas o serviço Foundry exige este campo. Workaround: construa manualmente o dict
com `id`, `name`, `version` e `type` (veja exemplos acima).

### 2. AgentReference no contêiner (agentserver-core)

O serviço Foundry envia um campo `id` ao rotear requisições para o contêiner, mas
`azure-ai-agentserver-core==1.0.0b10` rejeita campos desconhecidos em
`AgentReference`. O `main.py` inclui um monkey-patch em
`_patch_agent_reference()` para tratar isso.

### 3. `init_chat_model` requer `azure_endpoint` e `api_version`

Ao usar `init_chat_model("azure_openai:...")` com LangChain, os
parâmetros `azure_endpoint` e `api_version` são obrigatórios. O contêiner recebe o
endpoint via variável de ambiente `AZURE_OPENAI_ENDPOINT`.

### 4. `az acr build` UnicodeEncodeError no Windows

`az acr build` falha com `UnicodeEncodeError: 'charmap' codec` no
PowerShell 5.1 devido ao colorama. Use `--no-logs` como workaround:

```powershell
az acr build --registry <ACR> --image <TAG> --file Dockerfile . --no-logs
```

### 5. Token audience para invocação

- Endpoint `*.services.ai.azure.com` (projeto): audience `https://ai.azure.com/.default`
- Endpoint `*.openai.azure.com` (OpenAI): audience `https://cognitiveservices.azure.com/.default`

O `client.get_openai_client()` do SDK `AIProjectClient` já configura isso
automaticamente (api-version `2025-11-15-preview`).

## Diferença da Lição 1

| Aspecto | Lição 1 | Lição 2 |
|---|---|---|
| Tipo | Agente baseado em prompt | Agente hospedado (contêiner) |
| Framework | SDK direto (`azure-ai-agents`) | LangGraph + adaptador |
| Execução | Serverless no Foundry | Contêiner próprio no Foundry |
| Ferramentas | Code Interpreter (built-in) | Ferramentas customizadas (Python) |
| Complexidade | Simples | Média |

## Versões do SDK Utilizadas

| Pacote | Versão |
|---|---|
| `azure-ai-agentserver-langgraph` | 1.0.0b10 |
| `azure-ai-agentserver-core` | 1.0.0b10 (dependência) |
| `azure-ai-projects` | 2.0.0b3 (cliente local) |
| `azure-ai-agents` | 1.2.0b5 (dependência) |
| `langchain` / `langgraph` | Instalado pelo agentserver |
