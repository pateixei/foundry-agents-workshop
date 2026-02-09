FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar codigo
COPY . .

# Porta do agentserver HTTP
EXPOSE 8080

# Entrypoint - HTTP server mode
CMD ["python", "app.py"]
