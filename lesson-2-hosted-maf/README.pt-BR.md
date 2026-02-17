# Lição 2: Implantando um Agente de IA no Microsoft Foundry

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-2-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-2-deployment.png) | Fluxo de implantação |
| [📁 Notas da Solução](labs/solution/README.pt-BR.md) | Código da solução e detalhes de deployment |

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

## Pré-requisitos
- Pasta `../prereq/` executada para provisionar infraestrutura Azure
- Azure CLI (`az`) instalado e autenticado
- Python 3.10+ com pip

## Como Executar

1. Execute a implantação da infraestrutura na pasta `../prereq/` (se ainda não feito)
2. Execute a implantação do agente:

```powershell
cd lesson-2-hosted-maf/solution
.\deploy.ps1
```

O script vai automaticamente configurar, testar e implantar o agente no Foundry.
