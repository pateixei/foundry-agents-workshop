Follow these guidelines consistently in all tasks.

# General guidelines

- Create all files using ASCII encoding only.
- Use the Microsoft Foundry platform for all agent-related operations.
- Deploy any required models within a Foundry project.

# Agent architecture

When creating agents in code, separate responsibilities clearly:
- A client application
- An agent backend

The backend always runs on Foundry. There is no need to implement or run a local backend.
The client application is always a local console app.

# Testing

- All testing code must be implemented as a console client application that calls the agent backend.

# Microsoft Agent Framework

- When using the Microsoft Agent Framework, there is a known issue in the agentserver package: AgentReference does not correctly accept the "id" field from Foundry’s routing layer.
- There is a second known issue: AzureAIClient._get_agent_reference_or_create returns an agent reference dict without the "id" field. The Foundry Responses API requires "id" in the agent reference. Without it, internal API calls from the container fail with: 400 - "ID cannot be null or empty (Parameter 'id')". Fix by monkey-patching the method to add id = name to the returned dict.
- There is a third known issue: AzureAIClient._prepare_options causes recursive routing for hosted agents. When _is_application_endpoint is False (project endpoint without "/applications/" in URL), the method adds extra_body with agent reference and removes model/tools from the request. The Foundry routing layer receives the agent reference, resolves it to the same hosted container, and routes the request back — causing an infinite loop and timeout. Fix by overriding _prepare_options to skip agent reference injection and keep model/tools so the container calls the LLM directly.
- There is a fourth known limitation: The Foundry Responses API does NOT allow the "instructions" field in the payload for hosted agents. Sending it returns 400 "Not allowed" (param=instructions). The portal also does not show a system prompt editor for hosted agents. System prompts for hosted agents are managed exclusively by the container code. To change the system prompt, update the code and redeploy.
- Search for these errors and apply the latest known fixes when implementing agents with this framework.
- All agents built with Microsoft Agent Framework must be compatible with Microsoft Foundry's playground in Foundry portal. 

# Image generation

For image generation tasks:

- Produce diagrams in draw.io format only.
- Use Azure and Microsoft iconography exclusively.
- When applicable, define shapes with Style="ArcSize=6".
- For text elements, set labelBackgroundColor=none.


# Az cli agent related commands (examples)

All commands below use `az cognitiveservices agent` (preview). Common parameters:
--name <agent-name> --account-name <foundry-account> --project-name <foundry-project>

## Creating an agent

```
az cognitiveservices agent create --name fin-market-agent --account-name ai-foundry001 --project-name ag365-prj001 --image "acr123.azurecr.io/fin-market-agent:v3-noloop" --env "FOUNDRY_PROJECT_ENDPOINT=https://ai-foundry001.services.ai.azure.com/api/projects/ag365-prj001" "AZURE_CLIENT_ID=<MANAGED-IDENTITY-CLIENT-ID>" "HOSTED_AGENT_VERSION=1"
```

## Starting an agent

```
az cognitiveservices agent start --name fin-market-agent --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```

## Checking agent status

```
az cognitiveservices agent status --name fin-market-agent --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```

## Viewing container logs

```
az cognitiveservices agent logs show --name fin-market-agent --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001 --tail 100
```

## Removing an agent (stop -> delete deployment -> delete agent)

IMPORTANT: You must stop the deployment and wait for it to reach "Deleted" status before deleting the agent version. Attempting to delete the agent while deployments still exist will fail with: "Cannot delete agent version — there are non-deleted associated hosted containers."

Step 1 - Stop the deployment:
```
az cognitiveservices agent stop --name fin-market-agent --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```

Step 2 - Poll status until it reports "Deleted":
```
az cognitiveservices agent status --name fin-market-agent --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```
Wait until the status field shows "Deleted". This can take 30-60 seconds.

Step 3 - Delete the agent version:
```
az cognitiveservices agent delete --name fin-market-agent --agent-version 1 --account-name ai-foundry001 --project-name ag365-prj001
```

# Additional SDK references
- Agent365: https://learn.microsoft.com/en-us/microsoft-agent-365/developer/ 