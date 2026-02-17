"""
Lab 1 - Task 3: Create Test Client

Complete the TODOs to implement an interactive chat client
that tests the declarative agent using the OpenAI Responses API.
"""

import argparse
import os
import sys

# TODO: Import AIProjectClient from azure.ai.projects
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT",
)
DEFAULT_AGENT_NAME = "fin-market-declarative"


def test_agent(endpoint, agent_name):
    """Test the declarative agent via the Responses API."""
    credential = DefaultAzureCredential()

    # TODO: Create AIProjectClient with endpoint and credential
    project_client = None

    # TODO: Get OpenAI client from the project using project_client.get_openai_client()
    openai_client = None

    # TODO: Create a conversation using openai_client.conversations.create()
    conversation = None

    print(f"Agent: {agent_name}")
    print(f"Conversation: {conversation.id}")
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
            # TODO: Send message using openai_client.responses.create()
            # Parameters:
            #   conversation=conversation.id,
            #   extra_body={"agent": {"name": agent_name, "type": "agent_reference"}},
            #   input=user_input,
            response = None

            if response:
                print(response.output_text)
            else:
                print("(no response)")

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
