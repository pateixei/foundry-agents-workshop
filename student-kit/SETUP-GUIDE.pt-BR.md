# Guia de Configuração do Ambiente para Estudantes

> 🇺🇸 **[Read in English](SETUP-GUIDE.md)**

**Workshop**: Microsoft Foundry AI Agents Workshop — Intensivo de 5 Dias  
**Versão**: 0.7  
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
| 6 | Inscrição no **Programa Copilot Frontier** (Dias 3-5) | [adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/) |

> [!CAUTION]
> **🔴 OBRIGATÓRIO — Inscrição no Programa Copilot Frontier (Dias 3–5)**
>
> Seu tenant M365 **DEVE** estar inscrito no **programa Microsoft Copilot Frontier preview** para completar as Lições 5–8 (Agent 365). Sem esta inscrição, o A365 CLI falhará com **"Forbidden: Access denied by Frontier access control"** ao registrar blueprints de agentes.
>
> **Inscreva-se aqui → [https://adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/)**
>
> Após a inscrição, um Global Admin deve habilitar o Copilot Frontier no [Centro de Admin do Microsoft 365](https://admin.microsoft.com/) → Copilot → Configurações → Acesso de usuários → Copilot Frontier. **Aguarde até 24 horas** para propagação.

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
├── lesson-5-a365-langgraph/  # A365 SDK completo (LangGraph + Bot Framework + OTel)
├── lesson-6-a365-prereq/     # Configuração cross-tenant do Agent 365
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

## Passo 8: Configuração do Tenant de Desenvolvedor Microsoft 365 (Dias 3–5)

> [!IMPORTANT]
> **Obrigatório para as Lições 5–8 (integração com Agent 365)**
>
> Você **DEVE** ter um tenant de desenvolvedor Microsoft 365 para completar as lições do Agent 365 (Dias 3–5). Isso é **separado** da sua assinatura do Azure e fornece um ambiente M365 gratuito para desenvolvimento e testes.

### 8.1 Ingressar no Programa de Desenvolvedor Microsoft 365

O Programa de Desenvolvedor Microsoft 365 fornece uma assinatura gratuita e renovável do Microsoft 365 E5 para construir e testar soluções M365.

**Benefícios:**
- Assinatura gratuita do Microsoft 365 E5 (renovável a cada 90 dias com uso ativo)
- 25 licenças de usuário
- Pacotes de dados de amostra pré-configurados (opcional)
- Acesso a todos os serviços do Microsoft 365 (Teams, SharePoint, Exchange, etc.)
- Acesso de Administrador Global ao seu tenant

**Registro passo a passo:**

1. **Navegue até o portal do Programa de Desenvolvedor**
   - Acesse [https://developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program)
   - Clique em **"Ingressar agora"** (ou **"Entrar"** se você já tem uma conta Microsoft)

2. **Entre com uma conta Microsoft**
   - Use sua **conta Microsoft pessoal** (por exemplo, @outlook.com, @hotmail.com, @live.com)
   - **Importante**: NÃO use sua conta corporativa/escolar se quiser ter controle total
   - Se você não tem uma conta Microsoft pessoal, crie uma em [https://signup.live.com](https://signup.live.com)

3. **Complete o formulário de registro**
   - **País/Região**: Selecione seu país
   - **Empresa**: Digite o nome da sua empresa ou "Desenvolvedor Individual"
   - **Preferência de idioma**: Selecione seu idioma preferido
   - **Aceitar termos**: Revise e aceite os termos e condições
   - Clique em **"Avançar"**

4. **Configure sua assinatura de desenvolvedor**
   Você terá duas opções:
   
   **Opção A: Sandbox instantâneo (Recomendado para este workshop)**
   - Clique em **"Configurar assinatura E5"**
   - O sistema provisionará automaticamente um tenant com:
     - Domínio: `<nome-aleatório>.onmicrosoft.com`
     - Nome de usuário admin: `admin@<nome-aleatório>.onmicrosoft.com`
     - Uma senha temporária (você será solicitado a alterá-la no primeiro login)
   - **Vantagens**: Configuração instantânea (< 1 minuto), sem configuração necessária
   - **Nota**: Anote suas credenciais de admin imediatamente — você não poderá recuperá-las depois

   **Opção B: Sandbox configurável (Avançado)**
   - Escolha **"Configurar assinatura E5"** e então selecione **"Configurável"**
   - Você pode personalizar:
     - Nome de usuário (admin@...)
     - Prefixo do domínio (por exemplo, `minhaempresa.onmicrosoft.com`)
     - Senha
   - Pacotes de dados de amostra (opcional — adiciona usuários de amostra, emails, sites do SharePoint)
   - Leva 2–5 minutos para provisionar
   
   > **Recomendação do Workshop**: Use **Opção A (Sandbox instantâneo)** para configuração mais rápida. Você sempre pode adicionar dados de amostra depois.

5. **Salve suas credenciais**
   
   Após a conclusão do provisionamento, você verá:
   ```
   Sua assinatura de desenvolvedor Microsoft 365 está pronta!
   
   Domínio: dev123456.onmicrosoft.com
   Nome de usuário: admin@dev123456.onmicrosoft.com
   Senha: [senha temporária mostrada uma vez]
   ```
   
   **🚨 CRÍTICO**: Salve essas credenciais em um local seguro (recomenda-se gerenciador de senhas). Você precisará delas para:
   - Entrar no Centro de Administração do Microsoft 365
   - Inscrever-se no Programa Copilot Frontier (obrigatório — veja abaixo)
   - Configurar autenticação do A365 CLI
   - Publicar e testar agentes no Teams

### 8.2 Primeiro Login e Alteração de Senha

1. Acesse [https://admin.microsoft.com](https://admin.microsoft.com)
2. Entre com `admin@<seu-tenant>.onmicrosoft.com` e a senha temporária
3. Você será solicitado a alterar sua senha imediatamente
4. Configure a autenticação multifator (MFA) se solicitado — **recomendado** por segurança
5. Complete o assistente de configuração do Microsoft 365 (opcional — você pode pular isso)

### 8.3 Verifique seu Tenant

Após entrar no Centro de Administração, verifique sua assinatura:

1. Na navegação à esquerda, vá para **Cobrança** → **Seus produtos**
2. Você deve ver:
   - **Microsoft 365 E5 Developer (without Windows and Audio Conferencing)**
   - Status: **Ativo**
   - Assinatura expira em: **[90 dias a partir da criação]**
3. Anote seu **ID do Tenant** (você precisará disso para o A365 CLI):
   - Vá para **Configurações** → **Configurações da organização** → **Perfil da organização**
   - Copie o **ID do Tenant** (um GUID como `12345678-1234-1234-1234-123456789012`)

### 8.4 Inscrever-se no Programa Copilot Frontier (OBRIGATÓRIO)

> [!CAUTION]
> **🔴 OBRIGATÓRIO para as Lições do Agent 365**
>
> Sem a inscrição no Copilot Frontier, você **não pode** publicar ou testar agentes do Agent 365. O A365 CLI falhará com:
> ```
> Erro: Proibido: Acesso negado pelo controle de acesso Frontier
> ```

**Etapas de inscrição:**

1. **Ingressar no Programa Frontier**
   - Acesse [https://adoption.microsoft.com/copilot/frontier-program/](https://adoption.microsoft.com/copilot/frontier-program/)
   - Clique em **"Ingressar no programa"**
   - Entre com sua **conta de administrador do tenant de desenvolvedor M365** (`admin@<seu-tenant>.onmicrosoft.com`)
   - Complete o formulário de inscrição
   - Aceite os termos do programa

2. **Ativar Copilot Frontier em seu tenant**
   - Acesse [https://admin.microsoft.com](https://admin.microsoft.com)
   - Entre como Administrador Global (sua conta admin)
   - Navegue para **Copilot** → **Configurações** (ou **Configurações** → **Copilot**)
   - Vá para **Acesso de usuário** → **Copilot Frontier**
   - Alterne **Ativar Copilot Frontier** para **Ligado**
   - Clique em **"Salvar"**

3. **Aguarde a propagação**
   - Aguarde **até 24 horas** para que as alterações se propaguem pelos serviços do Microsoft 365
   - **Recomendação**: Complete esta etapa **pelo menos 1 dia antes do Dia 3** do workshop

4. **Verificar acesso ao Frontier (após propagação)**
   ```bash
   # Testar autenticação do A365 CLI (após configuração do Dia 3)
   a365 auth login --tenant-id <SEU_ID_TENANT_M365>
   a365 blueprint list
   ```
   Se bem-sucedido, você deve ver uma lista vazia ou blueprints existentes (não um erro "Forbidden").

### 8.5 Renovação da Assinatura

Sua assinatura de desenvolvedor Microsoft 365 E5 é **gratuita por 90 dias** e **automaticamente renovável** se você mostrar uso ativo de desenvolvimento.

**Critérios de renovação:**
- Uso ativo inclui: chamadas de API, logins de usuários, desenvolvimento de agentes, instalações de aplicativos do Teams
- A Microsoft avalia o uso automaticamente ~2 semanas antes da expiração
- Se ativo, a assinatura renova por mais 90 dias
- Se inativo, você receberá um email de aviso 30 dias antes da expiração

**Melhores práticas para garantir renovação:**
- Use seu tenant regularmente (faça login, envie emails, teste agentes)
- Construa e teste agentes ao longo do workshop
- Mantenha seu perfil do programa de desenvolvedor atualizado

**O que acontece se expirar?**
- Você receberá vários emails de aviso antes da expiração
- Se expirar, os dados do seu tenant são retidos por 30 dias
- Você pode ingressar no programa novamente com um novo tenant (domínio diferente)

### 8.6 Notas Importantes

- **Azure ≠ Microsoft 365**: Sua assinatura do Azure e tenant M365 são **separados** e provavelmente em **tenants Entra ID diferentes**. Este é o "cenário cross-tenant" abordado na Lição 6.
- **Conta Pessoal vs. Corporativa**: Para controle total, use uma **conta Microsoft pessoal** (não seu email corporativo) ao ingressar no Programa de Desenvolvedor.
- **Múltiplos Tenants**: Você pode ter múltiplos tenants de desenvolvedor M365, mas apenas **um por conta Microsoft**.
- **Persistência de Dados**: Trate o tenant de desenvolvedor como efêmero para workshops. Não armazene dados críticos de produção.
- **Licenciamento**: A licença E5 inclui todos os serviços M365, mas alguns recursos (como conformidade avançada) podem exigir configuração adicional.

### 8.7 Solução de Problemas

**Problema: "Você já tem uma assinatura de desenvolvedor"**
- Você ingressou anteriormente no programa com esta conta Microsoft
- Acesse [https://developer.microsoft.com/microsoft-365/profile](https://developer.microsoft.com/microsoft-365/profile) para visualizar sua assinatura existente
- Verifique a aba **Assinaturas** para os detalhes do seu tenant
- Se você esqueceu as credenciais, talvez precise aguardar a expiração ou contatar o suporte

**Problema: "Não é possível se inscrever com conta corporativa/escolar"**
- O programa requer uma conta Microsoft pessoal para o registro inicial
- Crie uma nova conta Microsoft pessoal em [https://signup.live.com](https://signup.live.com)
- Use essa conta para ingressar no Programa de Desenvolvedor

**Problema: "Assinatura não está renovando"**
- Certifique-se de estar usando ativamente o tenant (chamadas de API, logins de usuários)
- Verifique seu painel do Programa de Desenvolvedor para métricas de uso
- Considere adicionar pacotes de dados de amostra ou usuários de teste para aumentar a atividade

**Problema: "Não é possível ativar o Copilot Frontier"**
- Verifique se você está conectado como Administrador Global
- Certifique-se de que seu tenant está inscrito no Programa Frontier primeiro
- Tente em um navegador diferente (Edge ou Chrome recomendados)
- Limpe o cache e cookies do navegador
- Aguarde 1 hora após a inscrição no Frontier antes de ativar no Centro de Administração

**Problema: "ID do Tenant não encontrado"**
- Acesse [https://admin.microsoft.com](https://admin.microsoft.com) → **Configurações** → **Configurações da organização** → **Perfil da organização**
- Procure por **ID do Diretório** ou **ID do Tenant** (são a mesma coisa)
- Alternativamente, use o Azure CLI: `az login --tenant <seu-tenant>.onmicrosoft.com --allow-no-subscriptions && az account show --query tenantId -o tsv`

---

## Passo 9: Script de Validação do Ambiente

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
