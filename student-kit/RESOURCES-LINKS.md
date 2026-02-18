# Reference Materials & Links

> 🇧🇷 **[Leia em Português (pt-BR)](RESOURCES-LINKS.pt-BR.md)**

**Workshop**: Microsoft Foundry AI Agents Workshop — 5-Day Intensive  
**Version**: 0.7  
**Last Updated**: February 16, 2026  

---

## Core Azure AI Documentation

| Resource | URL | Used In |
|----------|-----|---------|
| Azure AI Foundry Overview | https://learn.microsoft.com/azure/ai-foundry/ | All modules |
| Azure AI Foundry Quickstart (Code) | https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code | Module 1 |
| Azure AI Agents SDK (Python) | https://learn.microsoft.com/python/api/overview/azure/ai-agents-readme | Modules 1-2 |
| `azure-ai-agents` PyPI | https://pypi.org/project/azure-ai-agents/ | Modules 1-2 |
| Azure AI Agent Service REST API | https://learn.microsoft.com/rest/api/azureai/agents | Reference |
| Responses API | https://learn.microsoft.com/azure/ai-foundry/concepts/responses-api | Module 1 |

## Microsoft Agent Framework (MAF)

| Resource | URL | Used In |
|----------|-----|---------|
| MAF Overview | https://learn.microsoft.com/azure/ai-foundry/concepts/agent-framework | Module 2 |
| Hosted Agents Concept | https://learn.microsoft.com/azure/ai-foundry/concepts/hosted-agents | Modules 2-3 |
| Hosted Agent Quickstart | https://learn.microsoft.com/azure/ai-foundry/how-to/deploy-hosted-agent | Module 2 |
| MAF Python Reference | https://learn.microsoft.com/python/api/overview/azure/ai-agent-framework | Module 2 |

## LangGraph / LangChain

| Resource | URL | Used In |
|----------|-----|---------|
| LangGraph Documentation | https://langchain-ai.github.io/langgraph/ | Modules 3-4, 6 |
| LangChain Python Docs | https://python.langchain.com/docs/introduction/ | Modules 3-4, 6 |
| `langchain-openai` PyPI | https://pypi.org/project/langchain-openai/ | Modules 3-4, 6 |
| AzureChatOpenAI Reference | https://python.langchain.com/docs/integrations/chat/azure_chat_openai/ | Modules 3-4, 6 |
| LangGraph on Azure AI Foundry | https://learn.microsoft.com/azure/ai-foundry/how-to/develop/langgraph | Module 3 |

## Azure Container Apps (ACA)

| Resource | URL | Used In |
|----------|-----|---------|
| ACA Overview | https://learn.microsoft.com/azure/container-apps/overview | Module 4 |
| ACA Quickstart | https://learn.microsoft.com/azure/container-apps/get-started | Module 4 |
| Managed Identity in ACA | https://learn.microsoft.com/azure/container-apps/managed-identity | Module 4 |
| ACA Bicep Reference | https://learn.microsoft.com/azure/templates/microsoft.app/containerapps | Module 4 |

## Microsoft 365 Agents / Agent 365

| Resource | URL | Used In |
|----------|-----|---------|
| Microsoft 365 Agents Overview | https://learn.microsoft.com/microsoft-365-copilot/extensibility/agents-are-apps | Modules 5-8 |
| A365 Connected Agents | https://learn.microsoft.com/microsoft-365-copilot/extensibility/publish-agent-teams-toolkit | Modules 5-6 |
| Microsoft 365 Developer Program | https://developer.microsoft.com/microsoft-365/dev-program | Module 5 |
| Bot Framework SDK (Python) | https://learn.microsoft.com/azure/bot-service/bot-service-quickstart-create-bot | Module 6 |
| `botbuilder-core` PyPI | https://pypi.org/project/botbuilder-core/ | Module 6 |
| Teams App Manifest | https://learn.microsoft.com/microsoftteams/platform/resources/schema/manifest-schema | Module 7 |

## Azure Infrastructure & DevOps

| Resource | URL | Used In |
|----------|-----|---------|
| Azure Bicep Documentation | https://learn.microsoft.com/azure/azure-resource-manager/bicep/ | Prereq, Module 4 |
| Azure CLI Reference | https://learn.microsoft.com/cli/azure/ | All modules |
| Azure Container Registry | https://learn.microsoft.com/azure/container-registry/ | Modules 2-4, 6 |
| Azure Monitor / App Insights | https://learn.microsoft.com/azure/azure-monitor/ | Module 6 |
| OpenTelemetry for Python | https://opentelemetry.io/docs/languages/python/ | Module 6 |
| Managed Identity Overview | https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview | All modules |

## AWS → Azure Migration References

| AWS Service | Azure Equivalent | Reference |
|-------------|-----------------|-----------|
| AWS Lambda + LangGraph | Hosted Agent (LangGraph on Foundry) | [Comparison](https://learn.microsoft.com/azure/architecture/aws-professional/) |
| Amazon Bedrock | Azure AI Foundry Models | [Models](https://learn.microsoft.com/azure/ai-foundry/how-to/model-catalog-overview) |
| AWS AgentCore | Microsoft Agent Framework (MAF) | [MAF Docs](https://learn.microsoft.com/azure/ai-foundry/concepts/agent-framework) |
| ECS / Fargate | Azure Container Apps | [ACA Docs](https://learn.microsoft.com/azure/container-apps/) |
| API Gateway | Azure API Management (AI Gateway) | [APIM](https://learn.microsoft.com/azure/api-management/) |
| CloudWatch | Azure Monitor + Application Insights | [Monitor](https://learn.microsoft.com/azure/azure-monitor/) |
| CloudFormation | Azure Bicep / ARM Templates | [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/) |
| IAM Roles | Managed Identities + Azure RBAC | [Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/) |

## Python Packages Quick Reference

### Day 1-2 (Declarative + MAF)
```
azure-ai-agents>=1.2.0b5
azure-identity>=1.19.0
python-dotenv>=1.0.0
opentelemetry-api>=1.27.0
```

### Day 2-3 (LangGraph on Foundry + ACA)
```
langchain-openai>=0.3.0
langchain-core>=0.3.0
langgraph>=0.3.0
fastapi>=0.115.0
uvicorn>=0.32.0
azure-ai-agentserver-langgraph
```

### Day 4-5 (A365 SDK Integration)
```
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
azure-monitor-opentelemetry>=1.6.0
opentelemetry-instrumentation-fastapi>=0.48b0
```

## Community & Support

| Resource | URL |
|----------|-----|
| Azure AI Foundry Community Forum | https://learn.microsoft.com/answers/tags/azure-ai-foundry |
| Stack Overflow — Azure AI | https://stackoverflow.com/questions/tagged/azure-ai |
| LangGraph GitHub Discussions | https://github.com/langchain-ai/langgraph/discussions |
| Microsoft Q&A — Azure | https://learn.microsoft.com/answers/ |
| Azure Updates (What's New) | https://azure.microsoft.com/updates/ |

## Workshop Repository

| Item | Location |
|------|----------|
| Source Code | `https://github.com/<ORG>/a365-workshop` |
| Known Issues & Workarounds | `context.md` (repository root) |
| Architecture Diagrams | Each lesson's `media/` folder |
| Lab Statements | Each lesson's `labs/` folder |
| Instructor Materials | `instructor-guide/` |
