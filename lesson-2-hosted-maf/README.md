# Licao 1: Deployment de Agente de IA no Microsoft Foundry

## Objetivo
Nesta licao, voce aprendera a criar e fazer o deployment de um agente de IA no Microsoft Foundry usando o **Microsoft Agent Framework**, focado em responder questoes sobre o mercado financeiro.

## Agente
**Financial Market Agent** - Agente Python com Microsoft Agent Framework publicado como Hosted Agent no Foundry.

Caracteristicas:
- Desenvolvido em Python com Microsoft Agent Framework (`agent-framework-azure-ai`)
- Usa o modelo gpt-4.1 provisionado via Microsoft Foundry
- Expoe 3 tools: cotacao de acoes, taxa de cambio, resumo de mercado
- Hosted Agent no Foundry com Managed Identity
- OpenTelemetry integrado com Azure Monitor
- HTTP Server via `azure-ai-agentserver-agentframework`

## Estrutura da Licao

```
lesson-1/
  README.md
  foundry-agent/
    agent.yaml           # Manifesto do agente
    app.py               # HTTP server
    # create_hosted_agent.py movido para prereq/
    deploy.ps1           # Script de deploy automatizado
    Dockerfile           # Container image
    test_agent.py        # Console client (testa via Foundry backend)
    requirements.txt     # Dependencias
    src/
      main.py            # Entrypoint run()
      agent/
        finance_agent.py # Agente MAF
    tools/
      finance_tools.py   # Tools do agente
```

## Pre-requisitos
- Pasta `../prereq/` executada para provisionar a infraestrutura no Azure
- Azure CLI (`az`) instalado e autenticado
- Python 3.10+ com pip

## Como executar

1. Execute o deploy da infraestrutura na pasta `../prereq/` (se ainda nao fez)
2. Execute o deploy do agente:

```powershell
cd lesson-1/foundry-agent
.\deploy.ps1
```

O script vai automaticamente configurar, testar e deployar o agente no Foundry.
