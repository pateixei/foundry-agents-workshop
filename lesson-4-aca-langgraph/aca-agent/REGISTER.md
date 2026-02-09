# Registrar Agente ACA no Microsoft Foundry Control Plane

Este guia detalha o passo a passo para registrar o agente LangGraph (rodando no Azure Container Apps) como **Custom Agent** no Microsoft Foundry Control Plane.

## Pre-requisitos

Antes de iniciar o registro, certifique-se de que:

1. **O agente esta rodando no ACA** e respondendo no endpoint `/health`
   ```powershell
   # Verificar health
   $FQDN = az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.configuration.ingress.fqdn" -o tsv
   Invoke-RestMethod -Uri "https://$FQDN/health"
   # Esperado: { "status": "ok" }
   ```

2. **RBAC configurado** — a Managed Identity do ACA tem a role `Cognitive Services OpenAI User` no Foundry account

3. **AI Gateway configurado** no recurso Foundry (veja Passo 2 abaixo)

---

## Passo 1 — Acessar o portal do Microsoft Foundry

1. Acesse [https://ai.azure.com](https://ai.azure.com)
2. Faca login com sua conta Azure
3. **Importante**: Certifique-se de que o toggle **Foundry (new)** esta ativado no banner superior

   > O registro de custom agents so esta disponivel no portal Foundry (new).
   > Se voce estiver no portal classico, ative o toggle.

---

## Passo 2 — Verificar o AI Gateway

O Foundry usa o Azure API Management (APIM) como proxy para custom agents. E necessario ter um AI Gateway configurado.

1. No portal, clique em **Operate** (canto superior direito)
2. Selecione **Admin console** no menu lateral
3. Abra a aba **AI Gateway**
4. Verifique se o recurso Foundry (`ai-foundry001`) tem um AI Gateway associado
5. Se nao houver, clique em **Add AI Gateway** para criar um

   > O AI Gateway e gratuito para configurar e habilita governanca, seguranca, telemetria e rate limits.

---

## Passo 3 — Verificar observabilidade (opcional, recomendado)

Para que o Foundry exiba traces e metricas do agente:

1. Em **Operate > Admin console**, localize o projeto `ag365-prj001`
2. Clique no projeto e abra a aba **Connected resources**
3. Verifique se ha um recurso **Application Insights** associado
4. Se nao houver, clique em **Add connection > Application Insights** e selecione o recurso `appi-ai001`

---

## Passo 4 — Registrar o agente

1. No portal, clique em **Operate** (canto superior direito)
2. Selecione **Overview** no menu lateral
3. Clique no botao **Register agent**
4. O wizard de registro sera aberto. Preencha os campos:

### Dados do agente (como ele roda)

| Campo | Valor | Obrigatorio |
|-------|-------|:-----------:|
| **Agent URL** | `https://aca-lg-agent.<region>.azurecontainerapps.io` | Sim |
| **Protocol** | `HTTP` | Sim |
| **OpenTelemetry Agent ID** | *(deixe vazio — usara o Agent name)* | Nao |
| **Admin portal URL** | *(deixe vazio)* | Nao |

> **Dica**: Para obter a URL do agente, execute:
> ```powershell
> az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.configuration.ingress.fqdn" -o tsv
> ```
> Adicione `https://` antes do FQDN retornado.

### Dados de exibicao no Control Plane

| Campo | Valor | Obrigatorio |
|-------|-------|:-----------:|
| **Project** | `ag365-prj001` | Sim |
| **Agent name** | `aca-lg-agent` | Sim |
| **Description** | `Agente de mercado financeiro (LangGraph no ACA)` | Nao |

5. Clique em **Save** para concluir o registro

---

## Passo 5 — Obter a URL proxy

Apos o registro, o Foundry gera uma nova URL (proxy via AI Gateway/APIM) para o agente:

1. No menu lateral, clique em **Assets**
2. Use o filtro **Source > Custom** para ver apenas custom agents
3. Selecione o agente `aca-lg-agent`
4. No painel de detalhes (lado direito), localize **Agent URL**
5. Clique no icone de copia para copiar a URL proxy

A URL proxy tera o formato:
```
https://apim-<foundry-id>.azure-api.net/aca-lg-agent/
```

> **Nota**: O Foundry atua como proxy. A autenticacao original do endpoint continua valendo.
> Ao consumir a URL proxy, forneca o mesmo mecanismo de autenticacao que usaria no endpoint original.

---

## Passo 6 — Testar via URL proxy (opcional)

Apos obter a URL proxy, voce pode testar:

```powershell
# Usando a URL proxy do Foundry
$PROXY_URL = "https://apim-<foundry-id>.azure-api.net/aca-lg-agent"
$body = @{ message = "Qual a cotacao da PETR4?" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "$PROXY_URL/chat" -Method POST -ContentType "application/json" -Body $body
```

Ou diretamente pelo ACA (sem proxy):
```powershell
python ../../../test/chat.py --lesson 4 --once "Qual a cotacao da PETR4?"
```

---

## Verificar traces e metricas

Apos o registro e algumas chamadas ao agente:

1. **Operate > Assets** > selecione `aca-lg-agent`
2. A secao **Traces** mostra cada chamada HTTP feita ao endpoint do agente
3. Clique em uma entrada para ver detalhes (request/response, latencia, headers)

> Para traces mais detalhados (tool calls, LLM calls), instrumente o codigo do agente com OpenTelemetry seguindo as [convencoes semanticas para GenAI](https://opentelemetry.io/docs/specs/semconv/gen-ai/).

---

## Troubleshooting

| Problema | Causa provavel | Solucao |
|----------|---------------|---------|
| Nao aparece opcao "Register agent" | Portal classico ativo | Ative o toggle **Foundry (new)** |
| Nao mostra projetos no wizard | AI Gateway nao configurado | Operate > Admin console > AI Gateway > Add |
| Agente registrado mas sem traces | App Insights nao conectado | Conecte App Insights ao projeto |
| Erro 401 via URL proxy | Auth nao fornecida na chamada | Inclua headers de auth do endpoint original |
| Erro de rede no registro | ACA nao acessivel publicamente | Verifique ingress externo no ACA |

---

## Arquitetura do registro

```
Cliente ──► AI Gateway (APIM) ──► Azure Container Apps
               │                      │
               │ Proxy + Governance    │ aca-lg-agent
               │ Rate Limiting         │ FastAPI + LangGraph
               │ Telemetry             │ Port 8080
               │                      │
          Foundry Control Plane    Managed Identity
          (Monitor, Traces,        (Cognitive Services
           Agent Inventory)         OpenAI User)
```

O Foundry **nao modifica** as requests — apenas as roteia pelo APIM para ganhar visibilidade e controle.
