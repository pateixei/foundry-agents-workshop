# Lesson 4 - LangGraph Agent on Azure Container Apps

In this lesson, we deploy the same LangGraph agent from previous lessons on
our own infrastructure (**Azure Container Apps**) and register it as a
**Connected Agent** in the Microsoft Foundry Control Plane.

See complete details in [solution/README.md](solution/README.md).

## Quick Start

```powershell
cd solution
.\deploy.ps1
```

## Quick Test

```powershell
# Direct call to ACA (without going through Foundry)
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the PETR4 stock price?"}'
```

## Key Concepts

- **Azure Container Apps (ACA)**: Serverless platform for containers with auto-scaling
- **Connected Agent**: External agent registered in the Foundry Control Plane for governance
- **AI Gateway (APIM)**: Foundry proxy that routes requests and collects telemetry
- **FastAPI**: HTTP framework that serves the agent (replaces the agentserver adapter from hosted agents)
- **Managed Identity**: ACA uses its own MI (different from the Foundry project's MI)

## Difference from Lessons 2-3

| Aspect | Lessons 2-3 (Hosted) | Lesson 4 (ACA) |
|---|---|---|
| Infrastructure | Foundry (Capability Host) | Azure Container Apps (user) |
| HTTP Server | agentserver adapter (port 8088) | FastAPI + uvicorn (port 8080) |
| Registration | Hosted Agent (CLI/SDK) | Connected Agent (Control Plane portal) |
| Scaling | Foundry managed | ACA managed (minReplicas/maxReplicas) |
| Proxy | Native Responses API | AI Gateway (APIM) |
| Managed Identity | Foundry project MI | Container App MI |
