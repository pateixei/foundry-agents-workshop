# Capability Host no Microsoft Foundry

O **Capability Host** é um recurso de infraestrutura do Microsoft Foundry que habilita a execução de **Hosted Agents** (agentes em contêineres) dentro de um projeto Foundry.

## O que ele faz

Funciona como uma "ponte" entre o projeto Foundry e os recursos de computação necessários para executar contêineres de agentes. Especificamente:

| Função | Descrição |
|---|---|
| **Orquestração de contêineres** | Gerencia o ciclo de vida dos contêineres de agentes (iniciar, parar, verificação de saúde) |
| **Roteamento de requisições** | Recebe chamadas da Responses API e as encaminha para o contêiner correto |
| **Conexão ACR** | Permite que o projeto faça pull de imagens do Azure Container Registry |
| **Managed Identity** | Fornece identidade gerenciada para que o contêiner acesse outros serviços (ex.: endpoint OpenAI) |
| **Armazenamento** | Associa uma conta de armazenamento para persistência de dados do agente |

## Como é criado

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
              |-- Conexão de armazenamento
              |-- Conexão AI Service (endpoint OpenAI)
              +-- Conexão ACR (imagens de contêiner)
                    +-- Hosted Agent v1, v2, ...
```

## Pontos importantes

- É **obrigatório** para executar hosted agents — sem ele, você só pode criar agentes via Agent Service (sem contêiner customizado).
- Precisa ser criado **tanto no nível da conta quanto no nível do projeto** (dois níveis).
- Atualmente em **preview** — requer `az cli >= 2.73.0` com a extensão `cognitiveservices` mais recente.
- Cada projeto precisa de apenas **um** capability host (normalmente chamado `default`).

## Contexto no Workshop

- **Lição 1**: Não utiliza capability host porque o agente roda nativamente no Agent Service.
- **Lição 2**: Capability host é necessário porque o agente LangGraph roda em um contêiner customizado.
