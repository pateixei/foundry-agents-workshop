"""
Lab 4: Agente de Mercado Financeiro usando LangGraph no Azure Container Apps.

Objetivo: Completar um agente LangGraph que roda como Connected Agent no ACA,
registravel no Microsoft Foundry Control Plane.
"""

import os
import logging
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from pydantic import BaseModel

from langchain_openai import AzureChatOpenAI
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

## Diretrizes
- Sempre responda em portugues brasileiro
- Inclua disclaimer: 'Esta informacao e apenas para fins educativos'
- Formate valores no padrao brasileiro (R$ 1.234,56)
"""


# =============================================================
# TODO 1: Implemente as tools do agente
# Crie pelo menos duas tools usando o decorator @tool:
#   - get_stock_price(ticker: str) -> str
#   - get_exchange_rate(pair: str) -> str
# =============================================================

# @tool
# def get_stock_price(ticker: str) -> str:
#     """Consulta o preco atual de uma acao pelo ticker."""
#     # TODO: Implemente a logica (pode usar dados simulados)
#     pass

# @tool
# def get_exchange_rate(pair: str) -> str:
#     """Consulta a taxa de cambio de um par de moedas."""
#     # TODO: Implemente a logica
#     pass


# =============================================================
# TODO 2: Configure o LLM com AzureChatOpenAI
# Use DefaultAzureCredential + get_bearer_token_provider
# =============================================================

tools_list = []  # TODO: Adicione suas tools aqui
tools_by_name = {t.name: t for t in tools_list}


def get_llm():
    """Inicializa o LLM com credenciais Azure (Managed Identity do ACA)."""
    # TODO: Implemente usando AzureChatOpenAI com:
    #   - azure_deployment from env AZURE_AI_MODEL_DEPLOYMENT_NAME
    #   - azure_ad_token_provider using DefaultAzureCredential
    #   - azure_endpoint from env AZURE_OPENAI_ENDPOINT
    pass


_llm_with_tools = None


def get_llm_with_tools():
    """Retorna o LLM com tools vinculadas (singleton)."""
    global _llm_with_tools
    if _llm_with_tools is None:
        _llm_with_tools = get_llm().bind_tools(tools_list)
    return _llm_with_tools


# =============================================================
# TODO 3: Implemente os nodes do grafo LangGraph
# =============================================================

def llm_call(state: MessagesState):
    """Node: LLM decide se chama uma tool ou responde diretamente."""
    # TODO: Invoque get_llm_with_tools() com system prompt + messages
    pass


def tool_node(state: MessagesState):
    """Node: Executa as tool calls solicitadas pelo LLM."""
    # TODO: Itere sobre last_message.tool_calls e execute cada tool
    pass


def should_continue(state: MessagesState) -> Literal["tools", END]:
    """Decide se o grafo deve continuar para tools ou encerrar."""
    last = state["messages"][-1]
    if isinstance(last, AIMessage) and last.tool_calls:
        return "tools"
    return END


# =============================================================
# TODO 4: Monte o grafo do LangGraph
# =============================================================

def build_graph():
    """Constroi o grafo do agente."""
    # TODO: Crie um StateGraph(MessagesState) com:
    #   - node "llm" -> llm_call
    #   - node "tools" -> tool_node
    #   - edge START -> "llm"
    #   - conditional_edges de "llm" via should_continue
    #   - edge "tools" -> "llm"
    #   Compile e retorne o grafo
    pass


graph = None  # TODO: Inicialize com build_graph()


# =============================================================
# FastAPI Server (fornecido - nao precisa alterar)
# =============================================================

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    global graph
    graph = build_graph()
    logger.info("Agent graph initialized")
    yield


app = FastAPI(title="Financial Market Agent - ACA", lifespan=lifespan)


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """Endpoint principal para conversar com o agente."""
    result = graph.invoke({"messages": [HumanMessage(content=req.message)]})
    last = result["messages"][-1]
    return ChatResponse(response=last.content)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
