"""
Cliente de console para testar o agente declarativo criado.

Usa a nova experiencia Foundry (azure-ai-projects 2.x + OpenAI Responses API).

Uso:
    python test_agent.py
    python test_agent.py --agent-name fin-market-declarative

Exemplos de perguntas:
    - Qual e a cotacao da PETR4?
    - Como esta o cambio USD/BRL hoje?
    - Me de um resumo do mercado brasileiro
"""

import argparse
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT",
)
DEFAULT_AGENT_NAME = "fin-market-declarative"


def test_agent(endpoint, agent_name):
    """Testa o agente declarativo via Responses API."""
    credential = DefaultAzureCredential()
    project_client = AIProjectClient(
        endpoint=endpoint,
        credential=credential,
    )

    # Obter OpenAI client a partir do projeto
    openai_client = project_client.get_openai_client()

    # Criar conversa para chat multi-turn
    conversation = openai_client.conversations.create()
    print(f"🤖 Agente: {agent_name}")
    print(f"💬 Conversa criada: {conversation.id}")
    print(f"\nDigite suas perguntas (ou 'sair' para encerrar):\n")

    # Loop de conversa
    while True:
        user_input = input("Voce: ").strip()

        if user_input.lower() in ("sair", "quit", "exit"):
            print("\n👋 Encerrando conversa. Ate logo!")
            break

        if not user_input:
            continue

        print("\nAgente: ", end="", flush=True)

        try:
            # Enviar mensagem via Responses API com agent_reference
            response = openai_client.responses.create(
                conversation=conversation.id,
                extra_body={
                    "agent": {
                        "name": agent_name,
                        "type": "agent_reference",
                    }
                },
                input=user_input,
            )

            print(response.output_text)
            print("\n" + "─" * 60 + "\n")

        except Exception as e:
            print(f"\n❌ Erro ao processar mensagem: {e}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Testa agente declarativo de mercado financeiro"
    )
    parser.add_argument(
        "--endpoint", default=DEFAULT_ENDPOINT, help="AI Project endpoint"
    )
    parser.add_argument(
        "--agent-name", default=DEFAULT_AGENT_NAME, help="Nome do agente"
    )
    args = parser.parse_args()

    test_agent(args.endpoint, args.agent_name)


if __name__ == "__main__":
    main()
