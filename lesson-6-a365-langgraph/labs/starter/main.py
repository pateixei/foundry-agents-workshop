"""
Lab 5 - Starter: A365 SDK Integration

Enhance your ACA agent with Bot Framework and OpenTelemetry.
Complete the TODOs to add:
- Application Insights tracing
- Bot Framework /api/messages endpoint
- Adaptive Cards for rich responses
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

# TODO: Import Azure Monitor OpenTelemetry
# from azure.monitor.opentelemetry import configure_azure_monitor
# from opentelemetry import trace
# from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# TODO: Import Bot Framework
# from botbuilder.core import BotFrameworkAdapter
# from botbuilder.schema import Activity, ActivityTypes

logger = logging.getLogger(__name__)

# TODO: Set up tracer
# tracer = trace.get_tracer(__name__)

SYSTEM_PROMPT = """You are a financial market expert assistant."""

# TODO: Copy your tools from Lab 4 (get_stock_price, get_market_summary, get_exchange_rate)
# TODO: Copy your LangGraph graph from Lab 4 (get_llm, build_agent, etc.)


# TODO: Implement create_adaptive_card(title, text, facts) function
# Should return an Adaptive Card JSON structure


# TODO: Implement A365BotAdapter class
# - __init__: Create BotFrameworkAdapter with app_id and app_password from env
# - process_activity: Process incoming Activity, invoke agent, return response


# TODO: Add /api/messages POST endpoint to handle Bot Framework activities


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    response: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    # TODO: Configure Azure Monitor if connection string is available
    # TODO: Initialize LangGraph agent
    # TODO: Initialize A365BotAdapter
    yield


app = FastAPI(title="Financial Market Agent - A365", lifespan=lifespan)

# TODO: Instrument FastAPI with OpenTelemetry
# FastAPIInstrumentor.instrument_app(app)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    # TODO: Invoke agent and return response
    pass


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    uvicorn.run(app, host="0.0.0.0", port=8080)
