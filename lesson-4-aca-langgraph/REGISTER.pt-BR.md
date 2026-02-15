# Registrar Agente ACA no Microsoft Foundry Control Plane

Este guia detalha o processo passo a passo para registrar o agente LangGraph (executando no Azure Container Apps) como um **Agente Personalizado** no Microsoft Foundry Control Plane.

## Pré-requisitos

Antes de iniciar o registro, verifique que:

1. **O agente está em execução no ACA** e respondendo no endpoint `/health`
   ```powershell
   # Check health
   $FQDN = az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.configuration.ingress.fqdn" -o tsv
   Invoke-RestMethod -Uri "https://$FQDN/health"
   # Expected: { "status": "ok" }
   ```

2. **RBAC configurado** — a Managed Identity do ACA possui a função `Cognitive Services OpenAI User` na conta Foundry

3. **AI Gateway configurado** no recurso Foundry (veja a Etapa 2 abaixo)

---

## Etapa 1 — Acessar o portal Microsoft Foundry

1. Acesse [https://ai.azure.com](https://ai.azure.com)
2. Faça login com sua conta Azure
3. **Importante**: Verifique se o toggle **Foundry (new)** está habilitado no banner superior

   > O registro de agente personalizado está disponível apenas no portal Foundry (new).
   > Se você estiver no portal clássico, habilite o toggle.

---

## Etapa 2 — Verificar o AI Gateway

O Foundry usa o Azure API Management (APIM) como proxy para agentes personalizados. Você precisa ter um AI Gateway configurado.

1. No portal, clique em **Operate** (canto superior direito)
2. Selecione **Admin console** no menu lateral
3. Abra a aba **AI Gateway**
4. Verifique se o recurso Foundry (`ai-foundry001`) possui um AI Gateway associado
5. Se não, clique em **Add AI Gateway** para criar um

   > O AI Gateway é gratuito para configurar e habilita governança, segurança, telemetria e limites de taxa.

---

## Etapa 3 — Verificar observabilidade (opcional, recomendado)

Para que o Foundry exiba traces e métricas do agente:

1. Em **Operate > Admin console**, localize o projeto `ag365-prj001`
2. Clique no projeto e abra a aba **Connected resources**
3. Verifique se há um recurso **Application Insights** associado
4. Se não, clique em **Add connection > Application Insights** e selecione o recurso `appi-ai001`

---

## Etapa 4 — Registrar o agente

1. No portal, clique em **Operate** (canto superior direito)
2. Selecione **Overview** no menu lateral
3. Clique no botão **Register agent**
4. O assistente de registro será aberto. Preencha os campos:

### Dados do agente (como ele executa)

| Campo | Valor | Obrigatório |
|-------|-------|:-----------:|
| **Agent URL** | `https://aca-lg-agent.<region>.azurecontainerapps.io` | Sim |
| **Protocol** | `HTTP` | Sim |
| **OpenTelemetry Agent ID** | *(deixe vazio — usará o nome do agente)* | Não |
| **Admin portal URL** | *(deixe vazio)* | Não |

> **Dica**: Para obter a URL do agente, execute:
> ```powershell
> az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.configuration.ingress.fqdn" -o tsv
> ```
> Adicione `https://` antes do FQDN retornado.

### Dados de exibição no Control Plane

| Campo | Valor | Obrigatório |
|-------|-------|:-----------:|
| **Project** | `ag365-prj001` | Sim |
| **Agent name** | `aca-lg-agent` | Sim |
| **Description** | `Financial market agent (LangGraph on ACA)` | Não |

5. Clique em **Save** para concluir o registro

---

## Etapa 5 — Obter a URL de proxy

Após o registro, o Foundry gera uma nova URL (proxy via AI Gateway/APIM) para o agente:

1. No menu lateral, clique em **Assets**
2. Use o filtro **Source > Custom** para ver apenas agentes personalizados
3. Selecione o agente `aca-lg-agent`
4. No painel de detalhes (lado direito), localize **Agent URL**
5. Clique no ícone de copiar para copiar a URL de proxy

A URL de proxy terá o formato:
```
https://apim-<foundry-id>.azure-api.net/aca-lg-agent/
```

> **Nota**: O Foundry atua como proxy. A autenticação do endpoint original continua aplicável.
> Ao consumir a URL de proxy, forneça o mesmo mecanismo de autenticação que você usaria no endpoint original.

---

## Etapa 6 — Testar via URL de proxy (opcional)

Após obter a URL de proxy, você pode testar:

```powershell
# Using the Foundry proxy URL
$PROXY_URL = "https://apim-<foundry-id>.azure-api.net/aca-lg-agent"
$body = @{ message = "What is the PETR4 quote?" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "$PROXY_URL/chat" -Method POST -ContentType "application/json" -Body $body
```

Ou diretamente através do ACA (sem proxy):
```powershell
python ../../../test/chat.py --lesson 4 --once "What is the PETR4 quote?"
```

---

## Verificar traces e métricas

Após o registro e algumas chamadas ao agente:

1. **Operate > Assets** > selecione `aca-lg-agent`
2. A seção **Traces** mostra cada chamada HTTP feita ao endpoint do agente
3. Clique em uma entrada para ver os detalhes (request/response, latência, headers)

> Para traces mais detalhados (chamadas de ferramentas, chamadas LLM), instrumente o código do agente com OpenTelemetry seguindo as [convenções semânticas para GenAI](https://opentelemetry.io/docs/specs/semconv/gen-ai/).

---

## Resolução de problemas

| Problema | Causa Provável | Solução |
|----------|---------------|---------|
| Opção "Register agent" não aparece | Portal clássico ativo | Habilite o toggle **Foundry (new)** |
| Nenhum projeto exibido no assistente | AI Gateway não configurado | Operate > Admin console > AI Gateway > Add |
| Agente registrado mas sem traces | App Insights não conectado | Conecte o App Insights ao projeto |
| Erro 401 via URL de proxy | Autenticação não fornecida na chamada | Inclua os headers de autenticação do endpoint original |
| Erro de rede durante o registro | ACA não está acessível publicamente | Verifique o ingress externo no ACA |

---

## Arquitetura de registro

```
Client ──► AI Gateway (APIM) ──► Azure Container Apps
               │                      │
               │ Proxy + Governance    │ aca-lg-agent
               │ Rate Limiting         │ FastAPI + LangGraph
               │ Telemetry             │ Port 8080
               │                      │
          Foundry Control Plane    Managed Identity
          (Monitor, Traces,        (Cognitive Services
           Agent Inventory)         OpenAI User)
```

O Foundry **não modifica** as requisições — ele apenas as roteia pelo APIM para obter visibilidade e controle.
