# Capability Host no Microsoft Foundry

> 🇺🇸 **[Read in English](capability-host.md)**

O **Capability Host** é um recurso de infraestrutura do Microsoft Foundry que habilita a execução de **Hosted Agents** (agentes em contêineres) dentro de um projeto Foundry.

## O que ele faz

Funciona como uma "ponte" entre o projeto Foundry e os recursos de computação necessários para executar contêineres de agentes. Especificamente:

| Função | Descrição |
|---|---|
| **Orquestração de contêineres** | Gerencia o ciclo de vida dos contêineres de agentes (iniciar, parar, verificação de saúde) |
| **Roteamento de requisições** | Recebe chamadas da Responses API e as encaminha para o contêiner correto |
| **Conexão ACR** | Permite que o projeto faça pull de imagens do Azure Container Registry |
| **Managed Identity** | Fornece identidade gerenciada para que o contêiner acesse outros serviços (ex.: endpoint OpenAI) |
| **Armazenamento** | Associa uma conta de armazenamento para persistência de dados do agente, threads e vector stores |

## Como é criado (Bicep)

Neste workshop, o Capability Host é provisionado como parte da infraestrutura compartilhada via `prereq/main.bicep`:

```bicep
resource capabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview' = {
  name: 'default'
  parent: aiFoundry
  properties: {
    capabilityHostKind: 'Agents'
    enablePublicHostingEnvironment: true
  }
  dependsOn: [
    aiProject
    storageAccount
  ]
}
```

> ⚠️ **Crítico**: A propriedade `enablePublicHostingEnvironment: true` é **obrigatória** para hosted agents. Sem ela, o agente ficará preso no estado "Starting" e falhará após ~15 minutos com timeout de provisionamento. Esta propriedade instrui o Foundry a criar o ambiente de computação gerenciado para executar contêineres de agentes.

O Foundry provisiona e gerencia automaticamente as conexões de armazenamento e serviço de AI quando `enablePublicHostingEnvironment` está habilitado. Uma Storage Account deve existir no resource group (usada para threads, vector stores e dados do agente).

## Hierarquia

```
Foundry Account (hub)
  +-- Project
  +-- Capability Host (kind: Agents)   <- nível da conta
        |-- enablePublicHostingEnvironment: true
        |-- Armazenamento auto-provisionado (threads, vector stores)
        |-- Conexão AI Service auto-provisionada
        +-- Hosted Agent v1, v2, ...
```

## Pontos importantes

- É **obrigatório** para executar hosted agents — sem ele, você só pode criar agentes via Agent Service (sem contêiner customizado).
- **`enablePublicHostingEnvironment: true`** é obrigatório — sem ele, o provisionamento do ambiente gerenciado expirará por timeout.
- Criado no **nível da conta** via Bicep. O Foundry propaga as capacidades para os projetos automaticamente.
- Atualmente em **preview** — usa API version `2025-10-01-preview`.
- Cada conta precisa de apenas **um** capability host (chamado `default`).
- Requer uma **Storage Account** no resource group para persistência de dados (threads, vector stores, dados do agente).
- O Capability Host **não pode ser atualizado** — se precisar alterar propriedades, você deve deletar e recriar.

## Contexto no Workshop

- **Lição 1**: Não utiliza capability host porque o agente roda nativamente no Agent Service (declarativo).
- **Lições 2 e 3**: Capability host é **obrigatório** porque os agentes rodam em contêineres customizados (hosted agents).
- **Lições 4 e 6**: Não utilizam capability host porque os agentes rodam no Azure Container Apps (auto-hospedado).
