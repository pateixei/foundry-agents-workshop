# Guia de Configuração do Ambiente para Participantes

**Workshop**: Microsoft Foundry AI Agents Workshop — Intensivo de 5 Dias  
**Versão**: 1.0  
**Tempo Estimado**: 30–45 minutos  
**Última Verificação**: 15 de fevereiro de 2026  

---

## Checklist de Pré-requisitos

Antes de começar, certifique-se de que você tem:

| # | Requisito | Observações |
|---|-----------|-------------|
| 1 | Laptop com direitos de administrador/sudo | Windows 10+, macOS 12+, ou Ubuntu 22.04+ |
| 2 | Internet ≥ 10 Mbps | Necessário para Azure, Docker, pip |
| 3 | Assinatura Azure com papel de **Contributor** | [azure.com/free](https://azure.com/free) ou corporativa |
| 4 | Conta no GitHub | Para clonar o repositório do workshop |
| 5 | Tenant de Desenvolvedor Microsoft 365 (Dias 3-5) | [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program) |

---

## Passo 1: Instalar Ferramentas Essenciais

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

Baixe em [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) e instale.

```powershell
# Verify
docker --version       # Expected: Docker version 24.x+
docker info            # Should show "Server: Docker Desktop"
```

> **Windows**: Certifique-se de que o backend WSL 2 está habilitado (Docker Desktop → Settings → General → Use the WSL 2 based engine).

### 1.4 Git

```powershell
# Windows — winget
winget install Git.Git

# macOS — Xcode tools (usually pre-installed)
xcode-select --install

# Verify
git --version   # Expected: git version 2.40+
```

### 1.5 .NET 8.0 SDK (Necessário para Dias 3–5: A365 CLI)

```powershell
# Windows — winget
winget install Microsoft.DotNet.SDK.8

# macOS — Homebrew
brew install dotnet@8

# Verify
dotnet --version   # Expected: 8.0.x
```

### 1.6 VS Code

Baixe em [code.visualstudio.com](https://code.visualstudio.com/) ou:

```powershell
winget install Microsoft.VisualStudioCode
```

---

## Passo 2: Extensões do VS Code

Abra o VS Code e instale estas extensões (Ctrl+Shift+X):

| Extensão | ID | Finalidade |
|----------|----|------------|
| Python | `ms-python.python` | IntelliSense e depuração Python |
| Pylance | `ms-python.vscode-pylance` | Verificação de tipos Python |
| Azure Account | `ms-vscode.azure-account` | Login no Azure |
| Azure Resources | `ms-azuretools.vscode-azureresourcegroups` | Navegar recursos Azure |
| Docker | `ms-azuretools.vscode-docker` | Suporte a Dockerfile |
| Bicep | `ms-azuretools.vscode-bicep` | Suporte a templates Bicep |
| REST Client | `humao.rest-client` | Testar endpoints de API |

Instalação rápida via terminal:

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

## Passo 3: Configuração da Assinatura Azure

### 3.1 Fazer Login

```powershell
az login
az account show --query "{name:name, id:id, state:state}" -o table
```

### 3.2 Definir Assinatura Padrão

```powershell
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 3.3 Verificar Permissões

```powershell
# Must show "Contributor" or "Owner"
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --query "[].roleDefinitionName" -o tsv
```

### 3.4 Registrar Provedores Necessários

```powershell
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.Insights
```

> **Usuários corporativos**: Se sua assinatura requer aprovação de TI, faça isso de 3 a 5 dias úteis antes do workshop.

---

## Passo 4: Clonar o Repositório do Workshop

```powershell
git clone https://github.com/<ORG>/a365-workshop.git
cd a365-workshop
```

### Estrutura do Repositório

```
a365-workshop/
├── prereq/              # Templates de infraestrutura (Bicep) & scripts de provisionamento
├── lesson-1-declarative/ # Agente declarativo (azure-ai-agents SDK)
├── lesson-2-hosted-maf/  # Agente hospedado com Microsoft Agent Framework
├── lesson-3-hosted-langgraph/ # Agente hospedado com LangGraph no Foundry
├── lesson-4-aca-langgraph/    # Agente conectado no Azure Container Apps
├── lesson-5-a365-prereq/     # Configuração cross-tenant do Agent 365
├── lesson-6-a365-sdk/        # A365 SDK completo (LangGraph + Bot Framework + OTel)
├── lesson-7-publish/         # Publicar no M365 Admin Center
├── lesson-8-instances/       # Criar instâncias de agente no Teams
├── test/                     # Cliente de teste (chat.py)
├── slides/                   # Diagramas de arquitetura
└── context.md                # Problemas conhecidos & soluções alternativas
```

---

## Passo 5: Provisionar Infraestrutura Azure

### 5.1 Criar um Resource Group

```powershell
$RESOURCE_GROUP = "rg-ai-agents-workshop"
$LOCATION = "eastus2"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5.2 Implantar Recursos do Workshop

```powershell
cd prereq

# Deploy using the Bicep template
./deploy.ps1
```

Isso provisiona:
- **Azure AI Foundry** (Hub + Project) — hospedagem de agentes
- **Azure Container Registry (ACR)** — imagens Docker
- **Log Analytics Workspace** — monitoramento
- **Application Insights** — telemetria
- **Implantação do GPT-4o-mini** — modelo LLM

### 5.3 Validar a Implantação

```powershell
./validate-deployment.ps1
```

Saída esperada — todos os recursos mostrando `✅`:
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

## Passo 6: Ambiente Virtual Python

### 6.1 Criar Ambiente Virtual

```powershell
# From repository root
python -m venv .venv

# Activate
# Windows PowerShell:
.\.venv\Scripts\Activate.ps1

# macOS/Linux:
source .venv/bin/activate
```

### 6.2 Instalar Dependências Base

```powershell
pip install --upgrade pip
pip install azure-ai-agents azure-identity python-dotenv
```

### 6.3 Verificar Instalação do SDK

```powershell
python -c "import azure.ai.agents; print('✅ azure-ai-agents installed:', azure.ai.agents.__version__)"
```

---

## Passo 7: Instalar A365 CLI (Dias 3–5)

```powershell
dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli --prerelease

# Verify
a365 --version
```

---

## Passo 8: Script de Validação do Ambiente

Execute esta verificação abrangente:

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

Salve como `validate-setup.ps1` ou execute diretamente. Todos os itens devem aparecer em **verde**.

---

## Resolução de Problemas

### `az login` falha com SSO/MFA

```powershell
az login --use-device-code
```

### Docker daemon não iniciado

- Windows: Abra o Docker Desktop pelo Menu Iniciar, aguarde "Docker Desktop is running"
- macOS: `open -a Docker`

### Versão do Python incorreta

```powershell
# Check all Python installations
where.exe python          # Windows
which -a python3          # macOS/Linux
```

### Erros de cota da assinatura Azure

```powershell
# Check quota for CognitiveServices
az cognitiveservices usage list --location eastus2 -o table
```

### "Permission denied" no deploy.ps1

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Falha no pip install atrás de proxy corporativo

```powershell
pip install --proxy http://proxy.company.com:8080 azure-ai-agents
```

---

## Precisa de Ajuda?

- **Canal Slack/Teams do Workshop**: #ai-agents-workshop
- **Horário de atendimento**: Dia -3 e Dia -1 (veja o e-mail de boas-vindas)
- **Problemas conhecidos**: Consulte `context.md` na raiz do repositório
- **E-mail**: [e-mail do instrutor — a ser fornecido]
