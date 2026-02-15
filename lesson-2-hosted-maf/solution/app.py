"""
HTTP Server do agente usando azure-ai-agentserver-agentframework.
Exponibiliza o agente como API REST para deployment no Foundry.

Inclui:
- Patch para bug no agentserver-core onde AgentReference nao aceita 'id'
  enviado pelo Foundry Responses API (context.md known issue).
- Patch para _prepare_options que evita roteamento recursivo em hosted agents.
  Sem este patch, o container chama o Foundry com agent reference de si mesmo,
  causando loop infinito e timeout.

Nota: O Foundry nao permite o campo 'instructions' no payload para hosted
agents (retorna 400 "Not allowed" param=instructions). O system prompt e
gerenciado exclusivamente pelo codigo do container.
"""

import asyncio
import os
import sys

from dotenv import load_dotenv

# Carregar .env com override para funcionar em ambientes deployed
load_dotenv(override=True)

# Configurar Azure Monitor OpenTelemetry
connection_string = os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING")
if connection_string:
    from azure.monitor.opentelemetry import configure_azure_monitor
    configure_azure_monitor(connection_string=connection_string)

# ------------------------------------------------------------------
# Patch: agentserver-core bug - AgentReference nao aceita 'id'
# O Foundry Responses API envia {"id": ..., "name": ..., ...} mas
# AgentReference.__init__() so aceita name, version e type.
# ------------------------------------------------------------------
try:
    from azure.ai.agentserver.core.server.common import agent_run_context as _arc
    from azure.ai.agentserver.core.models.projects import AgentReference as _AR

    _original_deser = _arc._deserialize_agent_reference

    def _patched_deserialize_agent_reference(payload: dict):
        if not payload:
            return None
        clean = {k: v for k, v in payload.items() if k in ("name", "version", "type")}
        return _AR(**clean)

    _arc._deserialize_agent_reference = _patched_deserialize_agent_reference
except Exception:
    pass  # Se o patch falhar, seguir sem ele
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# Patch: AzureAIClient._get_agent_reference_or_create missing 'id'
# O Foundry Responses API exige 'id' no agent reference, mas o MAF
# retorna apenas {name, version, type}. Isso causa:
#   400 - "ID cannot be null or empty (Parameter 'id')"
# quando o container faz a chamada interna ao Responses API.
# Adicionamos id = name no dict retornado.
# ------------------------------------------------------------------
try:
    from agent_framework_azure_ai._client import AzureAIClient as _AIC

    _original_get_ref = _AIC._get_agent_reference_or_create

    async def _patched_get_agent_ref(self, *args, **kwargs):
        ref = await _original_get_ref(self, *args, **kwargs)
        if isinstance(ref, dict) and "name" in ref and "id" not in ref:
            ref["id"] = ref["name"]
        return ref

    _AIC._get_agent_reference_or_create = _patched_get_agent_ref
except Exception:
    pass  # Se o patch falhar, seguir sem ele
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# Patch: _prepare_options — evitar roteamento recursivo em hosted agents.
#
# Problema:
#   Quando _is_application_endpoint é False (endpoint de projeto, e.g.
#   .../api/projects/xxx), _prepare_options adiciona
#   extra_body = {"agent": {name, version, ...}} e REMOVE model, tools,
#   etc. do request. O Foundry recebe a chamada, resolve o agent ref,
#   e roteia DE VOLTA para o mesmo container → loop infinito → timeout.
#
# Correção:
#   Substituir _prepare_options para:
#   1. Manter _prepare_messages_for_azure_ai (converte mensagens p/ Azure)
#   2. Manter _transform_input_for_azure_ai (workaround schema divergence)
#   3. NÃO adicionar agent reference (evita roteamento recursivo)
#   4. NÃO remover model/tools (necessários para chamada direta ao LLM)
# ------------------------------------------------------------------
try:
    from agent_framework_azure_ai._client import AzureAIClient as _AIC2
    from agent_framework.openai._responses_client import OpenAIResponsesClient as _OIRC
    from typing import cast, Any, MutableSequence

    _orig_azure_prepare = _AIC2._prepare_options

    async def _hosted_prepare_options(self, messages, chat_options, **kwargs):
        # 1. Preparação Azure-specific de mensagens
        prepared_messages, instructions = self._prepare_messages_for_azure_ai(messages)
        # 2. Preparação base (OpenAI) — retorna run_options com model, tools, input, etc.
        run_options = await _OIRC._prepare_options(self, prepared_messages, chat_options, **kwargs)
        # 3. Workaround: transformação de input para Azure SDK (schema divergence)
        if "input" in run_options and isinstance(run_options["input"], list):
            run_options["input"] = self._transform_input_for_azure_ai(
                cast(list[dict[str, Any]], run_options["input"])
            )
        # 4. NÃO adiciona agent reference (evita routing recursivo)
        # 5. NÃO remove model/tools (necessários para chamada direta ao LLM)
        return run_options

    _AIC2._prepare_options = _hosted_prepare_options
except Exception as e:
    import traceback
    traceback.print_exc()
    print(f"WARN: _prepare_options patch failed: {e}")
# ------------------------------------------------------------------

# Adicionar raiz do projeto ao path
_project_root = os.path.dirname(os.path.abspath(__file__))
if _project_root not in sys.path:
    sys.path.insert(0, _project_root)

from src.agent.finance_agent import create_finance_agent  # noqa: E402
from azure.ai.agentserver.agentframework import AgentFrameworkAIAgentAdapter  # noqa: E402


async def main():
    """Inicia o agente como HTTP server."""
    agent, credential = await create_finance_agent()
    try:
        adapter = AgentFrameworkAIAgentAdapter(agent)
        await adapter.run_async()
    finally:
        await credential.close()


if __name__ == "__main__":
    asyncio.run(main())
