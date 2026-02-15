"""
Hosted Agent de Mercado Financeiro usando LangGraph no Azure AI Foundry.
Expoe o agente como Responses API via azure-ai-agentserver-langgraph.
"""

import os
import logging

from langchain_openai import AzureChatOpenAI
from langchain_core.messages import AIMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langgraph.graph import END, START, MessagesState, StateGraph
from typing_extensions import Literal

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from azure.ai.agentserver.langgraph import from_langgraph

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """Voce e um assistente especialista em mercado financeiro brasileiro e internacional.

## Seu Objetivo
Ajudar investidores e profissionais do mercado financeiro com informacoes e analises
sobre acoes, cambio, indices e tendencias de mercado.

## Suas Capacidades
- Fornecer informacoes sobre acoes da B3 (PETR4, VALE3, ITUB4, etc.) e mercados globais
- Explicar taxas de cambio e suas tendencias
- Fornecer resumos e analises de mercado (Brasil, EUA, Europa, Global)
- Explicar conceitos financeiros de forma clara e acessivel

## Diretrizes
- Sempre responda em portugues brasileiro
- Explique que voce nao tem acesso a dados em tempo real, mas pode fornecer informacoes gerais e educativas sobre o mercado
- Inclua disclaimer: 'Esta informacao e apenas para fins educativos e nao constitui recomendacao de investimento'
- Formate valores no padrao brasileiro (R$ 1.234,56)
- Seja objetivo e direto nas respostas
"""


# =============================================================
# Tools - Funcoes que o agente pode chamar
# =============================================================

@tool
def get_stock_price(ticker: str) -> str:
    """Consulta o preco atual de uma acao pelo ticker.

    Args:
        ticker: Codigo do ticker da acao (ex: PETR4, VALE3, AAPL)
    """
    prices = {
        "PETR4": {"price": 38.72, "change": 1.23, "currency": "BRL"},
        "VALE3": {"price": 61.45, "change": -0.87, "currency": "BRL"},
        "ITUB4": {"price": 32.18, "change": 0.45, "currency": "BRL"},
        "BBDC4": {"price": 13.95, "change": -0.32, "currency": "BRL"},
        "WEGE3": {"price": 41.30, "change": 2.15, "currency": "BRL"},
        "AAPL": {"price": 228.50, "change": 1.85, "currency": "USD"},
        "MSFT": {"price": 445.20, "change": 3.12, "currency": "USD"},
        "GOOGL": {"price": 178.90, "change": -1.45, "currency": "USD"},
        "AMZN": {"price": 198.75, "change": 2.30, "currency": "USD"},
        "NVDA": {"price": 142.60, "change": 5.40, "currency": "USD"},
    }
    ticker = ticker.upper().strip()
    data = prices.get(ticker)
    if not data:
        return f"Ticker '{ticker}' nao encontrado. Tickers disponiveis: {', '.join(prices.keys())}"
    sign = "+" if data["change"] >= 0 else ""
    return (
        f"{ticker}: {data['currency']} {data['price']:.2f} "
        f"({sign}{data['change']:.2f}%)"
    )


@tool
def get_market_summary() -> str:
    """Retorna um resumo dos principais indices do mercado financeiro."""
    return (
        "Resumo do Mercado:\n"
        "- Ibovespa: 131.245 pts (+0.82%)\n"
        "- S&P 500: 5.832 pts (+0.45%)\n"
        "- NASDAQ: 18.956 pts (+0.67%)\n"
        "- Dow Jones: 43.128 pts (+0.23%)\n"
        "- Dolar (USD/BRL): R$ 5,12 (-0,35%)\n"
        "- Euro (EUR/BRL): R$ 5,58 (-0,18%)"
    )


@tool
def get_exchange_rate(pair: str) -> str:
    """Consulta a taxa de cambio de um par de moedas.

    Args:
        pair: Par de moedas (ex: USD/BRL, EUR/BRL, BTC/USD)
    """
    rates = {
        "USD/BRL": {"rate": 5.12, "change": -0.35},
        "EUR/BRL": {"rate": 5.58, "change": -0.18},
        "GBP/BRL": {"rate": 6.48, "change": 0.12},
        "BTC/USD": {"rate": 67842.50, "change": 2.45},
        "ETH/USD": {"rate": 3456.80, "change": 1.87},
    }
    pair = pair.upper().strip()
    data = rates.get(pair)
    if not data:
        return f"Par '{pair}' nao encontrado. Pares disponiveis: {', '.join(rates.keys())}"
    sign = "+" if data["change"] >= 0 else ""
    return f"{pair}: {data['rate']:.2f} ({sign}{data['change']:.2f}%)"


# =============================================================
# LLM e Graph
# =============================================================

tools_list = [get_stock_price, get_market_summary, get_exchange_rate]
tools_by_name = {t.name: t for t in tools_list}
_llm_with_tools = None


def get_llm():
    """Inicializa o LLM com credenciais Azure."""
    deployment_name = os.getenv("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-4.1")
    azure_endpoint = os.getenv(
        "AZURE_OPENAI_ENDPOINT", ""  # Definido pelo deploy.ps1 via env var
    )
    api_version = os.getenv("OPENAI_API_VERSION", "2025-01-01-preview")

    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(
        credential, "https://cognitiveservices.azure.com/.default"
    )
    return AzureChatOpenAI(
        azure_deployment=deployment_name,
        azure_ad_token_provider=token_provider,
        azure_endpoint=azure_endpoint,
        api_version=api_version,
    )


def get_llm_with_tools():
    """Retorna o LLM com tools vinculadas (singleton)."""
    global _llm_with_tools
    if _llm_with_tools is None:
        _llm_with_tools = get_llm().bind_tools(tools_list)
    return _llm_with_tools


# --- Nodes do grafo ---

def llm_call(state: MessagesState):
    """Node: LLM decide se chama uma tool ou responde diretamente."""
    return {
        "messages": [
            get_llm_with_tools().invoke(
                [SystemMessage(content=SYSTEM_PROMPT)] + state["messages"]
            )
        ]
    }


def tool_node(state: MessagesState):
    """Node: Executa as tool calls solicitadas pelo LLM."""
    results = []
    last_message = state["messages"][-1]
    if not isinstance(last_message, AIMessage) or not last_message.tool_calls:
        return {"messages": []}
    for tool_call in last_message.tool_calls:
        fn = tools_by_name[tool_call["name"]]
        observation = fn.invoke(tool_call["args"])
        results.append(
            ToolMessage(content=str(observation), tool_call_id=tool_call["id"])
        )
    return {"messages": results}


def should_continue(state: MessagesState) -> Literal["Action", "__end__"]:
    """Edge condicional: se o LLM fez tool call, vai para tool_node; senao, END."""
    last = state["messages"][-1]
    if isinstance(last, AIMessage) and last.tool_calls:
        return "Action"
    return "__end__"


# --- Build do grafo ---

def build_agent():
    """Constroi e compila o grafo LangGraph do agente."""
    builder = StateGraph(MessagesState)

    builder.add_node("llm_call", llm_call)
    builder.add_node("environment", tool_node)

    builder.add_edge(START, "llm_call")
    builder.add_conditional_edges(
        "llm_call",
        should_continue,
        {"Action": "environment", END: END},
    )
    builder.add_edge("environment", "llm_call")

    return builder.compile()


# =============================================================
# Workaround: azure-ai-agentserver-core 1.0.0b10 AgentReference
# does not accept the 'id' field that the Foundry service sends.
# Monkey-patch __init__ to accept and ignore extra kwargs.
# =============================================================

def _patch_agent_reference():
    """Patch AgentReference deserialization to accept the 'id' field.

    Bug: azure-ai-agentserver-core 1.0.0b10 AgentReference does not
    define an 'id' field, but the Foundry service includes it when
    routing requests to the container.  The Model base class raises
    TypeError for unknown kwargs.

    Fix: override _deserialize_agent_reference to pop 'id' before
    constructing AgentReference, then store it in the dict afterwards.
    """
    try:
        import azure.ai.agentserver.core.server.common.agent_run_context as ctx_mod
        from azure.ai.agentserver.core.models.projects import AgentReference

        _known_fields = {"type", "name", "version"}

        def _patched_deserialize(payload: dict) -> AgentReference:
            if not payload:
                return None  # type: ignore
            extras = {k: v for k, v in payload.items() if k not in _known_fields}
            clean = {k: v for k, v in payload.items() if k in _known_fields}
            ref = AgentReference(**clean)
            # Store extras (like 'id') in underlying MutableMapping
            for k, v in extras.items():
                ref[k] = v
            return ref

        ctx_mod._deserialize_agent_reference = _patched_deserialize
        logging.getLogger(__name__).info(
            "Patched _deserialize_agent_reference to accept extra fields (e.g. 'id')"
        )
    except Exception as e:
        logging.getLogger(__name__).warning(
            "Could not patch agent reference deserialization: %s", e
        )


# =============================================================
# Entry point - Hosted Agent Server
# =============================================================

if __name__ == "__main__":
    try:
        _patch_agent_reference()
        agent = build_agent()
        adapter = from_langgraph(agent)
        adapter.run()
    except Exception:
        logger.exception("Financial Market Agent encountered an error")
        raise
