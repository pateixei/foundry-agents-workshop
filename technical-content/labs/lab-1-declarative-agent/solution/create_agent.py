"""
Lab 1 Solution - Create a Declarative Agent

Creates a declarative financial advisor agent in Azure AI Foundry.
"""

import argparse
import os

from azure.ai.agents import AIProjectClient
from azure.ai.agents.models import PromptAgentDefinition
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT",
)
DEFAULT_MODEL = os.environ.get("MODEL_DEPLOYMENT_NAME", "gpt-4.1")
DEFAULT_AGENT_NAME = "fin-market-declarative"

SYSTEM_PROMPT = (
    "Voce e um assistente especialista em mercado financeiro brasileiro e internacional.\n\n"
    "## Seu Objetivo\n"
    "Ajudar investidores e profissionais do mercado financeiro com informacoes e analises "
    "sobre acoes, cambio, indices e tendencias de mercado.\n\n"
    "## Suas Capacidades\n"
    "- Fornecer informacoes sobre acoes da B3 (PETR4, VALE3, ITUB4, etc.) e mercados globais\n"
    "- Explicar taxas de cambio e suas tendencias\n"
    "- Fornecer resumos e analises de mercado (Brasil, EUA, Europa, Global)\n"
    "- Explicar conceitos financeiros de forma clara e acessivel\n\n"
    "## Diretrizes\n"
    "- Sempre responda em portugues brasileiro\n"
    "- Explique que voce nao tem acesso a dados em tempo real, mas pode fornecer "
    "informacoes gerais e educativas sobre o mercado\n"
    "- Inclua disclaimer: 'Esta informacao e apenas para fins educativos e nao "
    "constitui recomendacao de investimento'\n"
    "- Formate valores no padrao brasileiro (R$ 1.234,56)\n"
    "- Seja objetivo e direto nas respostas\n"
)


def create_declarative_agent(endpoint, agent_name, model):
    """Create a declarative agent in Foundry using PromptAgentDefinition."""
    credential = DefaultAzureCredential()
    project_client = AIProjectClient(
        endpoint=endpoint,
        credential=credential,
    )

    agent = project_client.agents.create_version(
        agent_name=agent_name,
        definition=PromptAgentDefinition(
            model=model,
            instructions=SYSTEM_PROMPT,
        ),
    )

    print(f"Agente criado com sucesso!")
    print(f"  Nome:    {agent.name}")
    print(f"  Versao:  {agent.version}")
    print(f"  ID:      {agent.id}")
    print(f"\nO agente esta visivel e editavel no portal do Foundry.")
    print(f"Acesse: https://ai.azure.com/ para editar instructions, model, etc.")

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
