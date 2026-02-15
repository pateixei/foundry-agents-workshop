# Lesson 6: Microsoft Agent 365 SDK Integration

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## Overview

This lesson enhances the LangGraph agent from Lesson 4 with Microsoft Agent 365 SDK features for observability, adaptive cards, and native M365 integration.

## Key Enhancements

### 1. Azure Monitor Observability
- OpenTelemetry tracing for all requests
- Tool execution monitoring
- Performance metrics
- Error tracking

### 2. Bot Framework Protocol  
- Native `/api/messages` endpoint for A365
- Activity-based conversation handling
- Multi-turn conversation support

### 3. Adaptive Cards
- Rich M365-optimized responses
- Interactive UI elements
- Better user experience

### 4. Enhanced Tools
- Instrumented with tracing spans
- Performance monitoring
- Usage analytics

## New Dependencies

```txt
# A365 SDK and Observability
azure-monitor-opentelemetry>=1.6.0
opentelemetry-api>=1.27.0
opentelemetry-sdk>=1.27.0
opentelemetry-instrumentation-fastapi>=0.48b0
botbuilder-core>=4.16.0
botbuilder-schema>=4.16.0
```

## Deployment

```powershell
cd lesson-6-a365-sdk
./deploy.ps1
```

Update A365 config with new endpoint:
```powershell
cd ../lesson-5-a365-prereq  
# Update messagingEndpoint in a365.config.json
a365 setup blueprint --skip-infrastructure
```

## Testing

```powershell
# Health check
Invoke-RestMethod "https://<endpoint>/health"

# Chat API
$body = @{message = "Qual o preco da PETR4?"} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/chat" -Method Post -Body $body -ContentType "application/json"

# Bot Framework Activity
$activity = @{
    type = "message"
    text = "Mostre um resumo do mercado"
    from = @{ id = "user123" }
    conversation = @{ id = "conv123" }
} | ConvertTo-Json
Invoke-RestMethod -Uri "https://<endpoint>/api/messages" -Method Post -Body $activity -ContentType "application/json"
```

## View Telemetry

Azure Portal → Application Insights → Transaction Search

## Next Steps

- Lesson 7: Publish to M365 Admin Center
- Lesson 8: Create agent instances in Teams
