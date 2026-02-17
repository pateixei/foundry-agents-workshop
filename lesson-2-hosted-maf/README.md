# Lesson 2: Deploying an AI Agent on Microsoft Foundry

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Navigation

| Resource | Description |
|----------|-------------|
| [📖 Demo Walkthrough](demos/README.md) | Code walkthrough and demo instructions |
| [🔬 Lab Exercise](labs/LAB-STATEMENT.md) | Hands-on lab with tasks and success criteria |
| [📐 Architecture Diagram](media/lesson-2-architecture.png) | Architecture overview |
| [🛠️ Deployment Diagram](media/lesson-2-deployment.png) | Deployment flow |
| [📁 Solution Notes](labs/solution/README.md) | Solution code and deployment details |

## Objective
In this lesson, you will learn how to create and deploy an AI agent on Microsoft Foundry using the **Microsoft Agent Framework**, focused on answering questions about the financial market.

## Agent
**Financial Market Agent** - Python agent with Microsoft Agent Framework published as a Hosted Agent in Foundry.

Features:
- Developed in Python with Microsoft Agent Framework (`agent-framework-azure-ai`)
- Uses the gpt-4.1 model provisioned via Microsoft Foundry
- Exposes 3 tools: stock quotes, exchange rates, market summary
- Hosted Agent in Foundry with Managed Identity
- OpenTelemetry integrated with Azure Monitor
- HTTP Server via `azure-ai-agentserver-agentframework`

## Lesson Structure

```
lesson-2-hosted-maf/
  README.md
  demos/                 # Demo walkthrough
  labs/                  # Hands-on lab
    solution/
      agent.yaml           # Agent manifest
      app.py               # HTTP server
      deploy.ps1           # Automated deployment script
      Dockerfile           # Container image
      requirements.txt     # Dependencies
      src/
        main.py            # Entrypoint run()
        agent/
          finance_agent.py # MAF agent
      tools/
        finance_tools.py   # Agent tools
  media/                 # Architecture diagrams
```

## Prerequisites
- `../prereq/` folder executed to provision Azure infrastructure
- Azure CLI (`az`) installed and authenticated
- Python 3.10+ with pip

## How to Run

1. Execute the infrastructure deployment in the `../prereq/` folder (if not done yet)
2. Execute the agent deployment:

```powershell
cd lesson-2-hosted-maf/solution
.\deploy.ps1
```

O script vai automaticamente configurar, testar e deployar o agente no Foundry.
