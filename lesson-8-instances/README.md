# Lesson 8: Creating Agent Instances in Microsoft Teams

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Configure** the agent blueprint in Teams Developer Portal
2. **Request** an agent instance from Microsoft Teams
3. **Approve** the instance request as the M365 administrator
4. **Interact** with the agent in a Teams chat
5. **Monitor** agent activity in the Microsoft 365 admin center
6. **Troubleshoot** common instance creation issues

---

## Overview

After publishing your agent (Lesson 7), users can request **agent instances** through Microsoft Teams. An agent instance gives the agent its own Microsoft Entra identity (an "agentic user") and makes it available as a chat participant in Teams — just like a human colleague.

> **Important design change:** The `a365 create-instance` CLI command has been **removed**. It bypassed required registration steps that are necessary for full agent functionality. Instance creation is now done entirely through the **Microsoft Teams UI** and **Microsoft 365 admin center**, following the official governance workflow.

### What is an agent instance?

| Concept | Description |
|---------|-------------|
| **Blueprint** | The Entra app registration — the template defining the agent type, permissions, and config |
| **Instance** | A specific instantiation of the blueprint — the agent gets its own Entra user identity |
| **Agentic user** | An Entra user account for the agent (e.g. `fin-market-agent@domain.com`) — appears in Teams like a person |

---

## Prerequisites

✅ **Lesson 7 completed** — `a365 publish` ran successfully  
✅ **Agent appears in admin center** — visible at [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)  
✅ **`manifest/manifest.json`** exists in `lesson-6-a365-prereq\labs\solution\manifest\`  
✅ **Frontier enabled** — your tenant has the Frontier preview enabled for your user account  
✅ **Microsoft Teams** installed (desktop or web app)  
✅ **Global Administrator** access (needed to approve instance requests)  

---

## Step 1: Get Your Blueprint ID

You need the blueprint ID several places in this lesson.

```powershell
cd lesson-6-a365-prereq\labs\solution
a365 config display -g
```

Copy the value of `agentBlueprintId` from the output. It will look like:

```
agentBlueprintId: 809bce64-ea7f-4f64-94b1-6f0c582b2f21
```

---

## Step 2: Configure Agent in Teams Developer Portal

Before creating instances, you must configure the agent blueprint in the Teams Developer Portal to connect it to the Microsoft 365 messaging infrastructure. Without this step, the agent won't receive messages from Teams.

1. **Open the Developer Portal configuration page:**

   ```
   https://dev.teams.microsoft.com/tools/agent-blueprint/<your-blueprint-id>/configuration
   ```

   Replace `<your-blueprint-id>` with your actual `agentBlueprintId` copied in Step 1.

2. **Configure the agent:**
   - Set **Agent Type** → `Bot Based`
   - Set **Bot ID** → paste your `agentBlueprintId`
   - Click **Save**

   ![Developer Portal configuration page showing Agent Type: Bot Based and Bot ID field]

3. **Verify the save:**
   - ✅ Agent Type shows: `Bot Based`
   - ✅ Bot ID matches your `agentBlueprintId`
   - ✅ Page shows "Saved successfully"

> **Tip:** If you don't have access to the Teams Developer Portal, contact your tenant administrator to complete this step.

---

## Step 3: Request an Agent Instance in Teams

1. Open **Microsoft Teams** (desktop or web)

2. Click the **Apps** icon in the left sidebar (or use the top search bar)

3. Search for your agent by name — e.g. `Financial Market Agent`

4. Click on the agent card

5. Click **Request Instance** (or **Create Instance** if directly available)

6. Optionally enter a custom display name for your instance

7. Confirm — this sends an **approval request to your tenant admin**

> **Note:** The instance creation process is asynchronous. After the admin approves, the agent user account is created in Entra and the agent becomes available in Teams. This can take a few minutes to a few hours.

---

## Step 4: Approve the Instance Request (Admin)

As the admin, approve the pending request:

1. Go to [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
2. Find the pending request for your agent
3. Review the permissions and details
4. Click **Approve**

After approval:
- The agentic user account is created in Microsoft Entra
- The agent becomes searchable and chattable in Teams
- The agent appears under **All Agents** in the admin center

---

## Step 5: Test Your Agent in Teams

> **Note:** After admin approval, it may take **a few minutes to a few hours** for the agent user to become searchable in Teams. This is an asynchronous background process.

1. In Microsoft Teams, search for your agent's display name in the **Search** bar or **New Chat**

2. Open a chat with the agent

3. Send a test message — for example:
   ```
   What's the current stock price for MSFT?
   ```

4. Verify the agent responds correctly:
   - Agent shows typing indicator
   - Agent responds within a few seconds
   - Response includes relevant financial data

### Example conversation

```
You: What's the current price of AAPL?

Financial Market Agent:
📈 Apple Inc. (AAPL)
Current Price: $178.42
Change: +2.34 (+1.33%)
[Last 30 days data retrieval requested...]
```

---

## Step 6: Verify in Admin Center

After your agent instance is created and active:

1. Go to [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Select your agent
3. Open the **Activity** tab

You should see:
- ✅ Sessions listed with timestamps
- ✅ Each session shows triggers and actions taken
- ✅ Tool calls logged with timestamps

---

## Monitoring Agent Health

### Check Azure Container App logs

```powershell
az containerapp logs show `
  --name aca-lg-agent `
  --resource-group <your-resource-group> `
  --follow
```

Look for:
- ✅ Incoming requests from Teams (`POST /api/messages`)
- ✅ Successful authentication
- ✅ Tool calls executing
- ❌ Error messages or exceptions

### Check messaging endpoint health

```powershell
curl https://aca-lg-agent.purplerock-e895e6b1.eastus.azurecontainerapps.io/health
# Expected: {"status": "ok"} or HTTP 200
```

### Query Entra scopes and consent status

```powershell
cd lesson-6-a365-prereq\labs\solution

# Check blueprint scopes
a365 query-entra blueprint-scopes --config a365.config.json

# Check instance scopes (after instance is created)
a365 query-entra instance-scopes --config a365.config.json
```

---

## Instance Lifecycle Management

### CLI commands (Entra resources only)

```powershell
# Remove instance identity and user from Entra
a365 cleanup instance --config a365.config.json

# Remove blueprint and service principal from Entra
a365 cleanup blueprint --config a365.config.json
```

> **Note:** These CLI commands remove Entra resources only. To remove an agent instance from a user's Teams, the user removes the chat (or the admin removes the app from the tenant's installed apps in Teams Admin Center).

### Admin center management

All instance lifecycle actions (suspend, resume, delete, permissions review) are managed through the admin center:

- **All agents:** [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
- **Requested agents:** [https://admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested)
- **Teams Admin Center:** [https://admin.teams.microsoft.com](https://admin.teams.microsoft.com) → Teams apps → Manage apps

---

## Troubleshooting

### Agent doesn't appear in Teams search

**Symptom:** Agent published successfully but doesn't show up in Teams Apps search.

**Root cause:** Developer Portal configuration is missing or not saved.

**Solution:**
1. Get your blueprint ID:
   ```powershell
   a365 config display -g
   # Copy agentBlueprintId
   ```
2. Go to `https://dev.teams.microsoft.com/tools/agent-blueprint/<blueprint-id>/configuration`
3. Set Agent Type → `Bot Based`, Bot ID → your blueprint ID, click **Save**
4. Wait 5–10 minutes, then search again in Teams

---

### "Request Instance" button doesn't work or is missing

**Symptom:** Agent appears in Teams Apps but can't be added; button is greyed out or nothing happens.

**Root cause:** Microsoft Agent 365 Frontier isn't enabled for the tenant or the user.

**Solution:**
1. In the M365 admin center, go to **Settings** → **Copilot** → **Frontier**
2. Verify your user is included in the Frontier access list
3. Contact your tenant admin if access needs to be granted

---

### Agent doesn't respond to messages

**Symptom:** Instance created, agent visible in Teams, but messages go unanswered.

**Checklist:**
1. Verify Azure Container App is running:
   ```powershell
   az containerapp show `
     --name aca-lg-agent `
     --resource-group <your-resource-group> `
     --query "properties.runningStatus"
   # Expected: "Running"
   ```
2. Confirm endpoint is reachable:
   ```powershell
   curl https://aca-lg-agent.purplerock-e895e6b1.eastus.azurecontainerapps.io/health
   ```
3. Check Container App logs for errors
4. Verify Developer Portal configuration is saved (Step 2)

---

### License assignment fails

**Symptom:** Admin center shows error when approving instance request — license can't be assigned.

**Cause:** Insufficient licenses or incorrect license type.

**Solution:**
1. Go to **M365 admin center** → **Billing** → **Licenses** — verify available licenses
2. Ensure **Microsoft 365 Copilot** is licensed for the tenant (required for Frontier/Agent 365)
3. Manually assign license to the agentic user: **Users** → find the agent user → assign Microsoft 365 E5 / Teams Enterprise / M365 Copilot

---

### Agent user not found in Teams after hours

**Symptom:** Admin approved the request, but agent user still not searchable in Teams after several hours.

**Check:**
1. Confirm approval status in admin center at [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Check if the agentic user exists in Entra:
   ```powershell
   az ad user show --id fin-market-agent@M365CPI28789782.onmicrosoft.com
   ```
3. If user exists, the Teams sync is pending — wait and retry
4. If user doesn't exist, the instance wasn't fully provisioned — re-request via Teams

---

### `query-entra instance-scopes` returns `Request_ResourceNotFound`

**Symptom:** Running `a365 query-entra instance-scopes --config a365.config.json` outputs:

```
ERROR: Not Found({"error":{"code":"Request_ResourceNotFound","message":"Resource '' does not exist..."}})
No OAuth2 permission grants found
```

**Root cause:** The agentic user or service principal found in Entra has no OAuth2 permission grant records. This happens when A365 setup never fully completed (`botMessagingEndpoint: null`, `completed: false`). Common causes:

1. **Missing `location` or `resourceGroup` in `a365.config.json`** — the Frontier backend requires these to register the messaging endpoint, even with `needDeployment: false`. Without them, `a365 setup blueprint --endpoint-only` fails with `400 BadRequest: Location is required`, leaving `botMessagingEndpoint: null` and `completed: false`.
2. **Admin consent was never granted** during setup — the service principal was created but permissions were not applied.
3. **No instance created yet** — `AgenticAppId` and `AgenticUserId` are `null` in `a365.generated.config.json`. This command is only meaningful after an instance is created via Teams UI.

**Solution:**

1. First, verify `a365.config.json` contains the required fields:
   ```json
   "resourceGroup": "<your-resource-group>",
   "location": "<your-azure-region>"
   ```
   If missing, add them — required even with `needDeployment: false`.

2. Confirm setup completion:
   ```powershell
   a365 config display -g
   # Check: completed: true and botMessagingEndpoint is not null
   ```
3. If `completed: false`, re-run endpoint registration then permissions:
   ```powershell
   a365 setup blueprint --endpoint-only
   a365 setup permissions mcp
   a365 setup permissions bot
   ```
4. If setup completed but consent is missing, grant admin consent manually:
   - Go to [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations**
   - Find the **Financial Market Agent Blueprint** app
   - Go to **API permissions** → click **Grant admin consent for \<tenant\>**
5. Re-run the command to confirm grants are now present:
   ```powershell
   a365 query-entra instance-scopes --config a365.config.json
   ```

> **Note:** If no instance has been created yet (`AgenticAppId: null` in `a365.generated.config.json`), this error is expected — the command will return meaningful data only after an instance is created via Teams UI and approved by an admin (Steps 3–4).

---

## Testing Scenarios

### Scenario 1: Basic financial query

```
You: What's the current price of MSFT?
Agent: [Uses stock price tool, returns price with change data]

You: How does that compare to last week?
Agent: [Uses context from previous turn to answer comparatively]
```

**Verify:** Multi-turn context is maintained.

### Scenario 2: Error handling

| Input | Expected Behavior |
|-------|-------------------|
| Unknown ticker (`XYZINVALID`) | Graceful: "Symbol not found" |
| Vague request (`Is it good?`) | Clarifying: "Which stock are you asking about?" |
| Out-of-scope (`Tell me a joke`) | Redirect: "I specialize in financial information" |

### Scenario 3: Tool execution audit

After sending a request that uses tools (e.g. stock price lookup):

1. Go to admin center → your agent → **Activity** tab
2. Verify tool calls are logged with timestamps and inputs/outputs

---

## Quick Reference

| Action | Where |
|--------|-------|
| Get blueprint ID | `a365 config display -g` |
| Configure for Teams | `https://dev.teams.microsoft.com/tools/agent-blueprint/<id>/configuration` |
| Request instance | Microsoft Teams → Apps → Search → Request Instance |
| Approve request | [admin.cloud.microsoft/#/agents/all/requested](https://admin.cloud.microsoft/#/agents/all/requested) |
| View all agents | [admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all) |
| Check scopes | `a365 query-entra blueprint-scopes` |
| Remove instance | `a365 cleanup instance --config a365.config.json` |
| Remove blueprint | `a365 cleanup blueprint --config a365.config.json` |

---

## ❓ Frequently Asked Questions

**Q: Why was `a365 create-instance` removed?**  
A: It bypassed required registration steps (Developer Portal configuration, admin approval workflow) that are necessary for agents to receive messages and operate with full governance. Instance creation via Teams ensures these steps are always completed. The command may return in a future version once it's on par with the recommended workflow.

**Q: How long does instance creation take?**  
A: The admin approval itself is fast (a few minutes). Creating the agentic user in Entra and propagating it through Teams can take a few minutes to a few hours. If not searchable after 2 hours, verify the user was created in Entra.

**Q: Can team members see my personal instance conversations?**  
A: No. Each user has a 1:1 chat with the agent. Conversation history is private to that user.

**Q: What happens if I redeploy Azure Container Apps with a new URL?**  
A: You need to update the messaging endpoint and re-publish:
```powershell
a365 setup blueprint --endpoint-only --update-endpoint "https://new-url/api/messages" --config a365.config.json
a365 publish
```

**Q: What if ACA scales to zero (cold start)?**  
A: If `minReplicas: 0`, the first message after an idle period triggers a cold start (5–30 seconds). Set `minReplicas: 1` in your Container App for always-on availability.

**Q: How do I remove an agent instance completely?**  
A: Use `a365 cleanup instance` to remove the Entra identity. Users also need to remove the chat from Teams manually (or the admin can remove the app from all users via Teams Admin Center).

---

## Next Steps

🎉 **Congratulations — your agent is live in Microsoft Teams!**

Explore further:
- Add more tools to your agent (calendar, SharePoint, email via MCP servers)
- Set up CI/CD with `a365 deploy` for automated code deployments
- Explore observability dashboards in the admin center Activity tab
- Add the Agent 365 SDK to your agent for notifications and richer telemetry

---

## References

- [Microsoft Agent 365 — Create Agent Instances](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/create-instance)
- [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Agent 365 CLI — Removed `create-instance` command](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/agent-365-cli#important-updates)
- [Microsoft 365 Admin Center — Agents](https://admin.cloud.microsoft/#/agents/all)
- [Teams Developer Portal](https://dev.teams.microsoft.com)
- [Agent 365 GitHub Samples](https://github.com/microsoft/Agent365-Samples)
