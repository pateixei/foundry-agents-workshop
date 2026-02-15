# Instructional Scripts - Workshop Facilitator Guide

**Created by**: Agent 3 (Instructional Designer)  
**Date**: 2026-02-14  
**Status**: Draft - Awaiting Review & Approval  

---

## 📚 Complete Module Scripts

This folder contains minute-by-minute instructional scripts for all 9 workshop modules (Module 0 + Modules 1-8).

---

## 📋 Module Index

### Pre-Workshop
| Module | Title | Duration | Script File | Status |
|--------|-------|----------|-------------|--------|
| **Module 0** | Infrastructure Prerequisites | 45-60 min (async) | [`MODULE-0-INFRASTRUCTURE-SCRIPT.md`](MODULE-0-INFRASTRUCTURE-SCRIPT.md) | ✅ Ready |

**Format**: Self-service guide (students complete before Day 1)

---

### Day 1: Agent Patterns & Hosted Deployments

| Module | Title | Duration | Script File | Status |
|--------|-------|----------|-------------|--------|
| **Module 1** | Declarative Agent Pattern | 120 min (Hours 2-3) | [`MODULE-1-DECLARATIVE-AGENT-SCRIPT.md`](MODULE-1-DECLARATIVE-AGENT-SCRIPT.md) | ✅ Ready |
| **Module 2 (Part 1)** | Hosted MAF Agent | 120 min (Hours 3-4) | [`MODULE-2-HOSTED-MAF-SCRIPT.md`](MODULE-2-HOSTED-MAF-SCRIPT.md) | ✅ Ready |

**Day 1 Total**: 4 hours (Module 0 + Modules 1-2 Part 1)

---

### Day 2: LangGraph & Advanced Patterns

| Module | Title | Duration | Script File | Status |
|--------|-------|----------|-------------|--------|
| **Module 2 (Part 2)** | Hosted MAF (Continued) | 60 min (Hour 1) | [`MODULE-2-HOSTED-MAF-SCRIPT.md`](MODULE-2-HOSTED-MAF-SCRIPT.md) | ✅ Ready |
| **Module 3** | Hosted LangGraph Agent | 120 min (Hours 3-4) | [`MODULE-3-HOSTED-LANGGRAPH-SCRIPT.md`](MODULE-3-HOSTED-LANGGRAPH-SCRIPT.md) | ✅ Ready |

**Day 2 Total**: 4 hours (Module 2 Part 2 + Module 3 + break)

---

### Day 3: ACA Deployment & Agent 365 Setup

| Module | Title | Duration | Script File | Status |
|--------|-------|----------|-------------|--------|
| **Module 4** | ACA Deployment (Connected Agents) | 120 min (Hours 1-2) | [`MODULE-4-ACA-DEPLOYMENT-SCRIPT.md`](MODULE-4-ACA-DEPLOYMENT-SCRIPT.md) | ✅ Ready |
| **Module 5** | Agent 365 Prerequisites | 60 min (Hour 3) | [`MODULES-5-6-A365-SETUP-SDK-SCRIPT.md`](MODULES-5-6-A365-SETUP-SDK-SCRIPT.md) | ✅ Ready |
| **Module 6 (Part 1)** | Agent 365 SDK Integration | 60 min (Hour 4) | [`MODULES-5-6-A365-SETUP-SDK-SCRIPT.md`](MODULES-5-6-A365-SETUP-SDK-SCRIPT.md) | ✅ Ready |

**Day 3 Total**: 4 hours (Modules 4-6 Part 1)

---

### Day 4: SDK Integration & Publishing

| Module | Title | Duration | Script File | Status |
|--------|-------|----------|-------------|--------|
| **Module 6 (Part 2)** | Agent 365 SDK (Continued) | 60 min (Hour 1) | [`MODULES-5-6-A365-SETUP-SDK-SCRIPT.md`](MODULES-5-6-A365-SETUP-SDK-SCRIPT.md) | ✅ Ready |
| **Module 7** | Publishing to M365 Admin Center | 60 min (Hour 2) | [`MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md`](MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md) | ✅ Ready |
| **Module 8 (Part 1)** | Creating Agent Instances | 60 min (Hour 3) | [`MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md`](MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md) | ✅ Ready |

**Day 4 Total**: 4 hours (Module 6 Part 2 + Modules 7-8 Part 1 + break)

---

### Day 5: Instance Testing & Wrap-Up

| Module | Title | Duration | Script File | Status |
|--------|-------|----------|-------------|--------|
| **Module 8 (Part 2)** | Instance Testing & Lifecycle | 60 min (Hour 1) | [`MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md`](MODULES-7-8-PUBLISH-INSTANCES-SCRIPT.md) | ✅ Ready |

**Day 5 Total**: 1 hour (Module 8 Part 2 completion)

**Note**: Days 5 Hours 2-4 reserved for Q&A, troubleshooting, and wrap-up (not scripted modules)

---

## 📊 Total Workshop Timing

| Element | Duration |
|---------|----------|
| **Module 0** (Pre-workshop) | 45-60 min (async) |
| **Day 1** | 4 hours |
| **Day 2** | 4 hours |
| **Day 3** | 4 hours |
| **Day 4** | 4 hours |
| **Day 5** | 1 hour (Module 8) + 3 hours (open) |
| **Total Instruction** | ~17-18 hours |
| **Total Workshop Duration** | 20 hours (5 days × 4 hours) |

---

## ✅ Script Features

Each instructional script includes:

### 1. **Module Overview**
- Learning objectives (SMART format)
- Timing breakdown
- Materials needed
- Prerequisites

### 2. **Minute-by-Minute Instruction**
- Exact timestamps (e.g., "11:15-11:30 | Topic Name")
- Instructor narration (what to say verbatim)
- Instructional methods (presentation, hands-on, demo)
- Slide content (bullet points for PowerPoint)

### 3. **Hands-On Activities**
- Progressive checkpoints (validation gates every 10-15 min)
- Student tasks with explicit instructions
- Expected outputs (screenshots, CLI output)
- Success criteria (✅ criteria for moving forward)

### 4. **AWS-to-Azure Comparisons**
- Service mapping tables (AWS Lambda → Azure Functions, etc.)
- Pattern differences (deployment models, orchestration, state management)
- Migration guidance (what to change, what stays the same)

### 5. **Troubleshooting Playbooks**
- Common errors in table format (Issue → Cause → Fix)
- Diagnostic commands (CLI queries, Portal navigation)
- Escalation paths (when to ask for help)

### 6. **Instructor Checklists**
- Before module (preparation steps)
- During module (monitoring checkpoints)
- After module (validation + documentation)

### 7. **Pedagogical Notes**
- Learning theory connections (Bloom's taxonomy, cognitive load, constructivism)
- Assessment opportunities (formative checkpoints, summative scenarios)
- Differentiation strategies (advanced challenges, struggling learner support)

### 8. **Success Metrics**
- Quantified completion indicators (e.g., "85%+ deploy successfully")
- Observable behaviors (e.g., "Students articulate one key difference")
- Checkpoint tracking (number of students passing each gate)

---

## 🎯 Target Audience Context

All scripts designed for:
- **Background**: Mid-senior developers from AWS/LangGraph
- **Sector**: Financial Services
- **Languages**: English + Portuguese (bilingual support)
- **Format**: Self-paced with optional live Q&A
- **Learning Style**: Hands-on (80% labs, 20% lecture)

---

## 🔧 How to Use These Scripts

### For Instructors/Facilitators:
1. **Pre-Workshop**: Read all scripts, run through labs yourself
2. **Preparation**: Complete checklists in each script (setup accounts, test deployments)
3. **Delivery**: Follow minute-by-minute timing, adapt narration to your style
4. **Monitoring**: Track checkpoint completion rates, address blockers immediately
5. **Post-Module**: Update delivery logs, document issues for future iterations

### For Workshop Organizers:
1. **Materials Prep**: Extract slide content from scripts → build PowerPoint decks
2. **Environment Setup**: Use Module 0 script to prepare student accounts
3. **Scheduling**: Use timing tables to create workshop calendar
4. **Support Planning**: Review troubleshooting playbooks → prepare helpers/TAs

### For Content Reviewers (YOU - Current Task):
1. **Read each script**: Verify technical accuracy
2. **Check flow**: Ensure logical progression between modules
3. **Validate timing**: Confirm durations realistic
4. **Test hands-on steps**: Walk through student tasks
5. **Provide feedback**: Mark sections needing adjustment

---

## 📝 Review Checklist for Stakeholders

When reviewing scripts, verify:

- [ ] **Technical Accuracy**: Code samples correct, CLI commands valid, Portal paths accurate
- [ ] **Timing Realism**: Durations achievable (not too rushed or too slow)
- [ ] **Prerequisite Clarity**: Each module states what must be complete before starting
- [ ] **Checkpoint Validity**: Checkpoints have clear success/failure criteria
- [ ] **AWS Comparison Accuracy**: Service mappings correct and helpful
- [ ] **Troubleshooting Completeness**: Playbooks cover 80%+ of likely issues
- [ ] **Pedagogical Soundness**: Activities align with learning objectives
- [ ] **Accessibility**: Bilingual notes present, alternative approaches for different learning styles

---

## 🚀 Next Steps After Approval

Once you approve these scripts:
1. **Agent 4 (Technical Instructor/SME)**: Reviews technical content, validates code samples
2. **Agent 5 (Technical Reviewer)**: Tests all hands-on labs end-to-end
3. **Agent 6 (Content Producer)**: Creates slide decks, student workbooks, and videos
4. **Agent 7-9**: Delivery planning, analytics setup, continuous improvement

---

## 📧 Feedback & Iterations

**Current Status**: Draft v1.0 (2026-02-14)  
**Awaiting**: Your comprehensive review and change requests  

**How to Provide Feedback**:
1. Read all 7 script files (start with Module 0, proceed sequentially)
2. Note specific changes needed (by module and section)
3. Indicate priority: **Critical** (blocks workshop) vs **Nice-to-have** (enhancement)

**I'm ready to iterate based on your feedback!**

---

**Prepared by**: Agent 3 (Instructional Designer)  
**Workshop**: "From AWS Lambda to Azure AI Agents: A 365 Journey"  
**Version**: 1.0 (Initial Draft)  
**Status**: ⏳ Awaiting Client Review
