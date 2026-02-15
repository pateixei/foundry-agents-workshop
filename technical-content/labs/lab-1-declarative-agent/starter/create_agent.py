"""
Lab 1 - Task 2: Create a Declarative Agent

Complete the TODOs to create a declarative financial advisor agent
in Azure AI Foundry using the azure-ai-agents SDK.
"""

import argparse
import os

# TODO: Import AIProjectClient from azure.ai.agents
# TODO: Import PromptAgentDefinition from azure.ai.agents.models
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT",
)
DEFAULT_MODEL = os.environ.get("MODEL_DEPLOYMENT_NAME", "gpt-4.1")
DEFAULT_AGENT_NAME = "fin-market-declarative"

# TODO: Define SYSTEM_PROMPT for financial advisor behavior
# The prompt should:
# - Define the agent's role (financial market expert)
# - Set language to Brazilian Portuguese
# - Include disclaimer about educational-only information
# - Specify capabilities (stocks, exchange rates, market summaries)
SYSTEM_PROMPT = ""


def create_declarative_agent(endpoint, agent_name, model):
    """Create a declarative agent in Foundry using PromptAgentDefinition."""
    credential = DefaultAzureCredential()

    # TODO: Create AIProjectClient with endpoint and credential
    project_client = None

    # TODO: Create agent using project_client.agents.create_version()
    # Pass agent_name and a PromptAgentDefinition with model and instructions
    agent = None

    print(f"Agente criado com sucesso!")
    print(f"  Nome:    {agent.name}")
    print(f"  Versao:  {agent.version}")
    print(f"  ID:      {agent.id}")

    return agent


def main():
    parser = argparse.ArgumentParser(
        description="Cria agente declarativo de mercado financeiro no Foundry"
    )
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT, help="AI Project endpoint")
    parser.add_argument("--name", default=DEFAULT_AGENT_NAME, help="Nome do agente")
    parser.add_argument("--model", default=DEFAULT_MODEL, help="Model deployment name")
    args = parser.parse_args()

    print(f"Endpoint: {args.endpoint}")
    print(f"Agente:   {args.name}")
    print(f"Modelo:   {args.model}")
    print()

    create_declarative_agent(args.endpoint, args.name, args.model)


if __name__ == "__main__":
    main()
