FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . ./user_agent/
EXPOSE 8088

CMD ["python", "user_agent/main.py"]
