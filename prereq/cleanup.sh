#!/bin/bash
# Cleanup Script - Workshop Agent365
# This script removes the resource group and all child resources
# Purges soft-deleted Cognitive Services (AI Foundry) resources by default

set -e

# ─── Defaults ────────────────────────────────────────────────
RESOURCE_GROUP=""
PARAMETERS_FILE="main.bicepparam"
PURGE=true
SKIP_CONFIRM=false

# ─── Colors ──────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
fail() { echo -e "  ${RED}[X]${NC} $1"; }
info() { echo -e "  ${CYAN}->$NC $1"; }
warn() { echo -e "  ${YELLOW}[!]${NC} $1"; }

# ─── Parse arguments ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-group)     RESOURCE_GROUP="$2"; shift 2 ;;
        --parameters-file)    PARAMETERS_FILE="$2"; shift 2 ;;
        --no-purge)            PURGE=false; shift ;;
        --yes)                SKIP_CONFIRM=true; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --resource-group NAME   Resource group name (default: from params file)"
            echo "  --parameters-file FILE  Bicep parameters file (default: main.bicepparam)"
            echo "  --no-purge              Skip purging soft-deleted Cognitive Services resources"
            echo "  --yes                   Skip confirmation prompt"
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
echo -e "${RED}========================================${NC}"
echo -e "${RED}   CLEANUP WORKSHOP AGENT365${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# ─── Read ResourceGroupName from parameters file if not provided ──
if [[ -z "$RESOURCE_GROUP" && -f "$PARAMETERS_FILE" ]]; then
    RG_MATCH=$(grep -oP "param\s+resourceGroupName\s*=\s*'([^']+)'" "$PARAMETERS_FILE" 2>/dev/null | grep -oP "'([^']+)'" | tr -d "'" | head -1)
    if [[ -n "$RG_MATCH" ]]; then
        RESOURCE_GROUP="$RG_MATCH"
        info "ResourceGroupName from parameters file: $RESOURCE_GROUP"
    fi
fi

if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}Error: --resource-group is required (or set it in $PARAMETERS_FILE)${NC}"
    exit 1
fi

# ─── Check if Resource Group exists ─────────────────────────
echo -e "${YELLOW}Checking Resource Group...${NC}"
if ! az group show --name "$RESOURCE_GROUP" --output none 2>/dev/null; then
    echo -e "${YELLOW}Resource Group '$RESOURCE_GROUP' not found. Nothing to clean up.${NC}"
    exit 0
fi
ok "Resource Group '$RESOURCE_GROUP' found"

# ─── List resources in the group ─────────────────────────────
echo -e "\n${YELLOW}Resources in group '$RESOURCE_GROUP':${NC}"
az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type}" --output table 2>/dev/null || true

# ─── Collect Cognitive Services account names for purge ──────
CS_ACCOUNTS=""
if [[ "$PURGE" == "true" ]]; then
    CS_ACCOUNTS=$(az resource list --resource-group "$RESOURCE_GROUP" \
        --query "[?type=='Microsoft.CognitiveServices/accounts'].name" \
        --output tsv 2>/dev/null) || CS_ACCOUNTS=""
    LOCATION=$(az group show --name "$RESOURCE_GROUP" --query "location" --output tsv 2>/dev/null) || LOCATION=""
fi

# ─── Confirmation ────────────────────────────────────────────
echo ""
echo -e "${RED}WARNING: This will permanently delete the resource group '$RESOURCE_GROUP' and ALL its resources.${NC}"
if [[ "$PURGE" == "true" && -n "$CS_ACCOUNTS" ]]; then
    echo -e "${RED}The following Cognitive Services accounts will also be PURGED (unrecoverable):${NC}"
    for acct in $CS_ACCOUNTS; do
        echo -e "  ${RED}- $acct${NC}"
    done
fi
echo ""

if [[ "$SKIP_CONFIRM" != "true" ]]; then
    read -rp "Are you sure you want to proceed? (yes/no): " ANSWER
    if [[ "$ANSWER" != "yes" ]]; then
        echo -e "${YELLOW}Cleanup cancelled.${NC}"
        exit 0
    fi
fi

# ─── Delete Resource Group ───────────────────────────────────
echo -e "\n${YELLOW}[1/2] Deleting Resource Group '$RESOURCE_GROUP'...${NC}"
echo -e "      ${CYAN}(This may take several minutes)${NC}"
az group delete --name "$RESOURCE_GROUP" --yes --no-wait false 2>/dev/null
ok "Resource Group '$RESOURCE_GROUP' deleted"

# ─── Purge Cognitive Services (soft-delete) ──────────────────
if [[ "$PURGE" == "true" && -n "$CS_ACCOUNTS" && -n "$LOCATION" ]]; then
    echo -e "\n${YELLOW}[2/2] Purging soft-deleted Cognitive Services accounts...${NC}"
    for acct in $CS_ACCOUNTS; do
        info "Purging '$acct' in '$LOCATION'..."
        az cognitiveservices account purge \
            --name "$acct" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" 2>/dev/null && \
            ok "Purged '$acct'" || \
            warn "Could not purge '$acct' (may already be purged or not in soft-delete state)"
    done
else
    echo -e "\n${YELLOW}[2/2] Skipping Cognitive Services purge (remove --no-purge to enable)${NC}"
fi

# ─── Done ────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   CLEANUP COMPLETED${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
if [[ "$PURGE" != "true" ]]; then
    echo -e "${YELLOW}Note: Cognitive Services resources may remain in soft-deleted state for 48 hours.${NC}"
    echo -e "${YELLOW}To purge them, re-run without --no-purge${NC}"
fi
