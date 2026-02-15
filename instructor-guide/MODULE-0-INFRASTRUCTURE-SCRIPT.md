# Pre-Workshop Setup Guide: Infrastructure Deployment

---

**Module**: 0 - Infrastructure Foundation (PRE-WORKSHOP)  
**Completion Time**: 45-60 minutes  
**Format**: Self-paced, asynchronous  
**Deadline**: Complete 24 hours BEFORE workshop Day 1  
**Location**: `instructor-guide/MODULE-0-INFRASTRUCTURE-SCRIPT.md`  
**Agent**: 3 (Instructional Designer)  

---

## 🎯 Objectives

By completing this pre-workshop setup, you will:
1. **Deploy** complete Azure infrastructure using Bicep templates
2. **Validate** that Foundry project, ACR, and ACA are operational
3. **Verify** you have proper access and credentials configured
4. **Be ready** to start building AI agents on Day 1 (no deployment delays)

---

## ⚠️ IMPORTANT: Complete This BEFORE Workshop Starts

**Why do this in advance?**
- Infrastructure deployment takes 10-15 minutes
- Troubleshooting may require IT support (subscription setup, permissions)
- Workshop Day 1 starts with agent development (assumes infrastructure ready)
- **If you arrive without this completed, you'll fall behind immediately**

**Support Available**:
- Async support channel: [Slack/Teams link]
- Office hours: [Calendar link] (48h before workshop)
- Emergency contact: [Email/phone]

---

## 📋 Pre-Flight Checklist (Complete First)

Before starting deployment, ensure you have:

### Required Accounts & Access
- [ ] **Azure Subscription** with Owner or Contributor role
  - Verify: `az account show` shows your subscription
  - Don't have one? [Create free account](https://azure.microsoft.com/free/) (requires credit card)
  
- [ ] **Azure CLI** installed (version 2.57 or later)
  - Verify: `az --version`
  - Install: [Download here](https://learn.microsoft.com/cli/azure/install-azure-cli)

- [ ] **Docker Desktop** installed and running
  - Verify: `docker ps` (should not error)
  - Install: [Download here](https://www.docker.com/products/docker-desktop/)

- [ ] **Git** installed
  - Verify: `git --version`
  - Install: [Download here](https://git-scm.com/downloads)

- [ ] **Python 3.10+** installed
  - Verify: `python --version` (or `python3 --version`)
  - Install: [Download here](https://www.python.org/downloads/)

### Required Permissions
- [ ] **Contributor role** on Azure subscription (minimum)
  - Check: Portal → Subscriptions → Your subscription → Access Control (IAM)
  - If missing: Request from subscription admin

- [ ] **Ability to create Resource Groups** in subscription
  - Test: `az group create --name test-rg --location eastus` (then delete it)

### Required Quota (Verify Availability)
- [ ] **Cognitive Services quota** in target region
  - Check: Portal → Subscriptions → Usage + quotas → Search "Cognitive Services"
  - Needed: 1x Standard S0 instance

- [ ] **Container Apps quota** in target region
  - Check: Portal → Subscriptions → Usage + quotas → Search "Container Apps"
  - Needed: 1x environment

**❌ Missing something?** Stop here. Fix prerequisites before continuing. Post in support channel if blocked.

---

## 🚀 Step-by-Step Deployment Guide

### Step 1: Clone Workshop Repository (5 min)

**Action**:
```powershell
# Navigate to your working directory
cd c:\Cloud\Code  # (or your preferred location)

# Clone repository
git clone https://github.com/[INSTRUCTOR-REPO]/a365-workshop.git
cd a365-workshop

# Verify structure
ls  # Should see: prereq/, lesson-1-declarative/, lesson-2-hosted-maf/, etc.
```

**✅ Success Indicator**: You see folders `prereq/`, `lesson-1-declarative/`, `lesson-2-hosted-maf/`

**❌ Troubleshooting**:
- "git not recognized" → Install Git (see checklist)
- "Repository not found" → Check URL (instructor will provide correct link)

---

### Step 2: Login to Azure (2 min)

**Action**:
```powershell
# Login to Azure
az login

# Verify correct subscription
az account show

# If wrong subscription, switch:
az account list --output table
az account set --subscription "<Your Subscription Name or ID>"
```

**✅ Success Indicator**: `az account show` displays YOUR subscription name

**❌ Troubleshooting**:
- "az not recognized" → Install Azure CLI (see checklist)
- "No subscriptions found" → You need an Azure subscription (create one or contact admin)
- "Multiple subscriptions" → Use `az account set` to choose the right one

---

### Step 3: Review Infrastructure Template (5 min)

**Action**:
```powershell
# Navigate to prereq folder
cd prereq

# Review files
ls
# You should see:
#   main.bicep          - Infrastructure definition
#   main.bicepparam     - Configuration parameters
#   deploy.ps1          - Deployment script
#   validate-deployment.ps1 - Validation script
```

**Open and review** `main.bicep` (optional, for understanding):
```powershell
notepad main.bicep  # or VS Code: code main.bicep
```

**What's being deployed?**
- ✅ **Azure AI Foundry project** (agent platform)
- ✅ **Azure Container Registry (ACR)** (for hosted agents)
- ✅ **Azure Container Apps (ACA) environment** (runtime for containers)
- ✅ **Application Insights** (monitoring & telemetry)

**Estimated cost**: ~$10-15 for entire 5-day workshop period

**Review parameters** (main.bicepparam):
```bicep
param foundryName = 'foundry-workshop-${uniqueString(resourceGroup().id)}'
param location = 'eastus'  // ← Change if needed
param acrName = 'acrworkshop${uniqueString(resourceGroup().id)}'
```

**⚠️ Optional: Customize location**
- If `eastus` has quota issues or high latency for you, change `location` to:
  - `eastus2`
  - `westus2`
  - `northeurope`
  - `brazilsouth` (for Brazilian students)

**Save changes** if you modified anything.

---

### Step 4: Execute Deployment (15-20 min)

**Action**:
```powershell
# Still in prereq/ folder
# Run deployment script
.\deploy.ps1

# Expected output:
# ✔️ Creating resource group: rg-foundry-workshop-xyz
# ✔️ Deploying infrastructure (this takes ~10-15 min)...
# [Progress indicators will show]
# ✔️ Deployment complete!
# ✔️ Output saved to: setup-output.txt
```

**⏳ While waiting (10-15 minutes)**:
- ☕ Get coffee
- 📖 Read [Azure AI Foundry overview](https://learn.microsoft.com/azure/ai-studio/)
- 👀 Watch deployment in Azure Portal (optional):
  1. Open portal.azure.com
  2. Navigate to Resource Groups
  3. Find `rg-foundry-workshop-*`
  4. Watch resources appear in real-time

**✅ Success Indicators**:
- Terminal shows "✔️ Deployment complete!"
- File `setup-output.txt` is created
- No error messages in terminal

**❌ Common Errors & Fixes**:

| Error Message | Cause | Fix |
|---------------|-------|-----|
| **"Resource name already exists"** | Naming collision (global namespace) | Edit `main.bicepparam`, add unique suffix to names (e.g., your initials) |
| **"Quota exceeded for Cognitive Services"** | Subscription limit reached | Try different region in `main.bicepparam`: `location = 'westus2'` |
| **"Authorization failed"** | Insufficient permissions | Verify Contributor role on subscription (check IAM) |
| **"This region doesn't support Container Apps"** | Region limitation | Change `location` to supported region (e.g., `eastus`, `westeurope`) |
| **Deployment stuck >20 min** | Azure backend issue | Cancel (Ctrl+C) and retry: `.\deploy.ps1` |

**⚠️ Still stuck?** Post error message + `setup-output.txt` content in support channel

---

### Step 5: Validate Deployment (5 min)

**Action**:
```powershell
# Run validation script
.\validate-deployment.ps1

# Expected output:
# 🔍 Validating Workshop Setup...
# 
# ✅ Checking Resource Group...
#    Resource Group: rg-foundry-workshop-xyz exists
# 
# ✅ Checking Foundry...
#    Foundry: foundry-workshop-xyz is Running
# 
# ✅ Checking ACR...
#    ACR: acrworkshopxyz is available
# 
# ✅ Checking ACA Environment...
#    ACA Environment: aca-env-workshop-xyz is Running
# 
# ✅ ALL CHECKS PASSED! You're ready for the workshop.
```

**✅ Success Indicator**: All checks show ✅ green checkmarks

**❌ If any check fails**:
1. Wait 2 minutes (resources may still be provisioning)
2. Run `.\validate-deployment.ps1` again
3. If still failing, check Azure Portal:
   - Go to Resource Group
   - Click failing resource
   - Check "Overview" → Status should be "Running" or "Succeeded"
4. If resource shows "Failed", post screenshot in support channel

---

### Step 6: Portal Verification (5 min)

**Action**: Verify you can access resources in Azure Portal

1. **Open portal.azure.com**
2. **Navigate to Resource Groups**
3. **Find your resource group**: `rg-foundry-workshop-*` (click it)
4. **Verify 4+ resources exist**:
   - Cognitive Services account (Foundry)
   - Container Registry
   - Container Apps Environment
   - Application Insights
   - (Maybe others: Log Analytics Workspace, etc.)

5. **Click Foundry resource** (Cognitive Services account)
   - Verify **Status**: "Succeeded"
   - Note the **Location** and **Endpoint** (starts with `https://`)

6. **Take screenshot** of resource group overview (all resources listed)
   - Save as `setup-verification-[YOUR-NAME].png`
   - **Submit to workshop organizer** (confirmation of completion)

**✅ Success Indicator**: You can see all resources in Portal, Foundry shows "Succeeded"

---

### Step 7: Save Configuration Details (3 min)

**Action**: Securely store deployment outputs for workshop use

1. **Open `setup-output.txt`** (created by deploy.ps1):
   ```powershell
   notepad setup-output.txt
   ```

2. **Verify it contains**:
   ```
   AZURE_AI_PROJECT_ENDPOINT=https://foundry-workshop-xyz.cognitiveservices.azure.com
   AZURE_SUBSCRIPTION_ID=xxxxx-xxxxx-xxxxx
   AZURE_RESOURCE_GROUP=rg-foundry-workshop-xyz
   AZURE_CONTAINER_REGISTRY=acrworkshopxyz
   AZURE_CONTAINER_APPS_ENV=aca-env-workshop-xyz
   ```

3. **Keep this file safe** – you'll need it on Day 1!
   - Bookmark the file location
   - Or copy values to password manager
   - **Do NOT share publicly** (contains resource identifiers)

**✅ Success Indicator**: `setup-output.txt` exists with all 5 variables

---

## ✅ Final Pre-Workshop Checklist

**Before Day 1, confirm you have:**

### Infrastructure Readiness
- [ ] Azure infrastructure deployed successfully
- [ ] All validation checks passed (green checkmarks)
- [ ] `setup-output.txt` file saved and accessible
- [ ] Screenshot of Azure Portal resources submitted

### Development Environment Ready
- [ ] Workshop repository cloned locally
- [ ] Azure CLI authenticated (`az account show` works)
- [ ] Docker Desktop running (`docker ps` works)
- [ ] Python 3.10+ available (`python --version` shows 3.10+)

### Access Verification
- [ ] Can access Azure Portal (portal.azure.com)
- [ ] Can see your resource group in Portal
- [ ] Can click Foundry resource and see "Succeeded" status

### Knowledge Check (Self-Assessment)
- [ ] I can explain: What is Azure Resource Group?
- [ ] I can explain: What is Azure AI Foundry?
- [ ] I can explain: Why do we need Container Registry?
- [ ] I know where to find: My Foundry endpoint URL

**✅ All checked?** You're ready! See you on Day 1 at [start time].

**❌ Missing items?** Complete them now or contact support **at least 24 hours before workshop**.

---

## 🆘 Getting Help

### Self-Help Resources
- 📘 **Azure CLI troubleshooting**: [Microsoft Docs](https://learn.microsoft.com/cli/azure/troubleshooting)
- 📘 **Bicep deployment errors**: [Common errors guide](https://learn.microsoft.com/azure/azure-resource-manager/bicep/common-deployment-errors)
- 📘 **Azure AI Foundry docs**: [Get started guide](https://learn.microsoft.com/azure/ai-studio/)
- 🎥 **Video walkthrough**: [Workshop Setup Tutorial (15 min)][link]

### Async Support Channels
- **Slack/Teams channel**: [link to channel]
- **Email**: workshop-support@[domain]
- **Office hours**: [Calendar link] (48h before workshop start)

### When Posting for Help, Include:
1. **Error message** (copy-paste full text)
2. **Output of**: `az account show`
3. **Output of**: `az --version`
4. **Content of**: `setup-output.txt` (if exists)
5. **Screenshot**: Error in terminal or Azure Portal
6. **Your OS**: Windows/Mac/Linux

### Emergency Contact (24h before workshop)
- **Critical blocker?** Email: [emergency-email]
- **Response time**: Within 4 hours (business days)

---

## 📚 Recommended Pre-Reading (Optional)

If you want to arrive even more prepared, review these (20-30 min total):

### For AWS Practitioners (Target Audience)
- 📄 **AWS to Azure service comparison**: [Microsoft guide](https://learn.microsoft.com/azure/architecture/aws-professional/)
  - Focus on: CloudFormation→Bicep, ECR→ACR, ECS→ACA
- 📄 **Azure Resource Manager concepts**: [Overview](https://learn.microsoft.com/azure/azure-resource-manager/management/overview)

### For AI/ML Background
- 📄 **What is Azure AI Foundry?**: [Introduction](https://learn.microsoft.com/azure/ai-studio/what-is-ai-studio)
- 📄 **Agent patterns overview**: [Microsoft documentation](https://learn.microsoft.com/azure/ai-studio/concepts/agents)

### For Container Experience
- 📄 **Azure Container Apps overview**: [Quickstart](https://learn.microsoft.com/azure/container-apps/overview)
- 📄 **ACR vs Docker Hub**: [Comparison guide](https://learn.microsoft.com/azure/container-registry/container-registry-intro)

**Don't stress if you don't read these** – they're supplemental. Workshop will cover concepts from scratch.

---

## 🎯 What Happens on Day 1?

With infrastructure ready, Day 1 starts with:

**Hour 1 (09:00-10:00)**: Welcome + Module 1 - Declarative Agent
- Quick infrastructure verification (5 min)
- Deploy your first AI agent (no Docker, SDK only)
- Test agent in Foundry portal playground
- Modify agent configuration live

**Hour 2-3 (10:00-12:00)**: Module 2 - Hosted Agent with MAF
- Build custom Python tools
- Containerize agent
- Deploy to Azure Container Apps
- Compare declarative vs hosted patterns

**Hour 4 (13:00-14:00)**: Module 3 - LangGraph Migration
- Convert LangGraph agent to Foundry-hosted
- Deploy same architecture
- Understand migration path from AWS Lambda/ECS

---

## 📊 Success Metrics (Self-Assessment)

**You're ready for Day 1 if you can:**

✅ Run `az account show` and see your subscription  
✅ Run `.\validate-deployment.ps1` and see all green checks  
✅ Open Azure Portal and navigate to your Foundry resource  
✅ Explain in one sentence: "What is the purpose of the Container Registry?"  
✅ Locate `setup-output.txt` and read the Foundry endpoint URL  

**If you can do all 5:** 🎉 You're 100% prepared!

**If you struggle with any:** 🚨 Contact support NOW (don't wait for Day 1)

---

## 🔄 Cleanup (After Workshop - Don't Do This Now!)

**⚠️ IMPORTANT: Do NOT delete resources until workshop ends (Day 5)**

After workshop completion (Day 5 or later), to avoid ongoing charges:

```powershell
# Delete entire resource group (removes all resources)
az group delete --name rg-foundry-workshop-xyz --yes --no-wait

# Verify deletion (after ~5 min)
az group show --name rg-foundry-workshop-xyz
# Should show: "ResourceGroupNotFound"
```

**Estimated costs if you forget**: ~$2-5/day (mostly from Container Apps environment)

---

**Setup Guide Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Reviewed by**: (Pending)  
**Status**: Draft - Awaiting approval

## 💡 Tips for Success

### Best Practices
- **Don't rush**: Follow each step carefully (template is designed for ~45-60 min completion)
- **Read error messages**: Most errors have clear solutions (see troubleshooting table)
- **Screenshot everything**: Portal views, terminal outputs (helps with troubleshooting)
- **Test early**: Complete this 48+ hours before workshop (gives time to fix issues)
- **Ask for help**: Don't struggle alone—use support channels

### Common Mistakes to Avoid
- ❌ **Skipping validation**: Always run `validate-deployment.ps1`
- ❌ **Using free tier Foundry**: Workshop requires Standard (S0) tier
- ❌ **Deleting resources early**: Keep everything until workshop ends
- ❌ **Ignoring `setup-output.txt`**: You'll need this file on Day 1
- ❌ **Not testing Azure CLI auth**: Run `az account show` before starting

---

## 🎓 Learning Notes (For Instructors)

### Pedagogical Approach
This pre-workshop guide uses:
- **Self-directed learning**: Students complete independently
- **Checklist methodology**: Clear success indicators at each step
- **Troubleshooting scaffolding**: Anticipate common errors, provide fixes
- **Validation-driven**: Multiple checkpoints ensure correctness

### Expected Completion Rate
- **90%+ students** should complete without support
- **5-10%** may need async help (permissions, quota issues)
- **<5%** may need synchronous office hours (complex blockers)

### Support Load Estimation
- **Pre-workshop office hours**: Expect 10-15% of students
- **Most common issues**: Subscription permissions, quota limits
- **Escalation scenarios**: IT admin approval needed (RBAC, quota increases)

---

**Setup Guide Version**: 1.0  
**Last Updated**: 2026-02-14  
**Created by**: Agent 3 (Instructional Designer)  
**Reviewed by**: (Pending)  
**Status**: Draft - Awaiting approval
