"""
Lab 2 - Task 3: Implement Entry Point

Complete the TODOs to implement the run() function called by the agent server.
"""

import asyncio
import os
import sys
from typing import Optional

from dotenv import load_dotenv

load_dotenv(override=True)

# Add project root to path
_project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

from src.agent.finance_agent import create_finance_agent


async def run(user_input: str, thread_id: Optional[str] = None) -> str:
    """Main entry point called by agent server.

    Args:
        user_input: User message.
        thread_id: Existing thread ID for context (optional).

    Returns:
        Agent response as string.
    """
    # TODO: Create the finance agent using create_finance_agent()

    # TODO: Get or create a thread
    # If thread_id is provided, use agent.get_thread(thread_id)
    # Otherwise, use agent.get_new_thread()

    # TODO: Run the agent with streaming
    # Use agent.run_stream(user_input, thread=thread)
    # Concatenate all chunks into response_text

    # TODO: Close the credential (await credential.close())

    # TODO: Return the response text
    pass
