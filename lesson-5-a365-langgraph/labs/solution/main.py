"""
Financial Market Agent with Microsoft Agent 365 SDK Integration.

This enhanced version adds:
- Observability: Azure Monitor Application Insights tracing
- Bot Framework: A365-compatible conversation protocol 
- Adaptive Cards: Rich, interactive responses
- Tool Notifications: Progress updates during tool execution
"""

import os
import logging
from contextlib import asynccontextmanager
from typing import Optional

import uvicorn
from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel

from langchain_openai import AzureChatOpenAI
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langgraph.graph import END, START, MessagesState, StateGraph
from typing_extensions import Literal

from azure.identity import DefaultAzureCredential, get_bearer_token_provider

# A365 SDK and Observability
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Bot Framework
from botbuilder.core import BotFrameworkAdapter, BotFrameworkAdapterSettings
from botbuilder.schema import Activity, ActivityTypes

logger = logging.getLogger(__name__)

# Get tracer for manual instrumentation
tracer = trace.get_tracer(__name__)

SYSTEM_PROMPT = """You are a financial market expert assistant for Brazilian and international markets.

## Your Objective
Help investors and financial market professionals with information and analysis
about stocks, currency exchange, indices, and market trends.

## Your Capabilities
- Provide information about B3 stocks (PETR4, VALE3, ITUB4, etc.) and global markets
- Explain exchange rates and their trends
- Provide market summaries and analysis (Brazil, USA, Europe, Global)
- Explain financial concepts clearly and accessibly

## Guidelines
- Always respond in Brazilian Portuguese
- Explain that you don't have real-time data access, but can provide general and educational market information
- Include disclaimer: 'Esta informacao e apenas para fins educativos e nao constitui recomendacao de investimento'
- Format values in Brazilian standard (R$ 1.234,56)
- Be objective and direct in responses
"""


# =============================================================
# Tools - Functions the agent can call
# =============================================================

@tool
def get_stock_price(ticker: str) -> str:
    """Query the current stock price by ticker.

    Args:
        ticker: Stock ticker code (e.g., PETR4, VALE3, AAPL)
    """
    with tracer.start_as_current_span("get_stock_price") as span:
        span.set_attribute("ticker", ticker)
        
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
            span.set_attribute("found", False)
            return f"Ticker '{ticker}' nao encontrado. Tickers disponiveis: {', '.join(prices.keys())}"
        
        span.set_attribute("found", True)
        span.set_attribute("price", data["price"])
        
        sign = "+" if data["change"] >= 0 else ""
        return (
            f"{ticker}: {data['currency']} {data['price']:.2f} "
            f"({sign}{data['change']:.2f}%)"
        )


@tool
def get_market_summary() -> str:
    """Returns a summary of main financial market indices."""
    with tracer.start_as_current_span("get_market_summary"):
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
    """Query exchange rate for a currency pair.

    Args:
        pair: Currency pair (e.g., USD/BRL, EUR/BRL, BTC/USD)
    """
    with tracer.start_as_current_span("get_exchange_rate") as span:
        span.set_attribute("pair", pair)
        
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
            span.set_attribute("found", False)
            return f"Par '{pair}' nao encontrado. Pares disponiveis: {', '.join(rates.keys())}"
        
        span.set_attribute("found", True)
        span.set_attribute("rate", data["rate"])
        
        sign = "+" if data["change"] >= 0 else ""
        return f"{pair}: {data['rate']:.2f} ({sign}{data['change']:.2f}%)"


# =============================================================
# LLM and Graph
# =============================================================

tools_list = [get_stock_price, get_market_summary, get_exchange_rate]
tools_by_name = {t.name: t for t in tools_list}
_llm_with_tools = None


def get_llm():
    """Initialize LLM with Azure credentials (ACA Managed Identity)."""
    deployment_name = os.getenv("AZURE_AI_MODEL_DEPLOYMENT_NAME", "gpt-4.1")
    azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "")
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
    """Returns LLM with bound tools (singleton)."""
    global _llm_with_tools
    if _llm_with_tools is None:
        _llm_with_tools = get_llm().bind_tools(tools_list)
    return _llm_with_tools


# --- Graph nodes ---

def llm_call(state: MessagesState):
    """Node: LLM decides whether to call a tool or respond directly."""
    with tracer.start_as_current_span("llm_call"):
        return {
            "messages": [
                get_llm_with_tools().invoke(
                    [SystemMessage(content=SYSTEM_PROMPT)] + state["messages"]
                )
            ]
        }


def tool_node(state: MessagesState):
    """Node: Execute tool calls requested by LLM."""
    with tracer.start_as_current_span("tool_execution") as span:
        results = []
        last_message = state["messages"][-1]
        
        if not isinstance(last_message, AIMessage) or not last_message.tool_calls:
            return {"messages": []}
        
        span.set_attribute("tool_count", len(last_message.tool_calls))
        
        for tool_call in last_message.tool_calls:
            fn = tools_by_name[tool_call["name"]]
            observation = fn.invoke(tool_call["args"])
            results.append(
                ToolMessage(content=str(observation), tool_call_id=tool_call["id"])
            )
        
        return {"messages": results}


def should_continue(state: MessagesState) -> Literal["Action", "__end__"]:
    """Conditional edge: if LLM made tool call, go to tool_node; otherwise, END."""
    last = state["messages"][-1]
    if isinstance(last, AIMessage) and last.tool_calls:
        return "Action"
    return "__end__"


# --- Build graph ---

def build_agent():
    """Build and compile the LangGraph agent graph."""
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
# Adaptive Cards - Rich Responses 
# =============================================================

def create_adaptive_card(title: str, text: str, facts: Optional[list] = None):
    """Create an Adaptive Card for rich M365 responses."""
    card_content = {
        "type": "AdaptiveCard",
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.5",
        "body": [
            {
                "type": "TextBlock",
                "text": title,
                "weight": "Bolder",
                "size": "Large"
            },
            {
                "type": "TextBlock",
                "text": text,
                "wrap": True
            }
        ]
    }
    
    if facts:
        fact_set = {
            "type": "FactSet",
            "facts": facts
        }
        card_content["body"].append(fact_set)
    
    return {
        "contentType": "application/vnd.microsoft.card.adaptive",
        "content": card_content
    }


# =============================================================
# Bot Framework Adapter - A365 Conversation Protocol
# =============================================================

class A365BotAdapter:
    """Adapter to handle Bot Framework Activity protocol from A365."""
    
    def __init__(self, agent):
        self.agent = agent
        self.adapter = BotFrameworkAdapter(BotFrameworkAdapterSettings(
            app_id=os.getenv("MICROSOFT_APP_ID", ""),
            app_password=os.getenv("MICROSOFT_APP_PASSWORD", "")
        ))
    
    async def process_activity(self, activity: Activity) -> dict:
        """Process incoming activity and return response."""
        with tracer.start_as_current_span("process_activity") as span:
            span.set_attribute("activity_type", activity.type)
            span.set_attribute("conversation_id", activity.conversation.id if activity.conversation else "")
            
            if activity.type != ActivityTypes.message or not activity.text:
                return {"text": "Nenhuma mensagem para processar."}
            
            # Invoke agent
            result = self.agent.invoke({
                "messages": [HumanMessage(content=activity.text)]
            })
            
            # Extract final AI response
            for msg in reversed(result["messages"]):
                if isinstance(msg, AIMessage) and msg.content:
                    content = msg.content if isinstance(msg.content, str) else str(msg.content)
                    
                    # Create rich response with adaptive card
                    return {
                        "type": ActivityTypes.message,
                        "text": content,
                        "attachments": [
                            create_adaptive_card(
                                "Resposta do Agente de Mercado Financeiro",
                                content
                            )
                        ]
                    }
            
            return {"text": "Sem resposta do agente."}


# =============================================================
# FastAPI - HTTP Server
# =============================================================

class ChatRequest(BaseModel):
    """Chat request body (simple REST API)."""
    message: str


class ChatResponse(BaseModel):
    """Chat response body (simple REST API)."""
    response: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize agent and telemetry on server startup."""
    # Configure Azure Monitor if connection string is provided
    connection_string = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
    if connection_string:
        logger.info("Configuring Azure Monitor telemetry...")
        configure_azure_monitor(connection_string=connection_string)
        logger.info("Azure Monitor configured.")
    else:
        logger.warning("No Application Insights connection string found. Telemetry disabled.")
    
    logger.info("Initializing LangGraph agent...")
    app.state.agent = build_agent()
    app.state.bot_adapter = A365BotAdapter(app.state.agent)
    logger.info("Agent ready to receive requests.")
    
    yield
    
    logger.info("Server shutdown.")


app = FastAPI(
    title="Financial Market Agent - A365 SDK",
    description="Financial market agent (LangGraph) with Microsoft Agent 365 SDK integration",
    version="2.0.0",
    lifespan=lifespan,
)

# Instrument FastAPI with OpenTelemetry
FastAPIInstrumentor.instrument_app(app)


@app.get("/health")
async def health():
    """Health check for ACA probes."""
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    """Send message to agent and return response.

    Simple REST API endpoint for backward compatibility.
    Agent can call tools (get_stock_price, get_market_summary, get_exchange_rate)
    before producing final response.
    """
    with tracer.start_as_current_span("chat_endpoint"):
        result = app.state.agent.invoke({
            "messages": [HumanMessage(content=req.message)]
        })

        # Extract final AIMessage with content
        for msg in reversed(result["messages"]):
            if isinstance(msg, AIMessage) and msg.content:
                content = msg.content if isinstance(msg.content, str) else str(msg.content)
                return ChatResponse(response=content)

        return ChatResponse(response="Sem resposta do agente.")


@app.post("/api/messages")
async def messages(request: Request):
    """Bot Framework Activity endpoint for A365 integration.
    
    This endpoint receives Activity objects from Microsoft Agent 365
    and returns Activity responses with adaptive cards.
    """
    with tracer.start_as_current_span("messages_endpoint"):
        try:
            # Parse incoming activity
            body = await request.json()
            activity = Activity().deserialize(body)
            
            # Process through bot adapter
            response = await app.state.bot_adapter.process_activity(activity)
            
            return response
            
        except Exception as e:
            logger.error(f"Error processing activity: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Internal error processing message.")


# =============================================================
# Entry point
# =============================================================

if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    uvicorn.run(app, host="0.0.0.0", port=8080)
