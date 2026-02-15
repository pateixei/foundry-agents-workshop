#!/bin/bash
# Deployment Script - Workshop Agent365
# This script provisions all required Azure infrastructure
# Bash equivalent of deploy.ps1 for Linux / WSL / macOS

set -e

# ─── Defaults ────────────────────────────────────────────────
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
LOCATION="eastus"
DEPLOYMENT_NAME="main"
PARAMETERS_FILE="main.bicepparam"
SKIP_VALIDATION=false
WHAT_IF=false

# ─── Colors ──────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
fail() { echo -e "  ${RED}[X]${NC} $1"; }
info() { echo -e "  ${CYAN}->$NC $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }

# ─── Parse arguments ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --subscription)       SUBSCRIPTION_ID="$2"; shift 2 ;;
        --resource-group)     RESOURCE_GROUP="$2"; shift 2 ;;
        --location)           LOCATION="$2"; shift 2 ;;
        --deployment-name)    DEPLOYMENT_NAME="$2"; shift 2 ;;
        --parameters-file)    PARAMETERS_FILE="$2"; shift 2 ;;
        --skip-validation)    SKIP_VALIDATION=true; shift ;;
        --what-if)            WHAT_IF=true; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --subscription ID       Azure subscription ID"
            echo "  --resource-group NAME   Resource group name (default: from params file or rg-agent365-workshop)"
            echo "  --location REGION       Azure region (default: eastus)"
            echo "  --deployment-name NAME  Deployment name (default: main)"
            echo "  --parameters-file FILE  Bicep parameters file (default: main.bicepparam)"
            echo "  --skip-validation       Skip post-deployment validation"
            echo "  --what-if               Simulate deployment without executing"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ─── Banner ──────────────────────────────────────────────────
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   DEPLOYMENT WORKSHOP AGENT365${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ─── [1/8] Check Azure CLI ──────────────────────────────────
echo -e "${YELLOW}[1/8] Checking Azure CLI...${NC}"
if command -v az &>/dev/null; then
    AZ_VERSION=$(az version --query '"azure-cli"' -o tsv 2>/dev/null)
    ok "Azure CLI version $AZ_VERSION found"
else
    fail "Azure CLI not found"
    echo -e "\nInstall: https://aka.ms/InstallAzureCLI\n"
    exit 1
fi

# ─── [2/8] Check authentication ─────────────────────────────
echo -e "\n${YELLOW}[2/8] Checking Azure authentication...${NC}"
ACCOUNT_JSON=$(az account show --output json 2>/dev/null) || {
    fail "Not authenticated with Azure"
    echo -e "\nRun: az login\n"
    exit 1
}

ACCOUNT_NAME=$(echo "$ACCOUNT_JSON" | jq -r '.name')
ACCOUNT_ID=$(echo "$ACCOUNT_JSON" | jq -r '.id')
ACCOUNT_USER=$(echo "$ACCOUNT_JSON" | jq -r '.user.name')

ok "Authenticated as: $ACCOUNT_USER"
info "Active subscription: $ACCOUNT_NAME ($ACCOUNT_ID)"

if [[ -n "$SUBSCRIPTION_ID" && "$ACCOUNT_ID" != "$SUBSCRIPTION_ID" ]]; then
    info "Switching to subscription: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
    ACCOUNT_JSON=$(az account show --output json)
    ACCOUNT_NAME=$(echo "$ACCOUNT_JSON" | jq -r '.name')
    ok "Subscription changed to: $ACCOUNT_NAME"
elif [[ -z "$SUBSCRIPTION_ID" ]]; then
    SUBSCRIPTION_ID="$ACCOUNT_ID"
fi

# ─── [3/8] Check CLI extensions ─────────────────────────────
echo -e "\n${YELLOW}[3/8] Checking Azure CLI extensions...${NC}"
REQUIRED_EXTENSIONS=("containerapp" "ml")

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if az extension list --query "[?name=='$ext']" -o tsv 2>/dev/null | grep -q "$ext"; then
        ok "Extension '$ext' installed"
    else
        warn "Extension '$ext' not found. Installing..."
        az extension add --name "$ext" --only-show-errors 2>/dev/null
        ok "Extension '$ext' installed"
    fi
done

# ─── Read ResourceGroupName from parameters file if not provided ──
if [[ -z "$RESOURCE_GROUP" && -f "$PARAMETERS_FILE" ]]; then
    RG_MATCH=$(grep -oP "param\s+resourceGroupName\s*=\s*'([^']+)'" "$PARAMETERS_FILE" 2>/dev/null | grep -oP "'([^']+)'" | tr -d "'" | head -1)
    if [[ -n "$RG_MATCH" ]]; then
        RESOURCE_GROUP="$RG_MATCH"
        info "ResourceGroupName from parameters file: $RESOURCE_GROUP"
    fi
fi

if [[ -z "$RESOURCE_GROUP" ]]; then
    RESOURCE_GROUP="rg-agent365-workshop"
    info "Using default ResourceGroupName: $RESOURCE_GROUP"
fi

# ─── [4/8] Check deployment files ───────────────────────────
echo -e "\n${YELLOW}[4/8] Checking deployment files...${NC}"
TEMPLATE_FILE="main.bicep"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    fail "File $TEMPLATE_FILE not found"
    exit 1
fi
ok "Template found: $TEMPLATE_FILE"

USE_PARAMS_FILE=false
if [[ ! -f "$PARAMETERS_FILE" ]]; then
    warn "Parameters file $PARAMETERS_FILE not found"
    info "Deploying without parameters file"
else
    ok "Parameters found: $PARAMETERS_FILE"
    USE_PARAMS_FILE=true
fi

# ─── [5/8] Create or verify Resource Group ───────────────────
echo -e "\n${YELLOW}[5/8] Checking Resource Group...${NC}"
RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP" 2>/dev/null)
if [[ "$RG_EXISTS" == "true" ]]; then
    ok "Resource Group '$RESOURCE_GROUP' already exists"
else
    info "Creating Resource Group '$RESOURCE_GROUP' in $LOCATION..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
    ok "Resource Group created"
fi

# ─── [6/8] Validate Bicep template ──────────────────────────
echo -e "\n${YELLOW}[6/8] Validating Bicep template...${NC}"
VALIDATE_CMD="az deployment group validate --resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE"
if [[ "$USE_PARAMS_FILE" == true ]]; then
    VALIDATE_CMD="$VALIDATE_CMD --parameters $PARAMETERS_FILE"
fi

if eval "$VALIDATE_CMD" --output json &>/dev/null; then
    ok "Bicep template validated successfully"
else
    fail "Template validation failed"
    eval "$VALIDATE_CMD" --output json
    exit 1
fi

# ─── [7/8] Execute deployment ────────────────────────────────
echo -e "\n${YELLOW}[7/8] Starting deployment...${NC}"

DEPLOY_BASE="az deployment group"
DEPLOY_PARAMS="--resource-group $RESOURCE_GROUP --template-file $TEMPLATE_FILE --name $DEPLOYMENT_NAME"
if [[ "$USE_PARAMS_FILE" == true ]]; then
    DEPLOY_PARAMS="$DEPLOY_PARAMS --parameters $PARAMETERS_FILE"
fi

if [[ "$WHAT_IF" == true ]]; then
    info "WhatIf mode — simulating deployment..."
    eval "$DEPLOY_BASE what-if $DEPLOY_PARAMS"
    echo -e "\n  ${CYAN}[i] Simulated. Run without --what-if to execute.${NC}"
    exit 0
fi

info "Resource Group: $RESOURCE_GROUP"
info "Location: $LOCATION"
info "Deployment Name: $DEPLOYMENT_NAME"
echo -e "\n  ${YELLOW}[!] Please wait... This may take 10-15 minutes.${NC}\n"

START_TIME=$(date +%s)

if eval "$DEPLOY_BASE create $DEPLOY_PARAMS --verbose"; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))

    echo -e "\n  ${GREEN}[OK] Deployment completed successfully!${NC}"
    echo -e "  ${CYAN}-> Elapsed time: ${MINUTES}m ${SECONDS}s${NC}"
else
    echo -e "\n  ${RED}[X] Deployment failed${NC}"
    exit 1
fi

# ─── [8/8] Get deployment outputs ────────────────────────────
echo -e "\n${YELLOW}[8/8] Getting deployment outputs...${NC}"

DEPLOYMENT_JSON=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --output json 2>/dev/null)

if [[ -n "$DEPLOYMENT_JSON" ]]; then
    OUTPUTS=$(echo "$DEPLOYMENT_JSON" | jq '.properties.outputs // empty')

    if [[ -n "$OUTPUTS" && "$OUTPUTS" != "null" ]]; then
        echo ""
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}         DEPLOYMENT OUTPUTS${NC}"
        echo -e "${CYAN}========================================${NC}"
        echo ""

        echo "$OUTPUTS" | jq -r 'to_entries[] | "\(.key): \(.value.value)"' | sort

        # Save outputs to file
        OUTPUTS_FILE="deployment-outputs-$(date +%Y%m%d-%H%M%S).json"
        echo "$OUTPUTS" | jq '.' > "$OUTPUTS_FILE"
        echo -e "\nOutputs saved to: $OUTPUTS_FILE"
    fi
fi

# ─── Run validation ──────────────────────────────────────────
if [[ "$SKIP_VALIDATION" != true ]]; then
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}         VALIDATING DEPLOYMENT${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    if [[ -f "./validate-deployment.sh" ]]; then
        echo -e "Running validation script...\n"
        bash ./validate-deployment.sh --resource-group "$RESOURCE_GROUP" --deployment-name "$DEPLOYMENT_NAME"
    else
        warn "Validation script not found"
        info "Run manually: ./validate-deployment.sh --resource-group $RESOURCE_GROUP"
    fi
else
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}Validation skipped (--skip-validation used)${NC}"
    echo -e "${CYAN}Run manually: ./validate-deployment.sh --resource-group $RESOURCE_GROUP${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
fi

# ─── Final summary ───────────────────────────────────────────
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the deployment outputs above"
echo "2. Implement the agents (lesson-1 through lesson-4)"
echo "3. Build and deploy Docker images"
echo "4. Test agents using the provided endpoints"
echo ""
