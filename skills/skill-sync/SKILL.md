---
name: skill-sync
description: "Use when updating/syncing skills across projects after modifying any skills repo (ai-dev, guitarizta-skills, local-skills). Covers the full workflow: authoring in the correct repo, pushing to main, and how APM deploys skills, agents, and hooks on the host machine and into projects."
---

# Skill Sync Workflow

## Three Skill Repos

| Repo | Purpose | Scope |
|------|---------|-------|
| `loxosceles/ai-dev` | Coding, shared, project-setup skills — public | All projects |
| `loxosceles/guitarizta-skills` | Guitarizta domain skills (KB, comms, ops, etc.) — private | Host + Guitarizta projects |
| `loxosceles/local-skills` | Host-machine-only admin tasks (invoice downloads, file processing) — private | Host only — never in projects |

Project-specific Guitarizta workflows belong as committed skills inside the project repo (`.kiro/skills/<skill-name>/SKILL.md`), not pulled from `guitarizta-skills`.

Each repo also contains:
- `skills/` — the skill files (deployed by APM)
- `agents/kiro/` — Kiro agent JSON configs (host symlinks point here)
- `.apm/agents/` — agent JSONs for APM deployment
- `.apm/hooks/` — Kiro hooks (deployed by APM to `.kiro/hooks/`)
- `apm.yml` — APM package manifest at repo root

## How Skills, Agents, and Hooks Are Installed

**APM (Agent Package Manager)** is the single install mechanism for all three primitives.

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
        ├─ skills → .kiro/skills/        (Kiro)
        │         → .agents/skills/      (Claude Code / Codex / Copilot)
        │
        └─ hooks  → .kiro/hooks/         (deployed from .apm/hooks/)
```

### Install command

```sh
# From project root (or on the host):
uvx --from apm-cli==0.28.0 apm install --frozen
```

`--frozen` replays the exact SHAs from `apm.lock.yaml`. To update to latest main: `apm update` → regenerate lockfile → commit.

### Project manifest (`apm.yml`)

Every project has an `apm.yml` at root declaring its dependencies:

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

### Which repo for a new agent?

- General dev workflow agent → `ai-dev/agents/kiro/` + `ai-dev/.apm/agents/`
- Guitarizta-specific → `guitarizta-skills/agents/kiro/` + `guitarizta-skills/.apm/agents/`
- Host-only personal/admin → `local-skills/agents/kiro/` + `local-skills/.apm/agents/`

**Agent vs skill:** If it needs a specific persona, tool restrictions, or MCP config — agent. If it's a workflow the default agent follows — skill.

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

Install command (requires `GH_TOKEN` in env for private repos):
```sh
source ~/.secrets.d/github.env
cd ~/.apm-host && apm install --frozen --global --target kiro
```

This deploys physical skill files to `~/.kiro/skills/`.

**Until Phase 2 (host migration) is complete, updating a skill on the host requires a manual copy:**
```sh
cp "/Volumes/DATA EXT/Development/Repositories/__tools/ai-dev/skills/<skill-name>/SKILL.md" \
   ~/.kiro/skills/<skill-name>/SKILL.md
```

## Authoring

- Edit the skill in the appropriate repo under `__tools/`
- Push directly to `main` (no PR needed for skill/agent-only changes)
- Skills are self-contained: `SKILL.md` + any scripts/assets in the same directory

**Which repo?**

See `skill-routing` skill for the full decision tree. Quick summary:
- New coding pattern or guideline → `ai-dev`
- Guitarizta domain knowledge or tool → `guitarizta-skills`
- Host-only admin task → `local-skills`
- Project-specific workflow → commit directly to `.kiro/skills/` in the project repo

## Projects Using This System

| Project | Path | APM status |
|---------|------|-----------|
| can-do-it | `__projects/can-do-it` | ✅ Migrated |
| guitarizta-practice-plan | `__guitarizta/guitarizta-practice-plan` | ✅ Migrated |
| guitar-notation-studio | `__guitarizta/guitar-notation-studio` | ✅ Migrated |
| guitarizta-services | `__guitarizta/guitarizta-services` | ✅ Migrated |
| fckpaper | `__projects/fckpaper` | Pending |
| viability-agents | `__guitarizta/viability-agents` | Pending |
| career-match-engine | `__projects/career-match-engine` | Pending |
| guitarizta-landing-page | `__guitarizta/guitarizta-landing-page` | Pending |
| kiimana | `__projects/kiimana` | Pending |
| ai-portfolio | `__projects/ai-portfolio` | Pending |

## Migration State (as of 2026-08-21)

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Complete | Core projects migrated |
| Phase 1b | ⏳ Waiting | Roll out to remaining projects |
| Phase 2 | ⏳ Blocked on Phase 1b | Host machine global APM install |
| Phase 3 | 🔵 Separate track | Agent JSON → Markdown (Kiro v3) |

Note: Devcontainers are being removed from all projects. The APM install pattern runs on the host machine directly — no containers involved.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
