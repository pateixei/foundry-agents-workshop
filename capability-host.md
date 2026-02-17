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
| **Storage** | Associates a storage account for agent data persistence, threads and vector stores |

## How it's created (Bicep)

In this workshop, the Capability Host is provisioned as part of the shared infrastructure via `prereq/main.bicep`:

```bicep
resource capabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview' = {
  name: 'default'
  parent: aiFoundry
  properties: {
    capabilityHostKind: 'Agents'
    enablePublicHostingEnvironment: true
  }
  dependsOn: [
    aiProject
    storageAccount
  ]
}
```

> ⚠️ **Critical**: The `enablePublicHostingEnvironment: true` property is **mandatory** for hosted agents. Without it, the agent will stay stuck in "Starting" state and fail after ~15 minutes with a provisioning timeout. This property tells Foundry to create the managed compute environment for running agent containers.

The Foundry automatically provisions and manages the storage and AI service connections when `enablePublicHostingEnvironment` is enabled. A Storage Account must exist in the resource group (used for threads, vector stores and agent data).

## Hierarchy

```
Foundry Account (hub)
  +-- Project
  +-- Capability Host (kind: Agents)   <- account-level
        |-- enablePublicHostingEnvironment: true
        |-- Auto-provisioned storage (threads, vector stores)
        |-- Auto-provisioned AI Service connection
        +-- Hosted Agent v1, v2, ...
```

## Important points

- It's **required** to run hosted agents — without it, you can only create agents via Agent Service (without custom container).
- **`enablePublicHostingEnvironment: true`** is mandatory — without it, the managed environment provisioning will time out.
- Created at the **account level** via Bicep. The Foundry propagates capabilities to projects automatically.
- Currently in **preview** — uses API version `2025-10-01-preview`.
- Each account only needs **one** capability host (named `default`).
- Requires a **Storage Account** in the resource group for data persistence (threads, vector stores, agent data).
- Capability Host **cannot be updated** — if you need to change properties, you must delete and recreate it.

## Context in the Workshop

- **Lesson 1**: Doesn't use capability host because the agent runs natively in Agent Service (declarative).
- **Lessons 2 and 3**: Capability host is **required** because agents run in custom containers (hosted agents).
- **Lessons 4 and 6**: Don't use capability host because agents run in Azure Container Apps (self-hosted).
