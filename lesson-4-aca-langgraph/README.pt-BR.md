# Lição 4 - Agente LangGraph no Azure Container Apps

## Navegação

| Recurso | Descrição |
|---------|----------|
| [📖 Walkthrough da Demo](demos/README.pt-BR.md) | Explicação do código e instruções da demo |
| [🔬 Exercício de Lab](labs/LAB-STATEMENT.pt-BR.md) | Lab prático com tarefas e critérios de sucesso |
| [📐 Diagrama de Arquitetura](media/lesson-4-architecture.png) | Visão geral da arquitetura |
| [🛠️ Diagrama de Deployment](media/lesson-4-deployment.png) | Fluxo de implantação |
| [📁 Notas da Solução](labs/solution/README.pt-BR.md) | Código da solução e detalhes de deployment |
| [📝 Registro do Agente](REGISTER.pt-BR.md) | Como registrar agente como Connected Agent no Foundry |

Nesta lição, implantamos o mesmo agente LangGraph das lições anteriores em
infraestrutura própria (**Azure Container Apps**) e o registramos como
**Connected Agent** no Control Plane do Microsoft Foundry.

Veja detalhes completos em [labs/solution/README.pt-BR.md](labs/solution/README.pt-BR.md).

## Início Rápido

```powershell
cd labs/solution
.\deploy.ps1
```

## Teste Rápido

```powershell
# Chamada direta ao ACA (sem passar pelo Foundry)
python ../../test/chat.py --lesson 4 --endpoint https://<aca-fqdn>

# Via curl
curl -X POST https://<aca-fqdn>/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the PETR4 stock price?"}'
```

## Conceitos Principais

- **Azure Container Apps (ACA)**: Plataforma serverless para contêineres com auto-scaling
- **Connected Agent**: Agente externo registrado no Control Plane do Foundry para governança
- **AI Gateway (APIM)**: Proxy do Foundry que roteia requisições e coleta telemetria
- **FastAPI**: Framework HTTP que serve o agente (substitui o adaptador agentserver dos agentes hospedados)
- **Managed Identity**: O ACA usa sua própria MI (diferente da MI do projeto Foundry)

## Diferença das Lições 2-3

| Aspecto | Lições 2-3 (Hospedado) | Lição 4 (ACA) |
|---|---|---|
| Infraestrutura | Foundry (Capability Host) | Azure Container Apps (usuário) |
| Servidor HTTP | Adaptador agentserver (porta 8088) | FastAPI + uvicorn (porta 8080) |
| Registro | Hosted Agent (CLI/SDK) | Connected Agent (portal Control Plane) |
| Escalabilidade | Gerenciada pelo Foundry | Gerenciada pelo ACA (minReplicas/maxReplicas) |
| Proxy | Responses API nativa | AI Gateway (APIM) |
| Managed Identity | MI do projeto Foundry | MI do Container App |
