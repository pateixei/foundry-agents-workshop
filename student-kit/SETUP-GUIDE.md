# Student Environment Setup Guide

> 🇧🇷 **[Leia em Português (pt-BR)](SETUP-GUIDE.pt-BR.md)**

**Workshop**: Microsoft Foundry AI Agents Workshop — 5-Day Intensive  
**Version**: 0.7  
**Estimated Time**: 30–45 minutes  
**Last Verified**: February 15, 2026  

---

## Prerequisites Checklist

Before starting, ensure you have:

| # | Requirement | Notes |
|---|-------------|-------|
| 1 | Laptop with admin/sudo rights | Windows 10+, macOS 12+, or Ubuntu 22.04+ (native or WSL) |
| 2 | Internet ≥ 10 Mbps | Required for Azure, Docker, pip |
| 3 | Azure subscription with **Contributor** role | [azure.com/free](https://azure.com/free) or enterprise |
| 4 | GitHub account | To clone workshop repo |
| 5 | Microsoft 365 Developer Tenant (Days 3-5) | [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program) |

> **WSL Users (Windows Subsystem for Linux)**: All Linux instructions apply inside your WSL terminal. Ensure WSL 2 is installed: `wsl --install -d Ubuntu` from an elevated PowerShell prompt. Open a WSL terminal via `wsl` or Windows Terminal → Ubuntu.

---

## Step 1: Install Core Tools

### 1.1 Python 3.11+

**Windows (PowerShell)**:
```powershell
winget install Python.Python.3.11
```

**Linux / WSL (Debian/Ubuntu)**:
```bash
sudo apt update && sudo apt install -y python3.11 python3.11-venv python3-pip
```

**macOS (Homebrew)**:
```bash
brew install python@3.11
```

**Verify**:
```bash
python3 --version   # Expected: Python 3.11.x or higher
```

### 1.2 Azure CLI 2.60+

**Windows (PowerShell)**:
```powershell
winget install Microsoft.AzureCLI
```

**Linux / WSL (Debian/Ubuntu)**:
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**macOS (Homebrew)**:
```bash
brew install azure-cli
```

**Bicep Upgrade** 
```bash 
az bicep upgrade
```
**Verify**:
```bash
az version   # Expected: "azure-cli": "2.60.0" or higher
```

### 1.3 Docker

**Windows**: Download [Docker Desktop](https://www.docker.com/products/docker-desktop/) and ensure WSL 2 backend is enabled (Settings → General → Use the WSL 2 based engine).

**Linux / WSL (Debian/Ubuntu)**:
```bash
# Install Docker Engine (not Docker Desktop)
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Add your user to docker group (avoids sudo for docker commands)
sudo usermod -aG docker $USER
newgrp docker
```

> **WSL Tip**: If Docker Desktop for Windows is installed and WSL integration is enabled (Settings → Resources → WSL Integration), you can use `docker` directly from WSL without installing Docker Engine separately.

**Verify**:
```bash
docker --version       # Expected: Docker version 24.x+
docker info            # Should show server running
```

### 1.4 Git

**Windows (PowerShell)**:
```powershell
winget install Git.Git
```

**Linux / WSL (Debian/Ubuntu)**:
```bash
sudo apt install -y git
```

**macOS**: Usually pre-installed. If not: `xcode-select --install`

**Verify**:
```bash
git --version   # Expected: git version 2.40+
```

### 1.5 .NET 8.0 SDK (Required for Days 3–5: A365 CLI)

**Windows (PowerShell)**:
```powershell
winget install Microsoft.DotNet.SDK.8
```

**Linux / WSL (Debian/Ubuntu)**:
```bash
# Add Microsoft package repository
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt update
sudo apt install -y dotnet-sdk-8.0
```

**macOS (Homebrew)**:
```bash
brew install dotnet@8
```

**Verify**:
```bash
dotnet --version   # Expected: 8.0.x
```

### 1.6 jq (Linux / WSL only — JSON processor)

The bash deployment scripts use `jq` for JSON parsing:

```bash
sudo apt install -y jq
```

### 1.7 VS Code

Download from [code.visualstudio.com](https://code.visualstudio.com/) or:

**Windows**:
```powershell
winget install Microsoft.VisualStudioCode
```

**Linux / WSL (Debian/Ubuntu)**:
```bash
sudo apt install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install -y code
```

> **WSL Tip**: Install VS Code on Windows and use the **Remote - WSL** extension to develop inside WSL. Run `code .` from a WSL terminal to open VS Code connected to WSL.

---

## Step 2: Install VS Code Extensions

Open VS Code and install these extensions (Ctrl+Shift+X):

| Extension | ID | Purpose |
|-----------|----|---------|
| Python | `ms-python.python` | Python IntelliSense, debugging |
| Pylance | `ms-python.vscode-pylance` | Python type checking |
| Azure Account | `ms-vscode.azure-account` | Azure sign-in |
| Azure Resources | `ms-azuretools.vscode-azureresourcegroups` | Browse Azure resources |
| Docker | `ms-azuretools.vscode-docker` | Dockerfile support |
| Bicep | `ms-azuretools.vscode-bicep` | Bicep template support |
| REST Client | `humao.rest-client` | Test API endpoints |

Quick install via terminal:

```powershell
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-azuretools.vscode-bicep
code --install-extension humao.rest-client
```

---

## Step 3: Azure Subscription Setup

### 3.1 Sign In

```powershell
az login
az account show --query "{name:name, id:id, state:state}" -o table
```

### 3.2 Set Default Subscription

```powershell
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 3.3 Verify Permissions

```bash
# Must show "Contributor" or "Owner"
# Windows PowerShell:
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --query "[].roleDefinitionName" -o tsv

# Linux / WSL / macOS (Bash):
az role assignment list --assignee "$(az ad signed-in-user show --query id -o tsv)" --query "[].roleDefinitionName" -o tsv
```

### 3.4 Register Required Providers

```powershell
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Insights
```

> **Enterprise users**: If your subscription requires IT approval, do this 3–5 business days before the workshop.

---

## Step 4: Clone the Workshop Repository

```powershell
git clone https://github.com/<ORG>/a365-workshop.git
cd a365-workshop
```

### Repository Structure

```
a365-workshop/
├── prereq/              # Infrastructure templates (Bicep) & provisioning scripts
├── lesson-1-declarative/ # Declarative agent (azure-ai-agents SDK)
├── lesson-2-hosted-maf/  # Hosted agent with Microsoft Agent Framework
├── lesson-3-hosted-langgraph/ # Hosted agent with LangGraph on Foundry
├── lesson-4-aca-langgraph/    # Connected agent on Azure Container Apps
├── lesson-5-a365-prereq/     # Agent 365 cross-tenant setup
├── lesson-6-a365-sdk/        # Full A365 SDK (LangGraph + Bot Framework + OTel)
├── lesson-7-publish/         # Publish to M365 Admin Center
├── lesson-8-instances/       # Create agent instances in Teams
├── test/                     # Test client (chat.py)
```

---

## Step 5: Provision Azure Infrastructure

### 5.1 Deploy Workshop Resources

**Edit main.bicepparam**
Open bicep parameters file and ajust the resourceGroupName, location, etc as needed 

**Windows (PowerShell)**:
```powershell
cd prereq
./deploy.ps1
```

**Linux / WSL (pwsh)**:
```bash
cd prereq
pswh ./deploy.ps1
```

This provisions:
- **Azure AI Foundry** (Hub + Project) — agent hosting
- **Azure Container Registry (ACR)** — Docker images
- **Log Analytics Workspace** — monitoring
- **Application Insights** — telemetry
- **GPT-4o-mini deployment** — LLM model

### 5.2 Validate Deployment

**Windows (PowerShell)**:
```powershell
./validate-deployment.ps1
```

**Linux / WSL (Bash)**:
```bash
./validate-deployment.sh
```

Expected output — all resources showing `✅`:
```
✅ Resource Group: rg-ai-agents-workshop
✅ Azure AI Hub: aihub-workshop
✅ Azure AI Project: aiproj-workshop
✅ Container Registry: acrworkshop
✅ Log Analytics: log-workshop
✅ Application Insights: appi-workshop
✅ Model Deployment: gpt-4o-mini
```

---

## Step 6: Python Environment Setup

### 6.1 Create Virtual Environment

```bash
# From repository root
python3 -m venv .venv

# Activate — Windows PowerShell:
.\.venv\Scripts\Activate.ps1

# Activate — Linux / WSL / macOS:
source .venv/bin/activate
```

### 6.2 Install Base Dependencies

```powershell
pip install --upgrade pip
pip install azure-ai-agents azure-identity python-dotenv
```

### 6.3 Verify SDK Installation

```powershell
python -c "import azure.ai.agents; print('✅ azure-ai-agents installed:', azure.ai.agents.__version__)"
```

---

## Step 7: Install A365 CLI (Days 3–5)

```powershell
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify
a365 --version
```

---

## Step 8: Environment Validation Script

Run this comprehensive check to verify your setup.

**Windows (PowerShell)**:
```powershell
Write-Host "=== Workshop Environment Validation ===" -ForegroundColor Cyan

# 1. Python
$py = python --version 2>&1; Write-Host "Python: $py" -ForegroundColor $(if($py -match '3\.(1[1-9]|[2-9]\d)') {"Green"} else {"Red"})

# 2. Azure CLI
$az = az version --query '"azure-cli"' -o tsv 2>&1; Write-Host "Azure CLI: $az" -ForegroundColor $(if($az) {"Green"} else {"Red"})

# 3. Docker
$dk = docker --version 2>&1; Write-Host "Docker: $dk" -ForegroundColor $(if($dk -match 'Docker') {"Green"} else {"Red"})

# 4. Git
$gt = git --version 2>&1; Write-Host "Git: $gt" -ForegroundColor $(if($gt -match 'git') {"Green"} else {"Red"})

# 5. .NET SDK
$dn = dotnet --version 2>&1; Write-Host ".NET SDK: $dn" -ForegroundColor $(if($dn -match '8\.') {"Green"} else {"Yellow"})

# 6. Azure login
$acct = az account show --query name -o tsv 2>&1; Write-Host "Azure Account: $acct" -ForegroundColor $(if($acct -notmatch 'ERROR') {"Green"} else {"Red"})

# 7. azure-ai-agents SDK
$sdk = python -c "import azure.ai.agents; print(azure.ai.agents.__version__)" 2>&1; Write-Host "azure-ai-agents: $sdk" -ForegroundColor $(if($sdk -notmatch 'Error|No module') {"Green"} else {"Red"})

Write-Host "`n=== Validation Complete ===" -ForegroundColor Cyan
```

**Linux / WSL (Bash)**:
```bash
#!/bin/bash
echo "=== Workshop Environment Validation ==="

# Colors
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
check() { if [ $? -eq 0 ]; then echo -e "${GREEN}✅ $1${NC}"; else echo -e "${RED}❌ $1${NC}"; fi }

# 1. Python
python3 --version 2>/dev/null && check "Python" || check "Python NOT FOUND"

# 2. Azure CLI
az version --query '"azure-cli"' -o tsv 2>/dev/null && check "Azure CLI" || check "Azure CLI NOT FOUND"

# 3. Docker
docker --version 2>/dev/null && check "Docker" || check "Docker NOT FOUND"

# 4. Git
git --version 2>/dev/null && check "Git" || check "Git NOT FOUND"

# 5. .NET SDK
dotnet --version 2>/dev/null && check ".NET SDK" || echo -e "${YELLOW}⚠️  .NET SDK not found (needed for Days 3-5)${NC}"

# 6. Azure login
az account show --query name -o tsv 2>/dev/null && check "Azure Account" || check "Azure login FAILED (run: az login)"

# 7. azure-ai-agents SDK
python3 -c "import azure.ai.agents; print(azure.ai.agents.__version__)" 2>/dev/null && check "azure-ai-agents" || check "azure-ai-agents NOT INSTALLED"

# 8. jq (needed for bash scripts)
jq --version 2>/dev/null && check "jq" || echo -e "${YELLOW}⚠️  jq not found (run: sudo apt install -y jq)${NC}"

echo "=== Validation Complete ==="
```

Save as `validate-setup.ps1` (Windows) or `validate-setup.sh` (Linux). All items should show **green/✅**.

---

## Troubleshooting

### "az login" fails with SSO/MFA

```bash
az login --use-device-code
```

### Docker daemon not started

- **Windows**: Open Docker Desktop from Start Menu, wait for "Docker Desktop is running"
- **macOS**: `open -a Docker`
- **Linux**: `sudo systemctl start docker`
- **WSL**: If using Docker Desktop, ensure WSL integration is enabled. If using Docker Engine in WSL: `sudo service docker start`

### Python version mismatch

```bash
# Windows:
where.exe python

# Linux / WSL / macOS:
which -a python3
python3 --version
```

> **Linux/WSL Tip**: Use `python3` instead of `python`. If you need the `python` alias: `sudo apt install python-is-python3`

### Azure subscription quota errors

```bash
az cognitiveservices usage list --location eastus2 -o table
```

### "Permission denied" on .ps1 scripts (Windows)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Permission denied" on .sh scripts (Linux / WSL)

```bash
chmod +x deploy.sh validate-deployment.sh
```

### pip install fails behind corporate proxy

```bash
pip install --proxy http://proxy.company.com:8080 azure-ai-agents
```

### WSL-specific issues

**WSL not installed**:
```powershell
# From elevated PowerShell on Windows
wsl --install -d Ubuntu
# Restart required after installation
```

**WSL 1 vs WSL 2**:
```bash
# Check version
wsl --list --verbose

# Convert to WSL 2 if needed (from Windows PowerShell):
wsl --set-version Ubuntu 2
```

**DNS resolution issues in WSL**:
```bash
# If apt or pip fail with network errors
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

**Disk space in WSL**: WSL has a default virtual disk limit. If you run out of space building Docker images:
```bash
df -h   # Check available space
docker system prune -a   # Clean unused Docker data
```

---

## Need Help?

- **Workshop Slack/Teams channel**: #ai-agents-workshop
- **Office hours**: Day -3 and Day -1 (see welcome email)
- **Known issues**: See `context.md` in the repository root
- **Email**: [instructor email — to be provided]
