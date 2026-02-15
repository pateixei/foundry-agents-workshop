# Participant Environment Setup Guide

**Workshop**: Microsoft Foundry AI Agents Workshop — 5-Day Intensive  
**Version**: 1.0  
**Estimated Time**: 30–45 minutes  
**Last Verified**: February 15, 2026  

---

## Prerequisites Checklist

Before starting, ensure you have:

| # | Requirement | Notes |
|---|-------------|-------|
| 1 | Laptop with admin/sudo rights | Windows 10+, macOS 12+, or Ubuntu 22.04+ |
| 2 | Internet ≥ 10 Mbps | Required for Azure, Docker, pip |
| 3 | Azure subscription with **Contributor** role | [azure.com/free](https://azure.com/free) or enterprise |
| 4 | GitHub account | To clone workshop repo |
| 5 | Microsoft 365 Developer Tenant (Days 3-5) | [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program) |

---

## Step 1: Install Core Tools

### 1.1 Python 3.11+

```powershell
# Windows — winget
winget install Python.Python.3.11

# macOS — Homebrew
brew install python@3.11

# Verify
python --version   # Expected: Python 3.11.x or higher
```

### 1.2 Azure CLI 2.60+

```powershell
# Windows — winget
winget install Microsoft.AzureCLI

# macOS — Homebrew
brew install azure-cli

# Verify
az version   # Expected: "azure-cli": "2.60.0" or higher
```

### 1.3 Docker Desktop

Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) and install.

```powershell
# Verify
docker --version       # Expected: Docker version 24.x+
docker info            # Should show "Server: Docker Desktop"
```

> **Windows**: Ensure WSL 2 backend is enabled (Docker Desktop → Settings → General → Use the WSL 2 based engine).

### 1.4 Git

```powershell
# Windows — winget
winget install Git.Git

# macOS — Xcode tools (usually pre-installed)
xcode-select --install

# Verify
git --version   # Expected: git version 2.40+
```

### 1.5 .NET 8.0 SDK (Required for Days 3–5: A365 CLI)

```powershell
# Windows — winget
winget install Microsoft.DotNet.SDK.8

# macOS — Homebrew
brew install dotnet@8

# Verify
dotnet --version   # Expected: 8.0.x
```

### 1.6 VS Code

Download from [code.visualstudio.com](https://code.visualstudio.com/) or:

```powershell
winget install Microsoft.VisualStudioCode
```

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

```powershell
# Must show "Contributor" or "Owner"
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --query "[].roleDefinitionName" -o tsv
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
├── slides/                   # Architecture diagrams
└── context.md                # Known issues & workarounds
```

---

## Step 5: Provision Azure Infrastructure

### 5.1 Create a Resource Group

```powershell
$RESOURCE_GROUP = "rg-ai-agents-workshop"
$LOCATION = "eastus2"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5.2 Deploy Workshop Resources

```powershell
cd prereq

# Deploy using the Bicep template
./deploy.ps1
```

This provisions:
- **Azure AI Foundry** (Hub + Project) — agent hosting
- **Azure Container Registry (ACR)** — Docker images
- **Log Analytics Workspace** — monitoring
- **Application Insights** — telemetry
- **GPT-4o-mini deployment** — LLM model

### 5.3 Validate Deployment

```powershell
./validate-deployment.ps1
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

```powershell
# From repository root
python -m venv .venv

# Activate
# Windows PowerShell:
.\.venv\Scripts\Activate.ps1

# macOS/Linux:
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

Run this comprehensive check:

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

Save as `validate-setup.ps1` or run inline. All items should show **green**.

---

## Troubleshooting

### "az login" fails with SSO/MFA

```powershell
az login --use-device-code
```

### Docker daemon not started

- Windows: Open Docker Desktop from Start Menu, wait for "Docker Desktop is running"
- macOS: `open -a Docker`

### Python version mismatch

```powershell
# Check all Python installations
where.exe python          # Windows
which -a python3          # macOS/Linux
```

### Azure subscription quota errors

```powershell
# Check quota for CognitiveServices
az cognitiveservices usage list --location eastus2 -o table
```

### "Permission denied" on deploy.ps1

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### pip install fails behind corporate proxy

```powershell
pip install --proxy http://proxy.company.com:8080 azure-ai-agents
```

---

## Need Help?

- **Workshop Slack/Teams channel**: #ai-agents-workshop
- **Office hours**: Day -3 and Day -1 (see welcome email)
- **Known issues**: See `context.md` in the repository root
- **Email**: [instructor email — to be provided]
