"""
Lab 1 Solution - Test Agent Client

Interactive console client for testing the declarative agent.
Uses the new Foundry experience (azure-ai-projects 2.x + OpenAI Responses API).
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
    "https://aihub-workshop.services.ai.azure.com/api/projects/aiprj-workshp",
)
DEFAULT_AGENT_NAME = "fin-market-declarative"


def test_agent(endpoint, agent_name):
    """Test the declarative agent via the new Foundry Responses API."""
    credential = DefaultAzureCredential()
    project_client = AIProjectClient(
        endpoint=endpoint,
        credential=credential,
    )

    # Get OpenAI client from the project
    openai_client = project_client.get_openai_client()

    # Create a conversation for multi-turn chat
    conversation = openai_client.conversations.create()
    print(f"Conversation created: {conversation.id}")
    print(f"Agent: {agent_name}")
    print(f"\nType your questions (or 'sair' to exit):\n")

    while True:
        user_input = input("Voce: ").strip()

        if user_input.lower() in ("sair", "quit", "exit"):
            print("\nBye!")
            break

        if not user_input:
            continue

        print("\nAgente: ", end="", flush=True)

        try:
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
            print("\n" + "-" * 60 + "\n")

        except Exception as e:
            print(f"\nError: {e}\n")


def main():
    parser = argparse.ArgumentParser(description="Test declarative financial agent")
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT, help="AI Project endpoint")
    parser.add_argument("--agent-name", default=DEFAULT_AGENT_NAME, help="Agent name")
    args = parser.parse_args()

    test_agent(args.endpoint, args.agent_name)


if __name__ == "__main__":
    main()
