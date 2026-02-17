FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar codigo
COPY . .

# Porta do agentserver HTTP (azure-ai-agentserver-core default = 8088)
EXPOSE 8088

# Entrypoint - HTTP server LangGraph
CMD ["python", "main.py"]
