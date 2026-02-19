# Lesson 7: Publishing Your Agent to Microsoft 365 Admin Center

> 🇧🇷 **[Leia em Português (pt-BR)](README.pt-BR.md)**

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:
1. **Run** `a365 publish` to package and submit your agent to the Microsoft 365 admin center
2. **Customize** the agent manifest (name, version, descriptions, icons)
3. **Verify** successful publication in the Microsoft 365 admin center registry
4. **Understand** the full publish pipeline: manifest → package → upload → access → federation → Graph permissions
5. **Troubleshoot** common publish failures

---

## Overview

After completing the setup steps in Lesson 6 (blueprint creation, permissions, endpoint registration), you publish the agent to the Microsoft 365 admin center using the `a365 publish` command.

Publishing creates a **Teams app package** from your agent blueprint and makes it visible in the Microsoft 365 admin center as a managed agent. Once published, admins can onboard instances of your agent in Microsoft Teams.

> **Important:** `a365 publish` requires the Frontier preview program to be enabled for your tenant and the user to have the **Agent ID Developer**, **Agent ID Administrator**, or **Global Administrator** role.

---

## Architecture: Publication Pipeline

```
Developer Machine                   Microsoft Services
        |                                    |
        |  a365 publish                      |
        |  1. Update manifest.json           |
        |  2. Pause for customization        |
        |  3. Package → manifest.zip         |
        |  4. Add API permissions     ------>|  Microsoft Entra ID
        |  5. Upload package          ------>|  M365 Titles Service
        |  6. Configure user access          |
        |  7. Setup federated identity ---|->|  Blueprint App (Entra)
        |  8. Grant Graph permissions        |
        |       ✅ Published                 |
        |                                    |  admin.cloud.microsoft
        |                                    |  Registry tab: agent visible
```

---

## Prerequisites

Before running `a365 publish`, ensure:

1. ✅ **Lesson 6 completed** — the following setup commands ran successfully:
   ```powershell
   a365 setup blueprint --endpoint-only   # or a365 setup all on first-time setup
   a365 setup permissions mcp
   a365 setup permissions bot
   ```
2. ✅ **Agent Blueprint exists** — `a365.generated.config.json` contains a non-empty `agentBlueprintId`
3. ✅ **Messaging endpoint is reachable** — endpoint returns HTTP 200
4. ✅ **Authenticated** — active `az login` session for the M365 tenant
5. ✅ **Role** — Global Administrator, Agent ID Administrator, or Agent ID Developer
6. ✅ **Config files present** — `a365.config.json` and `a365.generated.config.json` in the working directory

### Verify readiness

```powershell
cd lesson-6-a365-prereq\labs\solution

# Display current config and confirm agentBlueprintId is filled
a365 config display -g
```

Look for `agentBlueprintId` — it must be a non-empty UUID. If empty, re-run Lesson 6 setup.

---

## Step 1: Run `a365 publish`

Run the publish command from the directory that contains your `a365.config.json`:

```powershell
cd lesson-6-a365-prereq\labs\solution
a365 publish
```

> **Note:** `a365 publish` does **not** accept a `--config` flag. It always auto-detects `a365.config.json` from the current working directory. Make sure to `cd` into the correct directory first.

### What the command does (in order)

| # | Action | Result |
|---|--------|--------|
| 1 | Updates `manifest.json` with your blueprint ID | `manifest/manifest.json` created |
| 2 | **Pauses** — prompts to open and customize the manifest | (interactive prompt) |
| 3 | Packages manifest + icons into a zip | `manifest/manifest.zip` created |
| 4 | Adds required API permissions to your custom client app | Entra permission grant |
| 5 | Uploads the package to the M365 Titles service | Agent entry in admin center |
| 6 | Configures title access for all users | Availability: All Users |
| 7 | Sets up workload identity / federated credentials on blueprint app | 2 FICs on blueprint app |
| 8 | Grants Microsoft Graph permissions to the blueprint service principal | Graph consent |

---

## Step 2: Customize the Agent Manifest

When the CLI pauses, it shows output similar to:

```
=== MANIFEST UPDATED ===
Location: ...\manifest\manifest.json

=== CUSTOMIZE YOUR AGENT MANIFEST ===
  Version ('version')          - increment for republishing (e.g. 1.0.0 → 1.0.1)
  Agent Name ('name.short')    - MUST be 30 characters or fewer
  Agent Name ('name.full')     - full descriptive name
  Descriptions                 - 'description.short' and 'description.full'
  Developer Info               - developer.name, websiteUrl, privacyUrl
  Icons                        - replace color.png and outline.png

Open manifest in your default editor now? (Y/n):
```

Open `manifest/manifest.json` and update the key fields:

```json
{
  "version": "1.0.0",
  "name": {
    "short": "Financial Market Agent",
    "full": "Financial Market Agent (A365 Workshop)"
  },
  "description": {
    "short": "AI agent for real-time stock and financial data.",
    "full": "LangGraph-based agent providing real-time stock prices, financial news, and portfolio insights via the Microsoft Agent 365 platform."
  },
  "developer": {
    "name": "Workshop Developer",
    "websiteUrl": "https://example.com",
    "privacyUrl": "https://example.com/privacy",
    "termsOfUseUrl": "https://example.com/terms"
  }
}
```

> **Rules:**
> - `name.short` must be **≤ 30 characters**
> - `version` must be **higher** than any previously published version
> - Do **not** change the `id` or `bots[0].botId` fields — these were injected by the CLI and must match your blueprint ID

When done editing, return to the terminal and type:

```
continue
```

---

## Step 3: Verify Successful Publication

### Expected CLI output

```
✅ Upload succeeded
✅ Title access configured for all users
✅ Microsoft Graph permissions granted successfully
✅ Agent blueprint configuration completed successfully
✅ Publish completed successfully!
```

### Check manifest files were created

```powershell
Test-Path lesson-6-a365-prereq\labs\solution\manifest\manifest.json   # → True
Test-Path lesson-6-a365-prereq\labs\solution\manifest\manifest.zip    # → True
```

### Check the Microsoft 365 admin center

1. Go to [https://admin.cloud.microsoft/#/agents/all](https://admin.cloud.microsoft/#/agents/all)
2. Open the **Registry** tab
3. Your agent (e.g. "Financial Market Agent") should appear with **Availability: All Users** ✅

> **Note:** It may take **5–10 minutes** after publishing for the agent to appear. Refresh the page if not visible immediately.

### Check federated identity credentials

1. [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations** → search for your blueprint app
2. **Certificates & secrets** → **Federated credentials**
3. You should see **2 federated identity credentials (FICs)** ✅

---

## Available `a365 publish` Options

```
a365 publish [options]

Options:
  --dry-run         Show changes without writing files or calling APIs
  --skip-graph      Skip Graph federated identity and role assignment steps
  --mos-env <env>   MOS environment identifier (e.g. prod, dev) [default: prod]
  --mos-token <t>   Override MOS token — bypass script and cache
  -v, --verbose     Enable verbose logging
```

**Dry-run example** — preview what would happen without making changes:

```powershell
a365 publish --dry-run
```

---

## Troubleshooting

### `Agent already exists` error

**Cause:** The same version number is already published.  
**Fix:** Increment `version` in `manifest/manifest.json` and run `a365 publish` again.

```json
"version": "1.0.1"
```

### `Permissions missing` error

**Cause:** Blueprint or MCP permissions weren't completed in setup.  
**Fix:**
```powershell
cd lesson-6-a365-prereq\labs\solution
a365 setup permissions mcp --config a365.config.json
a365 setup permissions bot --config a365.config.json
a365 publish
```

### Agent not appearing in admin center after 10+ minutes

1. Verify all ✅ lines appeared in CLI output — if not, re-run `a365 publish`
2. Use `admin.cloud.microsoft` (not `admin.microsoft.com`) — the Agents registry is at the new URL
3. Confirm you're signed into the correct M365 tenant in the browser
4. Check `agentBlueprintId` in `a365.generated.config.json` is non-empty

### `manifest.json` missing blueprint ID (shows placeholder `${{TEAM_APP_ID}}`)

**Cause:** `a365 publish` ran before `a365 setup all` completed successfully.  
**Fix:** Verify `a365.generated.config.json` has `agentBlueprintId`, then re-run `a365 publish`.

---

## Cleanup Commands

```powershell
# Remove the agent instance identity from Entra (if instances were created in Lesson 8)
a365 cleanup instance --config a365.config.json

# Remove the blueprint registration from Entra (also removes from admin center)
a365 cleanup blueprint --config a365.config.json

# Remove Azure resources (App Service, App Service Plan)
a365 cleanup azure --config a365.config.json
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `a365 publish` | Package and publish agent to M365 admin center |
| `a365 publish --dry-run` | Preview publish changes without executing |
| `a365 config display -g` | Display current config (verify agentBlueprintId) |
| `a365 query-entra blueprint-scopes` | List configured scopes and consent status on blueprint |
| `a365 cleanup blueprint` | Remove blueprint from Entra |
| `a365 cleanup instance` | Remove agent instance/user from Entra |

---

## ❓ Frequently Asked Questions

**Q: Do I need to re-publish after changing the agent code?**  
A: No. Code changes behind the same messaging endpoint URL take effect immediately with no re-publish required. Re-publish only when the manifest changes (name, icon, permissions) or the endpoint URL changes.

**Q: Do I need admin approval before the agent appears in admin center?**  
A: No — `a365 publish` uploads directly to your tenant's admin center registry. In the workshop, you are the admin. Instance *creation* (Lesson 8) is where admin approval occurs.

**Q: Can I re-publish without deleting the old version?**  
A: Yes. Increment `version` in `manifest/manifest.json` and run `a365 publish` again.

**Q: What if I need to update the messaging endpoint URL?**  
A: Run the endpoint update command first, then re-publish:
```powershell
# Update the registered endpoint
a365 setup blueprint --endpoint-only --update-endpoint "https://new-url/api/messages" --config a365.config.json
# Re-publish manifest
a365 publish
```

**Q: What does `--skip-graph` do?**  
A: Skips steps 7 and 8 (federated identity and Graph permission grants). Useful if those were already configured or if you want to manage permissions manually.

---

## Next Steps

**Lesson 8**: Configure the agent in Teams Developer Portal, request an agent instance in Teams, and start interacting with your agent.

---

## References

- [Microsoft Agent 365 — Publish to Admin Center](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/publish)
- [Agent 365 Development Lifecycle](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/a365-dev-lifecycle)
- [Agent 365 CLI Reference — publish command](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/reference/cli/publish)
- [Microsoft 365 Admin Center — Agents Registry](https://admin.cloud.microsoft/#/agents/all)
