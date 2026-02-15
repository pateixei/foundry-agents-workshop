# Register ACA Agent in Microsoft Foundry Control Plane

> 🇧🇷 **[Leia em Português (pt-BR)](REGISTER.pt-BR.md)**

This guide details the step-by-step process to register the LangGraph agent (running on Azure Container Apps) as a **Custom Agent** in Microsoft Foundry Control Plane.

## Prerequisites

Before starting registration, ensure that:

1. **The agent is running on ACA** and responding at the `/health` endpoint
   ```powershell
   # Check health
   $FQDN = az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.configuration.ingress.fqdn" -o tsv
   Invoke-RestMethod -Uri "https://$FQDN/health"
   # Expected: { "status": "ok" }
   ```

2. **RBAC configured** — the ACA Managed Identity has the `Cognitive Services OpenAI User` role on the Foundry account

3. **AI Gateway configured** on the Foundry resource (see Step 2 below)

---

## Step 1 — Access the Microsoft Foundry portal

1. Go to [https://ai.azure.com](https://ai.azure.com)
2. Sign in with your Azure account
3. **Important**: Ensure the **Foundry (new)** toggle is enabled in the top banner

   > Custom agent registration is only available in the Foundry (new) portal.
   > If you're in the classic portal, enable the toggle.

---

## Step 2 — Verify the AI Gateway

Foundry uses Azure API Management (APIM) as a proxy for custom agents. You need to have an AI Gateway configured.

1. In the portal, click **Operate** (top right corner)
2. Select **Admin console** in the side menu
3. Open the **AI Gateway** tab
4. Verify that the Foundry resource (`ai-foundry001`) has an associated AI Gateway
5. If not, click **Add AI Gateway** to create one

   > The AI Gateway is free to configure and enables governance, security, telemetry, and rate limits.

---

## Step 3 — Verify observability (optional, recommended)

For Foundry to display agent traces and metrics:

1. In **Operate > Admin console**, locate the project `ag365-prj001`
2. Click on the project and open the **Connected resources** tab
3. Check if there's an associated **Application Insights** resource
4. If not, click **Add connection > Application Insights** and select the `appi-ai001` resource

---

## Step 4 — Register the agent

1. In the portal, click **Operate** (top right corner)
2. Select **Overview** in the side menu
3. Click the **Register agent** button
4. The registration wizard will open. Fill in the fields:

### Agent data (how it runs)

| Field | Value | Required |
|-------|-------|:-----------:|
| **Agent URL** | `https://aca-lg-agent.<region>.azurecontainerapps.io` | Yes |
| **Protocol** | `HTTP` | Yes |
| **OpenTelemetry Agent ID** | *(leave empty — will use Agent name)* | No |
| **Admin portal URL** | *(leave empty)* | No |

> **Tip**: To get the agent URL, run:
> ```powershell
> az containerapp show --name aca-lg-agent --resource-group rg-ag365sdk --query "properties.configuration.ingress.fqdn" -o tsv
> ```
> Add `https://` before the returned FQDN.

### Display data in Control Plane

| Field | Value | Required |
|-------|-------|:-----------:|
| **Project** | `ag365-prj001` | Yes |
| **Agent name** | `aca-lg-agent` | Yes |
| **Description** | `Financial market agent (LangGraph on ACA)` | No |

5. Click **Save** to complete registration

---

## Step 5 — Get the proxy URL

After registration, Foundry generates a new URL (proxy via AI Gateway/APIM) for the agent:

1. In the side menu, click **Assets**
2. Use the **Source > Custom** filter to see only custom agents
3. Select the `aca-lg-agent` agent
4. In the details panel (right side), locate **Agent URL**
5. Click the copy icon to copy the proxy URL

The proxy URL will have the format:
```
https://apim-<foundry-id>.azure-api.net/aca-lg-agent/
```

> **Note**: Foundry acts as a proxy. The original endpoint authentication still applies.
> When consuming the proxy URL, provide the same authentication mechanism you would use on the original endpoint.

---

## Step 6 — Test via proxy URL (optional)

After obtaining the proxy URL, you can test:

```powershell
# Using the Foundry proxy URL
$PROXY_URL = "https://apim-<foundry-id>.azure-api.net/aca-lg-agent"
$body = @{ message = "What is the PETR4 quote?" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri "$PROXY_URL/chat" -Method POST -ContentType "application/json" -Body $body
```

Or directly through ACA (without proxy):
```powershell
python ../../../test/chat.py --lesson 4 --once "What is the PETR4 quote?"
```

---

## Verify traces and metrics

After registration and some calls to the agent:

1. **Operate > Assets** > select `aca-lg-agent`
2. The **Traces** section shows each HTTP call made to the agent endpoint
3. Click on an entry to see details (request/response, latency, headers)

> For more detailed traces (tool calls, LLM calls), instrument the agent code with OpenTelemetry following the [semantic conventions for GenAI](https://opentelemetry.io/docs/specs/semconv/gen-ai/).

---

## Troubleshooting

| Problem | Probable Cause | Solution |
|----------|---------------|---------|
| "Register agent" option doesn't appear | Classic portal active | Enable the **Foundry (new)** toggle |
| No projects shown in wizard | AI Gateway not configured | Operate > Admin console > AI Gateway > Add |
| Agent registered but no traces | App Insights not connected | Connect App Insights to the project |
| 401 error via proxy URL | Auth not provided in call | Include auth headers from original endpoint |
| Network error during registration | ACA not publicly accessible | Check external ingress on ACA |

---

## Registration architecture

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

Foundry **does not modify** requests — it only routes them through APIM to gain visibility and control.
