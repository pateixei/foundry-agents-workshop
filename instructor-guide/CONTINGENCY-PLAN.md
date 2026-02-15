# Workshop Contingency Plan

**Workshop**: Microsoft Foundry AI Agents Workshop — 5-Day Intensive  
**Version**: 1.0  
**Owner**: Content Producer  
**Last Updated**: February 15, 2026  

---

## Purpose

This document defines backup plans for the most likely disruptions during a 5-day hands-on Azure workshop. Each scenario includes **detection**, **immediate action**, and **long-term mitigation**.

---

## Scenario 1: Internet / Network Outage

### Detection
- Students report `pip install` failures, `az` commands timing out, Docker pull stuck
- Instructor cannot reach Azure Portal or Foundry

### Immediate Actions (< 5 min)
1. **Announce**: "We're experiencing connectivity issues. Let's switch to offline mode."
2. **Switch to architecture walkthrough** using pre-exported PNG diagrams in each lesson's `media/` folder
3. **Code review mode**: Walk through source files that are already cloned locally
4. **Use offline slides**: Instructor presents from local PDF/PPTX backups

### Mitigation (pre-prepared)
- [ ] Export all architecture diagrams to PNG before workshop (done — each lesson's `media/` folder)
- [ ] Cache Docker base images locally: `docker pull python:3.11-slim` on instructor machine
- [ ] Pre-download all pip packages as wheels:
  ```powershell
  pip download -r lesson-1-declarative/requirements.txt -d ./offline-packages/
  pip download -r lesson-6-a365-sdk/requirements.txt -d ./offline-packages/
  ```
- [ ] Pre-build all Docker images on instructor machine (acts as demo fallback)
- [ ] Save key Azure Portal screenshots for offline demo
- [ ] Prepare offline version of known workarounds

### Recovery
Once connectivity returns:
1. Students run `pip install -r requirements.txt` to catch up
2. Resume hands-on from where code review left off
3. If >30 min lost, compress current module's Q&A time

---

## Scenario 2: Azure Service Outage or Degradation

### Detection
- Azure Status page shows issues: https://status.azure.com
- Deployments fail with 5xx errors
- Foundry portal unresponsive

### Immediate Actions
1. Check https://status.azure.com and identify affected services
2. **If Azure AI Foundry is down**:
   - Switch to local code review + architecture discussion
   - Use pre-recorded deployment demos (if available)
   - Advance to theory portions of next module
3. **If ACR is down** (can't push images):
   - Use instructor's pre-pushed images from earlier testing
   - Skip container build, focus on code walkthrough
4. **If Azure OpenAI is down**:
   - Demonstrate mock responses (tools return simulated data anyway)
   - Focus on infrastructure and deployment concepts

### Mitigation (pre-prepared)
- [ ] Deploy to **two Azure regions** (primary: eastus2, backup: westus3)
- [ ] Pre-push all container images to ACR before workshop
- [ ] Record short video demos (3–5 min each) of successful deployments for all modules
- [ ] Have instructor Azure subscription in a different region than student subscriptions

### Recovery
1. Monitor Azure status page for resolution
2. Resume hands-on once services recover
3. Extend workshop time by 30 min if needed (communicate early)

---

## Scenario 3: Student Environment Failures

### Detection
- Multiple students cannot run `deploy.ps1` or labs
- Error patterns: auth failures, quota exceeded, missing tools

### Common Issues & Quick Fixes

| Issue | Fix | Time |
|-------|-----|------|
| `az login` fails | `az login --use-device-code` | 2 min |
| Python version wrong | `winget install Python.Python.3.11` | 5 min |
| Docker not running | Open Docker Desktop, wait for green | 3 min |
| Subscription quota exceeded | Switch region or request increase | 10-30 min |
| RBAC permission denied | Add Contributor role via Portal | 5 min |
| `pip install` SSL error | `pip install --trusted-host pypi.org --trusted-host pypi.python.org` | 2 min |
| PowerShell execution policy | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` | 1 min |

### Escalation Path
1. **Self-help**: Check lesson READMEs for known workarounds
2. **Peer help**: Pair struggling student with working neighbor
3. **Instructor help**: 1-on-1 troubleshooting (max 5 min per student)
4. **Fallback**: Student follows along on instructor's screen share until resolved

### Mitigation
- [ ] Validate all environments at Office Hours (Day -3, Day -1)
- [ ] Prepare "buddy system" — pair students with different OS/setups
- [ ] Have a pre-configured VM image (optional) as last-resort fallback

---

## Scenario 4: Pacing Problems

### 4a. Workshop Running Behind Schedule

| Time Lost | Action |
|-----------|--------|
| 15-30 min | Compress Q&A / troubleshooting time |
| 30-60 min | Skip optional demos; assign remaining lab as homework |
| 60+ min | Drop one deep-dive exercise; provide solution code |

### 4b. Workshop Running Ahead of Schedule

| Time Gained | Action |
|-------------|--------|
| 15-30 min | Extended Q&A, student show-and-tell |
| 30-60 min | Bonus: multi-agent orchestration preview or architecture discussion |
| 60+ min | Start next day's content early (with group consent) |

### 4c. Wide Skill Gap Among Students

- **Fast students**: Direct to stretch goals (add new tools, customize prompts, explore optional topics)
- **Slower students**: Provide solution code earlier; pair with advanced student
- **Everyone stuck on same issue**: Full-group troubleshooting session (5-10 min cap)

---

## Scenario 5: M365 Tenant Issues (Days 3–5)

### Detection
- A365 CLI commands fail
- Teams app sideloading blocked
- Cross-tenant auth errors

### Immediate Actions
1. Verify M365 Developer Tenant is correctly configured:
   ```powershell
   a365 setup validate
   ```
2. If tenant not provisioned: Demo from instructor tenant, students observe
3. If sideloading blocked: Enable in Teams Admin Center → Org Settings

### Mitigation
- [ ] Verify M365 Developer Program enrollment 1 week before workshop
- [ ] Pre-configure one shared demo M365 tenant as backup
- [ ] Document Teams Admin Center steps with screenshots
- [ ] Have `a365.config.json` template with clear placeholders

---

## Scenario 6: Instructor Unavailability

### Detection
- Primary instructor reports illness/emergency

### Action Plan
1. **Co-instructor takes over** using prepared instructional scripts in this `instructor-guide/` folder
2. Scripts contain full narration, timing, and code walkthrough — designed to be self-sufficient
3. Fall back to self-paced mode with facilitated Q&A if no co-instructor available
4. Instructor scripts cover all 7 module sets with detailed "Say" prompts

---

## Emergency Contacts

| Role | Contact | Responsibility |
|------|---------|---------------|
| Primary Instructor | TBD | Content delivery |
| Co-Instructor / Backup | TBD | Backup delivery |
| Content Producer | TBD | Materials, environment |
| IT Support | TBD | Network, accounts |
| Azure Support | [Azure Support Portal](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade) | Service issues |

---

## Pre-Workshop Contingency Prep Checklist

- [ ] All diagrams exported to PNG (offline)
- [ ] Docker base images cached on instructor machine
- [ ] pip packages downloaded as wheels (offline-packages/)
- [ ] All container images pre-pushed to ACR
- [ ] Deployment demos recorded as video backups
- [ ] Backup Azure region tested
- [ ] M365 demo tenant verified
- [ ] Contingency plan shared with co-instructor and facilitator
