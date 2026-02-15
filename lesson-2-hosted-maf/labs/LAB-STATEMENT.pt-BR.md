# Lab 2: Construir Tools Personalizadas com Microsoft Agent Framework

## Objetivo

Implementar tools Python personalizadas para um Hosted Agent (Agente Hospedado) usando o Microsoft Agent Framework (MAF). O agente executará lógica de negócios real: chamar APIs externas, processar dados e realizar cálculos — capacidades impossíveis com agentes declarativos.

## Cenário

Sua equipe de serviços financeiros precisa de um agente que possa:
- Consultar cotações de ações em tempo real via API
- Calcular conversões de câmbio com dados históricos
- Analisar métricas de desempenho de portfólio
- Acessar banco de dados interno de portfólios de clientes (simulado)

Isto requer **execução de código Python personalizado**, então você construirá um **Hosted Agent com MAF**.

## Objetivos de Aprendizagem

- Implementar tools Python personalizadas para agentes MAF
- Containerizar aplicações MAF com Docker
- Implantar contêineres no Azure Container Registry (ACR)
- Registrar agentes hospedados no Foundry via Azure CLI
- Debugar agentes usando logs de contêiner e Application Insights
- Entender a arquitetura MAF e padrões de chamada de tools

## Pré-requisitos

- [x] Lab 1 completado (entendimento de agentes declarativos)
- [x] Docker Desktop instalado e em execução
- [x] Azure CLI 2.57+ com comandos `az cognitiveservices agent`
- [x] ACR criado e acessível
- [x] Connection string do Application Insights

## Tarefas

### Tarefa 1: Implementar Tools Personalizadas (25 minutos)

Navegue até `starter/tools/` e implemente três tools financeiras:

**1.1 - `get_stock_quote(ticker: str) -> dict`**

Requisitos:
- Aceitar símbolo do ticker (ex.: "PETR4", "AAPL")
- Retornar JSON com: symbol, price, currency, change_percent
- Para o workshop: simular dados (em produção, chamar API real)

**Dicas**:
- Use `Annotated[str, "description"]` para type hints
- Retorne dict estruturado (MAF converte para JSON para o LLM)
- Inclua tratamento de erros para tickers inválidos

**1.2 - `calculate_portfolio_value(holdings: list[dict]) -> dict`**

Requisitos:
- Aceitar lista de holdings: `[{"ticker": "PETR4", "quantity": 100}, ...]`
- Calcular valor total usando `get_stock_quote` para cada ticker
- Retornar: total_value, detalhamento por_symbol, total_gain_percent

**1.3 - `get_market_sentiment(market: str) -> dict`**

Requisitos:
- Aceitar nome do mercado: "brazil", "usa", "europe"
- Retornar resumo estruturado: índices, sentimento, tendência
- Incluir texto narrativo adequado para resposta do agente

**Critérios de Sucesso**:
- ✅ Todas as três funções implementadas com type hints
- ✅ Funções retornam dados estruturados (dicts)
- ✅ Tratamento de erros para entradas inválidas
- ✅ Docstrings explicam propósito e parâmetros

### Tarefa 2: Criar Agente MAF (20 minutos)

Abra `starter/src/agent/finance_agent.py` e complete:

**2.1 - Importar módulos MAF necessários**
```python
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential
```

**2.2 - Definir system prompt**

Crie um system prompt abrangente que:
- Defina o papel do agente (consultor financeiro)
- Explique as capacidades das tools
- Configure formato e tom de resposta
- Inclua disclaimers

**2.3 - Implementar função `create_finance_agent()`**

```python
async def create_finance_agent():
    """Creates and returns MAF finance agent."""
    project_endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    model_deployment = os.environ["FOUNDRY_MODEL_DEPLOYMENT_NAME"]
    credential = DefaultAzureCredential()
    
    # TODO: Import tools from tools.finance_tools
    # TODO: Create AzureAIClient with tools
    # TODO: Return client and credential
```

**Dicas**:
- Passe a lista de tools para `AzureAIClient(tools=[...])`
- Inclua `agent_version` do ambiente para compatibilidade de hosted agent
- Use `DefaultAzureCredential` para autenticação via Managed Identity

**Critérios de Sucesso**:
- ✅ Função de criação do agente é async
- ✅ Tools estão registradas corretamente
- ✅ Variáveis de ambiente usadas corretamente
- ✅ Credenciais gerenciadas adequadamente

### Tarefa 3: Implementar Entry Point (10 minutos)

Abra `starter/src/main.py` e implemente:

```python
async def run(user_input: str, thread_id: Optional[str] = None) -> str:
    """Main entry point called by agent server."""
    # TODO: Create agent
    # TODO: Handle thread (new or existing)
    # TODO: Process user input
    # TODO: Return response
```

Requisitos:
- Aceitar `user_input` (string) e `thread_id` opcional
- Criar nova thread se `thread_id` for None
- Transmitir respostas do agente em streaming
- Tratar erros de forma adequada

**Critérios de Sucesso**:
- ✅ Função aceita e processa entrada do usuário
- ✅ Gerenciamento de thread funciona corretamente
- ✅ Respostas são transmitidas em streaming e concatenadas
- ✅ Credenciais são fechadas corretamente (async context manager)

### Tarefa 4: Configurar Observabilidade (10 minutos)

Adicione integração OpenTelemetry:

```python
from azure.monitor.opentelemetry import configure_azure_monitor
connection_string = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if connection_string:
    configure_azure_monitor(connection_string=connection_string)
```

Requisitos:
- Configurar antes de qualquer operação do agente
- Usar variável de ambiente para connection string
- Adicionar spans para invocações do agente e chamadas de tools

**Critérios de Sucesso**:
- ✅ Application Insights configurado
- ✅ Telemetria capturada para operações do agente

### Tarefa 5: Build e Deploy do Contêiner (20 minutos)

**5.1 - Revisar Dockerfile**

Certifique-se de que `starter/Dockerfile` está configurado:
- Imagem base: `python:3.11-slim`
- Diretório de trabalho: `/app`
- Porta exposta: `8088`
- CMD: Executar agentserver com adaptador MAF

**5.2 - Fazer build do contêiner**

```powershell
docker build -t fin-market-maf:v1 .
```

**5.3 - Push para ACR**

```powershell
az acr login --name YOUR-ACR
docker tag fin-market-maf:v1 YOUR-ACR.azurecr.io/fin-market-maf:v1
docker push YOUR-ACR.azurecr.io/fin-market-maf:v1
```

**5.4 - Deploy para Foundry**

```powershell
az cognitiveservices agent create \
  --name fin-market-maf \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-FOUNDRY-PROJECT \
  --image "YOUR-ACR.azurecr.io/fin-market-maf:v1" \
  --env "FOUNDRY_PROJECT_ENDPOINT=..." \
       "FOUNDRY_MODEL_DEPLOYMENT_NAME=..." \
       "APPLICATIONINSIGHTS_CONNECTION_STRING=..." \
       "HOSTED_AGENT_VERSION=1"

az cognitiveservices agent start \
  --name fin-market-maf \
  --agent-version 1 \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-FOUNDRY-PROJECT
```

**Critérios de Sucesso**:
- ✅ Contêiner construído sem erros
- ✅ Imagem enviada para ACR com sucesso
- ✅ Hosted Agent criado no Foundry
- ✅ Status do agente mostra "Running"

### Tarefa 6: Testar Tools Personalizadas (15 minutos)

**6.1 - Testar tools individuais**

```powershell
python test_tools.py
```

Verifique as saídas para:
- Cotação de ação individual
- Cálculo de portfólio com múltiplos holdings
- Sentimento de mercado para diferentes regiões

**6.2 - Teste ponta a ponta do agente**

```powershell
python test_agent.py
```

Perguntas de teste:
1. "Qual é o preço da PETR4?"
2. "Calcule o valor de um portfólio com 100 PETR4 e 50 VALE3"
3. "Como está o sentimento do mercado brasileiro hoje?"

**Comportamento Esperado**:
- Agente chama tools apropriadas automaticamente
- Respostas das tools são incorporadas em respostas em linguagem natural
- Múltiplas chamadas de tools são encadeadas quando necessário (ex.: cálculo de portfólio chama get_stock_quote para cada ticker)

**Critérios de Sucesso**:
- ✅ Agente invoca tools corretas para cada pergunta
- ✅ Saídas das tools são processadas corretamente
- ✅ Respostas são coerentes e precisas
- ✅ Disclaimers são incluídos

### Tarefa 7: Debug com Logs e Telemetria (10 minutos)

**7.1 - Visualizar logs do contêiner**

```powershell
az cognitiveservices agent logs show \
  --name fin-market-maf \
  --agent-version 1 \
  --account-name YOUR-FOUNDRY-ACCOUNT \
  --project-name YOUR-FOUNDRY-PROJECT \
  --tail 50
```

Procure por:
- Confirmação de inicialização do servidor do agente
- Mensagens de registro de tools
- Traces de requisição/resposta

**7.2 - Verificar Application Insights**

1. Navegue até Portal Azure → Application Insights
2. Vá para **Transaction Search**
3. Filtre os últimos 30 minutos
4. Inspecione:
   - Spans de `agent_run`
   - Spans de execução de tools
   - Spans de requisição ao modelo

**Critérios de Sucesso**:
- ✅ Logs mostram inicialização bem-sucedida do agente
- ✅ Registros de tools confirmados
- ✅ Telemetria visível no Application Insights
- ✅ Métricas de desempenho disponíveis

## Entregáveis

- [x] Três tools personalizadas implementadas e testadas
- [x] Agente MAF configurado e funcionando
- [x] Contêiner construído e implantado no ACR
- [x] Hosted Agent em execução no Foundry
- [x] Testes ponta a ponta passando
- [x] Telemetria configurada e visível

## Critérios de Avaliação

| Critério | Pontos | Descrição |
|-----------|--------|-------------|
| **Implementação de Tools** | 30 pts | Todas as três tools funcionais com type hints adequados |
| **Configuração do Agente MAF** | 20 pts | Agente configurado corretamente com tools |
| **Implantação** | 20 pts | Contêiner construído e implantado no Foundry |
| **Testes** | 15 pts | Testes ponta a ponta demonstram chamadas de tools |
| **Observabilidade** | 10 pts | Logs e telemetria configurados |
| **Qualidade do Código** | 5 pts | Limpo, documentado, com tratamento de erros |

**Total**: 100 pontos

## Resolução de Problemas

### "Docker build failed: pip install error"
- Certifique-se de que `requirements.txt` possui versões corretas dos pacotes
- Verifique conectividade de rede para acesso ao PyPI

### "ACR authorization failed"
- Execute `az acr login --name YOUR-ACR`
- Verifique se possui a role AcrPush

### "Hosted agent creation failed: agent already exists"
- Pare o agente existente primeiro
- Aguarde pelo status "Deleted" antes de recriar
- Ou use nome/versão diferente do agente

### "Tool not found by agent"
- Verifique se as tools foram passadas para `AzureAIClient(tools=[...])`
- Confira se os nomes das funções correspondem (sensível a maiúsculas/minúsculas)
- Certifique-se de que as funções possuem docstrings (usadas pelo LLM para descoberta de tools)

### "No telemetry in Application Insights"
- Aguarde 2-3 minutos para propagação
- Verifique se a connection string está correta
- Confira logs para mensagens de configuração do OpenTelemetry

## Estimativa de Tempo

- Tarefa 1: 25 minutos
- Tarefa 2: 20 minutos
- Tarefa 3: 10 minutos
- Tarefa 4: 10 minutos
- Tarefa 5: 20 minutos
- Tarefa 6: 15 minutos
- Tarefa 7: 10 minutos
- **Total**: 110 minutos

## Próximos Passos

- **Lab 3**: Implantar agente LangGraph no Azure Foundry
- Comparar arquiteturas MAF vs LangGraph
- Entender quando usar cada framework

---

**Dificuldade**: Intermediário  
**Pré-requisitos**: Python, Docker básico, Lab 1 completado  
**Tempo Estimado**: 110 minutos
