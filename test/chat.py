"""
Chat interativo com os agentes de mercado financeiro do workshop.

Consolidacao dos testes das 3 licoes em uma unica interface de chat.
Selecione a licao via --lesson e converse em modo interativo com o agente.

Uso:
    python chat.py --lesson 1          # Declarativo
    python chat.py --lesson 2          # Hosted MAF
    python chat.py --lesson 3          # Hosted LangGraph
    python chat.py --lesson 4          # ACA Connected (auto-resolve endpoint)
    python chat.py --lesson 1 --once "Qual a cotacao da PETR4?"

Requer: pip install azure-identity requests python-dotenv
"""

import argparse
import json
import os
import subprocess
import sys

import requests
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

load_dotenv(override=True)

# ── Configuracao dos agentes por licao ────────────────────────────
DEFAULT_ENDPOINT = os.environ.get(
    "PROJECT_ENDPOINT",
    "",  # Defina via env var ou --endpoint
)

ACA_ENDPOINT = os.environ.get(
    "ACA_ENDPOINT",
    "",  # Resolvido automaticamente via az CLI se nao informado
)

LESSONS = {
    1: {
        "name": os.environ.get("LESSON1_AGENT_NAME", "fin-market-declarative"),
        "version": None,  # Declarativo nao precisa de version
        "type": "declarative",
        "description": "Agente Declarativo (Prompt-Based)",
    },
    2: {
        "name": os.environ.get("LESSON2_AGENT_NAME", "fin-market-agent"),
        "version": os.environ.get("LESSON2_AGENT_VERSION", "1"),
        "type": "hosted",
        "description": "Agente Hosted (Microsoft Agent Framework)",
    },
    3: {
        "name": os.environ.get("LESSON3_AGENT_NAME", "lg-market-agent"),
        "version": os.environ.get("LESSON3_AGENT_VERSION", "3"),
        "type": "hosted",
        "description": "Agente Hosted (LangGraph)",
    },
    4: {
        "name": os.environ.get("LESSON4_AGENT_NAME", "aca-lg-agent"),
        "version": None,
        "type": "aca",
        "description": "Agente ACA (LangGraph - Connected Agent)",
        "endpoint": ACA_ENDPOINT,  # Endpoint proprio do ACA
    },
}


# ── Funcao de invocacao ──────────────────────────────────────────

def _resolve_aca_endpoint(app_name: str) -> str:
    """Resolve o FQDN do Container App via az CLI."""
    rg = os.environ.get("RESOURCE_GROUP", "rg-ai-agents-workshop")
    try:
        cmd = (
            f'az containerapp show --name {app_name} '
            f'--resource-group {rg} '
            f'--query "properties.configuration.ingress.fqdn" -o tsv'
        )
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=30, shell=True,
        )
        fqdn = result.stdout.strip()
        if fqdn:
            url = f"https://{fqdn}"
            print(f"  ACA endpoint resolvido: {url}")
            return url
    except Exception as exc:
        print(f"  AVISO: Nao foi possivel resolver ACA endpoint: {exc}", file=sys.stderr)

    print("ERRO: Informe --endpoint ou defina ACA_ENDPOINT no .env", file=sys.stderr)
    sys.exit(1)


def invoke_agent(endpoint, lesson_config, user_message):
    """Invoca o agente via REST.

    Adapta o body conforme o tipo do agente:
    - Declarativo: Responses API com name + type
    - Hosted: Responses API com id + name + version + type
    - ACA: chamada direta POST /chat (sem auth Foundry)
    """
    # ACA: chamada direta ao Container App (sem Foundry)
    if lesson_config["type"] == "aca":
        url = f"{endpoint}/chat"
        headers = {"Content-Type": "application/json"}
        body = {"message": user_message}
        resp = requests.post(url, headers=headers, json=body, timeout=120)
        resp.raise_for_status()
        return resp.json().get("response", "(sem resposta)")

    # Foundry agents (declarativo, hosted)
    credential = DefaultAzureCredential()
    token = credential.get_token("https://ai.azure.com/.default").token

    url = f"{endpoint}/openai/responses?api-version=2025-11-15-preview"

    agent_ref = {
        "name": lesson_config["name"],
        "type": "agent_reference",
    }

    if lesson_config["type"] == "hosted":
        agent_ref["id"] = lesson_config["name"]
        agent_ref["version"] = lesson_config["version"]

    body = {
        "input": [{"role": "user", "content": user_message}],
        "agent": agent_ref,
    }

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    resp = requests.post(url, headers=headers, json=body, timeout=120)
    resp.raise_for_status()
    data = resp.json()

    # Extrair texto da resposta
    for item in data.get("output", []):
        if item.get("type") == "message":
            for content in item.get("content", []):
                if content.get("type") == "output_text":
                    return content.get("text", "")

    return f"(sem texto na resposta - output: {data.get('output', [])})"


# ── Interface de chat ────────────────────────────────────────────

def print_header(lesson_num, config, endpoint):
    """Imprime o cabecalho do chat."""
    print()
    print("=" * 60)
    print(f"  Lesson {lesson_num} - {config['description']}")
    print(f"  Agente:   {config['name']}", end="")
    if config["version"]:
        print(f" v{config['version']}")
    else:
        print()
    print(f"  Endpoint: {endpoint}")
    print("=" * 60)
    print()
    print("Digite sua pergunta e pressione Enter.")
    print("Comandos: 'sair' ou 'quit' para encerrar.")
    print()


def chat_loop(endpoint, lesson_num, config):
    """Loop interativo de chat com o agente."""
    print_header(lesson_num, config, endpoint)

    while True:
        try:
            user_input = input("Voce > ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nAte logo!")
            break

        if not user_input:
            continue

        if user_input.lower() in ("sair", "quit", "exit", "q"):
            print("Ate logo!")
            break

        try:
            response = invoke_agent(endpoint, config, user_input)
            print(f"\nAgente > {response}\n")
        except requests.HTTPError as exc:
            print(f"\nERRO HTTP {exc.response.status_code}: {exc.response.text[:500]}\n")
        except Exception as exc:
            print(f"\nERRO: {exc}\n")


def single_query(endpoint, config, message):
    """Executa uma unica query e imprime a resposta."""
    try:
        response = invoke_agent(endpoint, config, message)
        print(response)
    except requests.HTTPError as exc:
        print(f"ERRO HTTP {exc.response.status_code}: {exc.response.text[:500]}", file=sys.stderr)
        sys.exit(1)
    except Exception as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        sys.exit(1)


# ── Main ─────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Chat interativo com agentes de mercado financeiro do workshop",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemplos:\n"
            "  python chat.py --lesson 1              # Chat com agente declarativo\n"
            "  python chat.py --lesson 2              # Chat com agente hosted MAF\n"
            "  python chat.py --lesson 3              # Chat com agente hosted LangGraph\n"
            "  python chat.py --lesson 4              # ACA connected (auto-resolve)\n"
            '  python chat.py --lesson 1 --once "Qual a cotacao da PETR4?"\n'
        ),
    )
    parser.add_argument(
        "--lesson",
        type=int,
        required=True,
        choices=[1, 2, 3, 4],
        help="Numero da licao (1=declarativo, 2=hosted MAF, 3=hosted LangGraph, 4=ACA connected)",
    )
    parser.add_argument(
        "--endpoint",
        default=DEFAULT_ENDPOINT,
        help="AI Project endpoint (default: env PROJECT_ENDPOINT)",
    )
    parser.add_argument(
        "--once",
        metavar="MENSAGEM",
        help="Envia uma unica mensagem e encerra (modo nao-interativo)",
    )
    args = parser.parse_args()

    config = LESSONS[args.lesson]

    # Resolver endpoint: ACA tem endpoint proprio, demais usam Foundry
    endpoint = args.endpoint
    if config["type"] == "aca":
        endpoint = config.get("endpoint") or args.endpoint
        if not endpoint or endpoint == DEFAULT_ENDPOINT:
            endpoint = _resolve_aca_endpoint(config["name"])

    if not endpoint:
        print(
            "ERRO: Endpoint nao configurado.\n"
            "  Defina a env var PROJECT_ENDPOINT ou use --endpoint <url>\n"
            "  Exemplo: python chat.py --lesson 1 --endpoint https://<foundry>.services.ai.azure.com/api/projects/<project>",
            file=sys.stderr,
        )
        sys.exit(1)

    if args.once:
        single_query(endpoint, config, args.once)
    else:
        chat_loop(endpoint, args.lesson, config)


if __name__ == "__main__":
    main()
