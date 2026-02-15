"""
Entrypoint do agente de mercado financeiro.
Expoe a funcao run() que e chamada pelo Agent Server HTTP ou diretamente.
Habilita OpenTelemetry com Azure Monitor para observabilidade.
"""

import asyncio
import os
import sys
from typing import Optional

from dotenv import load_dotenv
from opentelemetry import trace

# Carregar .env com override para funcionar em ambientes deployed
load_dotenv(override=True)

# Configurar Azure Monitor OpenTelemetry (antes de qualquer uso de tracer)
connection_string = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if connection_string:
    from azure.monitor.opentelemetry import configure_azure_monitor
    configure_azure_monitor(connection_string=connection_string)

tracer = trace.get_tracer(__name__)

# Adicionar raiz do projeto ao path para resolver imports
_project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

from src.agent.finance_agent import create_finance_agent


async def run(user_input: str, thread_id: Optional[str] = None) -> str:
    """
    Entrypoint principal do agente.

    Args:
        user_input: Mensagem do usuario.
        thread_id: ID de thread existente para manter contexto (opcional).

    Returns:
        Resposta do agente como string.
    """
    with tracer.start_as_current_span("agent_run") as span:
        span.set_attribute("user_input", user_input)
        span.set_attribute("thread_id", thread_id or "new")

        agent, credential = await create_finance_agent()

        try:
            if thread_id:
                # Reutilizar thread existente
                thread = agent.get_thread(thread_id)
            else:
                thread = agent.get_new_thread()

            response_text = ""
            async for chunk in agent.run_stream(user_input, thread=thread):
                if chunk.text:
                    response_text += chunk.text

            span.set_attribute("response_length", len(response_text))
            return response_text

        finally:
            await credential.close()
