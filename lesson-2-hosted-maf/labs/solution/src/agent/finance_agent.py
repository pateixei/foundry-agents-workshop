"""
Classe do agente de mercado financeiro usando Microsoft Agent Framework.
Usa AzureAIClient para conectar ao Foundry e expoe tools de financas.
"""

import os

from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential
from opentelemetry import trace

from tools.finance_tools import get_stock_quote, get_exchange_rate, get_market_summary

tracer = trace.get_tracer(__name__)

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

TOOLS = [get_stock_quote, get_exchange_rate, get_market_summary]


async def create_finance_agent():
    """Cria e retorna o agente de mercado financeiro via Microsoft Agent Framework."""
    with tracer.start_as_current_span("create_finance_agent"):
        project_endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
        model_deployment = os.environ["FOUNDRY_MODEL_DEPLOYMENT_NAME"]

        credential = DefaultAzureCredential()

        # Quando executando como hosted agent, a versao ja existe no Foundry.
        # Passar agent_version evita que o MAF tente criar um agente tipo
        # 'prompt' que conflita com o hosted agent existente.
        agent_version = os.environ.get("HOSTED_AGENT_VERSION")

        client = AzureAIClient(
            project_endpoint=project_endpoint,
            model_deployment_name=model_deployment,
            credential=credential,
            agent_version=agent_version,
        )

        agent = await client.create_agent(
            name="fin-market-agent",
            instructions=SYSTEM_PROMPT,
            tools=TOOLS,
        ).__aenter__()

        return agent, credential
