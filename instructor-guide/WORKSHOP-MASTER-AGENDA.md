# Workshop Master Agenda
**Microsoft Foundry AI Agents Workshop - 5-Day Intensive**

---

**Version**: 0.7  
**Target Audience**: Mid-Senior Developers expanding their agent development skills to Microsoft Foundry  
**Total Duration**: 20 hours (4 hours/day × 5 days)  
**Format**: Self-paced with optional live Q&A  
**Delivery**: English/Portuguese bilingual materials  

---

## Workshop Overview

### Learning Journey Map
```
Pre-Workshop (8-12h)          Day 1 (4h)              Day 2 (4h)              Day 3 (4h)              Day 4 (4h)              Day 5 (4h)
└─ Azure Fundamentals    →    Foundations        →    MAF Deep-Dive    →    LangGraph Focus    →    M365 Integration   →    Capstone
   └─ MAF Concepts            └─ Declarative           └─ Hosted Agents       └─ Connected           └─ Publishing           └─ Deploy
      └─ Env Setup               └─ First Deploy           └─ Debugging           └─ Own Infra           └─ Teams               └─ Present
```

### Pedagogical Approach
- **30% Concept** (Theory, architecture, decision frameworks)
- **60% Practice** (Hands-on labs, code customization, deployment)
- **10% Discussion** (Troubleshooting, Q&A, reflection)

### Daily Rhythm (4-Hour Structure)
Each day follows this pattern:
- **Hour 1 (00:00-00:60)**: Concept introduction + demo
- **Hour 2 (01:00-02:00)**: Guided hands-on lab
- **Hour 3 (02:00-03:00)**: Deep-dive exercise + exploration
- **Hour 4 (03:00-04:00)**: Troubleshooting + Q&A + optional topics

---

## Pre-Workshop Phase (1 Week Before)

### Timeline: Days -7 to -1

**Day -7 (One Week Before)**
- 📧 Send welcome email with:
  - Pre-workshop materials (Azure Fundamentals, MAF guide, setup checklist)
  - Azure subscription acquisition instructions
  - Pre-assessment quiz link
  - Office hours schedule
- ⏱️ Expected student effort: 8-12 hours spread over week

**Day -3 (Wednesday)**
- 🎥 Live Office Hours #1 (60 min)
  - Azure subscription troubleshooting
  - Tool installation support
  - Azure fundamentals Q&A
  - Cloud platform terminology for Azure

**Day -1 (Friday)**
- 🎥 Live Office Hours #2 (60 min)
  - Environment validation walkthrough
  - Run `validate-setup.ps1` together
  - Last-minute issues resolution
  - Workshop expectations and logistics
- ✅ Instructor validates: All students pass environment check

---

## Day 1: Foundations & First Agent

**Theme**: "From Zero to Deployed Agent"  
**Goal**: Build confidence with first successful deployment  
**Focus**: Azure basics, Foundry concepts, declarative pattern  

### Hour 1: Welcome & Infrastructure (00:00-01:00)

**00:00-00:15 | Welcome & Orientation**
- 👋 Introductions and icebreaker
- 🎯 Workshop objectives and success metrics
- 📋 Agenda overview and daily expectations
- 🔧 Quick environment check (all green?)
- 🤝 Communication channels (Slack/Teams, async support)

**00:15-00:30 | Azure & Foundry Fundamentals**
- 📊 Presentation: "Azure Fundamentals for Cloud Practitioners" (15 min)
  - Resource Manager vs other IaC tools
  - Resource Groups vs Tags
  - Subscriptions, Managed Identities
  - Azure CLI quick reference
- 🗺️ Cloud-to-Azure service mapping cheat sheet

**00:30-01:00 | Lesson 0: Infrastructure Provisioning**
- 🎬 Instructor Demo (15 min):
  - Navigate to `prereq/` folder
  - Explain Bicep template structure
  - Run `deploy.ps1` (Foundry, ACR, ACA, App Insights)
  - Show Azure Portal resources created
- 🛠️ Student Lab (15 min):
  - Clone workshop repository
  - Execute `prereq/deploy.ps1` in their subscription
  - Validate deployment with `validate-deployment.ps1`
  - Troubleshoot common errors (RBAC, quotas)

**✅ Checkpoint**: Everyone has Foundry project + ACR + ACA environment

---

### Hour 2: Declarative Agent Pattern (01:00-02:00)

**01:00-01:15 | Concept: Declarative Agents**
- 📊 Presentation: "Agent Patterns Overview"
  - Declarative vs Hosted vs Connected
  - When to use each pattern
  - Foundry Responses API architecture
  - Portal editability vs container control
- 🔍 Live demo: Explore Foundry portal agent interface

**01:15-01:45 | Lesson 1: Build Declarative Agent**
- 📖 Read together: `lesson-1-declarative/README.md` (5 min)
- 🎬 Instructor Demo (10 min):
  - Show `create_agent.py` code walkthrough
  - Explain `PromptAgentDefinition`
  - Run script: agent appears in portal
  - Test in portal playground
- 🛠️ Student Lab (20 min):
  ```powershell
  cd lesson-1-declarative
  pip install -r requirements.txt
  python create_agent.py
  python test_agent.py
  ```
  - Customize agent instructions
  - Test via SDK and portal
  - Experiment with different queries

**01:45-02:00 | Discussion & Troubleshooting**
- 💬 Q&A: Common issues (authentication, model not found)
- 🎯 Reflection: "When would you use declarative agents in production?"
- 📝 Self-check questions (README)

**✅ Checkpoint**: Everyone deployed and tested declarative agent

---

### Hour 3: Microsoft Agent Framework Introduction (02:00-03:00)

**02:00-02:30 | Concept: MAF for LangGraph Developers**
- 📊 Presentation: "MAF Conceptual Model" (15 min)
  - LangGraph State → MAF Agent Context
  - LangGraph Nodes → MAF Tools
  - LangGraph Edges → MAF Orchestration
  - Side-by-side code comparison
  - When to choose MAF over LangGraph
- 📖 Reference: `prereq/MAF-FOR-LANGGRAPH-DEVS.md`

**02:30-03:00 | Lesson 2: Hosted Agent (MAF) - Part 1**
- 📖 Read together: `lesson-2-hosted-maf/README.md` (5 min)
- 🎬 Instructor Demo (10 min):
  - Code walkthrough: `src/agent/finance_agent.py`
  - Explain MAF plain Python tools and registration via tool list
  - Show Dockerfile and container structure
  - Preview deploy.ps1 automation
- 🛠️ Student Lab (15 min):
  - Review MAF agent code
  - Customize tool function (e.g., add new stock ticker)
  - Understand container build process
  - Prepare for deployment (starts in Hour 4)

---

### Hour 4: Deep Dive & Troubleshooting (03:00-04:00)

**03:00-03:30 | Lesson 2: Hosted Agent (MAF) - Part 2 (Deployment)**
- 🛠️ Student Lab (30 min):
  ```powershell
  cd lesson-2-hosted-maf/labs/solution
  .\deploy.ps1
  ```
  - Build container image in ACR
  - Register as hosted agent
  - Start deployment
  - Monitor logs: `az cognitiveservices agent logs show`
  - Test agent: `python test_agent.py`

**⚠️ Expected Challenges**:
- ACR authentication issues
- Container build timeouts (slow network)
- Known MAF routing issues (apply known fixes)

**03:30-04:00 | Q&A, Debug Session & Day 1 Wrap**
- 🐛 Troubleshooting clinic (instructor helps stuck students)
- 💬 Open discussion: MAF vs Declarative trade-offs
- 📋 Preview Day 2: LangGraph deep dive (the critical lesson!)
- 📝 Optional homework: Read `lesson-3-hosted-langgraph/README.md`
- 🎯 Reflection: What was most challenging today?

**✅ Day 1 Success Criteria**:
- ✅ Infrastructure deployed
- ✅ Declarative agent working
- ✅ MAF agent deployed (or troubleshooting identified)
- ✅ Comfort with Azure CLI and Foundry portal

---

## Day 2: Microsoft Agent Framework Deep Dive

**Theme**: "Mastering Hosted Agents with MAF"  
**Goal**: Understand containerized agents, debugging, and lifecycle management  
**Focus**: MAF patterns, container troubleshooting, agent versioning  

### Hour 1: MAF Deep Dive (00:00-01:00)

**00:00-00:15 | Day 2 Kickoff & Recap**
- 🔄 Day 1 recap quiz (5 questions, Kahoot style)
- 🎯 Day 2 objectives and agenda
- 🐛 Review Day 1 blockers and resolutions

**00:15-00:45 | Advanced MAF Concepts**
- 📊 Presentation: "MAF Agent Lifecycle" (30 min)
  - Agent versions and deployments
  - Container lifecycle (build → register → start → stop → delete)
  - Debugging strategies (logs, tracing, local testing)
  - Known issues and workarounds
  - Managed Identity and RBAC requirements
  - Environment variables best practices

**00:45-01:00 | Demo: Debugging MAF Agents**
- 🎬 Live troubleshooting session:
  - Introduce intentional bug in agent code
  - Show how to read container logs
  - Demonstrate local testing with Docker
  - Fix and redeploy
  - Version management demo

---

### Hour 2: MAF Hands-On Enhancement (01:00-02:00)

**01:00-01:45 | Lab: Enhance Your MAF Agent**
- 🛠️ Student Exercise (45 min):
  - **Task 1** (15 min): Add a new custom tool (e.g., currency converter)
  - **Task 2** (15 min): Implement error handling and logging
  - **Task 3** (15 min): Test tool locally, then redeploy
  - **Stretch Goal**: Implement async tools or structured logging

**01:45-02:00 | Code Review & Discussion**
- 👥 Pair share: Show your custom tool
- 💬 Discussion: "What challenges did you face?"
- 📝 Best practices: Tool design patterns

**✅ Checkpoint**: Students have custom MAF agent with multiple tools

---

### Hour 3: LangGraph on Azure Foundry (02:00-03:00)

**02:00-02:30 | Concept: LangGraph on Foundry**
- 📊 Presentation: "Running LangGraph on Azure Foundry" (20 min)
  - **Key advantages of Foundry for LangGraph teams**:
    - "Your LangGraph code runs virtually unchanged"
    - "Gain M365 integration and enterprise governance"
    - "Multi-framework flexibility—choose the best tool per project"
  - LangGraph compatibility story
  - LangGraph deployment patterns on Foundry
  - `azure-ai-agentserver-langgraph` adapter explained
  - Deployment effort estimation (minimal!)
  - Multi-platform patterns (run agents where they fit best)

**02:30-03:00 | Lesson 3: Hosted Agent (LangGraph) - Part 1**
- 📖 Read together: `lesson-3-hosted-langgraph/README.md` (5 min)
- 🎬 Instructor Demo (10 min):
  - Code walkthrough: LangGraph agent structure
  - Compare LangGraph structure with MAF (side-by-side)
  - Explain ReAct pattern in LangGraph
  - Show adapter integration
- 🛠️ Student Lab (15 min):
  - Review LangGraph code: `labs/solution/main.py`
  - Identify familiar patterns from their LangGraph experience
  - Customize agent graph (add node or edge)
  - Prepare for deployment

---

### Hour 4: LangGraph Deployment & Troubleshooting (03:00-04:00)

**03:00-03:30 | Lesson 3: Hosted Agent (LangGraph) - Part 2 (Deployment)**
- 🛠️ Student Lab (30 min):
  ```powershell
  cd lesson-3-hosted-langgraph/labs/solution
  .\deploy.ps1
  ```
  - Build LangGraph container
  - Deploy to Foundry as hosted agent
  - Test via SDK: `python test_agent.py`
  - Compare behavior across different deployment approaches

**03:30-03:50 | Discussion: MAF vs LangGraph Decision Framework**
- 🎯 Interactive exercise: Decision tree activity
  - Scenario cards: "When would you choose X?"
  - Group discussion: Pros/cons of each framework
  - Hybrid patterns: Using both together

**03:50-04:00 | Day 2 Wrap & Preview**
- 📋 Day 2 reflection: "What surprised you?"
- 🎯 Preview Day 3: Own infrastructure (ACA), more control
- 📝 Optional homework: Read Azure Container Apps docs

**✅ Day 2 Success Criteria**:
- ✅ Advanced MAF agent with custom tools
- ✅ LangGraph agent deployed on Foundry
- ✅ Understand MAF vs LangGraph trade-offs
- ✅ Confidence debugging containerized agents

---

## Day 3: Connected Agents & Own Infrastructure

**Theme**: "Taking Control with Azure Container Apps"  
**Goal**: Deploy agents on own infrastructure with Foundry governance  
**Focus**: ACA deployment, connected agent pattern, AI Gateway  

### Hour 1: Connected Agent Architecture (00:00-01:00)

**00:00-00:15 | Day 3 Kickoff**
- 🔄 Days 1-2 mega-recap (10 min)
- 🎯 Day 3 theme: "Your Infra, Foundry Governance"
- 📊 Show progression map: Declarative → Hosted → Connected

**00:15-00:45 | Concept: Connected Agents**
- 📊 Presentation: "Hosted vs Connected Patterns" (30 min)
  - Architecture comparison diagram
  - When to use connected agents
  - Azure Container Apps introduction
  - AI Gateway (APIM) role and benefits
  - Managed Identity: Project MI vs ACA MI
  - Observability and governance strategy
  - Cost implications and scaling control

**00:45-01:00 | Demo: ACA & AI Gateway Walkthrough**
- 🎬 Live demo in Azure Portal:
  - Show ACA environment components
  - Explain Bicep template for ACA deployment
  - Preview AI Gateway configuration
  - Show how connected agent registers in Foundry

---

### Hour 2: Deploy to Azure Container Apps (01:00-02:00)

**01:00-01:15 | Lesson 4: Introduction**
- 📖 Read together: `lesson-4-aca-langgraph/README.md` (5 min)
- 🎬 Code walkthrough (10 min):
  - Compare with Lesson 3 code (what changed?)
  - FastAPI vs agentserver adapter
  - Bicep infrastructure template
  - Environment variables and secrets

**01:15-01:50 | Lab: Deploy Connected Agent**
- 🛠️ Student Lab (35 min):
  ```powershell
  cd lesson-4-aca-langgraph/labs/solution
  .\deploy.ps1
  ```
  - Deploy ACA infrastructure (Bicep)
  - Build and push container to ACR
  - Deploy container app
  - Test direct endpoint (bypass Foundry)
  - Register as connected agent in portal
  - Test via Foundry routing

**01:50-02:00 | Quick Troubleshooting Break**
- 🐛 Address deployment issues
- ✅ Validate: All agents respond to queries

**✅ Checkpoint**: Connected agent deployed and registered

---

### Hour 3: Deep Dive - Observability & Governance (02:00-03:00)

**02:00-02:30 | Lab: Explore AI Gateway & Monitoring**
- 🛠️ Guided exploration (30 min):
  - **Task 1**: View AI Gateway logs in APIM
  - **Task 2**: Analyze request traces in App Insights
  - **Task 3**: Configure rate limiting policy
  - **Task 4**: Test governance features (quota, throttling)
  - **Task 5**: Compare telemetry: Hosted vs Connected

**02:30-03:00 | Discussion: Architecture Decision Workshop**
- 🎯 Group activity: "Which Pattern for Which Scenario?"
  - Provide 5 real-world scenarios
  - Teams decide: Declarative, Hosted (MAF), Hosted (LangGraph), or Connected?
  - Present rationale
  - Instructor feedback and best practices

---

### Hour 4: Comparative Analysis & Day 3 Wrap (03:00-04:00)

**03:00-03:30 | Lab: Performance & Cost Comparison**
- 🛠️ Hands-on analysis (30 min):
  - Measure response latency: Hosted vs Connected
  - Review Azure cost analysis for deployed resources
  - Calculate cost estimates for production scale
  - Discuss scaling strategies for each pattern

**03:30-03:50 | Open Q&A & Troubleshooting Clinic**
- 💬 Open floor discussion
- 🐛 Debug session for stuck students
- 📝 Share experiences and lessons learned

**03:50-04:00 | Day 3 Wrap & Preview**
- 🎯 Reflection: "What's your preferred pattern and why?"
- 📋 Preview Day 4: Microsoft 365 integration
- 📝 Optional prep: Create M365 developer tenant (if don't have)

**✅ Day 3 Success Criteria**:
- ✅ Connected agent deployed on ACA
- ✅ Understand AI Gateway capabilities
- ✅ Can make informed architecture decisions
- ✅ Performed cost and performance analysis

---

## Day 4: Microsoft 365 Integration

**Theme**: "Bringing Agents to Teams & M365"  
**Goal**: Integrate agents with Microsoft 365 ecosystem  
**Focus**: Agent 365 SDK, Bot Framework, Adaptive Cards, publishing  

### Hour 1: Agent 365 Fundamentals & SDK Integration (00:00-01:00)

**00:00-00:15 | Day 4 Kickoff & M365 Context**
- 🔄 Quick recap: Days 1-3 journey
- 🎯 Day 4 theme: "From Backend to Business Users"
- 📊 Show demo: Agent in Teams (wow factor!)

**00:15-00:45 | Concept: Microsoft 365 Integration**
- 📊 Presentation: "Agent 365 Architecture" (30 min)
  - Why integrate with M365?
  - Agent 365 SDK components
  - Bot Framework Activity Protocol
  - Adaptive Cards for rich UI
  - Single Tenant versus Cross-tenant scenarios (Azure ≠ M365)
  - Publishing workflow overview for Cross-tenant (most complex)
  - Enterprise deployment models

**00:45-01:00 | Lesson 5: A365 SDK Deep Dive**
- 📖 Read: `lesson-5-a365-langgraph/README.md` (5 min)
- 🎬 Code walkthrough (10 min):
  - Azure Monitor OpenTelemetry integration
  - Bot Framework `/api/messages` endpoint
  - Adaptive Cards template generation
  - Instrumented tools with span tracking

**✅ Checkpoint**: Agent code reviewed and ready for SDK lab

---

### Hour 2: SDK Lab + A365 Prerequisites (01:00-02:00)

**01:00-01:35 | Lab: Enhance Agent with A365 SDK**
- 🛠️ Student Lab (35 min):
  ```powershell
  cd lesson-5-a365-langgraph
  .\deploy.ps1
  ```
  - Add OpenTelemetry to existing agent
  - Implement Bot Framework endpoint
  - Create Adaptive Card for financial data
  - Deploy enhanced agent
  - Test observability in Azure Monitor

**01:35-01:45 | Demo: Adaptive Cards Showcase**
- 🎬 Instructor shows creative Adaptive Card examples
- 💬 Discussion: When to use rich UI vs plain text

**✅ Checkpoint**: Agent enhanced with A365 SDK features

**01:45-02:00 | Lesson 6: A365 Prerequisites**
- 📖 Read: `lesson-6-a365-setup/README.md` (5 min)
- 🛠️ Student Lab (10 min):
  - Install A365 CLI: `a365 --version`
  - Configure for cross-tenant scenario
  - Create Entra ID app registration
  - Set up Agent Blueprint manifest
  - Validate configuration
  - Quick overview about differences from single tenant scenario

**✅ Checkpoint**: A365 CLI configured and ready

---

### Hour 3: Publishing to M365 Admin Center (02:00-03:00)

**02:00-02:15 | Lesson 6 — Step 3: Publishing Workflow**
- 📖 Read: `lesson-6-a365-setup/README.md#step-3---publish-to-m365-admin-center` (5 min)
- 📊 Presentation: "Publishing Process" (10 min)
  - Agent Blueprint submission
  - Admin Center approval workflow
  - Deployment scopes (all users, groups, test users)
  - Update and maintenance process

**02:15-02:50 | Lab: Publish Your Agent**
- 🛠️ Guided walkthrough (35 min):
  - Prepare Agent Blueprint package
  - Submit to M365 Admin Center (demo environment)
  - Navigate approval process
  - Configure deployment scope
  - Troubleshoot common submission errors
  - **Note**: Full approval takes days; use pre-approved demo agents

**02:50-03:00 | Discussion: Enterprise Deployment**
- 💬 Best practices for production deployment
- 🎯 Compliance and governance considerations

---

### Hour 4: Creating Agent Instances in Teams (03:00-04:00)

**03:00-03:30 | Lesson 6 — Steps 4–8: Teams Integration**
- 📖 Read: `lesson-6-a365-setup/README.md#step-4---configure-agent-in-teams-developer-portal` (5 min)
- 🎦 Demo: Configure Teams Developer Portal & request instance (10 min)
- 🛠️ Student Lab (15 min):
  - Create personal agent instance in Teams
  - Create shared team instance
  - Test agent in Teams chat
  - Explore instance management (suspend, resume, delete)
  - View usage analytics

**03:30-03:50 | Lab: Real-World Scenario Testing**
- 🛠️ Hands-on testing (20 min):
  - Test various financial queries in Teams
  - Share screenshots in workshop channel
  - Test Adaptive Cards rendering
  - Explore multi-turn conversations

**03:50-04:00 | Day 4 Wrap & Capstone Preview**
- 🎯 Reflection: "How would you use this in your organization?"
- 📋 Capstone project briefing (detailed in Day 5)
- 📝 Prep: Think about your capstone project idea

**✅ Day 4 Success Criteria**:
- ✅ Agent published to M365 Admin Center (Lesson 6, Step 3)
- ✅ Agent instance configured in Teams Developer Portal and approved (Lesson 6, Steps 4-6)
- ✅ Agent tested in Teams chat (Lesson 6, Step 7)
- ✅ Understand end-to-end A365 lifecycle (config → blueprint → publish → instance → test)

---

## Day 5: Capstone Project & Graduation

**Theme**: "Build Your Own Agent"  
**Goal**: Apply all learned concepts in a practical project  
**Focus**: Independent creation, troubleshooting, presentation  

### Hour 1: Capstone Briefing & Project Setup (00:00-01:00)

**00:00-00:20 | Final Workshop Kickoff**
- 🔄 Days 1-4 comprehensive recap (15 min)
  - Journey map visualization
  - Key concepts review
  - Q&A on any lingering topics
- 🎯 Day 5 focus: Apply everything you learned

**00:20-00:50 | Capstone Project Briefing**
- 📋 **Project Requirements** (see detailed rubric in assessment docs):
  - Build a custom financial services agent
  - Choose: Portfolio Advisor, Risk Analyzer, or Market Researcher
  - Must use LangGraph framework (Lesson 3 or 4 approach)
  - Implement minimum 2 custom tools
  - Deploy to Foundry (Hosted or Connected)
  - Optional: Integrate with Teams (bonus points)
  
- 🎯 **Evaluation Criteria** (100 points):
  - 40pts: Successful deployment and functionality
  - 30pts: Custom tools implementation
  - 20pts: Code quality and structure
  - 10pts: Documentation in README

- 🛠️ **Resources Available**:
  - All lesson templates as reference
  - Instructor support via async channel
  - Peer collaboration encouraged
  - Test datasets provided

**00:50-01:00 | Project Planning**
- 🛠️ Students:
  - Choose project scenario
  - Sketch architecture (hosted vs connected?)
  - List tools to implement
  - Estimate effort
  - Share plan in workshop channel (accountability!)

**✅ Checkpoint**: Everyone has a clear project plan

---

### Hours 2-3: Capstone Project Work (01:00-03:00)

**01:00-03:00 | Independent Project Development (120 min)**

- 🛠️ **Student Work**:
  - Create new directory: `capstone/<your-project-name>/`
  - Clone and customize appropriate lesson template
  - Implement custom tools (financial API integrations)
  - Build and deploy agent
  - Test and debug
  - Document in README
  
- 👨‍🏫 **Instructor Role**:
  - Circulate "virtually" (check-ins via chat)
  - Answer questions async
  - Scheduled 15-min office hours every 30 minutes
  - Monitor progress via shared tracker
  
- 🤝 **Peer Support**:
  - Optional breakout rooms or pair programming
  - Share tips and troubleshooting in channel
  - Code review buddy system

**Suggested Milestones**:
- ⏱️ **01:30** - Code completed, starting build
- ⏱️ **02:15** - Deployment successful
- ⏱️ **02:45** - Testing complete, documentation finalized

**⚠️ Instructor Alert**: Monitor for stuck students; intervene proactively

---

### Hour 4: Presentations, Assessment & Graduation (03:00-04:00)

**03:00-03:40 | Capstone Presentations (40 min)**

- 🎤 **Lightning Talks** (5 min each, 8 students max per session):
  - Student shares screen
  - Demo agent functionality (2 min)
  - Explain architecture decisions (2 min)
  - Q&A (1 min)
  - Peer feedback in chat

- 🎯 **Evaluation**:
  - Instructor scores using rubric (async after demos)
  - Peer appreciation: "Most creative project" vote

**03:40-03:55 | Knowledge Quiz & Survey (15 min)**

- 📝 **Post-Workshop Quiz** (10 min):
  - 20 multiple-choice questions
  - Covers all lessons
  - Passing: 70%+ (14/20 correct)
  - Immediate feedback

- 📊 **Workshop Survey** (5 min):
  - NPS score
  - Self-assessment: confidence levels
  - Most valuable lesson
  - Biggest challenge
  - Improvement suggestions

**03:55-04:00 | Closing & Next Steps (5 min)**

- 🎓 **Graduation Moment**:
  - Congratulate students
  - Highlight workshop achievements
  - Share aggregate quiz results
  - Recognize standout projects

- 📋 **Next Steps Roadmap**:
  - Post-workshop resources (Next-Steps.md)
  - Community Slack/Teams channel stays open
  - Office hours: 2 sessions in Week 2
  - Follow-up survey (1 week later): "Did you deploy an agent?"

- 🎯 **Final Challenge**:
  - **Goal**: Deploy a production/POC agent within 1 week
  - Share your success story in community channel
  - Request help if blocked

- 🙏 **Thank You & Closing Remarks**

---

## Post-Workshop Support (Weeks 1-2)

### Week 1: Consolidation
- **Day 1-2**: Students finalize capstone projects if needed
- **Day 3**: Instructor reviews all capstone submissions
- **Day 4**: Individual feedback sent to students
- **Day 5**: Async Q&A via community channel

### Week 2: Continuous Learning
- **Tuesday**: Live Office Hours #1 (60 min) - Deployment support
- **Thursday**: Live Office Hours #2 (60 min) - Advanced topics Q&A
- **Friday**: Follow-up survey sent (deployment success tracking)

### Week 3+: Community Phase
- 📚 Share advanced resources (Next-Steps.md topics)
- 💬 Monthly community call (optional)
- 📊 Collect success stories and testimonials
- 🎯 Track KPI: 80%+ deploy agent within 1 week

---

## Workshop Success Metrics Tracking

### During Workshop (Real-Time)
- ✅ Lab completion rate per lesson
- ✅ Environment issues logged and resolved
- ✅ Engagement in Q&A and discussion
- ✅ Capstone project submissions

### Immediately Post-Workshop
- ✅ Quiz pass rate (target: 70%+)
- ✅ Capstone pass rate (target: 80%+)
- ✅ NPS score (target: ≥8)
- ✅ Self-assessed confidence improvement

### 1 Week Post-Workshop
- ✅ Agent deployment rate (target: 80%+)
- ✅ Community engagement (questions, sharing)
- ✅ Support requests volume and resolution

### 1 Month Post-Workshop
- ✅ Production agents deployed count
- ✅ Executive stakeholder feedback
- ✅ Student testimonials collected

---

## Appendices

### Appendix A: Communication Cadence

| Timing | Channel | Purpose |
|--------|---------|---------|
| Day -7 | Email | Welcome + prereq materials |
| Day -3 | Zoom/Teams | Office hours #1 |
| Day -1 | Zoom/Teams | Office hours #2 + validation |
| Days 1-5 | Slack/Teams | Daily async support |
| Days 1-5 | Optional Zoom | End-of-day live Q&A (30 min) |
| Week 2 | Zoom/Teams | Post-workshop office hours (2×) |
| Week 3 | Email/Survey | Follow-up deployment tracking |

### Appendix B: Instructor Preparation Checklist

**2 Weeks Before**:
- [ ] Validate all lesson code works end-to-end
- [ ] Test infrastructure deployment scripts
- [ ] Prepare demo environment
- [ ] Create pre-workshop materials
- [ ] Set up communication channels

**1 Week Before**:
- [ ] Send welcome email with prereqs
- [ ] Test video conferencing setup
- [ ] Review diagnostic and student profiles
- [ ] Prepare troubleshooting playbook
- [ ] Schedule office hours

**1 Day Before**:
- [ ] Validate all students completed setup
- [ ] Prepare slides and demos
- [ ] Test screen sharing and recordings
- [ ] Review common issues from past cohorts
- [ ] Mental prep and dry run

### Appendix C: Daily Instructor Guide

See separate document: `INSTRUCTOR-GUIDE.md` in this folder (detailed minute-by-minute facilitation notes)

### Appendix D: Emergency Scenarios

**Scenario 1: Student's subscription blocked**
- **Solution**: Provide instructor sandbox access
- **Prevention**: Pre-validation 24h before

**Scenario 2: Azure outage during workshop**
- **Solution**: Switch to theory/discussion/code review
- **Backup**: Pre-deployed demo agents for testing

**Scenario 3: Majority stuck on same issue**
- **Solution**: Pause, address collectively, adjust schedule
- **Prevention**: Progressive difficulty, checkpoints

**Scenario 4: Network issues for remote students**
- **Solution**: Record sessions, provide async catch-up materials
- **Prevention**: Pre-downloaded materials, offline mode options

---

**Document Version**: 0.7  
**Last Updated**: February 16, 2026  
**Next Review**: After first cohort delivery  
**Maintained By**: Learning Architect Team
