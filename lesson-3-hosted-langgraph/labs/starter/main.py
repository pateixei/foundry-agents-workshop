"""
Lab 3 - Starter: Migrate LangGraph Agent from AWS to Azure

This is a skeleton for your Azure LangGraph agent.
Complete the TODOs to migrate from AWS Bedrock to Azure OpenAI.
"""

import os

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langgraph.graph import END, START, MessagesState, StateGraph
from typing_extensions import Literal

# TODO: Import AzureChatOpenAI from langchain_openai
# TODO: Import DefaultAzureCredential and get_bearer_token_provider from azure.identity

SYSTEM_PROMPT = """You are a financial market expert assistant."""


# TODO: Implement tools using @tool decorator
# Tool 1: get_stock_price(ticker: str) -> str
# Tool 2: get_market_summary() -> str
# Tool 3: get_exchange_rate(pair: str) -> str


# TODO: Create tools_list and tools_by_name dict


def get_llm():
    """Initialize LLM with Azure credentials."""
    # TODO: Replace AWS Bedrock init with Azure OpenAI
    # Use AzureChatOpenAI with:
    #   azure_deployment, azure_ad_token_provider, azure_endpoint, api_version
    pass


def get_llm_with_tools():
    """Returns LLM with bound tools."""
    # TODO: Call get_llm().bind_tools(tools_list)
    pass


def llm_call(state: MessagesState):
    """Node: LLM decides whether to call a tool or respond directly."""
    # TODO: Invoke LLM with system prompt + conversation messages
    pass


def tool_node(state: MessagesState):
    """Node: Execute tool calls requested by LLM."""
    # TODO: Extract tool calls from last message
    # TODO: Execute each tool and create ToolMessage responses
    pass


def should_continue(state: MessagesState) -> Literal["Action", "__end__"]:
    """Conditional edge: tools or end."""
    # TODO: Check if last message has tool_calls
    pass


def build_agent():
    """Build and compile the LangGraph agent graph."""
    builder = StateGraph(MessagesState)

    # TODO: Add nodes (llm_call, tool_node)
    # TODO: Add edges (START -> llm_call, conditional from llm_call, Action -> llm_call)
    # TODO: Compile and return the graph
    pass
