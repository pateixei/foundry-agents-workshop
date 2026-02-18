# Lesson 7: Publishing Agent to Microsoft 365 Admin Center

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Publish** Agent Blueprint to Microsoft 365 Admin Center
2. **Navigate** the admin approval workflow (submission → validation → approval → publication)
3. **Configure** deployment scope (specific users, groups, or entire organization)
4. **Monitor** published agent usage and health analytics
5. **Manage** agent lifecycle (update, unpublish, rollback)
6. **Understand** the governance model (admin controls, user discovery, policy enforcement)

---

## Overview

This lesson guides you through publishing your registered Agent Blueprint to the Microsoft 365 Admin Center, making it available for deployment to users and groups in your organization.

---

## Architecture: Publication Workflow

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

### Governance Roles

| Role | Capability |
|------|------------|
| **Agent Developer** | Register Blueprint, submit for publication |
| **M365 Administrator** | Review, approve/reject, set discovery policies |
| **End User** | Discover published agents, create instances, interact |

> **Admin approval ensures**: No rogue agents, compliance with company policy, proper branding, and security validation.

## Prerequisites

Before publishing, ensure you have:

1. ✅ Completed Lesson 6 setup (`a365 setup all`)
2. ✅ Agent Blueprint registered in Entra ID
3. ✅ Agent deployed and healthy in ACA
4. ✅ Messaging endpoint accessible
5. ✅ Global Administrator or Agent Administrator role

## Publishing Process

### Step 1: Verify Agent Blueprint Status

```powershell
cd lesson-6-a365-prereq
a365 blueprint list
```

**Expected output**:
```
Agent Blueprint: Financial Market Agent Blueprint
ID: <blueprint-id>
Status: Registered
Messaging Endpoint: https://aca-lg-agent...azurecontainerapps.io/api/messages
```

### Step 2: Publish to M365

```powershell
a365 publish
```

**What this does**:
- Submits agent blueprint to M365 Admin Center
- Creates agent package
- Initiates approval workflow
- Sets deployment readiness

**Expected output**:
```
Publishing agent blueprint...
✓ Agent package created
✓ Submitted to M365 Admin Center
✓ Approval request sent to administrators

Status: Pending Admin Approval
Agent ID: <agent-id>
```

### Step 3: Admin Approval in M365 Admin Center

1. Navigate to [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Go to **Settings** → **Integrated apps**
3. Find "Financial Market Agent Blueprint"
4. Click **Review** and verify:
   - Permissions requested
   - Data access
   - Messaging endpoint
5. Click **Approve**

**Timeline**: Approval typically takes 2-5 minutes to propagate.

### Step 4: Verify Publication Status

```powershell
a365 status
```

**Expected output**:
```
Agent: Financial Market Agent Blueprint
Publication Status: Published
Approval Status: Approved
Available for Deployment: Yes
```

### Step 5: Deploy to Users/Groups

#### Option A: Deploy to All Users

In M365 Admin Center:
1. Select your approved agent
2. Click **Deploy**
3. Choose "Deploy to everyone"
4. Confirm deployment

#### Option B: Deploy to Specific Groups

1. Select your agent
2. Click **Deploy**
3. Choose "Deploy to specific groups"
4. Select groups (Finance Team, IT Department, etc.)
5. Confirm deployment

#### Option C: Test with Specific Users First

```powershell
# Deploy to specific users via CLI (if available)
a365 deploy --users "user1@domain.com,user2@domain.com"
```

### Step 6: Verify Deployment

```powershell
a365 deployment status
```

**Check deployment progress**:
```
Deployment Status: Active
Deployed to: 15 users
Groups: Finance Team, Management
Last Updated: 2026-02-13 23:15:00
```

## Post-Publication Configuration

### Update Agent Metadata

```powershell
a365 blueprint update --display-name "Financial Market Assistant" --description "Updated description"
```

### Update Messaging Endpoint

If you redeploy your ACA:
```powershell
a365 blueprint update --messaging-endpoint "https://new-endpoint/api/messages"
```

### Manage Deployment Scope

```powershell
# Add users
a365 deploy add-users --users "user3@domain.com"

# Add groups
a365 deploy add-groups --groups "Sales Team"

# Remove users
a365 deploy remove-users --users "user1@domain.com"
```

## Troubleshooting

### Publication Fails

**Symptom**: `a365 publish` returns error

**Common causes**:
1. Blueprint not registered → Run `a365 setup blueprint`
2. Missing permissions → Verify Global Admin role
3. Endpoint not accessible → Test health endpoint
4. Invalid configuration → Check `a365.config.json`

**Solution**:
```powershell
# Verify setup
a365 config display
a365 blueprint list

# Re-register if needed
a365 setup blueprint --skip-infrastructure
```

### Approval Pending Too Long

**Symptom**: Status stuck at "Pending Approval" for >30 minutes

**Solutions**:
1. Check M365 Admin Center for pending requests
2. Verify admin has necessary permissions
3. Clear browser cache and retry approval
4. Contact Microsoft support for stuck approvals

### Agent Not Appearing in Admin Center

**Symptom**: Published agent not visible

**Solutions**:
1. Wait 5-10 minutes for synchronization
2. Refresh Admin Center page
3. Verify publication status: `a365 status`
4. Check if logged into correct tenant

### Deployment Not Reaching Users

**Symptom**: Users don't see agent in Teams/Outlook

**Solutions**:
1. Verify deployment status: `a365 deployment status`
2. Check user is in deployed group
3. Wait 10-15 minutes for propagation
4. Have user restart Teams/Outlook
5. Check user has necessary M365 licenses

## Monitoring Published Agent

### View Usage Analytics

M365 Admin Center → Integrated apps → Your Agent → Analytics:
- Total messages
- Active users
- Error rates
- Response times

### Check Health from M365

The M365 platform periodically pings your `/health` endpoint. Monitor:
```powershell
az containerapp logs show --name aca-lg-agent --resource-group rg-ag365sdk --follow
```

### Review Application Insights

For detailed telemetry:
1. Azure Portal → Application Insights
2. Check **Live Metrics** for real-time activity
3. Review **Failures** for errors
4. Analyze **Performance** for slow requests

## Unpublishing / Removing Agent

### When to Unpublish

| Scenario | Action | Effect |
|----------|--------|--------|
| Critical bug (incorrect advice) | Unpublish immediately | New instances blocked, existing continue |
| Security vulnerability | Unpublish + notify admin | Stop all access ASAP |
| Policy violation (PII handling) | Unpublish + audit | Review data handling |
| Planned maintenance | Optional unpublish | Can keep published if endpoint stays up |

### Unpublish from M365

```powershell
a365 unpublish
```

**What this does**:
- Removes agent from M365 catalog
- Stops new deployments
- Existing instances remain active

### Full Cleanup

```powershell
# Delete all instances first (Lesson 8)
a365 instance delete-all

# Then unpublish
a365 unpublish

# Finally remove blueprint
a365 blueprint delete
```

## Best Practices

1. **Test Before Wide Deployment**
   - Deploy to test group first
   - Verify functionality
   - Collect feedback
   - Then deploy organization-wide

2. **Communicate to Users**
   - Announce new agent availability
   - Provide usage instructions
   - Share example queries
   - Offer support channel

3. **Monitor After Publication**
   - Watch error rates
   - Track user adoption
   - Review feedback
   - Iterate based on usage

4. **Keep Endpoint Healthy**
   - Monitor `/health` endpoint
   - Set up alerts for downtime
   - Maintain SLA for availability

5. **Version Control**
   - Tag agent versions
   - Document changes
   - Test before updating endpoint
   - Communicate updates to users

## ❓ Frequently Asked Questions

**Q: How long does admin approval take?**
A: In the workshop, approval is near-instant (you are the admin). In production, it depends on organizational policy—hours to days. Follow up via the Admin Center if stuck >30 minutes.

**Q: What happens to existing instances when I unpublish?**
A: Existing instances continue to work (not deleted). No NEW instances can be created. Users see no disruption until admin explicitly removes instances.

**Q: Can I publish to the public Teams app store?**
A: In the workshop, we use `isPrivate: true` (organization-only). Public store publication requires Microsoft review and additional compliance checks.

**Q: What permissions does the admin review?**
A: Admin validates: Microsoft Graph permissions (User.Read, Conversations.Send), messaging endpoint security (HTTPS required), privacy policy links, and data handling practices.

**Q: Can I update a published agent without re-approval?**
A: Endpoint updates (new ACA URL) require re-publishing. Code changes behind the same endpoint don't—instances automatically get the new version.

**Q: What if multiple agents are published?**
A: Users see all published agents in the Teams app store (organization section). Each has its own approval status and deployment scope.

---

## 🏆 Self-Paced Challenges

1. **Publication Manifest**: Create a complete `publication-manifest.json` with custom icon, developer info, privacy URL, and terms of use for your agent
2. **Scoped Deployment**: Deploy the agent to a specific security group (not entire org) and verify only group members can discover it
3. **Rollback Drill**: Publish, unpublish, then re-publish your agent. Document the exact state at each step—what happens to existing instances?
4. **Analytics Dashboard**: After publishing, generate test traffic and explore the Usage Analytics in M365 Admin Center. Document available metrics.
5. **Governance Policy**: Write a one-page governance policy for your organization defining: who can submit agents, approval criteria, mandatory fields in the manifest, and SLA for admin review

---

## Next Steps

- **Lesson 8**: Creating agent instances in Teams for users
- Learn about instance lifecycle management
- Explore personal vs shared instances

## References

- [M365 Admin Center](https://admin.microsoft.com)
- [Microsoft Agent 365 Publishing](https://learn.microsoft.com/microsoft-agent-365/developer/)
- [Integrated Apps Management](https://learn.microsoft.com/microsoft-365/admin/manage/manage-deployment-of-add-ins)
