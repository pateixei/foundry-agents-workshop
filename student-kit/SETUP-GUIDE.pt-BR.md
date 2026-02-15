# Guia de Configuração do Ambiente para Estudantes

> 🇺🇸 **[Read in English](SETUP-GUIDE.md)**

**Workshop**: Microsoft Foundry AI Agents Workshop — Intensivo de 5 Dias  
**Versão**: 1.0  
**Tempo Estimado**: 30–45 minutos  
**Última Verificação**: 15 de fevereiro de 2026  

---

## Checklist de Pré-requisitos

Antes de começar, certifique-se de que você tem:

| # | Requisito | Observações |
|---|-----------|-------------|
| 1 | Laptop com direitos de administrador/sudo | Windows 10+, macOS 12+, ou Ubuntu 22.04+ (nativo ou WSL) |
| 2 | Internet ≥ 10 Mbps | Necessário para Azure, Docker, pip |
| 3 | Assinatura Azure com papel de **Contributor** | [azure.com/free](https://azure.com/free) ou corporativa |
| 4 | Conta no GitHub | Para clonar o repositório do workshop |
| 5 | Tenant de Desenvolvedor Microsoft 365 (Dias 3-5) | [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program) |

> **Usuários WSL (Windows Subsystem for Linux)**: Todas as instruções de Linux se aplicam dentro do seu terminal WSL. Certifique-se de que o WSL 2 está instalado: `wsl --install -d Ubuntu` a partir de um prompt PowerShell elevado. Abra um terminal WSL via `wsl` ou Windows Terminal → Ubuntu.

---

## Passo 1: Instalar Ferramentas Essenciais

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

**Verificar**:
```bash
python3 --version   # Esperado: Python 3.11.x ou superior
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

**Verificar**:
```bash
az version   # Esperado: "azure-cli": "2.60.0" ou superior
```

### 1.3 Docker

**Windows**: Baixe o [Docker Desktop](https://www.docker.com/products/docker-desktop/) e certifique-se de que o backend WSL 2 está habilitado (Settings → General → Use the WSL 2 based engine).

**Linux / WSL (Debian/Ubuntu)**:
```bash
# Instalar Docker Engine (não Docker Desktop)
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Adicionar seu usuário ao grupo docker (evita usar sudo para comandos docker)
sudo usermod -aG docker $USER
newgrp docker
```

> **Dica WSL**: Se o Docker Desktop para Windows estiver instalado e a integração WSL habilitada (Settings → Resources → WSL Integration), você pode usar `docker` diretamente do WSL sem instalar o Docker Engine separadamente.

**Verificar**:
```bash
docker --version       # Esperado: Docker version 24.x+
docker info            # Deve mostrar o servidor em execução
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

**macOS**: Geralmente pré-instalado. Se não: `xcode-select --install`

**Verificar**:
```bash
git --version   # Esperado: git version 2.40+
```

### 1.5 .NET 8.0 SDK (Necessário para Dias 3–5: A365 CLI)

**Windows (PowerShell)**:
```powershell
winget install Microsoft.DotNet.SDK.8
```

**Linux / WSL (Debian/Ubuntu)**:
```bash
# Adicionar repositório de pacotes Microsoft
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

**Verificar**:
```bash
dotnet --version   # Esperado: 8.0.x
```

### 1.6 jq (apenas Linux / WSL — processador JSON)

Os scripts bash de implantação usam `jq` para processamento de JSON:

```bash
sudo apt install -y jq
```

### 1.7 VS Code

Baixe em [code.visualstudio.com](https://code.visualstudio.com/) ou:

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

> **Dica WSL**: Instale o VS Code no Windows e use a extensão **Remote - WSL** para desenvolver dentro do WSL. Execute `code .` a partir de um terminal WSL para abrir o VS Code conectado ao WSL.

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

```bash
# Deve mostrar "Contributor" ou "Owner"
# Windows PowerShell:
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --query "[].roleDefinitionName" -o tsv

# Linux / WSL / macOS (Bash):
az role assignment list --assignee "$(az ad signed-in-user show --query id -o tsv)" --query "[].roleDefinitionName" -o tsv
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
```

---

## Passo 5: Provisionar Infraestrutura Azure

### 5.1 Criar um Resource Group

**Windows (PowerShell)**:
```powershell
$RESOURCE_GROUP = "rg-ai-agents-workshop"
$LOCATION = "eastus2"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

**Linux / WSL (Bash)**:
```bash
RESOURCE_GROUP="rg-ai-agents-workshop"
LOCATION="eastus2"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 5.2 Implantar Recursos do Workshop

**Windows (PowerShell)**:
```powershell
cd prereq
./deploy.ps1
```

**Linux / WSL (Bash)**:
```bash
cd prereq
chmod +x deploy.sh
./deploy.sh
```

Isso provisiona:
- **Azure AI Foundry** (Hub + Project) — hospedagem de agentes
- **Azure Container Registry (ACR)** — imagens Docker
- **Log Analytics Workspace** — monitoramento
- **Application Insights** — telemetria
- **Implantação do GPT-4o-mini** — modelo LLM

### 5.3 Validar a Implantação

**Windows (PowerShell)**:
```powershell
./validate-deployment.ps1
```

**Linux / WSL (Bash)**:
```bash
./validate-deployment.sh
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

```bash
# A partir da raiz do repositório
python3 -m venv .venv

# Ativar — Windows PowerShell:
.\.venv\Scripts\Activate.ps1

# Ativar — Linux / WSL / macOS:
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

# Verificar
a365 --version
```

---

## Passo 8: Script de Validação do Ambiente

Execute esta verificação abrangente.

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

# Cores
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
check() { if [ $? -eq 0 ]; then echo -e "${GREEN}✅ $1${NC}"; else echo -e "${RED}❌ $1${NC}"; fi }

# 1. Python
python3 --version 2>/dev/null && check "Python" || check "Python NÃO ENCONTRADO"

# 2. Azure CLI
az version --query '"azure-cli"' -o tsv 2>/dev/null && check "Azure CLI" || check "Azure CLI NÃO ENCONTRADO"

# 3. Docker
docker --version 2>/dev/null && check "Docker" || check "Docker NÃO ENCONTRADO"

# 4. Git
git --version 2>/dev/null && check "Git" || check "Git NÃO ENCONTRADO"

# 5. .NET SDK
dotnet --version 2>/dev/null && check ".NET SDK" || echo -e "${YELLOW}⚠️  .NET SDK não encontrado (necessário para Dias 3-5)${NC}"

# 6. Azure login
az account show --query name -o tsv 2>/dev/null && check "Azure Account" || check "Azure login FALHOU (execute: az login)"

# 7. azure-ai-agents SDK
python3 -c "import azure.ai.agents; print(azure.ai.agents.__version__)" 2>/dev/null && check "azure-ai-agents" || check "azure-ai-agents NÃO INSTALADO"

# 8. jq (necessário para scripts bash)
jq --version 2>/dev/null && check "jq" || echo -e "${YELLOW}⚠️  jq não encontrado (execute: sudo apt install -y jq)${NC}"

echo "=== Validação Completa ==="
```

Salve como `validate-setup.ps1` (Windows) ou `validate-setup.sh` (Linux). Todos os itens devem aparecer em **verde/✅**.

---

## Resolução de Problemas

### `az login` falha com SSO/MFA

```bash
az login --use-device-code
```

### Docker daemon não iniciado

- **Windows**: Abra o Docker Desktop pelo Menu Iniciar, aguarde "Docker Desktop is running"
- **macOS**: `open -a Docker`
- **Linux**: `sudo systemctl start docker`
- **WSL**: Se estiver usando Docker Desktop, certifique-se de que a integração WSL está habilitada. Se estiver usando Docker Engine no WSL: `sudo service docker start`

### Versão do Python incorreta

```bash
# Windows:
where.exe python

# Linux / WSL / macOS:
which -a python3
python3 --version
```

> **Dica Linux/WSL**: Use `python3` em vez de `python`. Se precisar do alias `python`: `sudo apt install python-is-python3`

### Erros de cota da assinatura Azure

```bash
az cognitiveservices usage list --location eastus2 -o table
```

### "Permission denied" em scripts .ps1 (Windows)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Permission denied" em scripts .sh (Linux / WSL)

```bash
chmod +x deploy.sh validate-deployment.sh
```

### Falha no pip install atrás de proxy corporativo

```bash
pip install --proxy http://proxy.company.com:8080 azure-ai-agents
```

### Problemas específicos do WSL

**WSL não instalado**:
```powershell
# A partir de um PowerShell elevado no Windows
wsl --install -d Ubuntu
# Reinicialização necessária após a instalação
```

**WSL 1 vs WSL 2**:
```bash
# Verificar versão
wsl --list --verbose

# Converter para WSL 2 se necessário (a partir do Windows PowerShell):
wsl --set-version Ubuntu 2
```

**Problemas de resolução DNS no WSL**:
```bash
# Se apt ou pip falharem com erros de rede
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

**Espaço em disco no WSL**: O WSL tem um limite padrão de disco virtual. Se você ficar sem espaço ao construir imagens Docker:
```bash
df -h   # Verificar espaço disponível
docker system prune -a   # Limpar dados Docker não utilizados
```

---

## Precisa de Ajuda?

- **Canal Slack/Teams do Workshop**: #ai-agents-workshop
- **Horário de atendimento**: Dia -3 e Dia -1 (veja o e-mail de boas-vindas)
- **Problemas conhecidos**: Consulte `context.md` na raiz do repositório
- **E-mail**: [e-mail do instrutor — a ser fornecido]
