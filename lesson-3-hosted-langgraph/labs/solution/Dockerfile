FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN adduser --disabled-password --gecos '' appuser && chown appuser:appuser /app
USER appuser

# Copiar codigo
COPY --chown=appuser:appuser . .

# Porta do agentserver HTTP (azure-ai-agentserver-core default = 8088)
EXPOSE 8088

# Entrypoint - HTTP server LangGraph
CMD ["python", "main.py"]
