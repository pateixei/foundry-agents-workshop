# Lesson 4 - LangGraph Agent no Azure Container Apps

Nesta licao, deployamos o mesmo agente LangGraph das licoes anteriores em
infraestrutura propria (**Azure Container Apps**) e o registramos como
**Connected Agent** no Microsoft Foundry Control Plane.

Veja detalhes completos em [aca-agent/README.md](aca-agent/README.md).

## Quick Start

```powershell
cd aca-agent
.\deploy.ps1
```

## Teste Rapido

```powershell
# Chamada direta ao ACA (sem passar pelo Foundry)
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Qual a cotacao da PETR4?"}'
```

## Conceitos Chave

- **Azure Container Apps (ACA)**: Plataforma serverless para containers com auto-scaling
- **Connected Agent**: Agente externo registrado no Foundry Control Plane para governanca
- **AI Gateway (APIM)**: Proxy do Foundry que roteia requisicoes e coleta telemetria
- **FastAPI**: Framework HTTP que serve o agente (substitui o agentserver adapter dos hosted agents)
- **Managed Identity**: O ACA usa sua propria MI (diferente da MI do projeto Foundry)

## Diferenca das Licoes 2-3

| Aspecto | Licoes 2-3 (Hosted) | Licao 4 (ACA) |
|---|---|---|
| Infraestrutura | Foundry (Capability Host) | Azure Container Apps (usuario) |
| Servidor HTTP | agentserver adapter (porta 8088) | FastAPI + uvicorn (porta 8080) |
| Registro | Hosted Agent (CLI/SDK) | Connected Agent (portal Control Plane) |
| Scaling | Foundry gerencia | ACA gerencia (minReplicas/maxReplicas) |
| Proxy | Responses API nativa | AI Gateway (APIM) |
| Managed Identity | MI do projeto Foundry | MI do Container App |
