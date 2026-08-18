---
name: mcp-server-setup
description: How to configure MCP servers for Kiro, VS Code, Claude, and Amazon Q in devcontainers. Follow when adding, debugging, or migrating MCP server configurations.
type: guideline
---

# MCP Server Setup

**This is a strict guideline.** Follow these rules exactly.

MCP server configuration in our devcontainer setup. A single source file is distributed to all agents by `post_create.sh`.

---

## Single Source of Truth

MCP servers are defined once in `~/.devcontainer-state/ai/mcp/servers.json` (gitignored, contains credentials). A committed template exists at `servers.json.template`.

On container start, `post_create.sh` distributes this file to:

| Agent | Destination | How |
|-------|------------|-----|
| Kiro CLI | `~/.kiro/settings/mcp.json` | Copy |
| Claude Code | `~/.claude/settings.json` | Merge `mcpServers` into existing settings |
| Amazon Q / Codex | `${WORKSPACE_ROOT}/.amazonq/mcp.json` | Copy |

**VS Code / Copilot** is the exception — `.vscode/mcp.json` uses a different format (`servers` key, `${ENV_VAR}` refs) and is committed to the repo. Maintain it separately.

---

## Source File Format

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

This format is shared by Kiro, Claude, and Amazon Q.

---

## VS Code Format

Different top-level key, env var references instead of raw values:

```json
{
  "servers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name"],
      "env": {
        "ENV_VAR": "${ENV_VAR}"
      }
    }
  }
}
```

---

## Known Servers and Their Env Vars

Use the exact env var names listed here. Mismatched names are the most common setup failure.

### Trello (`mcp-server-trello`)

```
TRELLO_API_KEY    — from https://trello.com/app-key
TRELLO_TOKEN      — NOT "TRELLO_API_TOKEN"
TRELLO_BOARD_ID   — optional, found in board URL
```

### GitHub (`@modelcontextprotocol/server-github`)

```
GITHUB_PERSONAL_ACCESS_TOKEN  — or GITHUB_TOKEN
```

---

## Adding a New MCP Server

### 1. Test the server manually in the container

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
  | ENV_VAR=value timeout 5 npx -y <package-name> 2>/dev/null
```

Expected: a JSON response with `result.serverInfo`. If you get an error about missing env vars, the var names are wrong — check the server's source or README.

### 2. Add to the source file

Edit `~/.devcontainer-state/ai/mcp/servers.json` on the host. Add the server entry with the exact env var names from the test.

### 3. Rebuild or re-run post_create.sh

The config is distributed on container start. Either rebuild the container or run `post_create.sh` manually.

### 4. Update VS Code config separately

If using Copilot, add the server to `.vscode/mcp.json` in the project repo using the `servers` format with `${ENV_VAR}` references.

---

## Devcontainer Considerations

- **Global npm packages persist** across rebuilds via `~/.cache/npm-global` (on the cache mount).
- **Credentials stay in devcontainer-state** (gitignored). They never appear in project repos — `.amazonq/` is gitignored, VS Code uses env var refs.
- **One edit, all agents** — change `servers.json` once, rebuild, and Kiro/Claude/Amazon Q all get the update.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Server not found | Package not installed | `npm install -g <package>` |
| "missing env var" error | Wrong env var name | Check Known Servers section; test manually |
| Server starts but agent can't connect | Config in wrong file or wrong format | Check `mcpServers` vs `servers` key |
| Config missing after rebuild | `servers.json` not on host | Check `~/.devcontainer-state/ai/mcp/servers.json` exists |
| Agent doesn't see config changes | Stale session | Restart the agent session |
| MCP warning on container start | `servers.json` not created yet | `cp servers.json.template servers.json` and fill in credentials |

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
