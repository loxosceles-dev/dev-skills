---
name: skill-sync
description: "Use when updating/syncing skills across projects after modifying any skills repo (ai-dev, guitarizta-skills, local-skills). Covers the full workflow: authoring in the correct repo, pushing to main, and how APM deploys skills, agents, and hooks into devcontainers and the host machine."
---

# Skill Sync Workflow

## Three Skill Repos

| Repo | Purpose | Install in devcontainers? |
|------|---------|--------------------------|
| `loxosceles/ai-dev` | Coding, shared, project-setup skills — public | Yes (all projects) |
| `loxosceles/guitarizta-skills` | Guitarizta domain skills (alphatex, CRM, comms, KB, etc.) — private | Guitarizta projects only |
| `loxosceles/local-skills` | Host-machine-only admin tasks (invoice downloads, file processing) — private | **Never** |

Each repo also contains:
- `skills/` — the skill files (deployed by APM)
- `agents/kiro/` — Kiro agent JSON configs (host symlinks point here; APM bundles these into `apm_modules/` for containers)
- `.apm/agents/` — agent JSONs for APM deployment (mirrors `agents/kiro/` contents)
- `.apm/hooks/` — Kiro hooks (deployed by APM to `.kiro/hooks/`)
- `apm.yml` — APM package manifest at repo root

## How Skills, Agents, and Hooks Are Installed

**APM (Agent Package Manager)** replaces `npx skills add`. It is the single install mechanism for all three primitives across all environments.

```
__tools/ai-dev/              (authoring — coding/shared skills, agents, hooks)
__tools/guitarizta-skills/   (authoring — guitarizta skills + agents)
__tools/local-skills/        (authoring — host-only skills + agents)
        │  git push to main
        ▼
github.com/loxosceles/{repo}   (source of truth, SHA-pinned via apm.lock.yaml)
        │  apm install --frozen
        ▼
apm_modules/                   (downloaded packages, gitignored)
        │
        ├─ skills → .kiro/skills/        (Kiro — physical files, no symlinks)
        │         → .agents/skills/      (Claude Code / Codex / Copilot)
        │
        ├─ hooks  → .kiro/hooks/         (deployed from .apm/hooks/)
        │
        └─ agents → post_create.sh copies */agents/kiro/*.json → ~/.kiro/agents/
```

### Install command

```sh
# Inside a devcontainer or on the host (from project root):
uvx --from apm-cli==0.28.0 apm install --frozen
```

`--frozen` replays the exact SHAs from `apm.lock.yaml`. To update to latest main: `apm update` → regenerate lockfile → commit.

### Project manifest (`apm.yml`)

Every project has an `apm.yml` at root declaring its dependencies and targets:

```yaml
name: my-project
version: 1.0.0
targets:
  - kiro
  - claude
  - codex
  - copilot
  - agent-skills
dependencies:
  apm:
    - loxosceles/ai-dev#<sha>
  mcp: []
```

Alongside it: `apm.lock.yaml` (committed, SHA-pinned, never hand-edited).

## Agents

### Host machine

`~/.kiro/agents/` contains symlinks into the repos — never real files:

```
~/.kiro/agents/
  lead-dev.json      → __tools/ai-dev/agents/kiro/lead-dev.json
  code-reviewer.json → __tools/ai-dev/agents/kiro/code-reviewer.json
  critic.json        → __tools/ai-dev/agents/kiro/critic.json
  planner.json       → __tools/ai-dev/agents/kiro/planner.json
  guitarizta.json    → __tools/guitarizta-skills/agents/kiro/guitarizta.json
  personal.json      → __tools/local-skills/agents/kiro/personal.json
  destructor.json    → __tools/local-skills/agents/kiro/destructor.json
```

To recreate symlinks after a fresh clone:
```sh
AIDEV="/Volumes/DATA EXT/Development/Repositories/__tools/ai-dev/agents/kiro"
GTZ="/Volumes/DATA EXT/Development/Repositories/__tools/guitarizta-skills/agents/kiro"
LOCAL="/Volumes/DATA EXT/Development/Repositories/__tools/local-skills/agents/kiro"
for a in lead-dev code-reviewer critic planner; do
  ln -sf "$AIDEV/${a}.json" ~/.kiro/agents/${a}.json
done
ln -sf "$GTZ/guitarizta.json" ~/.kiro/agents/guitarizta.json
ln -sf "$LOCAL/personal.json" ~/.kiro/agents/personal.json
ln -sf "$LOCAL/destructor.json" ~/.kiro/agents/destructor.json
```

### Inside devcontainers

APM downloads agent JSON files into `apm_modules/`. `post_create.sh` copies them to `~/.kiro/agents/` after the install:

```sh
find "${WORKSPACE_ROOT}/apm_modules" -path "*/agents/kiro/*.json" \
  -exec cp {} "$HOME/.kiro/agents/" \;
```

This runs on every build and every start via `post_start.sh` — agents stay in sync with `main` automatically.

### Which repo for a new agent?

- General dev workflow agent → `ai-dev/agents/kiro/` + `ai-dev/.apm/agents/`
- Guitarizta-specific → `guitarizta-skills/agents/kiro/` + `guitarizta-skills/.apm/agents/`
- Host-only personal/admin → `local-skills/agents/kiro/` + `local-skills/.apm/agents/`

Agent vs skill: if it needs a specific persona, tool restrictions, or MCP config — agent. If it's a workflow the default agent follows — skill.

**When adding a new agent:** add the JSON to both `agents/kiro/` (for host symlinks) and `.apm/agents/` (for APM deployment). Commit both.

### Secrets in agents

Never hardcode credentials in agent JSON. Use env vars:
- Set secrets in `~/.secrets.d/<service>.env`
- `~/.zshrc` sources all `~/.secrets.d/*.env` — Kiro inherits them
- In the agent's `mcpServers.env` block, omit the key — the MCP process inherits it from Kiro

## Host Machine Skill Setup

Skills on the host are managed via APM global install from `~/.apm-host/`:

```
~/.apm-host/
  apm.yml          ← host manifest (all 3 repos)
  apm.lock.yaml    ← committed lockfile (in chezmoi dotfiles)
```

Host manifest:
```yaml
name: host
version: 1.0.0
dependencies:
  apm:
    - loxosceles/ai-dev
    - loxosceles/guitarizta-skills
    - loxosceles/local-skills
```

Install command (requires `GITHUB_APM_PAT_LOXOSCELES` in env for private repos):
```sh
source ~/.secrets.d/github.env
cd ~/.apm-host && apm install --frozen --global --target kiro
```

This deploys physical skill files to `~/.kiro/skills/`. The old symlink farm (`~/.kiro/skill-sets/coding/`, `shared/`) will be removed after Phase 2 migration is verified.

**Note: Phase 2 (host migration) is not yet complete.** Until then, the host still uses the legacy symlink setup. Do not run the global install until Phase 2 is executed.

## Authoring

- Edit the skill in the appropriate repo under `__tools/`
- Push directly to `main` (no PR needed for skill/agent-only changes)
- Skills are self-contained: `SKILL.md` + any scripts/assets in the same directory
- After pushing, running containers auto-refresh on next start via `post_start.sh`

**Which repo?**
- New coding pattern or guideline → `ai-dev`
- Guitarizta domain knowledge or tool → `guitarizta-skills`
- Host-only admin task → `local-skills`

## Pulling Skills Into a Running Container (Manual Refresh)

If you need to refresh skills in a running container without restarting:

```sh
docker exec -w /workspaces/<project> <container> \
  uvx --from apm-cli==0.28.0 apm install --frozen
```

To update to latest skills after pushing a change:
```sh
# 1. Update lockfile in project
cd /path/to/project
apm update          # re-resolves SHAs
git add apm.lock.yaml && git commit -m "chore: Update skill lockfile"

# 2. Rebuild or exec into container
docker exec -w /workspaces/<project> <container> \
  uvx --from apm-cli==0.28.0 apm install --frozen
```

### Container naming

Pattern: `<project>_devcontainer-dev-1` → workspace at `/workspaces/<project>`

## Installing Skills in post_create.sh / post_start.sh

The canonical pattern (already in can-do-it, will be rolled out to all projects):

**post_create.sh** (runs once on build):
```sh
# Clear any existing .kiro/skills so APM deploys physical files
rm -rf "${WORKSPACE_ROOT}/.kiro/skills"
mkdir -p "${WORKSPACE_ROOT}/.kiro/skills"
# Project install: skills + hooks
cd "${WORKSPACE_ROOT}" && uvx --from apm-cli==0.28.0 apm install --frozen
# Agent install: copy from apm_modules to ~/.kiro/agents/
mkdir -p "$HOME/.kiro/agents"
find "${WORKSPACE_ROOT}/apm_modules" -path "*/agents/kiro/*.json" \
  -exec cp {} "$HOME/.kiro/agents/" \;
```

**post_start.sh** (runs on every container start):
```sh
cd "${WORKSPACE_ROOT}" && \
  uvx --from apm-cli==0.28.0 apm install --frozen > /dev/null 2>&1 && \
  find "${WORKSPACE_ROOT}/apm_modules" -path "*/agents/kiro/*.json" \
    -exec cp {} "$HOME/.kiro/agents/" \; 2>/dev/null && \
  echo "✓ Skills, agents, hooks synced"
```

**Key facts:**
- `uvx` is pre-installed in the Dockerfile — no install step needed
- `--frozen` is mandatory — always replay the lockfile, never resolve fresh
- `apm.lock.yaml` must be committed alongside `apm.yml`
- `apm_modules/` is gitignored (APM adds this automatically)

## Credential Requirements

Private repos (`guitarizta-skills`, `local-skills`) require:
```sh
GITHUB_APM_PAT_LOXOSCELES="<token from: gh auth token>"
```

- **Host:** `~/.secrets.d/github.env` (sourced by zsh at login)
- **Devcontainers with guitarizta-skills:** `.devcontainer/.env` with `GITHUB_APM_PAT_LOXOSCELES=<token>`, injected via `runArgs: ["--env-file", ".devcontainer/.env"]` in `devcontainer.json`
- **`ai-dev` is public** — standard coding projects need no PAT

## Projects Using This System

| Project | Path | Container | APM status |
|---------|------|-----------|-----------|
| can-do-it | `__projects/can-do-it` | `can-do-it_devcontainer-dev-1` | ✅ Migrated |
| fckpaper | `__projects/fckpaper` | `fckpaper_devcontainer-dev-1` | Pending |
| viability-agents | `__guitarizta/viability-agents` | `viability-agents_devcontainer-dev-1` | Pending |
| career-match-engine | `__projects/career-match-engine` | `career-match-engine_devcontainer-dev-1` | Pending |
| guitarizta-landing-page | `__guitarizta/guitarizta-landing-page` | `guitarizta-landing-page_devcontainer-dev-1` | Pending |
| guitarizta-practice-plan | `__guitarizta/guitarizta-practice-plan` | `guitarizta-practice-plan_devcontainer-dev-1` | Pending |
| kiimana | `__projects/kiimana` | `kiimana_devcontainer-dev-1` | Pending |
| ai-portfolio | `__projects/ai-portfolio` | `ai-portfolio_devcontainer-dev-1` | Pending |

Pending projects still use `npx skills add` — they migrate when their blueprint is updated (Phase 1b, after can-do-it stability period).

## Migration State (as of 2026-08-19)

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Complete | `can-do-it` devcontainer migrated to APM |
| Phase 1b | ⏳ Waiting (1 week) | Blueprint update — roll out to all projects |
| Phase 2 | ⏳ Blocked on Phase 1b | Host machine global install |
| Phase 3 | 🔵 Separate track | Agent JSON → Markdown (Kiro v3) |
| Phase 4 | ⏳ Blocked on Phase 2 | VPS / Hermes |

Full plan: `__tools/ai-dev/docs/planning/apm-migration.md`

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
