Add-Type -AssemblyName System.Drawing

$width = 1600
$height = 1050
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

# Colors
$bgColor = [System.Drawing.Color]::FromArgb(255, 248, 250, 253)
$rgBorder = [System.Drawing.Color]::FromArgb(255, 0, 120, 212)
$rgFill = [System.Drawing.Color]::FromArgb(20, 0, 120, 212)
$boxBorder = [System.Drawing.Color]::FromArgb(255, 180, 180, 180)
$accentBlue = [System.Drawing.Color]::FromArgb(255, 0, 120, 212)
$accentPurple = [System.Drawing.Color]::FromArgb(255, 135, 80, 185)
$accentGreen = [System.Drawing.Color]::FromArgb(255, 16, 124, 16)
$accentOrange = [System.Drawing.Color]::FromArgb(255, 202, 80, 16)
$accentTeal = [System.Drawing.Color]::FromArgb(255, 0, 133, 120)
$textDark = [System.Drawing.Color]::FromArgb(255, 50, 50, 50)
$textLight = [System.Drawing.Color]::FromArgb(255, 100, 100, 100)
$foundryBg = [System.Drawing.Color]::FromArgb(25, 135, 80, 185)
$foundryBorder = [System.Drawing.Color]::FromArgb(255, 135, 80, 185)
$containerBg = [System.Drawing.Color]::FromArgb(25, 16, 124, 16)
$containerBorder = [System.Drawing.Color]::FromArgb(255, 16, 124, 16)
$monitorBg = [System.Drawing.Color]::FromArgb(25, 202, 80, 16)
$monitorBorder = [System.Drawing.Color]::FromArgb(255, 202, 80, 16)

# Fonts
$titleFont = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$subtitleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$groupFont = New-Object System.Drawing.Font("Segoe UI Semibold", 13, [System.Drawing.FontStyle]::Bold)
$boxTitleFont = New-Object System.Drawing.Font("Segoe UI Semibold", 11, [System.Drawing.FontStyle]::Bold)
$boxDetailFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$iconFont = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Regular)

# Brushes
$bgBrush = New-Object System.Drawing.SolidBrush($bgColor)
$textBrush = New-Object System.Drawing.SolidBrush($textDark)
$textLightBrush = New-Object System.Drawing.SolidBrush($textLight)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$blueBrush = New-Object System.Drawing.SolidBrush($accentBlue)
$purpleBrush = New-Object System.Drawing.SolidBrush($accentPurple)
$greenBrush = New-Object System.Drawing.SolidBrush($accentGreen)
$orangeBrush = New-Object System.Drawing.SolidBrush($accentOrange)
$tealBrush = New-Object System.Drawing.SolidBrush($accentTeal)

# Pens
$rgPen = New-Object System.Drawing.Pen($rgBorder, 2.5)
$rgPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
$boxPen = New-Object System.Drawing.Pen($boxBorder, 1.5)
$arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 100, 100, 100), 1.8)
$arrowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
$foundryPen = New-Object System.Drawing.Pen($foundryBorder, 2)
$foundryPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::DashDot
$containerPen = New-Object System.Drawing.Pen($containerBorder, 2)
$containerPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::DashDot
$monitorPen = New-Object System.Drawing.Pen($monitorBorder, 2)
$monitorPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::DashDot

# Background
$g.FillRectangle($bgBrush, 0, 0, $width, $height)

# Title block
$g.FillRectangle($blueBrush, 0, 0, $width, 65)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$g.DrawString("Agent365 Workshop - Azure Architecture", $titleFont, $whiteBrush, [System.Drawing.RectangleF]::new(0, 12, $width, 45), $format)

# Subtitle
$g.DrawString("Resource Group: rg-ag365  |  Region: East US  |  8 Azure Resources", $subtitleFont, $textLightBrush, [System.Drawing.RectangleF]::new(0, 72, $width, 25), $format)

# Resource Group boundary
$rgRect = [System.Drawing.Rectangle]::new(30, 100, 1540, 910)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($rgFill)), $rgRect)
$g.DrawRectangle($rgPen, $rgRect)
$g.DrawString("Resource Group: rg-ag365", $groupFont, $blueBrush, 45, 108)

# Helper function to draw a resource box
function Draw-ResourceBox {
    param($x, $y, $w, $h, $icon, $title, $detail1, $detail2, $accentColor)
    $rect = [System.Drawing.Rectangle]::new($x, $y, $w, $h)
    $g.FillRectangle($whiteBrush, $rect)
    $g.DrawRectangle($boxPen, $rect)
    $accentBrush = New-Object System.Drawing.SolidBrush($accentColor)
    $g.FillRectangle($accentBrush, $x, $y, 5, $h)
    $g.DrawString($icon, $iconFont, $accentBrush, ($x + 12), ($y + 8))
    $titleBrush = New-Object System.Drawing.SolidBrush($accentColor)
    $g.DrawString($title, $boxTitleFont, $titleBrush, ($x + 50), ($y + 10))
    if ($detail1) { $g.DrawString($detail1, $boxDetailFont, $textLightBrush, ($x + 15), ($y + 35)) }
    if ($detail2) { $g.DrawString($detail2, $boxDetailFont, $textLightBrush, ($x + 15), ($y + 52)) }
    $accentBrush.Dispose()
    $titleBrush.Dispose()
}

# =========================================
# Monitoring group (top-left)
# =========================================
$monGroupRect = [System.Drawing.Rectangle]::new(55, 140, 480, 200)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($monitorBg)), $monGroupRect)
$g.DrawRectangle($monitorPen, $monGroupRect)
$g.DrawString("Monitoring & Observability", $groupFont, $orangeBrush, 70, 148)

Draw-ResourceBox 75 180 200 75 "L" "Log Analytics" "log-ai001" "Retention: 30 days" $accentOrange
Draw-ResourceBox 310 180 200 75 "A" "App Insights" "appi-ai001" "Type: Web" $accentOrange

# Arrow: Log Analytics -> App Insights
$g.DrawLine($arrowPen, 275, 218, 308, 218)

# =========================================
# Microsoft Foundry group (top-right) - unified AI
# =========================================
$foundryGroupRect = [System.Drawing.Rectangle]::new(570, 140, 970, 200)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($foundryBg)), $foundryGroupRect)
$g.DrawRectangle($foundryPen, $foundryGroupRect)
$g.DrawString("Microsoft Foundry (AI Services)", $groupFont, $purpleBrush, 585, 148)

# Foundry account inner box
$foundryInnerRect = [System.Drawing.Rectangle]::new(590, 175, 930, 150)
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 135, 80, 185))), $foundryInnerRect)
$g.DrawRectangle((New-Object System.Drawing.Pen($foundryBorder, 1.5)), $foundryInnerRect)
$g.DrawString("Foundry Account: ai-foundry001  (Kind: AIServices, allowProjectManagement: true)", $boxTitleFont, $purpleBrush, 605, 183)

# Model deployment
Draw-ResourceBox 610 215 310 75 "M" "Model Deployment" "gpt-4.1 (gpt-4o-mini)" "SKU: Standard  |  Capacity: 10" $accentPurple

# Foundry Project
Draw-ResourceBox 955 215 310 75 "P" "Foundry Project" "ag365-prj001" "Agent Framework host" $accentPurple

# Identity labels
$idFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$idBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 135, 80, 185))
$g.DrawString("SystemAssigned Identity", $idFont, $idBrush, 610, 298)
$g.DrawString("SystemAssigned Identity", $idFont, $idBrush, 955, 298)
$g.DrawString("OpenAI-compatible endpoint: ai-foundry001.cognitiveservices.azure.com", $idFont, $idBrush, 610, 313)
$idFont.Dispose()
$idBrush.Dispose()

# =========================================
# Container group (bottom)
# =========================================
$containerGroupRect = [System.Drawing.Rectangle]::new(55, 370, 1505, 340)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($containerBg)), $containerGroupRect)
$g.DrawRectangle($containerPen, $containerGroupRect)
$g.DrawString("Container Infrastructure", $groupFont, $greenBrush, 70, 378)

# ACR
Draw-ResourceBox 80 415 310 90 "R" "Container Registry" "acr123.azurecr.io" "SKU: Basic  |  Admin: Enabled" $accentGreen

# Container Apps Environment
$caeRect = [System.Drawing.Rectangle]::new(440, 415, 1095, 275)
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 16, 124, 16))), $caeRect)
$g.DrawRectangle((New-Object System.Drawing.Pen($containerBorder, 1.5)), $caeRect)
$g.DrawString("Container Apps Environment: cae-ai001", $boxTitleFont, $greenBrush, 455, 423)

# LangGraph Container App
Draw-ResourceBox 470 460 400 100 "C" "LangGraph Agent" "ca-lg-agent" "Image: containerapps-helloworld" $accentTeal

# Container App details
$detailFont = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$detailBrush = New-Object System.Drawing.SolidBrush($textLight)
$g.DrawString("CPU: 0.5  |  Memory: 1Gi", $detailFont, $detailBrush, 485, 570)
$g.DrawString("Scale: 1-3 replicas", $detailFont, $detailBrush, 485, 585)

# Ingress box
Draw-ResourceBox 470 610 400 50 ">" "Ingress (External)" "https://ca-lg-agent...azurecontainerapps.io" "" $accentTeal

# Env vars / secrets box
$envRect = [System.Drawing.Rectangle]::new(910, 460, 600, 210)
$g.FillRectangle($whiteBrush, $envRect)
$g.DrawRectangle($boxPen, $envRect)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($accentTeal)), 910, 460, 5, 210)

$envTitleBrush = New-Object System.Drawing.SolidBrush($accentTeal)
$g.DrawString("Environment & Secrets", $boxTitleFont, $envTitleBrush, 925, 468)

$envFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)
$envBrush = New-Object System.Drawing.SolidBrush($textDark)
$envY = 495
$envItems = @(
    "AZURE_OPENAI_ENDPOINT = aiFoundry.endpoint",
    "AZURE_OPENAI_DEPLOYMENT = gpt-4.1",
    "AZURE_OPENAI_API_KEY = [secret: from Foundry]",
    "APPINSIGHTS_CONN_STRING = [from appInsights]",
    "",
    "Registry: acr123.azurecr.io",
    "Secret: acr-password"
)
foreach ($item in $envItems) {
    if ($item -ne "") { $g.DrawString($item, $envFont, $envBrush, 925, $envY) }
    $envY += 18
}
$envTitleBrush.Dispose()
$envFont.Dispose()
$envBrush.Dispose()

# =========================================
# Connection arrows
# =========================================
$thickArrow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160, 100, 100, 100), 2)
$thickArrow.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
$thickArrow.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash

# ACR -> Container App (image pull)
$g.DrawLine($thickArrow, 390, 460, 468, 460)

# App Insights -> Container App (telemetry)
$g.DrawLine($thickArrow, 410, 256, 410, 368)

# Foundry -> Container App (API calls)
$g.DrawLine($thickArrow, 770, 340, 770, 368)

# Label arrows
$labelFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 80, 80, 80))
$g.DrawString("image pull", $labelFont, $labelBrush, 395, 440)
$g.DrawString("telemetry", $labelFont, $labelBrush, 352, 300)
$g.DrawString("API calls (OpenAI-compatible)", $labelFont, $labelBrush, 775, 348)

# Log Analytics <- App Insights
$g.DrawString("logs sink", $labelFont, $labelBrush, 195, 268)
$logArrow = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160, 202, 80, 16), 1.5)
$logArrow.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
$g.DrawLine($logArrow, 310, 256, 275, 290)
$g.DrawLine($logArrow, 175, 290, 175, 256)

# Log Analytics <- Container Apps Env
$g.DrawString("container logs", $labelFont, $labelBrush, 100, 340)
$g.DrawLine($logArrow, 175, 368, 175, 345)

$thickArrow.Dispose()
$labelFont.Dispose()
$labelBrush.Dispose()
$logArrow.Dispose()

# =========================================
# Resource count summary
# =========================================
$summaryY = 730
$summaryFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$summaryBoldFont = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Bold)

$g.DrawString("Resources (8):", $summaryBoldFont, $textBrush, 60, $summaryY)
$resources = @(
    @{ N = "1. Log Analytics Workspace"; C = $accentOrange },
    @{ N = "2. Application Insights"; C = $accentOrange },
    @{ N = "3. Foundry Account (AIServices)"; C = $accentPurple },
    @{ N = "4. Model Deployment (gpt-4.1)"; C = $accentPurple },
    @{ N = "5. Foundry Project (ag365-prj001)"; C = $accentPurple },
    @{ N = "6. Container Registry"; C = $accentGreen },
    @{ N = "7. Container Apps Environment"; C = $accentGreen },
    @{ N = "8. LangGraph Container App"; C = $accentTeal }
)

$col = 0
$rx = 60
$ry = $summaryY + 25
foreach ($r in $resources) {
    $rb = New-Object System.Drawing.SolidBrush($r.C)
    $g.FillRectangle($rb, $rx, ($ry + 4), 10, 10)
    $g.DrawString($r.N, $summaryFont, $textBrush, ($rx + 16), $ry)
    $rb.Dispose()
    $col++
    if ($col -eq 4) { $col = 0; $rx = 60; $ry += 22 }
    else { $rx += 380 }
}

$summaryFont.Dispose()
$summaryBoldFont.Dispose()

# =========================================
# Legend
# =========================================
$legendY = 810
$legendFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$g.DrawString("Legend:", $boxTitleFont, $textBrush, 60, $legendY)

$legendItems = @(
    @{ Color = $accentPurple; Label = "Microsoft Foundry / AI" },
    @{ Color = $accentGreen; Label = "Container Infrastructure" },
    @{ Color = $accentOrange; Label = "Monitoring" },
    @{ Color = $accentTeal; Label = "Container App" }
)
$lx = 140
foreach ($item in $legendItems) {
    $lb = New-Object System.Drawing.SolidBrush($item.Color)
    $g.FillRectangle($lb, $lx, ($legendY + 3), 14, 14)
    $g.DrawString($item.Label, $legendFont, $textBrush, ($lx + 20), $legendY)
    $lx += 200
    $lb.Dispose()
}
$legendFont.Dispose()

# Footer
$footerFont = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Italic)
$footerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 120, 120, 120))
$g.DrawString("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')  |  8 Azure Resources (Foundry-only, no standalone OpenAI)  |  Workshop Agent365", $footerFont, $footerBrush, [System.Drawing.RectangleF]::new(0, ($height - 30), $width, 25), $format)
$footerFont.Dispose()
$footerBrush.Dispose()

# Save
$outputPath = Join-Path $PSScriptRoot "..\slides\architecture-diagram.png"
$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Cleanup
$g.Dispose()
$bmp.Dispose()
$titleFont.Dispose()
$subtitleFont.Dispose()
$groupFont.Dispose()
$boxTitleFont.Dispose()
$boxDetailFont.Dispose()
$iconFont.Dispose()
$textBrush.Dispose()
$textLightBrush.Dispose()
$whiteBrush.Dispose()
$blueBrush.Dispose()
$purpleBrush.Dispose()
$greenBrush.Dispose()
$orangeBrush.Dispose()
$tealBrush.Dispose()
$bgBrush.Dispose()
$rgPen.Dispose()
$boxPen.Dispose()
$arrowPen.Dispose()
$foundryPen.Dispose()
$containerPen.Dispose()
$monitorPen.Dispose()
$detailFont.Dispose()
$detailBrush.Dispose()
$format.Dispose()

Write-Host "Diagrama atualizado salvo em: $outputPath" -ForegroundColor Green
Write-Host "  - Recurso Azure OpenAI standalone REMOVIDO" -ForegroundColor Yellow
Write-Host "  - Foundry account e agora o unico servico de AI" -ForegroundColor Yellow
Write-Host "  - 8 recursos no total" -ForegroundColor Yellow
