# Instructor Facilitation Guide
**Microsoft Foundry AI Agents Workshop**

---

**Version**: 1.0  
**Purpose**: Practical facilitation guidance for workshop delivery  
**Audience**: Workshop instructors and teaching assistants  

---

## Table of Contents
1. [Instructor Role & Responsibilities](#instructor-role--responsibilities)
2. [Preparation Checklist](#preparation-checklist)
3. [Detailed Module Scripts](#detailed-module-scripts)
4. [Daily Facilitation Plans](#daily-facilitation-plans)
5. [Facilitation Techniques](#facilitation-techniques)
6. [Troubleshooting Common Issues](#troubleshooting-common-issues)
7. [Managing Resistance](#managing-resistance)
8. [Time Management Strategies](#time-management-strategies)
9. [Assessment Administration](#assessment-administration)

---

## Instructor Role & Responsibilities

### Primary Responsibilities
1. **Content Delivery**
   - Present concepts clearly and engagingly
   - Demonstrate technical implementations
   - Bridge AWS → Azure knowledge gaps
   - Address Microsoft platform skepticism tactfully

2. **Hands-On Support**
   - Guide participants through labs
   -troubleshoot technical issues proactively
   - Monitor progress and intervene when stuck
   - Validate successful completions

3. **Environment Management**
   - Ensure all prerequisites met before Day 1
   - Maintain backup resources (sandboxes, images)
   - Test all code samples before each session
   - Have fallback plans for outages

4. **Community Building**
   - Foster collaborative learning environment
   - Manage discussions productively
   - Recognize participant contributions
   - Create safe space for questions

5. **Assessment & Feedback**
   - Evaluate capstone projects fairly
   - Provide constructive individual feedback
   - Track workshop metrics
   - Iterate based on feedback

### Time Commitment

**Pre-Workshop** (10-15 hours)
- Review and test all lessons
- Prepare demo environment
- Customize materials for cohort
- Pre-workshop office hours

**During Workshop** (25-30 hours)
- 20 hours: Live facilitation
- 5-10 hours: Async support, prep, grading

**Post-Workshop** (5-7 hours)
- Capstone evaluation
- Individual feedback
- Follow-up office hours
- Retrospective and improvements

---

## Preparation Checklist

### 3 Weeks Before Workshop

**Administrative**
- [ ] Confirm participant list and contact information
- [ ] Send welcome email with prerequisites
- [ ] Set up communication channels (Slack/Teams)
- [ ] Schedule pre-workshop office hours
- [ ] Create shared tracker for progress monitoring

**Technical**
- [ ] Validate own Azure subscription and resources
- [ ] Test all lesson code end-to-end (Lessons 0-8)
- [ ] Build all container images successfully
- [ ] Deploy each agent pattern to verify functionality
- [ ] Review `context.md` known issues and fixes
- [ ] Prepare backup resources (pre-built images, sandbox subscriptions)

**Materials**
- [ ] Review and update slides (if changes needed)
- [ ] Prepare demo scenarios and sample queries
- [ ] Create troubleshooting cheat sheet
- [ ] Print/digital handouts (architecture diagrams, cheat sheets)
- [ ] Prepare screen recording backup (in case live demo fails)

### 1 Week Before Workshop

**Participant Readiness**
- [ ] Send reminder about prerequisites completion
- [ ] Share study materials (Azure Fundamentals, MAF guide)
- [ ] Send Azure subscription guide
- [ ] Announce office hours schedule
- [ ] Send pre-assessment quiz link

**Environment Validation**
- [ ] Host Office Hours #1 (setup support)
- [ ] Track who completed environment setup
- [ ] Identify and resolve blockers
- [ ] Prepare backup sandboxes for those without subscriptions

**Final Preparation**
- [ ] Dry run of Day 1 content (timing check)
- [ ] Test video conferencing setup
- [ ] Prepare breakout rooms (if applicable)
- [ ] Review participant pre-assessment scores
- [ ] Identify participants who may need extra support

### 48 Hours Before Workshop

**Critical Checks**
- [ ] Host Office Hours #2 (final validation)
- [ ] Run `validate-setup.ps1` with participants
- [ ] Confirm all participants "green" on environment
- [ ] Distribute final reminder with Day 1 logistics
- [ ] Test recording setup

**Instructor Readiness**
- [ ] Review Day 1 agenda and notes
- [ ] Prepare opening remarks and icebreaker
- [ ] Set up dual-monitor workspace
- [ ] Test screenshare and code switching
- [ ] Mental preparation and rest

### Day Before Each Session

- [ ] Review day's content and key points
- [ ] Test demos planned for that day
- [ ] Check Azure services operational status
- [ ] Prepare discussion questions
- [ ] Review previous day's feedback/issues

---

## Detailed Module Scripts

Each module has a **detailed instructional script** with minute-by-minute facilitation guidance, talking points, demo instructions, common pitfalls, and transition cues. **Use these scripts as your primary reference during delivery.**

| Day | Module | Script | Description |
|-----|--------|--------|-------------|
| 1 | Module 0 — Infrastructure Setup | [MODULE-0-INFRASTRUCTURE-SCRIPT.md](instructional-scripts/MODULE-0-INFRASTRUCTURE-SCRIPT.md) | Azure resource deployment, environment validation, troubleshooting setup issues |
| 1 | Module 1 — Declarative Agent | [MODULE-1-DECLARATIVE-AGENT-SCRIPT.md](instructional-scripts/MODULE-1-DECLARATIVE-AGENT-SCRIPT.md) | First agent creation using declarative pattern, Azure AI Foundry portal walkthrough |
| 1–2 | Module 2 — Hosted MAF Agent | [MODULE-2-HOSTED-MAF-SCRIPT.md](instructional-scripts/MODULE-2-HOSTED-MAF-SCRIPT.md) | Microsoft Agent Framework hosted agent, code structure, local testing, deployment |
| 2–3 | Module 3 — Hosted LangGraph Agent | [MODULE-3-HOSTED-LANGGRAPH-SCRIPT.md](instructional-scripts/MODULE-3-HOSTED-LANGGRAPH-SCRIPT.md) | LangGraph agent on Azure AI Foundry, graph-based orchestration |
| 3 | Module 4 — ACA Deployment | [MODULE-4-ACA-DEPLOYMENT-SCRIPT.md](instructional-scripts/MODULE-4-ACA-DEPLOYMENT-SCRIPT.md) | Azure Container Apps deployment, Bicep templates, production patterns |
| 4 | Modules 5–6 — A365 Prerequisites & SDK | [MODULES-5-6-A365-SETUP-SDK-SCRIPT.md](instructional-scripts/MODULES-5-6-A365-SETUP-SDK-SCRIPT.md) | Microsoft 365 Agents SDK setup, configuration, and integration |
| 5 | Modules 7–8 — Publish & Instances | [MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md](instructional-scripts/MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md) | Agent publishing to Teams, agent instances, capstone project |

### How to Use the Scripts

1. **Before each session**: Read the corresponding script end-to-end. Note the timing markers, key talking points, and demo checkpoints.
2. **During delivery**: Keep the script open as a side reference. Follow the timing cues but adapt to your audience's pace.
3. **For demos**: Each script includes exact commands, expected outputs, and fallback instructions if something fails.
4. **For transitions**: Scripts include transition phrases between sub-sections to maintain flow.

> **Tip**: The scripts are designed to be self-contained. If you need to hand off a module to a co-instructor, the script has all the context they need.

---

## Daily Facilitation Plans

### Day 1: Setting the Foundation

**Theme**: "From Zero to Deployed Agent"  
**Focus**: Infrastructure, declarative pattern, MAF introduction

**Key Objectives:**
- Build participant confidence with first deployment
- Establish positive learning environment
- Address Azure onboarding anxieties
- Demonstrate portal and basic patterns

**Critical Success Factors:**
- Environment issues resolved quickly (have backup sandboxes ready)
- Everyone deploys declarative agent successfully
- Positive tone set for rest of week
- Participants comfortable asking questions

**Instructor Mindset:**
- Patient and encouraging (first-time Azure users!)
- Celebrate small wins ("Your first agent is deployed!")
- Normalize troubleshooting ("Errors are part of learning")
- Accessibility over perfection

**Granular Timing Overview** (aligned with Master Agenda):
- **Hour 1** (00:00-01:00):
  - 00:00-00:15: Welcome & environment validation
  - 00:15-00:30: Azure fundamentals presentation
  - 00:30-01:00: Infrastructure deployment lab (Module 0)
- **Hour 2** (01:00-02:00):
  - 01:00-01:15: Declarative pattern concepts
  - 01:15-01:45: Module 1 lab (build & test)
  - 01:45-02:00: Discussion & troubleshooting
- **Hour 3** (02:00-03:00):
  - 02:00-02:30: MAF for LangGraph developers
  - 02:30-03:00: Module 2 Part 1 (code review & local test)
- **Hour 4** (03:00-04:00):
  - 03:00-03:30: Module 2 Part 2 (deployment)
  - 03:30-04:00: Debug clinic & Day 1 wrap

**Timing Attention Points:**
- ⚠️ Infrastructure deployment (30 min) can extend if quota issues
- ⚠️ MAF deployment (Hour 4) may not complete—buffer built into Day 2
- ✅ Keep welcome to 15 minutes max to preserve lab time
- ⏱️ Watch clock during labs; give 5-minute warnings

**Facilitation Tips:**
- **00:00-00:15**: Keep  welcome brief; quick icebreaker, then dive in
- **Hour 2**: Show portal extensively; visual learners appreciate UI
- **Hour 3**: Explicitly connect MAF to LangGraph (comparison slide ready)
- **Hour 4**: Don't force MAF completion; pause for Day 2 if needed

**Common Day 1 Issues:**
1. **Azure quota limits**: Have list of alternative regions ready
2. **ACR authentication fails**: Walk through `az acr login` step-by-step
3. **Confusion about resource groups**: Use analogy (folders for resources)
4. **MAF routing issues**: Apply context.md fixes; explain why they're needed

**End of Day 1 Checklist:**
- [ ] All participants have infrastructure deployed
- [ ] Declarative agent working for everyone
- [ ] MAF agent either deployed or troubleshooting plan in place
- [ ] Day 2 preview shared
- [ ] Async support channel active

---

### Day 2: Deepening Understanding

**Theme**: "Mastering Hosted Agents with MAF"  
**Focus**: MAF deep-dive, LangGraph migration, debugging

**Key Objectives:**
- Complete MAF deployment (if not done Day 1)
- Master container debugging skills
- Successfully deploy LangGraph agent (CRITICAL)
- Address platform resistance head-on

**Critical Success Factors:**
- LangGraph agent deployed successfully (proof for AWS practitioners)
- Participants see LangGraph compatibility
- Architecture decision framework internalized
- Confidence with containerized agents

**Instructor Mindset:**
- Bridge builder (AWS ↔ Azure)
- Technical depth (debugging session)
- Empathetic to migration concerns
- Firm on LangGraph value proposition

**Granular Timing Overview** (aligned with Master Agenda):
- **Hour 1** (00:00-01:00):
  - 00:00-00:15: Day 2 kickoff + Kahoot recap quiz (5 questions)
  - 00:15-00:45: Advanced MAF concepts (lifecycle, debugging)
  - 00:45-01:00: Live debugging demo (intentional bug fixing)
- **Hour 2** (01:00-02:00):
  - 01:00-01:45: MAF enhancement lab (add custom tools)
  - 01:45-02:00: Code review & pair sharing
- **Hour 3** (02:00-03:00):
  - 02:00-02:30: LangGraph migration story (addressing resistance)
  - 02:30-03:00: Module 3 Part 1 (code walkthrough & customization)
- **Hour 4** (03:00-04:00):
  - 03:00-03:30: Module 3 Part 2 (LangGraph deployment)
  - 03:30-03:50: Decision framework activity (interactive)
  - 03:50-04:00: Day 2 wrap & Day 3 preview

**Timing Attention Points:**
- ⚠️ Kahoot quiz (00:00-00:15): Have link tested and ready
- ⚠️ LangGraph deployment (03:00-03:30) is complex; allocate buffer
- ✅ Decision framework (03:30-03:50) can be trimmed if running late
- ⏱️ Pair sharing (01:45-02:00): Keep groups small (2-3 people)
- ✅ More time available today (4 hours) for deep work
- ⚠️ Discussion on MAF vs LangGraph can extend; manage time

**Facilitation Tips:**
- **Hour 1**: Start with recap quiz (gamify with Kahoot); re-energizes cohort
- **Hour 2**: Live debugging demo is powerful—don't skip it
- **Hour 3**: "Why Foundry?" section is critical for engagement; speak to resistance directly
- **Hour 4**: Decision framework exercise works best in breakout groups (if virtual)

**Managing Resistance (Day 2 Focus):**
- **Anticipated pushback**: "Why not just stay on AWS?"
- **Your response framework**:
  1. Acknowledge: "AWS is excellent, and you've built great agents there"
  2. Expand: "This adds M365 integration without replacing AWS"
  3. Demonstrate: "Your LangGraph code runs virtually unchanged"
  4. Empower: "You can choose the best platform per use case"

**Common Day 2 Issues:**
1. **LangGraph graph not compiling**: Check edge connections; common mistake
2. **Adapter import errors**: Verify requirements.txt includes `azure-ai-agentserver-langgraph`
3. **Comparison questions**: "Which is faster, MAF or LangGraph?" (nuanced answer prepared)
4. **Resistance flares up**: Some participants may vocalize AWS preference—handle diplomatically

**End of Day 2 Checklist:**
- [ ] MAF agent deployed and enhanced with custom tools
- [ ] LangGraph agent successfully deployed
- [ ] Participants understand when to use each framework
- [ ] Addressed migration concerns
- [ ] Confidence level increased

---

### Day 3: Gaining Control

**Theme**: "Taking Control with Own Infrastructure"  
**Focus**: ACA deployment, connected pattern, observability

**Key Objectives:**
- Deploy agent on own infrastructure (ACA)
- Understand connected agent pattern
- Perform cost and performance analysis
- Make informed architecture decisions

**Critical Success Factors:**
- ACA deployment successful
- Connected agent registered in Foundry
- Cost comparison completed
- Architectural decision-making confidence

**Instructor Mindset:**
- Empower with control/flexibility
- Financial literacy (cost awareness)
- Systems thinking (architecture trade-offs)
- Practical decision-making focus

**Granular Timing Overview** (aligned with Master Agenda):
- **Hour 1** (00:00-01:00):
  - 00:00-00:15: Days 1-2 mega-recap
  - 00:15-00:45: Connected agent architecture presentation
  - 00:45-01:00: ACA & AI Gateway demo in Portal
- **Hour 2** (01:00-02:00):
  - 01:00-01:15: Lesson 4 introduction & code walkthrough
  - 01:15-01:50: Deploy connected agent lab (Bicep + Docker)
  - 01:50-02:00: Quick troubleshooting break
- **Hour 3** (02:00-03:00):
  - 02:00-02:30: Explore AI Gateway & monitoring lab
  - 02:30-03:00: Architecture decision workshop (group activity)
- **Hour 4** (03:00-04:00):
  - 03:00-03:30: Performance & cost comparison lab
  - 03:30-03:50: Open Q&A & troubleshooting clinic
  - 03:50-04:00: Day 3 wrap & Day 4 preview

**Timing Attention Points:**
- ⚠️ ACA deployment (01:15-01:50) involves Bicep; can extend
- ✅ Hour 4 has flexibility for deep discussions
- ⚠️ Cost analysis (03:00-03:30): Have calculator/examples ready
- ⏱️ Architecture workshop (02:30-03:00): Prepare 5 scenario cards

**Facilitation Tips:**
- **Hour 1**: Architecture comparison is visual—use diagrams extensively
- **Hour 2**: Bicep template walkthrough appeals to infrastructure-focused participants
- **Hour 3**: Observability lab is exploratory—encourage curiosity
- **Hour 4**: Decision workshop benefits from real-world scenarios (bring 5-7 cases)

**Cost Discussion Guidance:**
- Participants may be surprised by costs
- Frame positively: "Free tier covers workshop; production requires budgeting"
- Provide estimation tools/spreadsheets
- Discuss cost optimization strategies
- Compare with AWS costs fairly (not biased)

**Common Day 3 Issues:**
1. **ACA ingress configuration**: External=true required; document this clearly
2. **APIM confusion**: Explain gateway role simply; avoid unnecessary depth
3. **Cost anxiety**: Reassure about cleanup scripts; show cost management tools
4. **Decision paralysis**: Some participants struggle choosing patterns—provide framework

**End of Day 3 Checklist:**
- [ ] ACA agent deployed and tested
- [ ] Connected agent registered in Foundry
- [ ] Cost analysis completed
- [ ] Performance comparison documented
- [ ] Participants can make architecture decisions independently

---

### Day 4: Enterprise Integration

**Key Objectives:**
- Integrate agents with Microsoft 365
- Understand Agent 365 SDK
- Navigate publishing workflow
- Create Teams agent instances

**Critical Success Factors:**
- A365 CLI configured
- Enhanced agent with Bot Framework
- Agent instance created in Teams
- End-to-end M365 workflow understood

**Instructor Mindset:**
- Business value focus (reaching end users)
- Enterprise context (compliance, governance)
- Practical deployment orientation
- Celebrate "agent in Teams" moment

**Timing Attention Points:**
- ⚠️ Publishing workflow (Hour 3) is demo-heavy (approval takes days)
- ✅ Use pre-approved demo agents for instant gratification
- ⚠️ Teams integration requires M365 tenant—validate access beforehand

**Facilitation Tips:**
- **Hour 1**: Connect technical implementation to business value
- **Hour 2**: Adaptive Cards demo should be visually impressive
- **Hour 3**: Publishing walkthrough is procedural—screen record as backup
- **Hour 4**: Teams integration is the "wow moment"—build excitement

**M365 Tenant Considerations:**
- Some participants may not have M365 tenant access
- Provide demo tenant credentials (if available)
- Pair participants: those with/without access
- Focus on workflow understanding over hands-on for this section

**Common Day 4 Issues:**
1. **A365 CLI authentication**: Cross-tenant scenarios are complex; have cheat sheet
2. **Entra ID app registration**: Permissions can be confusing; guide step-by-step
3. **Publishing blocked**: Admin approval required; use demo workflow instead
4. **Teams instance creation fails**: Licensing issues possible; have demo ready

**End of Day 4 Checklist:**
- [ ] A365 SDK integration completed
- [ ] Participants understand publishing workflow
- [ ] Agent instance visible in Teams (demo or hands-on)
- [ ] Ready for capstone project
- [ ] Capstone ideas identified

---

### Day 5: Application & Graduation

**Theme**: "Build Your Own Agent"  
**Focus**: Independent creation, assessment, presentations

**Key Objectives:**
- Apply all learned concepts in capstone project
- Demonstrate competency independently
- Present and evaluate peer work
- Complete assessments
- Celebrate achievements

**Critical Success Factors:**
- 80%+ complete capstone project
- Quality presentations delivered
- Assessments completed
- Positive closing experience
- Clear next steps provided

**Instructor Mindset:**
- Coach/mentor (not lecturer)
- Supportive but allowing struggle
- Fair evaluator
- Celebratory and forward-looking

**Granular Timing Overview** (aligned with Master Agenda):
- **Hour 1** (00:00-01:00):
  - 00:00-00:20: Comprehensive Days 1-4 recap
  - 00:20-00:50: Capstone briefing (3 project types: Portfolio Advisor, Risk Analyzer, Market Researcher)
  - 00:50-01:00: Project planning (participants choose & plan)
- **Hours 2-3** (01:00-03:00): Independent project work
  - **Milestone checkpoints:**
    - ⏱️ 01:30 - Code complete, starting build
    - ⏱️ 02:15 - Deployment successful
    - ⏱️ 02:45 - Testing complete, documentation finalized
  - Scheduled office hours every 30 minutes
  - Async support via chat
- **Hour 4** (03:00-04:00):
  - 03:00-03:40: Lightning presentations (5 min each, 8 max)
  - 03:40-03:55: Knowledge quiz & survey (15 min)
  - 03:55-04:00: Closing & graduation (5 min)

**Timing Attention Points:**
- ⚠️ Capstone briefing (00:20-00:50): Be clear on requirements; avoid over-explaining
- ⚠️ Milestone 02:15 (deployment): If many behind, extend work time, shorten presentations
- ⚠️ Capstone development (2 hours) is tight; participants must manage time
- ✅ Presentations can flex (3-5 min each depending on cohort size)
- ⏱️ Keep closing to 5 min sharp; participants are tired

**Facilitation Tips:**
- **Hour 1**: Briefing is motivational; inspire creativity within constraints
- **Hours 2-3**: Circulate virtually; balance support with independence
- **Hour 4**: Presentations are energizing; maintain momentum
- **Closing**: Make it memorable; acknowledge effort

**Capstone Facilitation Balance:**
- **Too much help**: Participants don't learn through struggle
- **Too little help**: Participants get stuck and demoralized
- **Right balance**: Guide with questions; provide hints, not answers

**Evaluation Approach:**
- Use rubric consistently (no favoritism)
- Provide specific, actionable feedback
- Recognize unique strengths
- Note areas for improvement constructively
- Grade privately; feedback individually later

**Common Day 5 Issues:**
1. **Scope creep**: Participants try to build too much—help refocus
2. **Time management**: Some run out of time—encourage MVP focus
3. **Technical blockers**: Deployment failures in capstone—have troubleshooting ready
4. **Presentation anxiety**: Some participants nervous—create supportive environment

**Closing Experience:**
- **Avoid**: Weak, rushed ending
- **Achieve**: Memorable, inspiring conclusion
- **Elements**:
  - Congratulate efforts
  - Show progress visualization (Day 1 vs Day 5)
  - Share next steps resources
  - Invite to community
  - Express gratitude
  - (Optional) Certificate/completion acknowledgment

**End of Day 5 Checklist:**
- [ ] All capstone projects submitted
- [ ] Presentations completed
- [ ] Knowledge quiz administered
- [ ] Survey completed
- [ ] Next steps communicated
- [ ] Post-workshop support schedule shared
- [ ] Celebratory close delivered

---

## Facilitation Techniques

### Effective Presentation Strategies

**1. Storytelling Approach**
- Frame concepts as journey: "Imagine you're migrating your AWS agent..."
- Use participant context: Financial services examples throughout
- Personal anecdotes: Share your own learning experiences

**2. Visual Learning**
- Architecture diagrams for every pattern
- Live Azure Portal navigation (many first-time users)
- Code highlighting and annotation during walkthroughs
- Draw flow diagrams interactively

**3. Interactive Elements**
- Polls: "How many have deployed containers before?"
- Chat questions: "What's your biggest concern about Azure?"
- Think-pair-share: Discuss with neighbor, then share out
- Live coding collaboratively (participants suggest next steps)

**4. Chunking Complex Topics**
- Break MAF/LangGraph into digestible pieces
- Concept → Example → Practice rhythm
- Recap frequently: "So far we've..."
- Visual progress indicators

### Hands-On Lab Facilitation

**Before Lab:**
- **Set clear objectives**: "By end of lab, you'll have X deployed"
- **Estimate time realistically**: Don't under-estimate
- **Show expected outcome**: Demo first
- **Provide checkpoints**: "After 5 minutes, you should see Y"

**During Lab:**
- **Monitor progress**: Use shared tracker or quick polls
- **Circulate virtually**: Check in Slack/Teams
- **Identify stuck participants early**: Proactive intervention
- **Balance individual help with group needs**: Address common issues publicly

**Common Lab Facilitation Traps:**
- ❌ Moving on before majority ready
- ❌ Spending too long with one stuck participant (assign TA or defer to office hours)
- ❌ Not providing regular time updates: "15 minutes remaining"
- ❌ Assuming silence means understanding

**After Lab:**
- **Debrief**: "What challenges did you face?"
- **Normalize struggle**: "Errors are part of the process"
- **Connect to concepts**: "This lab showed you..."
- **Preview next step**: "Now we'll build on this with..."

### Managing Discussions

**Productive Discussion Techniques:**

1. **Use frameworks**: "Let's use the decision tree we reviewed"
2. **Timebox**: "5 minutes on this topic, then move forward"
3. **Synthesize**: "I'm hearing three main themes..."
4. **Redirect**: "That's a great question for office hours; let's capture it"
5. **Amplify quiet voices**: "Sara, you mentioned X—can you elaborate?"

**Handling Difficult Dynamics:**

| Scenario | Response Strategy |
|----------|------------------|
| **One participant dominates** | "Thanks, Alex. Let's hear from someone else now." |
| **Off-topic tangent** | "Important point, but not for today's scope. Let's offline that." |
| **Negative attitude spreads** | Address privately; redirect publicly to positive aspects |
| **Silence when asking for questions** | Ask specific people; rephrase question; use chat |
| **Participant criticizes Microsoft** | Acknowledge concern; pivot to workshop value; stay neutral |

### Building Psychological Safety

**Create environment where participants:**
- Feel safe asking "basic" questions
- Admit when stuck without embarrassment
- Share mistakes and learn from them
- Challenge ideas respectfully
- Support each other

**Instructor Actions:**
- Model vulnerability: "I made this mistake when learning"
- Praise questions: "Great question—glad you asked"
- Normalize errors: "Errors teach us how things work"
- Celebrate effort: "I see you troubleshooting—that's the skill"
- Show respect: "Everyone's background brings value"

---

## Troubleshooting Common Issues

### Technical Issues

#### Infrastructure Deployment Failures

**Issue**: Bicep deployment fails with quota exceeded
**Symptoms**: Error message "Quota exceeded for resource type"
**Solution**:
1. Check available quotas: `az vm list-usage --location <region>`
2. Try alternative region (have list prepared)
3. Request quota increase (if time permits)
4. Use instructor backup sandbox as fallback

**Issue**: Resource name already exists
**Symptoms**: "Resource name '<name>' already taken"
**Solution**:
1. Add unique suffix to names in `.bicepparam`
2. Use participant initials + timestamp: `foundry-jd-20260214`
3. Document pattern for consistency

#### Container Build & Deployment

**Issue**: ACR authentication fails
**Symptoms**: "unauthorized: authentication required"
**Solution**:
```powershell
# Re-authenticate
az acr login --name <acr-name>

# Verify login
az acr repository list --name <acr-name>
```

**Issue**: Container build timeout
**Symptoms**: ACR build takes >20 minutes or times out
**Solution**:
1. Check network connectivity
2. Reduce image size (optimize Dockerfile)
3. Use pre-built base images
4. Build locally and push: `docker build` + `docker push`

**Issue**: Agent stuck in "Pending" status
**Symptoms**: Hosted agent never reaches "Running"
**Solution**:
1. Check logs: `az cognitiveservices agent logs show`
2. Look for image pull errors or startup failures
3. Verify image exists in ACR
4. Check managed identity permissions
5. Review environment variables

#### MAF Known Issues

**Issue**: Recursive routing timeout
**Symptoms**: Agent call hangs then times out (60s)
**Solution**: Apply fix from `context.md`:
```python
# Override _prepare_options to prevent recursive routing
def _prepare_options_fixed(self, original_options):
    # Keep model and tools; don't inject agent reference
    return original_options

# Monkey-patch
client._prepare_options = _prepare_options_fixed
```

**Issue**: "ID cannot be null or empty"
**Symptoms**: 400 error from Foundry Responses API
**Solution**: Add `id` field to agent reference (per `context.md`)

#### LangGraph Issues

**Issue**: Graph doesn't compile
**Symptoms**: Error on `workflow.compile()`
**Solution**:
1. Check all nodes are defined before edges
2. Verify START and END edges
3. Ensure state types match between nodes
4. Draw graph on paper to visualize

**Issue**: Tool execution fails silently
**Symptoms**: Tool returns None or doesn't execute
**Solution**:
1. Add try-except blocks with logging
2. Verify async/await usage
3. Check tool is registered in graph
4. Test tool function independently

#### Azure Container Apps

**Issue**: Can't reach ACA endpoint
**Symptoms**: Connection timeout or 404
**Solution**:
1. Verify ingress enabled: `external: true`
2. Check target port matches application: `targetPort: 8080`
3. Confirm app is healthy: Check logs
4. Test health endpoint: `/health`

**Issue**: ACA not scaling
**Symptoms**: Always 1 replica despite load
**Solution**:
1. Verify scaling rules configured
2. Check metric thresholds realistic
3. Ensure minReplicas < maxReplicas
4. Review ACA scaling docs

### Participant-Related Issues

#### Learning & Engagement

**Issue**: Participant far behind pace
**Strategy**:
1. **Assess**: Is it technical issue or comprehension gap?
2. **Triage**: Critical blockers vs nice-to-have completions
3. **Support**: Assign TA or pair with another participant
4. **Adapt**: Provide abbreviated path (skip optional elements)
5. **Follow-up**: Offer extra office hours

**Issue**: Participant disengaged or distracted
**Strategy**:
1. **Check-in privately**: "How's it going? Any blockers?"
2. **Assign role**: Ask them to help another struggling participant
3. **Vary format**: Switch from lecture to hands-on
4. **Break**: Suggest they step away and return refreshed

**Issue**: Participant frustrated with errors
**Strategy**:
1. **Normalize**: "Errors are learning opportunities"
2. **Guide**: Walk through debugging process
3. **Celebrate**: "You found the issue—that's the skill!"
4. **Perspective**: "Even experts deal with this daily"

#### Group Dynamics

**Issue**: Skill level gap is very wide
**Strategy**:
1. **Pair strategically**: Mix skill levels for peer learning
2. **Differentiate**: Provide advanced challenges for faster participants
3. **Supporting roles**: Advanced learners can help troubleshoot
4. **Normalize**: "Everyone brings different strengths"

**Issue**: Negative sentiment spreading
**Strategy**:
1. **Address root cause**: Is content too hard/too fast?
2. **Redirect energy**: Turn complaints into constructive feedback
3. **Highlight positives**: "Look how far we've come!"
4. **Private conversation**: With most negative participant

---

## Managing Resistance

### Understanding Resistance Sources

**AWS Loyalty ("Why leave what works?")**
- **Root**: Sunk cost fallacy, expertise investment, comfort zone
- **Approach**: Expansion framing, not replacement
- **Language**: "Add to your toolkit" not "Replace AWS"

**Microsoft Skepticism**
- **Root**: Past negative experiences, bias, skepticism of big tech
- **Approach**: Acknowledge openly, focus on technical merit
- **Language**: "Judge based on what you build this week"

**Framework Lock-In Concern**
- **Root**: Don't want to learn "yet another framework"
- **Approach**: Show LangGraph compatibility, minimal changes
- **Language**: "Your LangGraph knowledge transfers directly"

**Change Fatigue**
- **Root**: Already learned one complex platform, tired of learning
- **Approach**: Emphasize ROI, efficiency gains, career value
- **Language**: "This opens new opportunities for you"

### Response Frameworks

**When participant says: "Why not just use AWS?"**

❌ **Don't say**: "Azure is better than AWS"
✅ **Do say**:
1. "AWS is excellent. You've built great things there."
2. "This workshop adds Microsoft ecosystem access to your options."
3. "Some use cases fit Azure better, others AWS. Now you can choose."
4. "Think of it as bilingual—you can work with clients on either platform."

**When participant says: "This is too complicated"**

❌ **Don't say**: "It's actually quite simple"
✅ **Do say**:
1. "You're learning a lot in a short time—that's challenging."
2. "By end of week, this will feel more natural."
3. "Which specific part feels most complicated? Let's focus there."
4. "Remember Day 1—you've already conquered a lot."

**When participant says: "I don't need M365 integration"**

❌ **Don't say**: "Yes you do, everyone needs it"
✅ **Do say**:
1. "That's fair—maybe not for your current projects."
2. "But your company or future clients might."
3. "Think of this as adding a valuable skill to your portfolio."
4. "Focus on the agent patterns—those apply everywhere."

### Turning Resistance into Engagement

**Strategies**:

1. **Acknowledge & Validate**
   - "That's a legitimate concern"
   - "I understand where you're coming from"
   - "You're not wrong to question that"

2. **Reframe Perspective**
   - "Let's look at it another way..."
   - "Consider this scenario..."
   - "What if you could..."

3. **Empower Choice**
   - "You decide what's best for your use case"
   - "You don't have to use everything we cover"
   - "Take what's valuable to you"

4. **Focus on Transferable Skills**
   - "These patterns apply to any platform"
   - "Debugging skills work everywhere"
   - "Architectural thinking is universal"

5. **Build on Existing Expertise**
   - "Your LangGraph skills are directly applicable"
   - "You already know the hard parts"
   - "This is just a different wrapper on familiar concepts"

---

## Time Management Strategies

### Staying on Schedule

**Before Workshop**:
- Test all content timing during dry run
- Identify sections that can compress if needed
- Mark "must cover" vs "nice to have" in agenda
- Prepare abbreviated versions of optional topics

**During Workshop**:
- Use visible timer (share screen with countdown)
- Announce time checkpoints: "15 minutes left in this lab"
- Have co-instructor or TA track time (if available)
- Be willing to cut content to stay on track

**When Running Behind**:

| Minutes Behind | Action |
|----------------|--------|
| **5-10 min** | Tighten transitions, reduce Q&A slightly |
| **10-20 min** | Skip one optional example/discussion |
| **20-30 min** | Move one lab to "homework" or office hours |
| **30+ min** | Major adjustment: combine activities, defer module |

**When Running Ahead**:
- Don't rush to catch up—use extra time wisely
- Extend Q&A or discussion
- Go deeper on complex topic
- Add bonus content or advanced examples
- Allow longer break (participants appreciate)

### Balancing Coverage vs Comprehension

**Signs You're Going Too Fast**:
- Participants aren't asking questions (confusion, not understanding)
- Labs taking much longer than estimated
- Many participants stuck on same issue
- Feedback: "Too fast" or "hard to follow"

**When to Slow Down**:
- Core concepts (agent patterns, MAF/LangGraph)
- First deployment (Day 1 infrastructure)
- Debugging workflows (they'll use repeatedly)
- Decision frameworks (need to internalize)

**When You Can Speed Up**:
- Slides reviewing pre-workshop materials
- Redundant examples (if concept clear)
- Administrative details
- Repetitive deployment scripts (once they've seen pattern)

---

## Assessment Administration

### Pre-Assessment Quiz

**Purpose**: Identify knowledge gaps, personalize support

**Administration**:
- Send 1 week before workshop
- Optional but recommended
- 15-20 questions covering prerequisites
- Auto-graded platform (Google Forms, Kahoot, etc.)

**Interpretation:**
- **<60%**: Recommend additional prep; may struggle
- **60-75%**: Average; standard support sufficient
- **>75%**: Strong; can handle advanced content

**Action**:
- Review aggregate results
- Identify weak areas to emphasize
- Note individual low scorers for extra support

### Formative Assessment (During Workshop)

**Per-Module Checkpoints:**
- Use checklist from Module Maps
- Quickly verify success criteria met
- Use polls: "Thumbs up if agent deployed"
- Monitor shared tracker for progress

**Self-Check Questions:**
- Provided in lesson READMEs
- Participants reflect independently
- Optionally discuss in groups
- Instructor spots-checks understanding

**Progress Tracking:**
- Maintain shared spreadsheet/dashboard
- Track: Module completion, blockers, status
- Update in real-time or end-of-day
- Identify struggling participants early

### Summative Assessment (End of Workshop)

#### Capstone Project Evaluation

**Process**:
1. **During Presentations**:
   - Take notes using rubric
   - Score preliminary (may adjust after code review)
   - Note standout elements

2. **Post-Presentation Review**:
   - Clone code repository
   - Test functionality personally
   - Review documentation
   - Finalize scores

3. **Feedback Delivery**:
   - Individual feedback within 48 hours
   - Specific, actionable comments
   - Recognize strengths
   - Suggest improvements

**Rubric Application** (see Module Maps for detailed rubric):
- Be consistent across all participants
- Document rationale for scores
- Avoid grade inflation
- Distinguish between effort and outcome

**Handling Edge Cases:**
- **Incomplete projects**: Score what's there; give partial credit
- **Highly creative projects**: Recognize innovation even if execution imperfect
- **Technical issues prevented completion**: Focus on design and understanding demonstrated

#### Knowledge Quiz

**Administration**:
- 10 minutes, 20 questions
- Multiple choice + select all that apply
- Via online platform (immediate results)
- Open note/resource (tests application, not memorization)

**Question Distribution:**
- 25% Infrastructure & Azure basics
- 25% Agent patterns (declarative, hosted, connected)
- 25% Frameworks (MAF, LangGraph, comparisons)
- 15% M365 integration
- 10% Troubleshooting & best practices

**Interpretation:**
- **<60%**: Needs significant review
- **60-70%**: Passing; acceptable understanding
- **70-85%**: Good comprehension
- **>85%**: Excellent mastery

#### Workshop Survey

**Key Questions**:
1. NPS: "How likely to recommend?" (0-10)
2. Self-assessment: "Rate your confidence deploying agents" (pre/post)
3. Most valuable module
4. Biggest challenge
5. Pace rating (too fast, right, too slow)
6. Instructor effectiveness
7. Open feedback

**Action on Results**:
- Aggregate and analyze within 1 week
- Share summary with stakeholders
- Identify improvement areas
- Iterate for next cohort

### Post-Workshop Follow-Up

**1 Week After**:
- **Survey**: "Did you deploy an agent in the past week?"
- **Office hours**: Offer support for blockers
- **Share resources**: Next steps guide, community links

**1 Month After**:
- **Check-in**: "How are you using what you learned?"
- **Collect success stories**: For testimonials
- **Track KPIs**: 80%+ deployed agents within 1 week?

---

## Instructor Self-Care

### Managing Workshop Intensity

**Workshop delivery is demanding**:
- Long days (4 hours + prep/support)
- Constant context switching (content → troubleshooting → discussion)
- Emotional labor (managing resistance, building confidence)
- Technical complexity (multiple systems, potential failures)

**Self-Care Strategies**:

**Before Workshop**:
- Ensure adequate prep (reduces stress)
- Get good sleep 2 nights before
- Plan breaks and meals
- Set boundaries on availability

**During Workshop**:
- Stay hydrated (water bottle visible onscreen)
- Take breaks seriously (step away from computer)
- Avoid caffeine overload
- Share load with co-instructor/TA if available

**After Workshop**:
- Decompress (30 min walk, hobby, relax)
- Don't immediately start on next day prep
- Celebrate successes
- Seek peer support if challenging moments occurred

**Managing Difficult Participants**:
- Don't take resistance personally
- Remember: They're stressed too
- Focus on those engaged positively
- Know when to escalate (if behavior inappropriate)

---

## Quick Reference Cards

### Opening Day 1 Template

```
"Good morning, everyone! Welcome to the Microsoft Foundry AI Agents Workshop.

My name is [name], and I'll be your guide this week as we explore building AI agents on Microsoft's platform.

Before we dive in, quick logistics:
- We'll spend 4 hours together each day for 5 days
- Mix of concepts, demos, and hands-on labs
- Breaks every hour
- Questions are encouraged—no such thing as a dumb question
- Slack/Teams channel for async support

Quick poll: How many of you have:
- Deployed agents on AWS? [show of hands]
- Used LangGraph before? [show of hands]
- Used Azure before? [show of hands]

Great! You bring valuable experience. This week, we're adding Microsoft Foundry to your toolkit—not replacing what you already know, but expanding your options.

By Friday, you'll deploy multiple agents, make informed architecture decisions, and have agents running in Microsoft Teams.

Let's get started!"
```

### Closing Day 5 Template

```
"Congratulations, everyone! You made it!

Let's take a moment to appreciate what you've accomplished:
- Day 1: First Azure deployment, first agent
- Day 2: Containerized agents with MAF and LangGraph
- Day 3: Own infrastructure with ACA
- Day 4: Integration with Microsoft 365
- Day 5: Built and deployed your own custom agent

That's a LOT in 5 days.

You've gone from 'first-time Azure users' to 'deploy production-ready agents.' That's significant.

Next steps:
- Deploy an agent in production/POC within 1 week (our goal!)
- Join our community channel—we're here to support you
- Office hours next week if you hit blockers
- Share your success stories

Thank you for your engagement, curiosity, and persistence. It's been a pleasure working with you.

Keep building amazing things. You have the skills now.

Any final questions?

[pause]

Congratulations again!"
```

---

**Document Version**: 1.0  
**Last Updated**: February 14, 2026  
**Maintained By**: Learning Architect Team  
**Feedback**: instructor-feedback@workshop.com
