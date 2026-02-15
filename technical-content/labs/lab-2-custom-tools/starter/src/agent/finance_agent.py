"""
Lab 2 - Task 2: Create MAF Finance Agent

Complete the TODOs to create an agent using Microsoft Agent Framework.
"""

import os

# TODO: Import AzureAIClient from agent_framework.azure
# TODO: Import DefaultAzureCredential from azure.identity.aio

from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary

# TODO: Define SYSTEM_PROMPT for financial advisor
# Should include: role, language (PT-BR), capabilities, disclaimers
SYSTEM_PROMPT = ""

# TODO: Create TOOLS list with the imported tool functions
TOOLS = []


async def create_finance_agent():
    """Creates and returns the MAF finance agent."""
    project_endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    model_deployment = os.environ["FOUNDRY_MODEL_DEPLOYMENT_NAME"]

    # TODO: Create DefaultAzureCredential
    credential = None

    agent_version = os.environ.get("HOSTED_AGENT_VERSION")

    # TODO: Create AzureAIClient with project_endpoint, model_deployment,
    #       credential, and agent_version
    client = None

    # TODO: Create agent with name, instructions (SYSTEM_PROMPT), and tools
    agent = None

    return agent, credential
