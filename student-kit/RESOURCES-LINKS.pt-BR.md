# Materiais de Referência & Links

> 🇺🇸 **[Read in English](RESOURCES-LINKS.md)**

**Workshop**: Microsoft Foundry AI Agents Workshop — Intensivo de 5 Dias  
**Versão**: 0.7  
**Última Atualização**: 16 de fevereiro de 2026  

---

## Documentação Principal do Azure AI

| Recurso | URL | Usado Em |
|---------|-----|----------|
| Visão Geral do Azure AI Foundry | https://learn.microsoft.com/azure/ai-foundry/ | Todos os módulos |
| Quickstart do Azure AI Foundry (Código) | https://learn.microsoft.com/azure/ai-foundry/quickstarts/get-started-code | Módulo 1 |
| Azure AI Agents SDK (Python) | https://learn.microsoft.com/python/api/overview/azure/ai-agents-readme | Módulos 1-2 |
| `azure-ai-agents` PyPI | https://pypi.org/project/azure-ai-agents/ | Módulos 1-2 |
| API REST do Azure AI Agent Service | https://learn.microsoft.com/rest/api/azureai/agents | Referência |
| Responses API | https://learn.microsoft.com/azure/ai-foundry/concepts/responses-api | Módulo 1 |

## Microsoft Agent Framework (MAF)

| Recurso | URL | Usado Em |
|---------|-----|----------|
| Visão Geral do MAF | https://learn.microsoft.com/azure/ai-foundry/concepts/agent-framework | Módulo 2 |
| Conceito de Agentes Hospedados | https://learn.microsoft.com/azure/ai-foundry/concepts/hosted-agents | Módulos 2-3 |
| Quickstart de Agente Hospedado | https://learn.microsoft.com/azure/ai-foundry/how-to/deploy-hosted-agent | Módulo 2 |
| Referência Python do MAF | https://learn.microsoft.com/python/api/overview/azure/ai-agent-framework | Módulo 2 |

## LangGraph / LangChain

| Recurso | URL | Usado Em |
|---------|-----|----------|
| Documentação do LangGraph | https://langchain-ai.github.io/langgraph/ | Módulos 3-4, 6 |
| Documentação Python do LangChain | https://python.langchain.com/docs/introduction/ | Módulos 3-4, 6 |
| `langchain-openai` PyPI | https://pypi.org/project/langchain-openai/ | Módulos 3-4, 6 |
| Referência do AzureChatOpenAI | https://python.langchain.com/docs/integrations/chat/azure_chat_openai/ | Módulos 3-4, 6 |
| LangGraph no Azure AI Foundry | https://learn.microsoft.com/azure/ai-foundry/how-to/develop/langgraph | Módulo 3 |

## Azure Container Apps (ACA)

| Recurso | URL | Usado Em |
|---------|-----|----------|
| Visão Geral do ACA | https://learn.microsoft.com/azure/container-apps/overview | Módulo 4 |
| Quickstart do ACA | https://learn.microsoft.com/azure/container-apps/get-started | Módulo 4 |
| Managed Identity no ACA | https://learn.microsoft.com/azure/container-apps/managed-identity | Módulo 4 |
| Referência Bicep do ACA | https://learn.microsoft.com/azure/templates/microsoft.app/containerapps | Módulo 4 |

## Microsoft 365 Agents / Agent 365

| Recurso | URL | Usado Em |
|---------|-----|----------|
| Visão Geral do Microsoft 365 Agents | https://learn.microsoft.com/microsoft-365-copilot/extensibility/agents-are-apps | Módulos 5-8 |
| Agentes Conectados A365 | https://learn.microsoft.com/microsoft-365-copilot/extensibility/publish-agent-teams-toolkit | Módulos 5-6 |
| Programa de Desenvolvedor Microsoft 365 | https://developer.microsoft.com/microsoft-365/dev-program | Módulo 5 |
| Bot Framework SDK (Python) | https://learn.microsoft.com/azure/bot-service/bot-service-quickstart-create-bot | Módulo 6 |
| `botbuilder-core` PyPI | https://pypi.org/project/botbuilder-core/ | Módulo 6 |
| Manifesto de App do Teams | https://learn.microsoft.com/microsoftteams/platform/resources/schema/manifest-schema | Módulo 7 |

## Infraestrutura Azure & DevOps

| Recurso | URL | Usado Em |
|---------|-----|----------|
| Documentação Azure Bicep | https://learn.microsoft.com/azure/azure-resource-manager/bicep/ | Pré-req, Módulo 4 |
| Referência do Azure CLI | https://learn.microsoft.com/cli/azure/ | Todos os módulos |
| Azure Container Registry | https://learn.microsoft.com/azure/container-registry/ | Módulos 2-4, 6 |
| Azure Monitor / App Insights | https://learn.microsoft.com/azure/azure-monitor/ | Módulo 6 |
| OpenTelemetry para Python | https://opentelemetry.io/docs/languages/python/ | Módulo 6 |
| Visão Geral de Managed Identity | https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview | Todos os módulos |

## Referências de Migração AWS → Azure

| Serviço AWS | Equivalente Azure | Referência |
|-------------|-------------------|------------|
| AWS Lambda + LangGraph | Hosted Agent (LangGraph no Foundry) | [Comparação](https://learn.microsoft.com/azure/architecture/aws-professional/) |
| Amazon Bedrock | Azure AI Foundry Models | [Modelos](https://learn.microsoft.com/azure/ai-foundry/how-to/model-catalog-overview) |
| AWS AgentCore | Microsoft Agent Framework (MAF) | [Docs MAF](https://learn.microsoft.com/azure/ai-foundry/concepts/agent-framework) |
| ECS / Fargate | Azure Container Apps | [Docs ACA](https://learn.microsoft.com/azure/container-apps/) |
| API Gateway | Azure API Management (AI Gateway) | [APIM](https://learn.microsoft.com/azure/api-management/) |
| CloudWatch | Azure Monitor + Application Insights | [Monitor](https://learn.microsoft.com/azure/azure-monitor/) |
| CloudFormation | Azure Bicep / ARM Templates | [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/) |
| IAM Roles | Managed Identities + Azure RBAC | [Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/) |

## Referência Rápida de Pacotes Python

### Dia 1-2 (Declarativo + MAF)
```
azure-ai-agents>=1.2.0b5
azure-identity>=1.19.0
python-dotenv>=1.0.0
opentelemetry-api>=1.27.0
```

### Dia 2-3 (LangGraph no Foundry + ACA)
```
langchain-openai>=0.3.0
langchain-core>=0.3.0
langgraph>=0.3.0
fastapi>=0.115.0
uvicorn>=0.32.0
azure-ai-agentserver-langgraph
```

### Dia 4-5 (Integração com A365 SDK)
```
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
azure-monitor-opentelemetry>=1.6.0
opentelemetry-instrumentation-fastapi>=0.48b0
```

## Comunidade & Suporte

| Recurso | URL |
|---------|-----|
| Fórum da Comunidade Azure AI Foundry | https://learn.microsoft.com/answers/tags/azure-ai-foundry |
| Stack Overflow — Azure AI | https://stackoverflow.com/questions/tagged/azure-ai |
| Discussões do LangGraph no GitHub | https://github.com/langchain-ai/langgraph/discussions |
| Microsoft Q&A — Azure | https://learn.microsoft.com/answers/ |
| Atualizações do Azure (Novidades) | https://azure.microsoft.com/updates/ |

## Repositório do Workshop

| Item | Localização |
|------|-------------|
| Código-Fonte | `https://github.com/<ORG>/a365-workshop` |
| Problemas Conhecidos & Soluções Alternativas | `context.md` (raiz do repositório) |
| Diagramas de Arquitetura | Pasta `media/` de cada lição |
| Enunciados dos Laboratórios | Pasta `labs/` de cada lição |
| Materiais do Instrutor | `instructor-guide/` |
