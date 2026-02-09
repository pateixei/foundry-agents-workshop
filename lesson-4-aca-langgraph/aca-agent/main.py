"""
Agente de Mercado Financeiro usando LangGraph no Azure Container Apps.

Expoe o agente como servidor HTTP (FastAPI) com endpoint /chat,
registravel como Connected Agent no Microsoft Foundry Control Plane.

Diferente das licoes 2-3 (hosted agents no Foundry), este agente
roda em infraestrutura propria (ACA) e e registrado externamente
no Foundry para governanca e monitoramento via AI Gateway (APIM).
"""

import os
import logging
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from pydantic import BaseModel

from langchain.chat_models import init_chat_model
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langgraph.graph import END, START, MessagesState, StateGraph
from typing_extensions import Literal

from azure.identity import DefaultAzureCredential, get_bearer_token_provider

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
    """Inicializa o LLM com credenciais Azure (Managed Identity do ACA)."""
    deployment_name = os.getenv("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-4.1")
    azure_endpoint = os.getenv(
        "AZURE_OPENAI_ENDPOINT", ""  # Definido pelo deploy.ps1 ou aca.bicep
    )
    api_version = os.getenv("OPENAI_API_VERSION", "2025-01-01-preview")

    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(
        credential, "https://cognitiveservices.azure.com/.default"
    )
    return init_chat_model(
        f"azure_openai:{deployment_name}",
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
# FastAPI - Servidor HTTP
# =============================================================

class ChatRequest(BaseModel):
    """Corpo da requisicao POST /chat."""
    message: str


class ChatResponse(BaseModel):
    """Corpo da resposta POST /chat."""
    response: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Inicializa o agente LangGraph no startup do servidor."""
    logger.info("Inicializando agente LangGraph...")
    app.state.agent = build_agent()
    logger.info("Agente pronto para receber requisicoes.")
    yield
    logger.info("Servidor encerrado.")


app = FastAPI(
    title="Financial Market Agent - ACA",
    description="Agente de mercado financeiro (LangGraph) no Azure Container Apps",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health():
    """Health check para probes do ACA."""
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    """Envia uma mensagem ao agente e retorna a resposta.

    O agente pode chamar tools (get_stock_price, get_market_summary,
    get_exchange_rate) antes de produzir a resposta final.
    """
    result = app.state.agent.invoke({
        "messages": [HumanMessage(content=req.message)]
    })

    # Extrair ultima AIMessage com conteudo
    for msg in reversed(result["messages"]):
        if isinstance(msg, AIMessage) and msg.content:
            content = msg.content if isinstance(msg.content, str) else str(msg.content)
            return ChatResponse(response=content)

    return ChatResponse(response="Sem resposta do agente.")


# =============================================================
# Entry point
# =============================================================

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    uvicorn.run(app, host="0.0.0.0", port=8080)
