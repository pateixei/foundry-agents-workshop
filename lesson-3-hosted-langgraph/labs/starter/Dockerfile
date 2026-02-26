FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN adduser --disabled-password --gecos '' appuser && chown appuser:appuser /app
USER appuser

COPY --chown=appuser:appuser . .

EXPOSE 8088
CMD ["python", "main.py"]
