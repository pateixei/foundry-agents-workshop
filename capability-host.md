# Capability Host in Microsoft Foundry

> 🇧🇷 **[Leia em Português (pt-BR)](capability-host.pt-BR.md)**

The **Capability Host** is an infrastructure resource of Microsoft Foundry that enables the execution of **Hosted Agents** (containerized agents) within a Foundry project.

## What it does

It functions as a "bridge" between the Foundry project and the compute resources needed to run agent containers. Specifically:

| Function | Description |
|---|---|
| **Container orchestration** | Manages the lifecycle of agent containers (start, stop, health check) |
| **Request routing** | Receives calls from the Responses API and forwards them to the correct container |
| **ACR connection** | Allows the project to pull images from Azure Container Registry |
| **Managed Identity** | Provides managed identity for the container to access other services (e.g., OpenAI endpoint) |
| **Storage** | Associates a storage account for agent data persistence |

## How it's created

```bash
az cognitiveservices account capability-host create \
    --account-name <foundry-account> \
    --project-name <project> \
    --capability-host-name default \
    --capability-host-kind Agents \
    --storage-connections "[{resource-id: <storage-id>}]" \
    --ai-service-connections "[{resource-id: <foundry-account-id>}]" \
    --acr-connections "[{resource-id: <acr-id>}]"
```

## Hierarchy

```
Foundry Account (hub)
  +-- Project
        +-- Capability Host (kind: Agents)
              |-- Storage connection
              |-- AI Service connection (OpenAI endpoint)
              +-- ACR connection (container images)
                    +-- Hosted Agent v1, v2, ...
```

## Important points

- It's **required** to run hosted agents -- without it, you can only create agents via Agent Service (without custom container).
- Needs to be created **both at account and project level** (two levels).
- Currently in **preview** -- requires `az cli >= 2.73.0` with the latest `cognitiveservices` extension.
- Each project only needs **one** capability host (typically named `default`).

## Context in the Workshop

- **Lesson 1**: Doesn't use capability host because the agent runs natively in Agent Service.
- **Lesson 2**: Capability host is necessary because the LangGraph agent runs in a custom container.
