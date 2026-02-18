# Lesson 8: Creating Agent Instances in Microsoft Teams

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Create** agent instances in Microsoft Teams (personal and shared)
2. **Understand** the difference between personal, shared, and org-wide instances
3. **Test** end-user experience with multi-turn conversations in Teams
4. **Manage** instance lifecycle (create, suspend, resume, delete)
5. **Configure** instance settings and customize behavior
6. **Troubleshoot** common instance creation and interaction issues

---

## Overview

After publishing your agent to the M365 Admin Center (Lesson 7), users can create **instances** of your agent in Microsoft Teams. An agent instance is a dedicated deployment of your agent that users interact with through the Teams interface.

> **Think of it this way**: Published agent = App in the app store. Instance = App installed on your phone.

In this lesson, you'll learn how to:
- Create personal and shared agent instances
- Configure instance settings
- Test your agent in Teams
- Manage instance lifecycle (suspend, resume, delete)
- Troubleshoot common instance creation issues

---

## Instance Types

| Type | Scope | Use Case | Who Creates | Isolation |
|------|-------|----------|-------------|-----------|
| **Personal** | Individual user | Private research, personal tasks | End user | Fully isolated conversation history |
| **Shared** | Team/Channel | Collaborative workflows, team visibility | Team owner | Shared context across team members |
| **Org-wide** | All users | Company-wide services (IT helpdesk, HR) | M365 Admin | Organization-level access |

> Each instance is **isolated**—separate conversation history, separate identity. A personal instance doesn't know about channel conversations, and vice versa.

## Prerequisites

✅ **Completed Lessons 1-7**
✅ **Agent Published** to M365 Admin Center and approved by admin
✅ **Agent Deployed** to users or groups
✅ **Microsoft Teams** installed (desktop or web)
✅ **A365 CLI** installed and configured
✅ **Permissions** to create agent instances in your organization

## What is an Agent Instance?

An **agent instance** is a dedicated deployment of your published agent that:
- Runs within Microsoft Teams
- Has its own configuration and settings
- Can be personal (for individual use) or shared (for team collaboration)
- Maintains separate conversation history and state
- Can be suspended, resumed, or deleted independently

### Personal vs. Shared Instances

| Feature | Personal Instance | Shared Instance |
|---------|------------------|-----------------|
| **Visibility** | Only visible to creator | Visible to team members |
| **Use Case** | Individual productivity | Team collaboration |
| **Conversations** | Private to user | Accessible to team |
| **Management** | User only | Team owners |
| **Creation Command** | `a365 create-instance` | `a365 create-instance --shared` |

## Step-by-Step Guide

### Step 1: Verify Agent Publication Status

Before creating instances, verify your agent is published and deployed:

```powershell
# Switch to PowerShell 7 (required for A365 CLI)
pwsh

# Navigate to your A365 config directory
cd c:\Cloud\Code\a365-workshop\lesson-6-a365-prereq

# Check publication status
a365 publish status
```

**Expected Output:**
```
Agent Blueprint: Financial Market Agent Blueprint
Status: Published
Published Date: 2025-01-15T10:30:00Z
Approval Status: Approved
Deployment Scope: All Users
```

If status shows `Not Published` or `Pending Approval`, complete Lesson 7 first.

---

### Step 2: List Available Agent Blueprints

See all published agents available in your organization:

```powershell
# List all published agents
a365 list blueprints
```

**Expected Output:**
```
Agent Blueprints:
1. Financial Market Agent Blueprint
   - ID: 856d0c29-2359-4401-955f-b6f7e4396c58
   - Status: Published
   - Deployment: All Users
   
2. HR Assistant Agent
   - ID: 7a8b9c0d-1234-5678-90ab-cdef12345678
   - Status: Published
   - Deployment: HR Department
```

Note the **Blueprint ID** for your agent - you'll need it for instance creation.

---

### Step 3: Create a Personal Agent Instance

Create a personal instance for individual use:

```powershell
# Create personal instance
a365 create-instance `
  --blueprint-id "856d0c29-2359-4401-955f-b6f7e4396c58" `
  --display-name "My Financial Market Agent" `
  --description "Personal agent for stock market research" `
  --instance-type personal
```

**Command Parameters:**
- `--blueprint-id`: The ID of your published agent blueprint
- `--display-name`: Friendly name for your instance (appears in Teams)
- `--description`: Brief description of the instance purpose
- `--instance-type`: `personal` for individual use

**Expected Output:**
```
Creating agent instance...
✓ Instance created successfully

Instance Details:
- Instance ID: 3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f
- Display Name: My Financial Market Agent
- Type: Personal
- Status: Active
- Created: 2025-01-15T14:30:00Z

Next Steps:
1. Open Microsoft Teams
2. Search for "My Financial Market Agent" in the Apps section
3. Start chatting with your agent
```

---

### Step 4: Create a Shared Agent Instance (Optional)

For team collaboration, create a shared instance:

```powershell
# Create shared instance
a365 create-instance `
  --blueprint-id "856d0c29-2359-4401-955f-b6f7e4396c58" `
  --display-name "Team Financial Research Agent" `
  --description "Shared agent for team market analysis" `
  --instance-type shared `
  --team-id "19:abc123def456@thread.tacv2"
```

**Additional Parameters for Shared Instances:**
- `--team-id`: The Teams channel ID where the agent will be available
- `--team-owners`: (Optional) Comma-separated list of user IDs who can manage the instance

**To Get Team ID:**
1. Open Microsoft Teams
2. Navigate to your team
3. Click the three dots (...) next to the channel name
4. Select "Get link to channel"
5. Extract the team ID from the URL

**Expected Output:**
```
Creating shared agent instance...
✓ Instance created successfully
✓ Agent added to team channel

Instance Details:
- Instance ID: 8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f
- Display Name: Team Financial Research Agent
- Type: Shared
- Team: Marketing Team
- Status: Active
- Created: 2025-01-15T14:45:00Z

All team members can now access the agent in the channel.
```

---

### Step 5: Verify Instance Creation

List all your created instances:

```powershell
# List all instances
a365 list instances
```

**Expected Output:**
```
Agent Instances:
1. My Financial Market Agent
   - Instance ID: 3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f
   - Type: Personal
   - Status: Active
   - Created: 2025-01-15T14:30:00Z
   
2. Team Financial Research Agent
   - Instance ID: 8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f
   - Type: Shared
   - Team: Marketing Team
   - Status: Active
   - Created: 2025-01-15T14:45:00Z
```

**Get detailed info about a specific instance:**

```powershell
# Get instance details
a365 get-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

---

### Step 6: Test Your Agent in Microsoft Teams

#### Testing Personal Instance

1. **Open Microsoft Teams** (desktop or web app)

2. **Navigate to Apps:**
   - Click the **Apps** icon in the left sidebar
   - Or search directly in the Teams search bar

3. **Find Your Agent:**
   - Search for "My Financial Market Agent"
   - Click on the agent card

4. **Start Chatting:**
   - Click "Add" to add the agent to your chat list
   - Click "Chat" to open a conversation
   - Type your first message: `What's the current price of AAPL stock?`

5. **Verify Agent Response:**
   - Agent should respond with stock price data
   - Response may include Adaptive Card with rich formatting
   - Check for proper tool execution (stock price lookup)

**Example Conversation:**

```
You: What's the current price of AAPL stock?

Financial Market Agent:
📈 Apple Inc. (AAPL)
Current Price: $178.42
Change: +2.34 (+1.33%)
Last Updated: 2025-01-15 14:50 EST

[View Chart] [Get Details]
```

#### Testing Shared Instance

1. **Navigate to Your Team Channel:**
   - Open the team where you created the shared instance
   - Select the channel

2. **Access the Agent:**
   - The agent should appear in the channel's app list
   - Or mention the agent: `@Team Financial Research Agent`

3. **Team Collaboration:**
   - All team members can interact with the same agent
   - Conversation history is visible to the team
   - Agent maintains context across team conversations

---

### Step 7: Configure Instance Settings (Advanced)

Customize your instance behavior:

```powershell
# Update instance display name
a365 update-instance `
  --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f" `
  --display-name "Financial Markets AI Assistant"

# Update instance description
a365 update-instance `
  --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f" `
  --description "AI-powered agent for real-time financial data and analysis"

# Configure instance settings (if supported)
a365 configure-instance `
  --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f" `
  --settings '{"max_conversation_length": 100, "enable_notifications": true}'
```

**Available Settings** (may vary by agent):
- `max_conversation_length`: Maximum number of messages to retain in context
- `enable_notifications`: Allow proactive notifications
- `response_timeout`: Timeout for agent responses (seconds)
- `tool_settings`: Configuration for specific tools

---

## Instance Lifecycle Management

### Suspend Instance

Temporarily disable an instance without deleting it:

```powershell
# Suspend instance
a365 suspend-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**When to suspend:**
- Temporary maintenance
- Agent endpoint updates
- Testing new agent version
- Investigating issues

**Expected Output:**
```
Suspending agent instance...
✓ Instance suspended successfully

Instance Status: Suspended
Users cannot interact with the agent until it's resumed.
```

---

### Resume Instance

Reactivate a suspended instance:

```powershell
# Resume instance
a365 resume-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Expected Output:**
```
Resuming agent instance...
✓ Instance resumed successfully

Instance Status: Active
Users can now interact with the agent.
```

---

### Delete Instance

Permanently remove an instance:

```powershell
# Delete instance
a365 delete-instance --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Warning:** This action is **permanent** and will:
- Delete all conversation history
- Remove the agent from Teams
- Revoke user access
- Cannot be undone

**Expected Output:**
```
⚠️  Warning: This will permanently delete the instance and all data.
Type 'yes' to confirm: yes

Deleting agent instance...
✓ Instance deleted successfully

The agent has been removed from Teams.
```

---

## Troubleshooting

### Issue 1: Cannot Find Agent in Teams

**Symptoms:**
- Agent doesn't appear in Teams Apps section
- Search returns no results
- "Add" button is disabled

**Solutions:**

1. **Verify Deployment:**
   ```powershell
   a365 publish status
   ```
   - Ensure status is `Published` and `Approved`
   - Check deployment scope includes you or your group

2. **Check Instance Status:**
   ```powershell
   a365 list instances
   ```
   - Verify instance status is `Active` (not `Suspended`)

3. **Refresh Teams:**
   - Sign out of Teams
   - Sign back in
   - Clear Teams cache: `%appdata%\Microsoft\Teams\Cache`

4. **Wait for Propagation:**
   - New instances can take 5-10 minutes to appear
   - M365 directory sync delays may extend this

5. **Verify Permissions:**
   - Check with M365 admin if you have access
   - Verify organizational policies allow custom agents

---

### Issue 2: Agent Not Responding

**Symptoms:**
- Agent shows in Teams but doesn't respond
- Messages show "Failed to send"
- Timeout errors

**Solutions:**

1. **Check Messaging Endpoint:**
   ```powershell
   # Verify endpoint is accessible
   curl https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/health
   ```
   - Should return `{"status": "ok"}`

2. **Verify Azure Container App:**
   ```powershell
   az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.runningStatus"
   ```
   - Should return `"Running"`

3. **Check Application Insights:**
   - Navigate to Application Insights in Azure Portal
   - Look for failed requests to `/api/messages`
   - Review exception traces

4. **Check Agent Logs:**
   ```powershell
   az containerapp logs show --name aca-lg-agent --resource-group rg-ag365sdk --follow
   ```

5. **Verify Bot Framework Configuration:**
   - Ensure `/api/messages` endpoint is implemented
   - Check Bot Framework Activity handling
   - Verify Adaptive Card generation

---

### Issue 3: Instance Creation Fails

**Symptoms:**
- `a365 create-instance` command fails
- Error: "Blueprint not found"
- Error: "Insufficient permissions"

**Solutions:**

1. **Verify Blueprint ID:**
   ```powershell
   a365 list blueprints
   ```
   - Ensure blueprint ID matches published agent

2. **Check Permissions:**
   - Verify you have `Agent.Create` permission
   - Contact M365 admin to grant permissions

3. **Validate Configuration:**
   ```powershell
   a365 config display
   ```
   - Ensure tenant ID and client app ID are correct

4. **Check PowerShell Version:**
   ```powershell
   $PSVersionTable.PSVersion
   ```
   - Must be PowerShell 7.0 or higher

5. **Re-authenticate:**
   ```powershell
   az logout
   az login --tenant 08f651c3-3144-498c-a5e3-9345be97f2e3 --allow-no-subscriptions
   ```

---

### Issue 4: Shared Instance Not Visible to Team

**Symptoms:**
- Shared instance created successfully
- Only creator can see the agent
- Team members cannot access

**Solutions:**

1. **Verify Team ID:**
   - Ensure correct team ID was used during creation
   - Check channel exists and is active

2. **Check Team Permissions:**
   - Verify team members have appropriate roles
   - Ensure organizational policies allow shared agents

3. **Add Agent to Channel:**
   ```powershell
   a365 add-to-channel `
     --instance-id "8f7e6d5c-4b3a-2c1d-0e9f-8a7b6c5d4e3f" `
     --channel-id "19:abc123def456@thread.tacv2"
   ```

4. **Notify Team Members:**
   - Send announcement in Teams channel
   - Include instructions for accessing the agent

---

## Best Practices

### 1. Naming Conventions
- Use clear, descriptive names: `Team Sales Agent` instead of `Agent 1`
- Include purpose in description: `Analyzes sales data and generates reports`
- Follow organization naming standards

### 2. Instance Management
- **Start Small:** Create personal instances first for testing
- **Monitor Usage:** Track active instances to avoid sprawl
- **Clean Up:** Delete unused instances to free resources
- **Document:** Maintain list of instances and their purposes

### 3. User Onboarding
- **Provide Training:** Create quick start guides for users
- **Set Expectations:** Explain agent capabilities and limitations
- **Gather Feedback:** Collect user feedback for improvements
- **Support Channels:** Establish support process for issues

### 4. Security and Compliance
- **Review Permissions:** Regularly audit who can create instances
- **Monitor Conversations:** Implement logging for compliance
- **Data Privacy:** Ensure agent handles sensitive data appropriately
- **Access Control:** Use shared instances only when appropriate

### 5. Performance Optimization
- **Monitor Latency:** Track response times in Application Insights
- **Scale Resources:** Increase ACA replicas if needed
- **Cache Data:** Implement caching for frequently accessed data
- **Optimize Tools:** Profile and optimize slow tool functions

---

## Monitoring and Analytics

### View Instance Usage

Track how users interact with your agent:

```powershell
# Get usage statistics
a365 get-usage --instance-id "3f4e5d6c-7a8b-9c0d-1e2f-3a4b5c6d7e8f"
```

**Metrics Available:**
- Total conversations
- Total messages sent/received
- Average response time
- Most used tools/features
- Error rates
- Active users

### Application Insights

Monitor agent performance in Azure Portal:

1. **Navigate to Application Insights:**
   - Azure Portal → Resource Groups → `rg-ag365sdk`
   - Select Application Insights resource

2. **Key Metrics to Monitor:**
   - **Requests:** Total requests to `/api/messages`
   - **Response Time:** P50, P95, P99 latencies
   - **Failures:** Failed requests and exceptions
   - **Dependencies:** External API calls (stock prices, etc.)
   - **Custom Events:** Tool executions, Adaptive Card generations

3. **Create Alerts:**
   - High error rate (>5%)
   - Slow response time (>2 seconds)
   - Service availability (<99%)

### Teams Admin Center

View organizational agent usage:

1. Navigate to [Teams Admin Center](https://admin.teams.microsoft.com)
2. Go to **Teams apps → Manage apps**
3. Find your agent
4. View analytics:
   - Active users
   - Total installations
   - Usage trends
   - User feedback

---

## Next Steps

Congratulations! You've completed the Azure AI Foundry Agents Workshop. 🎉

### Continue Learning

1. **Explore Advanced Features:**
   - Multi-turn conversations with memory
   - Proactive notifications
   - Integration with other M365 services (SharePoint, Outlook)
   - Custom Adaptive Cards

2. **Improve Your Agent:**
   - Add more tools (weather, news, calendar)
   - Implement error handling and retry logic
   - Add authentication for sensitive operations
   - Optimize performance and costs

3. **Scale Your Deployment:**
   - Deploy multiple agents for different use cases
   - Implement CI/CD pipeline for automated deployments
   - Create agent templates for rapid deployment
   - Build enterprise agent governance

4. **Learn More:**
   - [Microsoft Agent 365 Documentation](https://learn.microsoft.com/en-us/microsoft-365-copilot/extensibility/agents)
   - [Azure AI Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-services/)
   - [Bot Framework Documentation](https://learn.microsoft.com/en-us/azure/bot-service/)
   - [Teams App Development](https://learn.microsoft.com/en-us/microsoftteams/platform/)

---

---

## End-User Testing Scenarios

After creating instances, simulate real-world usage to validate the full workflow.

### Scenario 1: Personal Research Workflow

Test multi-step research in your personal instance:

```
You: I'm considering investing in cloud computing stocks.
     Can you provide prices for MSFT, GOOGL, and AMZN?

Agent: [Calls tools for each stock, returns prices]

You: Which has the best growth potential?

Agent: [Provides comparative analysis using context from previous question]
```

**Verify**: Agent retrieves multiple prices, provides comparison, and maintains conversation context.

### Scenario 2: Team Collaboration

In a shared channel instance, have multiple team members interact:

```
Member 1: @Financial Advisor What are the top 3 tech stocks by market cap?
Member 2: @Financial Advisor What's the PE ratio for these stocks?
Member 3: @Financial Advisor Based on current trends, which would you recommend?
```

**Verify**: Agent responds to different members and maintains shared context.

### Scenario 3: Error Handling

Test agent robustness with edge cases:

| Input | Expected Behavior |
|-------|-------------------|
| Invalid stock symbol (`INVALID`) | Graceful error: "I couldn't find that symbol" |
| Ambiguous request (`Is it good?`) | Clarifying question: "What stock are you asking about?" |
| Out-of-scope (`Tell me a joke`) | Redirect: "I specialize in financial information" |
| Empty message | Graceful handling without crash |

### Scenario 4: Adaptive Cards (if implemented in Lesson 5)

```
You: Show me a dashboard for AAPL
```

**Verify**: Agent returns Adaptive Card with stock ticker, price, change %, and action buttons.

---

## ❓ Frequently Asked Questions

**Q: What's the difference between deleting an instance and unpublishing?**
A: Deleting an instance removes one user's/team's deployment (conversation history lost). Unpublishing removes the agent from the catalog globally (no new instances, existing ones keep working).

**Q: Can I update my agent code without affecting instances?**
A: Yes! Instances point to the messaging endpoint. When you redeploy ACA with new code (same FQDN), all instances automatically get the new version.

**Q: How long does it take for a new instance to appear in Teams?**
A: Personal instances appear within 1-2 minutes. Shared instances may take 5-10 minutes due to M365 directory sync. If not visible after 15 minutes, try signing out and back into Teams.

**Q: Can team members see my personal instance conversations?**
A: No. Personal instances are fully isolated. Only you can see your conversation history. Shared instances are visible to all team members.

**Q: How many instances can I create?**
A: There's no hard limit per user, but organizational policies may restrict the number. Each instance consumes minimal resources—the heavy lifting is on the ACA backend.

**Q: What happens when ACA scales to zero?**
A: If your ACA has `minReplicas: 0`, the first request will experience a cold start (5-15 seconds). Configure `minReplicas: 1` for always-on availability.

---

## 🏆 Self-Paced Challenges

1. **Org-Wide Instance**: If you have admin rights, create an org-wide instance and verify all users in your tenant can discover it
2. **Instance Comparison**: Create both a personal and shared instance with the same blueprint. Send the same question to both and document how context isolation works
3. **Lifecycle Drill**: Create → Test → Suspend → Resume → Delete → Re-create an instance. Document the state at each step and what data persists
4. **Channel Customization**: Create shared instances in 3 different channels with different display names. Verify each maintains independent context
5. **Performance Profiling**: Send 10 rapid-fire questions to your instance and monitor response times in Application Insights. Identify if ACA scaling triggers
6. **User Guide**: Write a 1-page end-user guide explaining how to find, install, and interact with the Financial Advisor Agent in Teams—as if for a non-technical colleague

---

## Quick Reference

### Common Commands

```powershell
# List published agents
a365 list blueprints

# Create personal instance
a365 create-instance --blueprint-id <ID> --display-name "My Agent" --instance-type personal

# Create shared instance
a365 create-instance --blueprint-id <ID> --display-name "Team Agent" --instance-type shared --team-id <TEAM_ID>

# List all instances
a365 list instances

# Get instance details
a365 get-instance --instance-id <ID>

# Suspend instance
a365 suspend-instance --instance-id <ID>

# Resume instance
a365 resume-instance --instance-id <ID>

# Delete instance
a365 delete-instance --instance-id <ID>

# Check publication status
a365 publish status

# View usage statistics
a365 get-usage --instance-id <ID>
```

### Endpoints

- **Health Check:** `https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/health`
- **Bot Framework:** `https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/api/messages`
- **REST API:** `https://aca-lg-agent.redmeadow-5d2fbed1.eastus.azurecontainerapps.io/chat`

### Key Files

- **A365 Config:** `lesson-6-a365-prereq/a365.config.json`
- **Agent Code:** `lesson-5-a365-langgraph/main.py`
- **Requirements:** `lesson-5-a365-langgraph/requirements.txt`

---

## Resources

- [Workshop Repository](https://github.com/pateixei/foundry-agents-workshop)
- [Lesson 5: A365 SDK Integration](../lesson-5-a365-langgraph/README.md)
- [Lesson 6: A365 Prerequisites](../lesson-6-a365-prereq/README.md)
- [Lesson 7: Publishing Guide](../lesson-7-publish/README.md)
- [Microsoft Learn: Build M365 Agents](https://learn.microsoft.com/en-us/training/paths/build-microsoft-365-agents/)

---

**Questions or Issues?** Open an issue in the [GitHub repository](https://github.com/pateixei/foundry-agents-workshop/issues).

Happy Building! 🚀
