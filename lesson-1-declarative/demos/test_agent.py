"""
Cliente de console para testar o agente declarativo criado.

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

from azure.ai.agents import AgentsClient
from azure.ai.agents.models import MessageRole
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "https://ai-foundry001.services.ai.azure.com/api/projects/ag365-prj001",
)
DEFAULT_AGENT_NAME = "fin-market-declarative"


def test_agent(endpoint, agent_name):
    """Testa o agente declarativo via SDK."""
    credential = DefaultAzureCredential()
    client = AgentsClient(
        endpoint=endpoint,
        credential=credential,
    )

    # Obter o agente pelo nome
    try:
        agents = client.list_agents()
        agent = None
        for a in agents:
            if a.name == agent_name:
                agent = a
                break

        if not agent:
            print(f"❌ Agente '{agent_name}' nao encontrado")
            print(f"\nAgentes disponiveis:")
            for a in agents:
                print(f"  - {a.name}")
            sys.exit(1)

        print(f"🤖 Conectado ao agente: {agent.name} (ID: {agent.id})")
    except Exception as e:
        print(f"❌ Erro ao buscar agente '{agent_name}': {e}")
        print(f"\nVerifique se o agente foi criado com create_agent.py")
        sys.exit(1)

    # Criar thread de conversa
    thread = client.threads.create()
    print(f"💬 Thread criada: {thread.id}")
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

        # Enviar mensagem e obter resposta
        try:
            # Criar mensagem na thread
            client.messages.create(
                thread_id=thread.id,
                role="user",
                content=user_input,
            )

            # Executar o agente na thread
            run = client.runs.create_and_process(
                thread_id=thread.id,
                agent_id=agent.id,
            )

            # Verificar se run completou com sucesso
            if run.status != "completed":
                print(f"❌ Run falhou com status: {run.status}")
                if run.last_error:
                    print(f"Erro: {run.last_error}")
                print()
                continue

            # Obter ultima resposta do assistente
            response = client.messages.get_last_message_text_by_role(
                thread_id=thread.id,
                role=MessageRole.AGENT,
            )
            if response:
                print(response.text.value)
            else:
                print("(sem resposta)")

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
