# Lição 6: Integração com o SDK do Microsoft Agent 365

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📝 Registro do Agente](REGISTER.pt-BR.md) | Como registrar o agente A365 |

## Visão Geral

Esta lição aprimora o agente LangGraph da Lição 4 com recursos do SDK do Microsoft Agent 365 para observabilidade, adaptive cards e integração nativa com o M365.

## Melhorias Principais

### 1. Observabilidade com Azure Monitor
- Rastreamento OpenTelemetry para todas as requisições
- Monitoramento de execução de ferramentas
- Métricas de desempenho
- Rastreamento de erros

### 2. Protocolo Bot Framework
- Endpoint nativo `/api/messages` para A365
- Tratamento de conversas baseado em Activity
- Suporte a conversas multi-turno

### 3. Adaptive Cards
- Respostas ricas otimizadas para M365
- Elementos de UI interativos
- Melhor experiência do usuário

### 4. Ferramentas Aprimoradas
- Instrumentadas com spans de rastreamento
- Monitoramento de desempenho
- Análise de uso

## Novas Dependências

```txt
# A365 SDK e Observabilidade
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
```

## Implantação

```powershell
cd lesson-6-a365-sdk
./deploy.ps1
```

Atualize a configuração do A365 com o novo endpoint:
```powershell
cd ../lesson-5-a365-prereq  
# Atualize messagingEndpoint no a365.config.json
a365 setup blueprint --skip-infrastructure
```

## Testes

```powershell
# Verificação de saúde
Invoke-RestMethod "https://<endpoint>/health"

# API de Chat
$body = @{message = "Qual o preco da PETR4?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/chat" -Method Post -Body $body -ContentType "application/json"

# Bot Framework Activity
$activity = @{
    type = "message"
    text = "Mostre um resumo do mercado"
    from = @{ id = "user123" }
    conversation = @{ id = "conv123" }
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

## Visualizar Telemetria

Portal do Azure → Application Insights → Pesquisa de Transações

## Próximos Passos

- Lição 7: Publicar no M365 Admin Center
- Lição 8: Criar instâncias de agente no Teams
