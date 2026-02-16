#!/bin/bash
# Deployment Validation Script - Workshop Agent365
# Validates that all resources were provisioned correctly
# Bash equivalent of validate-deployment.ps1 for Linux / WSL / macOS

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────
RESOURCE_GROUP=""
DEPLOYMENT_NAME="main"
VALIDATION_TIMEOUT=30
RETRY_WAIT=30
MAX_RETRIES=2

# ─── Colors ──────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
fail() { echo -e "  ${RED}[X]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }

# ─── Retry wrapper for az commands w/ timeout ────────────────
# Usage: result=$(az_with_retry <timeout_secs> az <args...>)
# Retries up to MAX_RETRIES times with RETRY_WAIT seconds between attempts on timeout.
az_with_retry() {
    local tmout="$1"; shift
    local attempt
    for attempt in $(seq 1 $((MAX_RETRIES + 1))); do
        local output
        output=$(timeout "$tmout" "$@" 2>/dev/null) && { echo "$output"; return 0; }
        local rc=$?
        # rc=124 means timeout killed the process; retry
        if [[ $rc -eq 124 && $attempt -le $MAX_RETRIES ]]; then
            echo -e "    ${YELLOW}Timeout on attempt $attempt/$((MAX_RETRIES + 1)). Waiting ${RETRY_WAIT}s before retrying...${NC}" >&2
            sleep "$RETRY_WAIT"
            continue
        fi
        # Non-timeout failure — return empty
        echo ""
        return $rc
    done
    echo ""
    return 124
}

# ─── Parse arguments ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-group)   RESOURCE_GROUP="$2"; shift 2 ;;
        --deployment-name)  DEPLOYMENT_NAME="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 --resource-group <name> [--deployment-name <name>]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}Error: --resource-group is required${NC}"
    echo "Usage: $0 --resource-group <name> [--deployment-name <name>]"
    exit 1
fi

# ─── Check dependencies ─────────────────────────────────────
if ! command -v jq &>/dev/null; then
    echo -e "${RED}Error: jq is required. Install with: sudo apt install -y jq${NC}"
    exit 1
fi

# ─── Tracking ────────────────────────────────────────────────
PASSED=0
TOTAL=0

add_result() {
    local resource="$1" check="$2" passed="$3" message="$4"
    TOTAL=$((TOTAL + 1))
    if [[ "$passed" == "true" ]]; then
        PASSED=$((PASSED + 1))
    fi
    RESULTS+=("{\"resource\":\"$resource\",\"check\":\"$check\",\"passed\":$passed,\"message\":\"$message\"}")
}

declare -a RESULTS=()

# ─── Banner ──────────────────────────────────────────────────
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   DEPLOYMENT VALIDATION - AGENT365${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "Resource Group: ${WHITE}$RESOURCE_GROUP${NC}"
echo -e "Deployment: ${WHITE}$DEPLOYMENT_NAME${NC}"
echo ""

# ─── [1/8] Resource Group ────────────────────────────────────
echo -e "${YELLOW}[1/8] Checking Resource Group...${NC}"
RG_JSON=$(az group show --name "$RESOURCE_GROUP" --output json 2>/dev/null) || {
    fail "Resource Group not found"
    add_result "Resource Group" "Existence" "false" "Not found"
    exit 1
}
RG_LOCATION=$(echo "$RG_JSON" | jq -r '.location')
ok "Resource Group found in: $RG_LOCATION"
add_result "Resource Group" "Existence" "true" "Found in $RG_LOCATION"

# ─── [2/8] Deployment outputs ────────────────────────────────
echo -e "\n${YELLOW}[2/8] Getting deployment outputs...${NC}"
DEPLOY_JSON=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --output json 2>/dev/null) || {
    fail "Could not retrieve deployment"
    add_result "Deployment" "Status" "false" "Not found"
    DEPLOY_JSON=""
}

OUTPUTS=""
if [[ -n "$DEPLOY_JSON" ]]; then
    PROV_STATE=$(echo "$DEPLOY_JSON" | jq -r '.properties.provisioningState')
    if [[ "$PROV_STATE" == "Succeeded" ]]; then
        ok "Deployment completed successfully"
        add_result "Deployment" "Status" "true" "Succeeded"
        OUTPUTS=$(echo "$DEPLOY_JSON" | jq '.properties.outputs // empty')
    else
        fail "Deployment state: $PROV_STATE"
        add_result "Deployment" "Status" "false" "State: $PROV_STATE"
    fi
fi

# Helper to get output value
get_output() {
    if [[ -n "$OUTPUTS" && "$OUTPUTS" != "null" ]]; then
        echo "$OUTPUTS" | jq -r ".$1.value // empty"
    fi
}

# ─── [3/8] Azure Container Registry ─────────────────────────
echo -e "\n${YELLOW}[3/8] Validating Azure Container Registry...${NC}"
ACR_NAME=$(get_output "acrName")
if [[ -n "$ACR_NAME" ]]; then
    ACR_JSON=$(az_with_retry "$VALIDATION_TIMEOUT" az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --output json) || ACR_JSON=""
    if [[ -n "$ACR_JSON" ]]; then
        ACR_STATE=$(echo "$ACR_JSON" | jq -r '.provisioningState')
        ACR_SERVER=$(echo "$ACR_JSON" | jq -r '.loginServer')
        if [[ "$ACR_STATE" == "Succeeded" ]]; then
            ok "ACR active: $ACR_SERVER"
            add_result "Container Registry" "Status" "true" "Active: $ACR_SERVER"
            
            ADMIN_ENABLED=$(echo "$ACR_JSON" | jq -r '.adminUserEnabled')
            if [[ "$ADMIN_ENABLED" == "true" ]]; then
                ok "Admin user enabled"
                add_result "Container Registry" "Admin User" "true" "Enabled"
            else
                warn "Admin user not enabled"
                add_result "Container Registry" "Admin User" "false" "Not enabled"
            fi
        else
            fail "ACR not active (state: $ACR_STATE)"
            add_result "Container Registry" "Status" "false" "State: $ACR_STATE"
        fi
    else
        warn "Timeout or error validating ACR"
        add_result "Container Registry" "Status" "false" "Timeout"
    fi
else
    warn "ACR name not found in deployment outputs"
    add_result "Container Registry" "Status" "false" "Not in outputs"
fi

# ─── [4/8] Log Analytics Workspace ──────────────────────────
echo -e "\n${YELLOW}[4/8] Validating Log Analytics Workspace...${NC}"
LOG_JSON=$(az_with_retry "$VALIDATION_TIMEOUT" az monitor log-analytics workspace list --resource-group "$RESOURCE_GROUP" --output json) || LOG_JSON="[]"
LOG_COUNT=$(echo "$LOG_JSON" | jq 'length')

if [[ "$LOG_COUNT" -gt 0 ]]; then
    LOG_NAME=$(echo "$LOG_JSON" | jq -r '.[0].name')
    LOG_ID=$(echo "$LOG_JSON" | jq -r '.[0].customerId')
    ok "Log Analytics Workspace found: $LOG_NAME"
    add_result "Log Analytics" "Existence" "true" "Workspace: $LOG_NAME"
else
    fail "Log Analytics Workspace not found"
    add_result "Log Analytics" "Existence" "false" "Not found"
fi

# ─── [5/8] Application Insights ─────────────────────────────
echo -e "\n${YELLOW}[5/8] Validating Application Insights...${NC}"
APPI_JSON=$(az_with_retry "$VALIDATION_TIMEOUT" az monitor app-insights component show --resource-group "$RESOURCE_GROUP" --output json) || APPI_JSON=""

if [[ -n "$APPI_JSON" && "$APPI_JSON" != "null" ]]; then
    APPI_NAME=$(echo "$APPI_JSON" | jq -r '.name // empty')
    if [[ -n "$APPI_NAME" ]]; then
        ok "Application Insights found: $APPI_NAME"
        add_result "Application Insights" "Existence" "true" "Active: $APPI_NAME"
    else
        fail "Application Insights not found"
        add_result "Application Insights" "Existence" "false" "Not found"
    fi
else
    fail "Application Insights not found"
    add_result "Application Insights" "Existence" "false" "Not found or timeout"
fi

# ─── [6/8] Container Apps Environment ───────────────────────
echo -e "\n${YELLOW}[6/8] Validating Container Apps Environment...${NC}"
CA_ENV_JSON=$(az_with_retry "$VALIDATION_TIMEOUT" az containerapp env list --resource-group "$RESOURCE_GROUP" --output json) || CA_ENV_JSON="[]"
CA_ENV_COUNT=$(echo "$CA_ENV_JSON" | jq 'length')

if [[ "$CA_ENV_COUNT" -gt 0 ]]; then
    CA_ENV_NAME=$(echo "$CA_ENV_JSON" | jq -r '.[0].name')
    CA_ENV_STATE=$(echo "$CA_ENV_JSON" | jq -r '.[0].properties.provisioningState // "Unknown"')
    if [[ "$CA_ENV_STATE" == "Succeeded" ]]; then
        ok "Container Apps Environment active: $CA_ENV_NAME"
        add_result "Container Apps Env" "Status" "true" "Active"
    else
        warn "Container Apps Environment provisioning: $CA_ENV_STATE"
        add_result "Container Apps Env" "Status" "false" "State: $CA_ENV_STATE"
    fi
else
    fail "Container Apps Environment not found"
    add_result "Container Apps Env" "Existence" "false" "Not found"
fi

# ─── [7/8] Microsoft Foundry account ────────────────────────
echo -e "\n${YELLOW}[7/8] Validating Microsoft Foundry account...${NC}"
AI_FOUNDRY_NAME=$(get_output "aiFoundryName")
EXPECTED_MODEL=$(get_output "aiModelDeployment")

if [[ -n "$AI_FOUNDRY_NAME" ]]; then
    AI_JSON=$(az_with_retry "$VALIDATION_TIMEOUT" az cognitiveservices account show \
        --name "$AI_FOUNDRY_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --output json) || AI_JSON=""

    if [[ -n "$AI_JSON" ]]; then
        AI_STATE=$(echo "$AI_JSON" | jq -r '.properties.provisioningState')
        AI_ENDPOINT=$(echo "$AI_JSON" | jq -r '.properties.endpoint')
        if [[ "$AI_STATE" == "Succeeded" ]]; then
            ok "Foundry account active: $AI_FOUNDRY_NAME"
            add_result "Microsoft Foundry" "Status" "true" "Active: $AI_ENDPOINT"

            # Check model deployment
            DEPLOYS_JSON=$(az_with_retry "$VALIDATION_TIMEOUT" az cognitiveservices account deployment list \
                --name "$AI_FOUNDRY_NAME" \
                --resource-group "$RESOURCE_GROUP" \
                --output json) || DEPLOYS_JSON="[]"

            MODEL_FOUND=$(echo "$DEPLOYS_JSON" | jq -r "[.[] | select(.name==\"$EXPECTED_MODEL\")] | length")
            if [[ "$MODEL_FOUND" -gt 0 ]]; then
                ok "Model deployment '$EXPECTED_MODEL' found"
                add_result "Model Deployment" "Existence" "true" "$EXPECTED_MODEL"
            else
                fail "Model deployment '$EXPECTED_MODEL' not found"
                add_result "Model Deployment" "Existence" "false" "Not found"
            fi
        else
            fail "Foundry account not active (state: $AI_STATE)"
            add_result "Microsoft Foundry" "Status" "false" "State: $AI_STATE"
        fi
    else
        warn "Timeout or error validating Foundry account"
        add_result "Microsoft Foundry" "Status" "false" "Timeout"
    fi
else
    warn "Foundry account name not found in outputs"
    add_result "Microsoft Foundry" "Status" "false" "Not in outputs"
fi

# ─── [8/8] Microsoft Foundry project ────────────────────────
echo -e "\n${YELLOW}[8/8] Validating Microsoft Foundry project...${NC}"
AI_PROJECT_NAME=$(get_output "aiProjectName")

if [[ -n "$AI_PROJECT_NAME" && -n "$AI_FOUNDRY_NAME" ]]; then
    SUB_ID=$(az account show --query id -o tsv)
    PROJECT_RES_ID="/subscriptions/$SUB_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/$AI_FOUNDRY_NAME/projects/$AI_PROJECT_NAME"
    
    PROJECT_JSON=$(az_with_retry 45 az resource show --ids "$PROJECT_RES_ID" --api-version 2025-06-01 --output json) || PROJECT_JSON=""

    if [[ -n "$PROJECT_JSON" ]]; then
        ok "Foundry project active: $AI_PROJECT_NAME"
        add_result "Microsoft Foundry Project" "Status" "true" "$AI_PROJECT_NAME"
    else
        fail "Foundry project not found"
        add_result "Microsoft Foundry Project" "Status" "false" "Not found"
    fi
else
    warn "Project name not available in outputs"
    add_result "Microsoft Foundry Project" "Status" "false" "Not in outputs"
fi

# ─── Final Report ────────────────────────────────────────────
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}         VALIDATION REPORT${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

FAILED=$((TOTAL - PASSED))
if [[ "$TOTAL" -gt 0 ]]; then
    SUCCESS_RATE=$(( (PASSED * 100) / TOTAL ))
else
    SUCCESS_RATE=0
fi

echo -e "Total checks: ${WHITE}$TOTAL${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [[ "$SUCCESS_RATE" -ge 90 ]]; then
    echo -e "Success rate: ${GREEN}${SUCCESS_RATE}%${NC}"
elif [[ "$SUCCESS_RATE" -ge 70 ]]; then
    echo -e "Success rate: ${YELLOW}${SUCCESS_RATE}%${NC}"
else
    echo -e "Success rate: ${RED}${SUCCESS_RATE}%${NC}"
fi

# Save report as JSON
REPORT_FILE="validation-report-$(date +%Y%m%d-%H%M%S).json"
echo "[" > "$REPORT_FILE"
for i in "${!RESULTS[@]}"; do
    if [[ $i -gt 0 ]]; then echo "," >> "$REPORT_FILE"; fi
    echo "${RESULTS[$i]}" >> "$REPORT_FILE"
done
echo "]" >> "$REPORT_FILE"
echo -e "\nReport saved to: $REPORT_FILE"

# ─── Important outputs ───────────────────────────────────────
if [[ -n "$OUTPUTS" && "$OUTPUTS" != "null" ]]; then
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}         IMPORTANT INFORMATION${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    OAI_ENDPOINT=$(get_output "openAIEndpoint")
    ACR_SERVER_OUT=$(get_output "acrLoginServer")
    FOUNDRY_NAME_OUT=$(get_output "aiFoundryName")
    FOUNDRY_ENDPOINT=$(get_output "aiFoundryEndpoint")
    PROJECT_NAME_OUT=$(get_output "aiProjectName")
    PROJECT_ENDPOINT=$(get_output "aiProjectEndpoint")

    [[ -n "$OAI_ENDPOINT" ]]      && echo -e "${YELLOW}AI Services Endpoint:${NC}\n  $OAI_ENDPOINT\n"
    [[ -n "$ACR_SERVER_OUT" ]]    && echo -e "${YELLOW}ACR Login Server:${NC}\n  $ACR_SERVER_OUT\n"
    [[ -n "$FOUNDRY_NAME_OUT" ]]  && echo -e "${YELLOW}Microsoft Foundry Name:${NC}\n  $FOUNDRY_NAME_OUT\n"
    [[ -n "$FOUNDRY_ENDPOINT" ]]  && echo -e "${YELLOW}Microsoft Foundry Endpoint:${NC}\n  $FOUNDRY_ENDPOINT\n"
    [[ -n "$PROJECT_NAME_OUT" ]]  && echo -e "${YELLOW}Microsoft Foundry Project:${NC}\n  $PROJECT_NAME_OUT\n"
    [[ -n "$PROJECT_ENDPOINT" ]]  && echo -e "${YELLOW}Project Endpoint:${NC}\n  $PROJECT_ENDPOINT\n"
fi

# ─── Exit code ───────────────────────────────────────────────
if [[ "$SUCCESS_RATE" -ge 90 ]]; then
    echo -e "\n${GREEN}[OK] VALIDATION COMPLETED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}All main resources were provisioned correctly.${NC}\n"
    exit 0
elif [[ "$SUCCESS_RATE" -ge 70 ]]; then
    echo -e "\n${YELLOW}[!] VALIDATION COMPLETED WITH WARNINGS${NC}"
    echo -e "${YELLOW}Most resources provisioned, but some items need attention.${NC}\n"
    exit 0
else
    echo -e "\n${RED}[X] VALIDATION FAILED${NC}"
    echo -e "${RED}Multiple resources were not provisioned correctly. Review errors above.${NC}\n"
    exit 1
fi
