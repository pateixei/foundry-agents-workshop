"""
Lab 1 Solution - Test Agent Client

Interactive console client for testing the declarative agent.
"""

import argparse
import os
import sys

from azure.ai.agents import AgentsClient
from azure.ai.agents.models import MessageRole
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://aihub-workshop.services.ai.azure.com/api/projects/aiprj-workshp",
)
DEFAULT_AGENT_NAME = "fin-market-declarative"


def test_agent(endpoint, agent_name):
    """Test the declarative agent via SDK."""
    credential = DefaultAzureCredential()
    client = AgentsClient(
        endpoint=endpoint,
        credential=credential,
    )

    # Find agent by name
    try:
        agents = client.list_agents()
        agent = None
        for a in agents:
            if a.name == agent_name:
                agent = a
                break

        if not agent:
            print(f"Agent '{agent_name}' not found")
            agents = client.list_agents()
            print(f"\nAvailable agents:")
            for a in agents:
                print(f"  - {a.name}")
            sys.exit(1)

        print(f"Connected to agent: {agent.name} (ID: {agent.id})")
    except Exception as e:
        print(f"Error finding agent '{agent_name}': {e}")
        sys.exit(1)

    # Create conversation thread
    thread = client.threads.create()
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
            client.messages.create(
                thread_id=thread.id,
                role="user",
                content=user_input,
            )

            run = client.runs.create_and_process(
                thread_id=thread.id,
                agent_id=agent.id,
            )

            if run.status != "completed":
                print(f"Run failed with status: {run.status}")
                if run.last_error:
                    print(f"Error: {run.last_error}")
                print()
                continue

            response = client.messages.get_last_message_text_by_role(
                thread_id=thread.id,
                role=MessageRole.AGENT,
            )
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
