# Workshop Readiness Checklist

**Workshop**: Microsoft Foundry AI Agents Workshop — 5-Day Intensive  
**Version**: 1.0  
**Owner**: Content Producer / Facilitator  
**When**: Complete by Day -1 (one day before workshop start)  

---

## A. Infrastructure & Accounts (Day -7)

- [ ] Azure subscription provisioned for instructor demo environment
- [ ] Instructor demo Resource Group deployed with all resources (run `prereq/deploy.ps1`)
- [ ] Instructor has Contributor access on demo subscription
- [ ] M365 Developer Tenant created and configured (for Days 3-5 demos)
- [ ] GitHub/Azure DevOps repository accessible to all participants
- [ ] Repository tagged/branched at stable version for workshop delivery

## B. Participant Communication (Day -7 to Day -3)

- [ ] Welcome email sent with:
  - [ ] Setup guide link (`SETUP-GUIDE.md`)
  - [ ] Resource links (`RESOURCES-LINKS.md`)
  - [ ] Pre-assessment quiz link (if applicable)
  - [ ] Office hours schedule
  - [ ] Communication channel invite (Slack/Teams)
- [ ] Communication channel created (#ai-agents-workshop)
- [ ] Calendar invites sent for all 5 workshop days
- [ ] Calendar invites sent for pre-workshop office hours (Day -3, Day -1)

## C. Environment Validation (Day -3 to Day -1)

- [ ] Office Hours #1 held (Day -3): Subscription + tool install support
- [ ] Office Hours #2 held (Day -1): Full environment validation
- [ ] All participants confirmed ✅ on `validate-setup.ps1`
- [ ] Participants with issues identified and mitigated
- [ ] Contingency plan reviewed with co-instructor/facilitator

## D. Materials Validation (Day -2)

### Source Code
- [ ] All lesson folders present and code runs locally
- [ ] `prereq/deploy.ps1` tested end-to-end on clean subscription
- [ ] `prereq/validate-deployment.ps1` returns all green
- [ ] `lesson-1-declarative/create_agent.py` creates agent successfully
- [ ] `lesson-2-hosted-maf/foundry-agent/deploy.ps1` deploys and agent responds
- [ ] `lesson-3-hosted-langgraph/langgraph-agent/deploy.ps1` deploys and agent responds
- [ ] `lesson-4-aca-langgraph/aca-agent/deploy.ps1` deploys, health check passes
- [ ] `lesson-6-a365-sdk/deploy.ps1` deploys, health + /chat endpoints work
- [ ] `test/chat.py` can interact with deployed agents

### Lab Files
- [ ] All 5 lab starters verified (files present, TODOs clear)
- [ ] All 5 lab solutions verified (code runs, produces expected output)
- [ ] LAB-STATEMENT.md files reviewed — tasks match starter/solution

### Instructional Scripts
- [ ] All 7 module scripts available in `instructional-scripts/`
- [ ] Instructor has reviewed scripts and is comfortable with flow
- [ ] Demo timing validated (scripts fit within allocated time)

### Slides & Diagrams
- [ ] Architecture diagrams exported to PNG (8 diagrams in `slides/`)
- [ ] Diagrams load correctly in presentation software
- [ ] `capability-host.md` content reviewed

## E. Technical Readiness (Day -1)

### Azure Services
- [ ] Azure AI Foundry portal accessible: https://ai.azure.com
- [ ] Azure Portal accessible: https://portal.azure.com
- [ ] ACR login working: `az acr login --name <acrName>`
- [ ] Azure OpenAI GPT-4o-mini deployment responding
- [ ] No Azure service advisories/outages affecting workshop regions

### Network
- [ ] Outbound HTTPS to `*.azure.com`, `*.azurecr.io`, `*.openai.azure.com` confirmed
- [ ] Docker Hub access confirmed (for base images)
- [ ] PyPI access confirmed (`pip install` works)
- [ ] NuGet access confirmed (`dotnet tool install` works)
- [ ] No corporate proxy/firewall blocking workshop endpoints

### Backup & Contingency
- [ ] Offline copies of all slides/diagrams available
- [ ] `context.md` workarounds reviewed and current
- [ ] Contingency plan (`CONTINGENCY-PLAN.md`) distributed to co-instructor
- [ ] Alternative pip mirror URL documented (if primary blocked)

## F. Delivery Day (Day 0 — 30 min before start)

- [ ] Instructor machine: demo environment tested one final time
- [ ] Screen sharing tested (VS Code visible, font size ≥ 14pt)
- [ ] Recording started (if applicable)
- [ ] Communication channel post: "Welcome! Workshop starts in 30 min"
- [ ] Agenda slide ready as first screen
- [ ] `context.md` open in a browser tab (quick reference for workarounds)
- [ ] Terminal open with Azure CLI logged in
- [ ] VS Code open with `a365-workshop` workspace loaded

---

## Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| Content Producer | | | ☐ Ready |
| Instructor/SME | | | ☐ Ready |
| Facilitator | | | ☐ Ready |

> **All three sign-offs required before Day 1 kickoff.**
