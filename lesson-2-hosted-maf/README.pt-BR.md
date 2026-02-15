# Lição 2: Implantando um Agente de IA no Microsoft Foundry

## Objetivo
Nesta lição, você aprenderá a criar e implantar um agente de IA no Microsoft Foundry usando o **Microsoft Agent Framework**, focado em responder perguntas sobre o mercado financeiro.

## Agente
**Agente de Mercado Financeiro** - Agente Python com Microsoft Agent Framework publicado como Hosted Agent no Foundry.

Recursos:
- Desenvolvido em Python com Microsoft Agent Framework (`agent-framework-azure-ai`)
- Usa o modelo gpt-4.1 provisionado via Microsoft Foundry
- Expõe 3 ferramentas: cotações de ações, taxas de câmbio, resumo de mercado
- Hosted Agent no Foundry com Managed Identity
- OpenTelemetry integrado com Azure Monitor
- Servidor HTTP via `azure-ai-agentserver-agentframework`

## Estrutura da Lição

```
lesson-1/
  README.md
  foundry-agent/
    agent.yaml           # Manifesto do agente
    app.py               # Servidor HTTP
    # create_hosted_agent.py movido para prereq/
    deploy.ps1           # Script de implantação automatizada
    Dockerfile           # Imagem do contêiner
    test_agent.py        # Cliente console (testa via backend Foundry)
    requirements.txt     # Dependências
    src/
      main.py            # Ponto de entrada run()
      agent/
        finance_agent.py # Agente MAF
    tools/
      finance_tools.py   # Ferramentas do agente
```

## Pré-requisitos
- Pasta `../prereq/` executada para provisionar infraestrutura Azure
- Azure CLI (`az`) instalado e autenticado
- Python 3.10+ com pip

## Como Executar

1. Execute a implantação da infraestrutura na pasta `../prereq/` (se ainda não feito)
2. Execute a implantação do agente:

```powershell
cd lesson-1/foundry-agent
.\deploy.ps1
```

O script vai automaticamente configurar, testar e implantar o agente no Foundry.
