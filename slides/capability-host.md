# Capability Host no Microsoft Foundry

O **Capability Host** e um recurso de infraestrutura do Microsoft Foundry que habilita a execucao de **Hosted Agents** (agentes containerizados) dentro de um projeto Foundry.

## O que faz

Ele funciona como uma "ponte" entre o projeto Foundry e os recursos de computacao necessarios para rodar containers de agentes. Especificamente:

| Funcao | Descricao |
|---|---|
| **Orquestracao de containers** | Gerencia o ciclo de vida dos containers de agentes (start, stop, health check) |
| **Roteamento de requests** | Recebe chamadas da Responses API e encaminha para o container correto |
| **Conexao com ACR** | Permite que o projeto faca pull de imagens do Azure Container Registry |
| **Managed Identity** | Fornece identidade gerenciada para o container acessar outros servicos (ex: OpenAI endpoint) |
| **Storage** | Associa uma storage account para persistencia de dados do agente |

## Como e criado

```bash
az cognitiveservices account capability-host create \
    --account-name <foundry-account> \
    --project-name <project> \
    --capability-host-name default \
    --capability-host-kind Agents \
    --storage-connections "[{resource-id: <storage-id>}]" \
    --ai-service-connections "[{resource-id: <foundry-account-id>}]" \
    --acr-connections "[{resource-id: <acr-id>}]"
```

## Hierarquia

```
Foundry Account (hub)
  +-- Project
        +-- Capability Host (kind: Agents)
              |-- Storage connection
              |-- AI Service connection (OpenAI endpoint)
              +-- ACR connection (container images)
                    +-- Hosted Agent v1, v2, ...
```

## Pontos importantes

- E **obrigatorio** para rodar hosted agents -- sem ele, so e possivel criar agentes via Agent Service (sem container custom).
- Precisa ser criado **tanto no account quanto no project** (dois niveis).
- Atualmente em **preview** -- requer `az cli >= 2.73.0` com a extensao `cognitiveservices` mais recente.
- Cada projeto so precisa de **um** capability host (nome tipicamente `default`).

## Contexto no Workshop

- **Lesson 1**: Nao usa capability host porque o agente roda nativamente no Agent Service.
- **Lesson 2**: Capability host e necessario porque o LangGraph agent roda em container custom.
