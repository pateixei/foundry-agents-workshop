"""
Lab 1 - Task 3: Create Test Client

Complete the TODOs to implement an interactive chat client
that tests the declarative agent you created.
"""

import argparse
import os
import sys

# TODO: Import AgentsClient from azure.ai.agents
# TODO: Import MessageRole from azure.ai.agents.models
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://YOUR-FOUNDRY.services.ai.azure.com/api/projects/YOUR-PROJECT",
)
DEFAULT_AGENT_NAME = "fin-market-declarative"


def test_agent(endpoint, agent_name):
    """Test the declarative agent via SDK."""
    credential = DefaultAzureCredential()

    # TODO: Create AgentsClient with endpoint and credential
    client = None

    # TODO: List agents and find the one matching agent_name
    # Use client.list_agents() and iterate to find by name
    agent = None

    if not agent:
        print(f"Agent '{agent_name}' not found")
        sys.exit(1)

    print(f"Connected to agent: {agent.name} (ID: {agent.id})")

    # TODO: Create a conversation thread using client.threads.create()
    thread = None

    print(f"Thread created: {thread.id}")
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
            # TODO: Send message using client.messages.create()
            # Parameters: thread_id, role="user", content=user_input

            # TODO: Run the agent using client.runs.create_and_process()
            # Parameters: thread_id, agent_id=agent.id

            # TODO: Get response using client.messages.get_last_message_text_by_role()
            # Parameters: thread_id, role=MessageRole.AGENT
            response = None

            if response:
                print(response.text.value)
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
