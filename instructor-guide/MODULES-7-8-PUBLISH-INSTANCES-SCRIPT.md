# Instructional Script: Modules 7-8 - Publishing & Agent Instances

---

**Modules**: 7-8 - Admin Center Publishing & Teams Instance Creation  
**Duration**: 120 minutes (Day 4 Hours 2-3 + Day 5 Hour 1: 14:45-17:00)  
**Instructor**: Technical SME + M365 Admin  
**Location**: `instructor-guide/MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Learning Objectives

By the end of these modules, students will be able to:
1. **Publish** Agent Blueprint to Microsoft 365 Admin Center
2. **Navigate** admin approval workflow (submission → validation → approval → publication)
3. **Create** agent instances in Microsoft Teams (personal and shared)
4. **Manage** instance lifecycle (create, update, delete)
5. **Test** end-user experience in Teams with agent interactions
6. **Understand** governance model (admin controls, user discovery, policy enforcement)

---

## 📊 Module Overview

### Module 7: Publishing to M365 Admin Center (60 min - Day 4 Hour 2)
| Element | Duration | Method |
|---------|----------|--------|
| **Publishing Overview** | 10 min | Admin Center architecture |
| **Blueprint Submission** | 15 min | CLI-driven submission |
| **Validation & Approval** | 25 min | Admin portal walkthrough (simulated) |
| **Publication Status** | 10 min | Monitoring + rollback |

### Module 8: Creating Agent Instances (60 min - Day 4 Hour 3 + Day 5 Hour 1)
| Element | Duration | Method |
|---------|----------|--------|
| **Instance Types** | 10 min | Personal vs Shared vs Org-wide |
| **Create Personal Instance** | 20 min | Teams integration (individual user) |
| **Create Shared Instance** | 20 min | Team/channel deployment |
| **End-User Testing** | 30 min | Full conversational workflow |
| **Lifecycle Management** | 10 min | Update, pause, delete |

---

## 🗣️ Module 7: Instructional Script

### 14:45-14:55 | Publishing Overview (10 min)

**Instructional Method**: Presentation

**Opening (2 min)**:
> "Your agent is registered (Module 5), enhanced with SDK (Module 6). Now: make it **discoverable** to end users."
>
> "This isn't automatic—M365 admins control which agents users can instantiate."

**Content Delivery (6 min)**:

**Slide: Publication Workflow**

```
Developer                   M365 Admin                  End Users
   |                           |                            |
   | 1. a365 publish           |                            |
   |-------------------------->|                            |
   |                           |                            |
   |                      2. Review in                      |
   |                      Admin Center                      |
   |                           |                            |
   |                      3. Approve/Reject                 |
   |                           |                            |
   |                      4. Publish to Catalog             |
   |                           |--------------------------->|
   |                           |                            |
   |                           |                       5. Discover
   |                           |                       & Install
```

**Say**:
> "Step 1: Developer runs `a365 publish` (we do this today)."
>
> "Steps 2-4: M365 Admin reviews in Admin Center—validates security, compliance, branding."
>
> "Step 5: Users discover agent in Teams app store (once published)."

**Governance Model**:

| Role | Capability |
|------|------------|
| **Agent Developer** | Register Blueprint, submit for publication |
| **M365 Administrator** | Review, approve/reject, set discovery policies |
| **End User** | Discover published agents, create instances, interact |

**Say**:
> "Admin approval ensures: No rogue agents, compliance with company policy, proper branding."

**Interactive (2 min)**:
- **Ask**: "In your organization, who would play each role?" (identify roles)
- **Discuss**: "Why is admin approval important?" (security, governance, quality control)

**Transition**:
> "Let's publish our agent."

---

### 14:55-15:10 | Blueprint Submission (15 min)

**Instructional Method**: CLI workflow

#### Step 1: Verify Blueprint Registration (3 min)

**Student Task**:
```powershell
cd lesson-7-publish

# Check Blueprint exists in Entra ID
a365 blueprint list
```

**Expected output**:
```
Blueprints in tenant <m365-tenant-id>:
- financial-advisor-aca (App ID: a1b2c3d4-...)
  Status: Registered
  Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
```

**If not found**: Re-run Module 5 setup

**Success Criteria**: ✅ Blueprint appears in list

---

#### Step 2: Prepare Publication Manifest (7 min)

**Instructor explains**:
> "Publication requires metadata: Name, description, icon, category."

**Student Task**: Edit `publication-manifest.json`

**Template**:
```json
{
  "name": "Financial Advisor Agent",
  "shortDescription": "AI agent providing stock insights and financial analysis",
  "longDescription": "Leverages LangGraph orchestration with real-time market data tools. Answers questions about stock prices, market sentiment, and portfolio recommendations.",
  "developer": {
    "name": "Contoso Financial Services",
    "websiteUrl": "https://contoso.com",
    "privacyUrl": "https://contoso.com/privacy",
    "termsOfUseUrl": "https://contoso.com/terms"
  },
  "icons": {
    "color": "icon-color.png",
    "outline": "icon-outline.png"
  },
  "categories": ["Finance", "AI Assistant"],
  "isPrivate": true,  // Only visible to this tenant (for workshop)
  "permissions": [
    "Microsoft.Graph.User.Read",
    "Microsoft.Graph.Conversations.Send"
  ]
}
```

**Explain fields**:
- `isPrivate: true`: "Agent won't appear in public Teams app store—only your organization."
- `icons`: "192x192 PNG for color, 32x32 for outline."
- `permissions`: "Same as registered in Module 5."

**Student Task**: Customize description with their agent's capabilities

**Success Criteria**: ✅ Manifest JSON valid

---

#### Step 3: Submit for Publication (5 min)

**Student Task**:
```powershell
# Publish Blueprint to M365 Admin Center
a365 publish --manifest publication-manifest.json
```

**Expected output**:
```
📤 Submitting agent for publication...
   Blueprint: financial-advisor-aca
   App ID: a1b2c3d4-...
   
✅ Submission successful!
   
📋 Publication Details:
   Submission ID: sub-123abc
   Status: Pending Admin Approval
   Submitted: 2026-02-14 14:58 UTC
   
⏳ Next Steps:
   1. M365 Admin reviews in Admin Center
   2. You'll receive email when status changes
   3. Track status: a365 publication status sub-123abc
```

**Instructor explains**:
> "Now we wait for admin approval. In workshop, I'll simulate admin flow."
>
> "In production: Takes hours to days depending on org policy."

**Success Criteria**: ✅ Submission confirmed, ID obtained

---

### 15:10-15:35 | Validation & Approval (25 min)

**Instructional Method**: Instructor demonstration (students observe)

**Note**: Since students likely lack M365 Admin Center access, instructor demonstrates with screen share.

#### Admin Portal Walkthrough (15 min)

**Instructor navigates** (screen share):

1. **Navigate to Admin Center**:
   - admin.microsoft.com → Teams apps → Manage apps
   - Filter: "Pending approval"
   - Find: "Financial Advisor Agent"

2. **Review Submission**:
   - Click agent name
   - Review tabs:
     - **App details**: Name, description, developer info
     - **Permissions**: Microsoft Graph permissions (User.Read, Conversations.Send)
     - **Messaging endpoint**: Verify HTTPS endpoint valid
     - **Compliance**: Data handling, privacy policy links

**Screenshot each tab** (prepare screenshots in advance)

3. **Validation Checks**:
   > "Admin validates:"
   >
   > - **Security**: Is messaging endpoint secure (HTTPS)? Are permissions justified?
   > - **Compliance**: Does agent handle data per company policy?
   > - **Branding**: Does icon/description meet quality standards?

4. **Decision Options**:
   - **Approve**: Publish to org catalog (users can discover)
   - **Reject**: Send back to developer with feedback
   - **Request changes**: Ask developer to update manifest

**Say**:
> "Common rejection reasons: Missing privacy policy, excessive permissions, insecure endpoint."

**Instructor action**: Approve agent

**Show approval confirmation**:
```
✅ "Financial Advisor Agent" approved for publication
   Publication status: Active
   Catalog visibility: Organization-wide (private)
   Users can now discover and install
```

**Interactive (5 min)**:
- **Poll**: "What would you check as admin?" (security, compliance, branding)
- **Discuss**: "Why require privacy policy?" (GDPR, data governance)

---

#### Approval Notification (5 min)

**Show email notification** (mock or screenshot):
```
Subject: Agent Publication Approved - Financial Advisor Agent

Your agent "Financial Advisor Agent" has been approved for publication.

Status: Active
Catalog: Organization (Private)
Published: 2026-02-14 15:12 UTC

Users can now:
- Discover the agent in Teams app store (search "Financial Advisor")
- Create personal or shared instances
- Interact with the agent in Teams conversations

Next steps:
- Monitor usage in M365 Admin Center
- Update agent as needed (requires re-approval)
- Create agent instances for testing

Technical details:
- App ID: a1b2c3d4-...
- Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
```

**Student Task**: Check publication status
```powershell
a365 publication status sub-123abc
```

**Expected output**:
```
Publication Status: Approved
Published to Catalog: Yes
Catalog Visibility: Organization (Private)
Published Date: 2026-02-14 15:12 UTC
```

**Success Criteria**: ✅ Status shows "Approved"

---

### 15:35-15:45 | Publication Status (10 min)

**Instructional Method**: Monitoring + troubleshooting

#### Monitoring Publication

**Instructor explains**:
> "Post-publication monitoring: Usage metrics, errors, policy changes."

**Show Admin Center metrics** (screenshot):
- **Usage**: 15 instances created, 245 messages exchanged
- **Errors**: 2% failure rate (timeout errors)
- **Top users**: Finance team members

**Student exploration** (if admin access):
```powershell
# List all published agents
a365 publication list

# View specific agent metrics
a365 publication metrics --app-id a1b2c3d4-...
```

---

#### Rollback Scenarios

**Instructor discusses**:

**When to unpublish**:
1. **Critical bug discovered**: Agent giving incorrect financial advice
2. **Security vulnerability**: Endpoint compromised
3. **Policy violation**: Agent handling PII incorrectly

**How to unpublish**:
```powershell
a365 publication unpublish --app-id a1b2c3d4-...
```

**Effect**:
- Existing instances continue to work (not deleted)
- New instances cannot be created
- Agent disappears from discovery catalog

**Say**:
> "Unpublish is reversible—you can re-approve later after fixing issues."

**Interactive (2 min)**:
- **Ask**: "When would you unpublish immediately?" (security breach)
- **Discuss**: "What happens to users with existing instances?" (continue until admin deletes instances)

**Wrap Module 7**:
> "Agent published! Now: create instances so end users can interact."

---

## 🗣️ Module 8: Instructional Script

### 15:45-15:55 | Instance Types (10 min)

**Instructional Method**: Presentation

**Opening (2 min)**:
> "Publication makes agent available. **Instances** are deployed copies users interact with."
>
> "Think: App in app store (published agent) vs App installed on your phone (instance)."

**Content Delivery (6 min)**:

**Slide: Instance Types**

| Type | Scope | Use Case | Who Creates |
|------|-------|----------|-------------|
| **Personal** | Individual user | Private conversations, personal tasks | End user |
| **Shared** | Team/Channel | Collaborative workflows, team visibility | Team owner |
| **Org-wide** | All users | Company-wide services (e.g., IT helpdesk) | M365 Admin |

**Instance Isolation**:
> "Each instance is isolated—separate conversation history, separate identity."

**Example scenarios**:
- **Personal**: "I want financial advice in private DMs."
- **Shared**: "Finance team wants shared agent in #trading channel."
- **Org-wide**: "All employees access HR benefits agent."

**Platform Comparison**:
> "In traditional serverless: You deploy a function once, all users share the same instance."
>
> "M365 Agents: Each user/team creates their own instance with isolated state."

**Interactive (2 min)**:
- **Ask**: "Which type would you use for customer support?" (shared in support team channel)
- **Ask**: "Which for personal research?" (personal instance)

**Transition**:
> "Let's create personal instance first."

---

### 15:55-16:15 | Create Personal Instance (20 min)

**Instructional Method**: Hands-on in Teams

#### Step 1: Discover Agent in Teams (5 min)

**Student Task** (in Microsoft Teams desktop/web app):

1. Open Teams → Apps (left sidebar)
2. Search: "Financial Advisor"
3. Find: "Financial Advisor Agent" (org private agent)
4. Click to view details

**Expected view**:
- Agent name + icon
- Short description
- Developer: Contoso Financial Services
- Button: "Add" or "Add for me"

**⚠️ If agent not found**:
- Verify publication status (Module 7 completed)
- Verify user in correct M365 Tenant
- Check Admin Center: Is agent visible in org catalog?

**Success Criteria**: ✅ Agent appears in search

---

#### Step 2: Install Personal Instance (10 min)

**Student Task**:

1. Click "Add" (or "Add for me" if personal-only)
2. Confirm permissions prompt (if shown):
   ```
   Financial Advisor Agent wants to:
   - Read your profile
   - Send messages on your behalf
   
   [Allow] [Deny]
   ```
3. Click **Allow**

**Expected result**: Agent opens in chat view

**Show UI**:
- Left sidebar: Agent appears under "Apps" section
- Chat window: Welcome message from agent
- Input box: Ready to type

**Instructor explains**:
> "Personal instance created! This is YOUR agent—conversation history private to you."

**Student Task**: Send first message
```
Hello! Can you explain what you do?
```

**Expected response** (agent should introduce itself):
```
Hi! I'm the Financial Advisor Agent. I can help you with:
- Stock price lookups (e.g., "What is AAPL price?")
- Market sentiment analysis
- Portfolio recommendations

What would you like to know?
```

**Verify**:
- Response arrives within 5 seconds
- Response is coherent and on-brand
- Agent uses adaptive card (if implemented in Module 6)

**Success Criteria**: ✅ Personal instance responds successfully

---

#### Step 3: Test Conversation Flow (5 min)

**Student Task**: Test multi-turn conversation

**Example dialogue**:
```
User: What is the AAPL stock price?
Agent: [Calls get_stock_price tool]
       Apple Inc. (AAPL) is currently trading at $185.32.
       +2.4% today.
       
       Would you like more details or other stock information?

User: What about MSFT?
Agent: [Calls get_stock_price tool]
       Microsoft Corp. (MSFT) is at $412.15.
       +1.8% today.

User: Which is a better investment?
Agent: [Calls get_market_sentiment tool]
       Both are strong tech stocks...
       [Provides comparison]
```

**Verify**:
- Agent maintains context (doesn't forget previous stocks mentioned)
- Tools invoked correctly (stock prices accurate)
- Natural conversation flow

**Success Criteria**: ✅ Multi-turn conversation works

---

### 16:15-16:35 | Create Shared Instance (20 min)

**Instructional Method**: Hands-on in Teams channel

**Objective**: Deploy agent to team channel (collaborative use)

#### Step 1: Add to Channel (10 min)

**Student Task** (Team owner or member with permissions):

1. Navigate to Teams → Select team (e.g., "Finance Department")
2. Select channel (e.g., "#general" or create "#ai-trading")
3. Click "+" tab at top of channel
4. Search "Financial Advisor"
5. Click agent → "Add to a team or chat"
6. Select channel → Click "Set up"

**Configuration prompt**:
```
Add Financial Advisor Agent to #ai-trading?

Permissions:
- Read channel messages
- Post messages in channel
- Members can @mention agent

[Add to channel] [Cancel]
```

**Click "Add to channel"**

**Expected result**:
- Agent appears as tab in channel header
- System message posted:
  ```
  Financial Advisor Agent added to #ai-trading by @YourName
  
  @mention the agent to interact (e.g., "@Financial Advisor What is AAPL price?")
  ```

**Success Criteria**: ✅ Agent added to channel

---

#### Step 2: Test Shared Instance (10 min)

**Student Task**: Interact with agent in channel

**Channel message**:
```
@Financial Advisor What is the TSLA stock price?
```

**Expected behavior**:
- Agent responds in thread (reply to your message)
- Response visible to all channel members
- Other members can see conversation history

**Instructor demonstrates collaborative scenario**:

**User A**: `@Financial Advisor What is AAPL price?`  
**Agent**: `Apple Inc. (AAPL): $185.32 (+2.4%)`

**User B**: `@Financial Advisor Compare AAPL and MSFT`  
**Agent**: `[Provides comparison based on context—remembers AAPL mentioned earlier in channel]`

**Say**:
> "Shared instance sees all channel messages—maintains shared context."
>
> "Personal instance (from earlier) is separate—doesn't know about channel conversation."

**Verify isolation**:
1. Open personal instance (from Step 15:55)
2. Ask: "What stocks did we discuss?"
3. Expected: Agent doesn't remember channel conversation (isolated instance)

**Success Criteria**: ✅ Shared instance responds in channel, maintains shared context

---

### 16:35-17:05 | End-User Testing (30 min)

**Instructional Method**: Comprehensive scenario testing

**Objective**: Simulate real-world usage patterns

#### Scenario 1: Personal Research Workflow (10 min)

**Student Task** (individual):

1. Open personal instance
2. Conduct research session:
   ```
   I'm considering investing in cloud computing stocks.
   Can you provide prices for MSFT, GOOGL, and AMZN?
   ```
3. Follow-up questions:
   ```
   Which has the best growth potential?
   What's the market sentiment on cloud services?
   ```
4. Verify:
   - Agent retrieves multiple stock prices
   - Provides comparative analysis
   - Maintains conversation context across questions

**Success Criteria**: ✅ Personal instance handles multi-step research task

---

#### Scenario 2: Team Collaboration (10 min)

**Student Task** (in channel with other students):

**Facilitator prompts team activity**:
> "Your team is evaluating tech stocks for Q1 portfolio rebalancing."

**Team workflow**:
1. **Member 1**: `@Financial Advisor What are the top 3 tech stocks by market cap?`
2. **Member 2**: `@Financial Advisor What's the PE ratio for these stocks?`
3. **Member 3**: `@Financial Advisor Based on current trends, which would you recommend for long-term growth?`

**Observe**:
- Agent responds to different team members
- Maintains shared context (remembers stocks from Member 1's question)
- Team can see full conversation thread

**Success Criteria**: ✅ Collaborative workflow succeeds

---

#### Scenario 3: Error Handling (5 min)

**Student Task**: Test agent robustness

**Edge cases**:
```
1. Invalid stock symbol: "@Financial Advisor What is INVALID price?"
   Expected: Agent gracefully handles (e.g., "I couldn't find stock symbol INVALID. Please check the symbol.")

2. Ambiguous request: "@Financial Advisor Is it good?"
   Expected: Agent asks clarifying question (e.g., "What stock are you asking about?")

3. Out-of-scope: "@Financial Advisor Tell me a joke"
   Expected: Agent redirects (e.g., "I specialize in financial information. How can I help with markets or stocks?")
```

**Verify**:
- Agent doesn't crash on invalid input
- Provides helpful error messages
- Stays on-brand (financial focus)

**Success Criteria**: ✅ Error handling graceful

---

#### Scenario 4: Adaptive Cards (5 min)

**If implemented in Module 6**:

**Student Task**: Request data that triggers adaptive card

```
@Financial Advisor Show me a dashboard for AAPL
```

**Expected**: Agent returns adaptive card with:
- Stock ticker + price
- Change percentage (color-coded: green = up, red = down)
- Chart image (if available)
- Action buttons (e.g., "Get more details", "Compare with another stock")

**Verify**:
- Card renders correctly in Teams
- Buttons functional (trigger agent responses)

**If not implemented**:
> "Adaptive cards are optional enhancement—focus on core functionality today."

**Success Criteria**: ✅ Adaptive cards work (or acknowledged as future enhancement)

---

### 17:05-17:15 | Lifecycle Management (10 min)

**Instructional Method**: Administration tasks

**Objective**: Update, pause, remove instances

#### Update Instance (3 min)

**Scenario**: Agent code updated (bug fix or new feature)

**Student Task**:
```powershell
# Redeploy ACA agent (from lesson-6-a365-sdk)
cd lesson-6-a365-sdk
.\deploy.ps1
```

**After deployment**:
- Return to Teams
- Test instance: Send message
- Expected: New version responds (updates propagate automatically)

**Say**:
> "Instance points to messaging endpoint. When you update ACA, all instances get new version instantly."

**No explicit 'update instance' step needed**: Instances are proxies to backend

**Success Criteria**: ✅ Updated agent version responds

---

#### Pause Instance (2 min)

**Scenario**: Temporarily disable agent (e.g., during maintenance)

**Admin/Owner action** (instructor demonstrates):
1. Teams → Right-click agent in channel → "Remove"
2. Or: Settings → Manage apps → Pause "Financial Advisor Agent"

**Effect**:
- Instance stops responding
- Users see: "Agent unavailable" (or similar)
- Can re-enable by re-adding

**Say**:
> "Pausing is temporary—doesn't delete conversation history."

---

#### Delete Instance (3 min)

**Scenario**: Permanently remove agent

**Student Task**:
1. Personal instance: Right-click agent → Uninstall
2. Shared instance: Channel tab → Remove tab → Confirm delete

**Confirmation prompt**:
```
Remove Financial Advisor Agent?

This will:
- Delete conversation history
- Remove agent from this channel
- Other channels with this agent are unaffected

[Remove] [Cancel]
```

**Click "Remove"**

**Effect**:
- Instance deleted (conversation history cleared)
- Agent still published (can create new instance anytime)

**Success Criteria**: ✅ Instance deleted

---

#### Restore Instance (2 min)

**Student Task**: Re-add agent after deletion

1. Search agent in Teams app store
2. Click "Add" → Select channel/personal
3. New instance created (conversation history starts fresh)

**Say**:
> "Deleting instance doesn't affect published agent—you can always create new instance."

**Success Criteria**: ✅ New instance created

---

### 17:15-17:20 | Wrap Modules 7-8

**Summary**:
> "You've published agent to M365 Admin Center (Module 7) and created personal + shared instances (Module 8)."
>
> "End users can now discover, install, and interact with your agent in Teams."

**Final Interactive (5 min)**:

**Facilitator leads reflection**:
1. **What surprised you?** (Complexity of admin approval? Ease of Teams integration?)
2. **What would you change in your agent?** (More tools? Better responses? Adaptive cards?)
3. **How would you use agents in your organization?** (Customer support? Internal tools? Data analysis?)

**Capture feedback** for Module 9 (Content Owner roadmap planning)

**Workshop Completion**:
> "Congratulations! You've built, deployed, and published an Azure AI Agent accessible in Microsoft 365."
>
> "Tomorrow (Day 5): Agent evaluation framework and production best practices (Modules 9-10)."

---

## 📋 Instructor Checklist

### Before Modules 7-8:
- [ ] Verify M365 Admin Center access (for instructor demo)
- [ ] Prepare publication approval screenshots (or rehearse live demo)
- [ ] Test agent in Teams (personal + shared instances)
- [ ] Create demo team/channel for shared instance testing
- [ ] Prepare adaptive cards demo (if implemented)

### During Modules 7-8:
- [ ] Monitor publication submission success rate (85%+ goal)
- [ ] Track instance creation issues (Teams permissions common problem)
- [ ] Verify agent responses in both personal and shared contexts
- [ ] Capture end-user testing feedback (for Content Owner)

### After Modules 7-8:
- [ ] Update `7-DELIVERY-LOG.md` with Teams integration issues
- [ ] Document publication approval workflow timing (for future workshops)
- [ ] Collect student feedback on M365 UX
- [ ] Verify all students tested both instance types

---

## 🔧 Troubleshooting Playbook

### Issue: Agent Not Appearing in Teams Search
**Fix 1**: Verify publication status (`a365 publication status`)  
**Fix 2**: Check Admin Center catalog visibility (must be "Organization" or "Public")  
**Fix 3**: Hard refresh Teams (Ctrl+R or Cmd+R)

### Issue: "Permission Denied" When Adding to Channel
**Fix**: Verify user has "Owner" or "Member" role in team (Guests cannot add apps)

### Issue: Agent Not Responding in Teams
**Fix 1**: Verify messaging endpoint reachable (`curl https://<aca-fqdn>/api/messages`)  
**Fix 2**: Check Application Insights for errors  
**Fix 3**: Verify App ID/App Password environment variables in ACA

### Issue: Shared Instance Not Maintaining Context
**Fix**: Verify Bot Framework conversation ID preservation in `/api/messages` handler

### Issue: Adaptive Cards Not Rendering
**Fix**: Verify card schema matches Bot Framework Adaptive Card v1.5 format

---

## 📊 Success Metrics

**Modules 7-8 Completion Indicators**:
- ✅ 90%+ successfully submit agent for publication
- ✅ 100% understand admin approval workflow (even if simulated)
- ✅ 85%+ create personal instance and test conversation
- ✅ 75%+ create shared instance in team channel
- ✅ 90%+ complete end-user testing scenarios
- ✅ 100% articulate difference between personal vs shared instances

---

## 🎓 Pedagogical Notes

**Learning Theory Connections**:
- **Experiential Learning** (Kolb): Concrete experience → Reflective observation (Module 8 testing scenarios)
- **Social Learning** (Bandura): Shared instance collaboration demonstrates peer learning
- **Cognitive Load**: Break into personal (simpler) → shared (more complex) progression

**Assessment Opportunities**:
- Formative: Checkpoint after each instance creation
- Summative: End-user testing scenario completion (measures all prior modules)

**Differentiation Strategies**:
- **Advanced**: Challenge to create org-wide instance (requires admin rights)
- **Struggling**: Provide pre-configured shared instance to test (bypass setup)

---

**Script Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Status**: Draft - Awaiting approval
