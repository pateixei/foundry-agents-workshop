# Microsoft Foundry Agents Workshop

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

Practical workshop to build, deploy, and manage AI agents using **Microsoft Foundry** with different approaches: declarative agents, hosted agents (MAF and LangGraph), agents on Azure Container Apps, and integration with Microsoft Agent 365.

## Contributors
- Marcio Uehara (security fixes)
- 

![Architecture Overview](prereq/media/architecture-diagram.png)

## Contents

| Lesson | Title | Approach | Description |
|:-----:|--------|-----------|-----------|
| [Prereq](prereq/) | Azure Infrastructure | Bicep + az CLI | Provisions Foundry, ACR, ACA Environment, App Insights |
| [1](lesson-1-declarative/) | Declarative Agent | `PromptAgentDefinition` | Agent created via SDK without container, editable in portal |
| [2](lesson-2-hosted-maf/) | Hosted Agent (MAF) | Microsoft Agent Framework | Container with MAF hosted in Foundry |
| [3](lesson-3-hosted-langgraph/) | Hosted Agent (LangGraph) | LangGraph + adapter | LangGraph container hosted in Foundry |
| [4](lesson-4-aca-langgraph/) | Connected Agent (ACA) | FastAPI + LangGraph | Own container in ACA, registered in Foundry Control Plane |
| [5](lesson-5-a365-langgraph/) | A365 SDK Integration | Azure Monitor + Bot Framework | Enhanced agent with observability, Bot Framework, Adaptive Cards |
| [6](lesson-6-a365-setup/) | Agent 365: Complete Setup, Publish & Instances | A365 CLI + Teams | Full A365 lifecycle: config, blueprint, publish to M365 Admin Center, create agent instances in Teams |

## Workshop Materials

In addition to lesson code, this repository includes comprehensive facilitation and student resources:

### For Students

| Resource | Description |
|----------|-------------|
| [SETUP GUIDE](student-kit/SETUP-GUIDE.md) | Step-by-step environment setup (Azure subscription, CLI, Python, Docker) |
| [RESOURCES LINKS](student-kit/RESOURCES-LINKS.md) | Curated links to documentation, learning paths, and reference materials |

### For Instructors

All instructor materials are in the [instructor-guide/](instructor-guide/INSTRUCTOR-GUIDE.md) folder:

### Technical Reference

Each lesson folder contains its own `demos/`, `labs/` (with `starter/`, `solution/`, and `LAB-STATEMENT.md`), and `media/` subfolders. Architecture diagrams are in each lesson's `media/` folder.

## Prerequisites

- Azure CLI (`az`) installed and authenticated
- Python 3.11+
- Docker (optional, builds are done in ACR)
- Azure Subscription with Contributor permissions

## Quick Start

```powershell
# 1. Provision infrastructure
cd prereq
.\deploy.ps1

# 2. Deploy declarative agent (lesson 1)
cd ../lesson-1-declarative
python create_agent.py

# 3. Deploy hosted agent MAF (lesson 2)
cd ../lesson-2-hosted-maf/solution
.\deploy.ps1

# 4. Deploy hosted agent LangGraph (lesson 3)
cd ../../lesson-3-hosted-langgraph/solution
.\deploy.ps1

# 5. Deploy agent on ACA (lesson 4)
cd ../../lesson-4-aca-langgraph/solution
.\deploy.ps1
```

## Test the agents

The `test/chat.py` script offers a unified interface to chat with any agent:

```powershell
pip install azure-identity requests python-dotenv

# Declarative
python test/chat.py --lesson 1 --endpoint https://<foundry>.services.ai.azure.com/api/projects/<project>

# Hosted MAF
python test/chat.py --lesson 2 --endpoint https://<foundry>.services.ai.azure.com/api/projects/<project>

# Hosted LangGraph
python test/chat.py --lesson 3 --endpoint https://<foundry>.services.ai.azure.com/api/projects/<project>

# ACA Connected (auto-resolve via az CLI)
python test/chat.py --lesson 4

# Single query
python test/chat.py --lesson 1 --once "What is the PETR4 stock price?"
```

## Workshop lessons

### Lesson 1 - Declarative Agent

Agent defined via `PromptAgentDefinition` and registered in Foundry. No container, no deployment. Instructions, model, and tools are editable directly in the portal.

### Lesson 2 - Hosted Agent (Microsoft Agent Framework)

Python container with Microsoft Agent Framework running inside Foundry as a Hosted Agent. Uses the `azure-ai-agentserver-agentframework` adapter to expose the Responses API.

### Lesson 3 - Hosted Agent (LangGraph)

Same concept as lesson 2, but using LangGraph as the orchestration framework. The `azure-ai-agentserver-langgraph` adapter converts the LangGraph graph into an HTTP server compatible with Foundry's Responses API.

### Lesson 4 - Connected Agent (Azure Container Apps)

The LangGraph agent runs on its own infrastructure (ACA) and is registered as a Connected Agent in the Foundry Control Plane. Foundry routes requests via AI Gateway (APIM) to gain observability and governance.

### Lesson 5 - A365 SDK Integration

Enhanced Financial Market Agent integrated with Microsoft Agent 365 SDK. Adds:
- **Azure Monitor OpenTelemetry** for distributed tracing and observability
- **Bot Framework Activity Protocol** via `/api/messages` endpoint for M365 integration
- **Adaptive Cards** for rich, interactive responses in Teams
- **Instrumented Tools** with span tracking for performance monitoring

The agent now supports both REST API (`/chat`) and Bot Framework Activity endpoints, enabling seamless integration with Microsoft 365 while maintaining backward compatibility.

### Lesson 6 - Microsoft Agent 365: Complete Setup, Publish & Instances

Unified end-to-end A365 lesson covering the full agent lifecycle for Microsoft 365. Includes:
- **A365 CLI configuration** and authentication for cross-tenant scenarios (Azure Tenant A + M365 Tenant B)
- **Agent Blueprint registration** in M365 Entra ID
- **Publishing** the agent with `a365 publish` and navigating the M365 Admin Center approval workflow
- **Teams Developer Portal** configuration and instance request flow
- **Admin approval**, activation, and user discovery in Teams
- **Testing** in Teams (personal and team chat), monitoring via Application Insights

## Approach comparison

| Aspect | Declarative (L1) | Hosted MAF (L2) | Hosted LangGraph (L3) | ACA Connected (L4) |
|---------|:-:|:-:|:-:|:-:|
| Docker Container | No | Yes | Yes | Yes |
| Infrastructure managed by Foundry | Yes | Yes | Yes | No |
| Custom tools (Python) | No | Yes | Yes | Yes |
| Editable in portal | Yes | No | No | No |
| Managed Identity | Project | Project | Project | ACA (own) |
| Auto-scaling | N/A | Foundry | Foundry | ACA (configurable) |
| Observability via Foundry | Native | Native | Native | Via AI Gateway |
| Framework | SDK only | MAF | LangGraph | FastAPI + LangGraph |

## Technologies used in this workshop

- **Azure AI Foundry** - Agent platform (Responses API, Hosted Agents, Control Plane)
- **Microsoft Agent Framework** - Official framework for agents in Foundry
- **LangGraph** - Graph framework for agent orchestration (ReAct pattern)
- **Azure Container Apps** - Serverless platform for containers
- **Bicep** - Infrastructure as Code for Azure
- **Azure API Management** - AI Gateway for governance and observability
- **Microsoft Agent 365** - Publishing agents in Microsoft 365

## License

This workshop is provided for educational purposes.
