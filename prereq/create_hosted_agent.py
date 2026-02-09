"""
Registra um Hosted Agent no Azure AI Foundry.

Script consolidado para criar hosted agents de qualquer licao (MAF ou LangGraph).
O agente e criado a partir de uma imagem Docker no ACR e registrado no Foundry.

Uso:
    python create_hosted_agent.py --endpoint <ep> --acr-image <img> --model-deployment <model> --agent-name <name>
    python create_hosted_agent.py --endpoint <ep> --acr-image <img> --model-deployment <model> --agent-name fin-market-agent --env-endpoint FOUNDRY_PROJECT_ENDPOINT --env-model FOUNDRY_MODEL_DEPLOYMENT_NAME
    python create_hosted_agent.py --endpoint <ep> --acr-image <img> --model-deployment <model> --agent-name lg-market-agent --env-endpoint AZURE_AI_PROJECT_ENDPOINT --env-model AZURE_AI_MODEL_DEPLOYMENT_NAME

Requer: pip install azure-ai-projects azure-identity
"""

import argparse
import time

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    ImageBasedHostedAgentDefinition,
    ProtocolVersionRecord,
)
from azure.identity import DefaultAzureCredential


def main():
    parser = argparse.ArgumentParser(
        description="Registra um hosted agent no Azure AI Foundry",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemplos:\n"
            "  # Lesson 2 - MAF\n"
            "  python create_hosted_agent.py \\\n"
            "    --endpoint https://ai-foundry001.services.ai.azure.com/api/projects/ag365-prj001 \\\n"
            "    --acr-image acr123.azurecr.io/fin-market-agent:v1 \\\n"
            "    --model-deployment gpt-4.1 \\\n"
            "    --agent-name fin-market-agent \\\n"
            "    --env-endpoint FOUNDRY_PROJECT_ENDPOINT \\\n"
            "    --env-model FOUNDRY_MODEL_DEPLOYMENT_NAME\n\n"
            "  # Lesson 3 - LangGraph\n"
            "  python create_hosted_agent.py \\\n"
            "    --endpoint https://ai-foundry001.services.ai.azure.com/api/projects/ag365-prj001 \\\n"
            "    --acr-image acr123.azurecr.io/lg-market-agent:v1 \\\n"
            "    --model-deployment gpt-4.1 \\\n"
            "    --agent-name lg-market-agent \\\n"
            "    --env-endpoint AZURE_AI_PROJECT_ENDPOINT \\\n"
            "    --env-model AZURE_AI_MODEL_DEPLOYMENT_NAME\n"
        ),
    )
    parser.add_argument("--endpoint", required=True, help="AI Project endpoint")
    parser.add_argument("--acr-image", required=True, help="ACR image with tag")
    parser.add_argument("--model-deployment", required=True, help="Model deployment name")
    parser.add_argument("--agent-name", required=True, help="Nome do agente no Foundry")
    parser.add_argument(
        "--env-endpoint",
        default="FOUNDRY_PROJECT_ENDPOINT",
        help="Nome da env var de endpoint passada ao container (default: FOUNDRY_PROJECT_ENDPOINT)",
    )
    parser.add_argument(
        "--env-model",
        default="FOUNDRY_MODEL_DEPLOYMENT_NAME",
        help="Nome da env var de model passada ao container (default: FOUNDRY_MODEL_DEPLOYMENT_NAME)",
    )
    parser.add_argument(
        "--description",
        default="Agente de mercado financeiro - hosted agent",
        help="Descricao do agente",
    )
    parser.add_argument(
        "--cpu", default="1.0", help="CPU do container (default: 1.0)"
    )
    parser.add_argument(
        "--memory", default="2Gi", help="Memoria do container (default: 2Gi)"
    )
    args = parser.parse_args()

    credential = DefaultAzureCredential()
    project_client = AIProjectClient(
        endpoint=args.endpoint,
        credential=credential,
    )

    # ----- Limpa agente existente com mesmo nome -----
    print(f"Verificando agentes existentes com nome '{args.agent_name}'...")
    try:
        existing = list(project_client.agents.list())
        for agent in existing:
            if getattr(agent, "name", None) == args.agent_name:
                print(f"  Removendo agente existente: {agent.name}")
                try:
                    project_client.agents.delete(agent.name)
                except Exception as ex:
                    print(f"  Aviso: nao foi possivel remover: {ex}")
    except Exception as ex:
        print(f"  Aviso ao listar agentes: {ex}")

    # ----- Cria novo hosted agent -----
    print(f"Criando hosted agent '{args.agent_name}'...")
    print(f"  Imagem:       {args.acr_image}")
    print(f"  Model:        {args.model_deployment}")
    print(f"  Env endpoint: {args.env_endpoint}")
    print(f"  Env model:    {args.env_model}")

    definition = ImageBasedHostedAgentDefinition(
        image=args.acr_image,
        container_protocol_versions=[
            ProtocolVersionRecord(protocol="responses", version="v1")
        ],
        cpu=args.cpu,
        memory=args.memory,
        environment_variables={
            args.env_endpoint: args.endpoint,
            args.env_model: args.model_deployment,
        },
    )

    agent = project_client.agents.create(
        name=args.agent_name,
        definition=definition,
        description=args.description,
    )

    print(f"Hosted agent criado com sucesso!")
    print(f"  Name: {agent.name}")
    if hasattr(agent, "version"):
        print(f"  Version: {agent.version}")

    # Aguarda o agente ficar pronto
    print("Aguardando provisionamento do agente (pode levar ate 3 minutos)...")
    for i in range(36):
        time.sleep(5)
        try:
            status = project_client.agents.get(args.agent_name)
            state = getattr(status, "provisioning_state", None) or getattr(
                status, "status", None
            )
            if state:
                print(f"  State: {state}")
                if str(state).lower() in ("succeeded", "ready", "running"):
                    print("Agente pronto!")
                    break
        except Exception:
            pass
        if i % 6 == 5:
            print(f"  Aguardando... ({(i + 1) * 5}s)")
    else:
        print("  Timeout aguardando agente. Verifique o portal do Foundry.")

    return args.agent_name


if __name__ == "__main__":
    agent_name = main()
    print(f"\nAgent Name: {agent_name}")
