# Microsoft Foundry Agents Workshop

Practical workshop to build, deploy, and manage AI agents using **Microsoft Foundry** with different approaches: declarative agents, hosted agents (MAF and LangGraph), agents on Azure Container Apps, and integration with Microsoft Agent 365.

![Architecture Overview](slides/architecture-diagram.png)

## Contents

| Lesson | Title | Approach | Description |
|:-----:|--------|-----------|-----------|
| [Prereq](prereq/) | Azure Infrastructure | Bicep + az CLI | Provisions Foundry, ACR, ACA Environment, App Insights |
| [1](lesson-1-declarative/) | Declarative Agent | `PromptAgentDefinition` | Agent created via SDK without container, editable in portal |
| [2](lesson-2-hosted-maf/) | Hosted Agent (MAF) | Microsoft Agent Framework | Container with MAF hosted in Foundry |
| [3](lesson-3-hosted-langgraph/) | Hosted Agent (LangGraph) | LangGraph + adapter | LangGraph container hosted in Foundry |
| [4](lesson-4-aca-langgraph/) | Connected Agent (ACA) | FastAPI + LangGraph | Own container in ACA, registered in Foundry Control Plane |
| [5](lesson-5-a365-prereq/) | Agent 365 (Prereqs) | A365 CLI | Preparation to publish agents in Microsoft 365 |
| [6](lesson-6-a365-sdk/) | A365 SDK Integration | Azure Monitor + Bot Framework | Enhanced agent with observability, Bot Framework, Adaptive Cards |
| [7](lesson-7-publish/) | Publishing to M365 | A365 CLI + Admin Center | Step-by-step guide to publish agent to M365 Admin Center |
| [8](lesson-8-instances/) | Creating Instances | Teams + A365 CLI | Guide to create personal and shared agent instances in Teams |

## Workshop Materials

In addition to lesson code, this repository includes comprehensive facilitation and participant resources:

### For Instructors

| Resource | Description |
|----------|-------------|
| [INSTRUCTOR-GUIDE.md](INSTRUCTOR-GUIDE.md) | Complete facilitation guide — preparation checklists, daily plans, techniques, troubleshooting |
| [WORKSHOP-MASTER-AGENDA.md](WORKSHOP-MASTER-AGENDA.md) | Detailed minute-by-minute agenda for all 5 days (20 hours) |
| [instructional-scripts/](instructional-scripts/) | Module-by-module delivery scripts with talking points, demo steps, and timing cues |
| [CONTINGENCY-PLAN.md](CONTINGENCY-PLAN.md) | Fallback strategies for outages, environment issues, and pacing problems |
| [ROOM-READY-CHECKLIST.md](ROOM-READY-CHECKLIST.md) | Pre-session environment and logistics checklist |

### For Participants

| Resource | Description |
|----------|-------------|
| [participant-kit/SETUP-GUIDE.md](participant-kit/SETUP-GUIDE.md) | Step-by-step environment setup (Azure subscription, CLI, Python, Docker) |
| [participant-kit/RESOURCES-LINKS.md](participant-kit/RESOURCES-LINKS.md) | Curated links to documentation, learning paths, and reference materials |

### Technical Reference

| Resource | Description |
|----------|-------------|
| [technical-content/](technical-content/) | Demo walkthroughs and hands-on labs |
| [context.md](context.md) | Workshop guidelines, known issues, and technical decisions |
| [slides/](slides/) | Architecture diagrams (draw.io / PNG) |

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
cd ../lesson-2-hosted-maf/foundry-agent
.\deploy.ps1

# 4. Deploy hosted agent LangGraph (lesson 3)
cd ../../lesson-3-hosted-langgraph/langgraph-agent
.\deploy.ps1

# 5. Deploy agent on ACA (lesson 4)
cd ../../lesson-4-aca-langgraph/aca-agent
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

## Architecture

### Lesson 1 - Declarative Agent

Agent defined via `PromptAgentDefinition` and registered in Foundry. No container, no deployment. Instructions, model, and tools are editable directly in the portal.

![Lesson 1 Architecture](slides/lesson-1-architecture.png)

### Lesson 2 - Hosted Agent (Microsoft Agent Framework)

Python container with Microsoft Agent Framework running inside Foundry as a Hosted Agent. Uses the `azure-ai-agentserver-agentframework` adapter to expose the Responses API.

![Lesson 2 Architecture](slides/lesson-2-architecture.png)

<details>
<summary>Deployment flow</summary>

![Lesson 2 Deployment](slides/lesson-2-deployment.png)
</details>

### Lesson 3 - Hosted Agent (LangGraph)

Same concept as lesson 2, but using LangGraph as the orchestration framework. The `azure-ai-agentserver-langgraph` adapter converts the LangGraph graph into an HTTP server compatible with Foundry's Responses API.

![Lesson 3 Architecture](slides/lesson-3-architecture.png)

<details>
<summary>Deployment flow</summary>

![Lesson 3 Deployment](slides/lesson-3-deployment.png)
</details>

### Lesson 4 - Connected Agent (Azure Container Apps)

The LangGraph agent runs on its own infrastructure (ACA) and is registered as a Connected Agent in the Foundry Control Plane. Foundry routes requests via AI Gateway (APIM) to gain observability and governance.

![Lesson 4 Architecture](slides/lesson-4-architecture.png)

<details>
<summary>Deployment flow</summary>

![Lesson 4 Deployment](slides/lesson-4-deployment.png)
</details>

### Lesson 5 - Microsoft Agent 365 (Prerequisites)

A365 CLI configuration, app registration in Entra ID, and Agent Blueprint setup to publish agents in Microsoft 365 (Teams, Outlook). Covers the cross-tenant scenario (Azure != M365).

### Lesson 6 - A365 SDK Integration

Enhanced Financial Market Agent integrated with Microsoft Agent 365 SDK. Adds:
- **Azure Monitor OpenTelemetry** for distributed tracing and observability
- **Bot Framework Activity Protocol** via `/api/messages` endpoint for M365 integration
- **Adaptive Cards** for rich, interactive responses in Teams
- **Instrumented Tools** with span tracking for performance monitoring

The agent now supports both REST API (`/chat`) and Bot Framework Activity endpoints, enabling seamless integration with Microsoft 365 while maintaining backward compatibility.

### Lesson 7 - Publishing to Microsoft 365

Step-by-step guide to publish your agent to the M365 Admin Center using the A365 CLI. Covers:
- Agent Blueprint publication workflow
- Admin approval process in M365 Admin Center
- Deployment scope configuration (all users, specific groups, test users)
- Post-publication updates and maintenance
- Troubleshooting common publication issues

Once published and approved, your agent becomes available for users to create instances in Teams and other M365 services.

### Lesson 8 - Creating Agent Instances in Teams

Complete guide to creating and managing agent instances in Microsoft Teams:
- **Personal Instances** for individual productivity
- **Shared Instances** for team collaboration
- Instance lifecycle management (suspend, resume, delete)
- Testing agents directly in Teams
- Monitoring usage and performance analytics
- Troubleshooting instance creation and connectivity issues

Users can interact with agents through the Teams chat interface, with support for Adaptive Cards and rich media responses.

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

## Repository structure

```
foundry-agents-workshop/
  prereq/                          # IaC (Bicep) + infrastructure scripts
  lesson-1-declarative/            # Declarative agent (SDK)
  lesson-2-hosted-maf/             # Hosted agent (Microsoft Agent Framework)
  lesson-3-hosted-langgraph/       # Hosted agent (LangGraph)
  lesson-4-aca-langgraph/          # Connected agent (ACA + FastAPI)
  lesson-5-a365-prereq/            # Agent 365 prerequisites
  lesson-6-a365-sdk/               # A365 SDK integration (observability, Bot Framework)
  lesson-7-publish/                # Publishing guide (M365 Admin Center)
  lesson-8-instances/              # Instance creation guide (Teams)
  instructional-scripts/           # Module delivery scripts for instructors
  technical-content/               # Demos and hands-on labs
  participant-kit/                 # Setup guide and resource links for participants
  INSTRUCTOR-GUIDE.md              # Facilitation guide for instructors
  WORKSHOP-MASTER-AGENDA.md        # Detailed 5-day agenda
  CONTINGENCY-PLAN.md              # Fallback strategies
  ROOM-READY-CHECKLIST.md          # Pre-session checklist
  test/
    chat.py                        # Unified client for all agents
  slides/
    *.drawio                       # Editable diagrams (draw.io)
    *.png                          # Exported diagrams
  context.md                       # Workshop guidelines
```

## Technologies

- **Azure AI Foundry** - Agent platform (Responses API, Hosted Agents, Control Plane)
- **Microsoft Agent Framework** - Official framework for agents in Foundry
- **LangGraph** - Graph framework for agent orchestration (ReAct pattern)
- **Azure Container Apps** - Serverless platform for containers
- **Bicep** - Infrastructure as Code for Azure
- **Azure API Management** - AI Gateway for governance and observability
- **Microsoft Agent 365** - Publishing agents in Microsoft 365

## License

This workshop is provided for educational purposes.
