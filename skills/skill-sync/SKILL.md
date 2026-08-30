---
name: skill-sync
description: "Use when updating/syncing skills across projects after modifying any skills repo (dev-skills, guitarizta-skills, local-skills). Covers the full workflow: authoring in the correct repo, pushing to main, and how APM deploys skills, agents, and hooks on the host machine and into projects."
---

# Skill Sync Workflow

## Three Skill Repos

| Repo | Purpose | Scope |
|------|---------|-------|
| `loxosceles-dev/dev-skills` | Coding, shared, project-setup skills — public | All projects |
| `loxosceles/guitarizta-skills` | Guitarizta domain skills (KB, comms, ops, etc.) — private | Host + Guitarizta projects |
| `loxosceles/local-skills` | Host-machine-only admin tasks (invoice downloads, file processing) — private | Host only — never in projects |

Project-specific Guitarizta workflows belong as committed skills inside the project repo (`.kiro/skills/<skill-name>/SKILL.md`), not pulled from `guitarizta-skills`.

Each repo also contains:
- `skills/` — the skill files (deployed by APM)
- `agents/kiro/` — Kiro agent JSON configs (host symlinks point here; authoritative version)
- `.apm/agents/` — agent JSONs mirrored from `agents/kiro/` (APM currently skips these — see Agents section)
- `.apm/hooks/` — Kiro hooks (deployed by APM to `.kiro/hooks/`)
- `apm.yml` — APM package manifest at repo root

## How Skills, Agents, and Hooks Are Installed

**APM (Agent Package Manager)** is the single install mechanism for skills and hooks. Agents are currently managed via symlinks (see Agents section).

```
__tools/dev-skills/              (authoring — coding/shared skills, agents, hooks)
__tools/guitarizta-skills/   (authoring — guitarizta skills + agents)
__tools/local-skills/        (authoring — host-only skills + agents)
        │  git push to main
        ▼
github.com/loxosceles/{repo}   (source of truth, SHA-pinned via apm.lock.yaml)
        │  apm install --frozen
        ▼
apm_modules/                   (downloaded packages, gitignored)
        │
        ├─ skills → .kiro/skills/        (Kiro — flat, one dir per skill)
        │         → .agents/skills/      (Claude Code / Codex / Copilot)
        │
        └─ hooks  → .kiro/hooks/         (deployed from .apm/hooks/)
```

Skills are deployed **flat** into `~/.kiro/skills/` — one directory per skill, directly under the root. There are no package-name subdirectories.

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
    - loxosceles-dev/dev-skills#<sha>
  mcp: []
```

Alongside it: `apm.lock.yaml` (committed, SHA-pinned, never hand-edited).

## Agents

### Current mechanism: symlinks

`~/.kiro/agents/` contains symlinks into the repos. This is the current working mechanism — Kiro v3 supports JSON agents.

```
~/.kiro/agents/
  lead-dev.json      → __tools/dev-skills/agents/kiro/lead-dev.json
  code-reviewer.json → __tools/dev-skills/agents/kiro/code-reviewer.json
  critic.json        → __tools/dev-skills/agents/kiro/critic.json
  planner.json       → __tools/dev-skills/agents/kiro/planner.json
  guitarizta.json    → __tools/guitarizta-skills/agents/kiro/guitarizta.json
  personal.json      → __tools/local-skills/agents/kiro/personal.json
  destructor.json    → __tools/local-skills/agents/kiro/destructor.json
```

To recreate symlinks after a fresh clone or host setup:
```sh
AIDEV="/Volumes/DATA EXT/Development/Repositories/__tools/dev-skills/agents/kiro"
GTZ="/Volumes/DATA EXT/Development/Repositories/__tools/guitarizta-skills/agents/kiro"
LOCAL="/Volumes/DATA EXT/Development/Repositories/__tools/local-skills/agents/kiro"
for a in lead-dev code-reviewer critic planner; do
  ln -sf "$AIDEV/${a}.json" ~/.kiro/agents/${a}.json
done
ln -sf "$GTZ/guitarizta.json" ~/.kiro/agents/guitarizta.json
ln -sf "$LOCAL/personal.json" ~/.kiro/agents/personal.json
ln -sf "$LOCAL/destructor.json" ~/.kiro/agents/destructor.json
```

### Why APM doesn't deploy agents yet

APM (v0.28.0) expects Kiro agents as `.md` files with YAML frontmatter. Our agents are `.json` — APM silently skips them. Each repo has `.apm/agents/` with the JSON files mirrored there, but they're ignored at install time.

This will be resolved in Phase 3 when agents are converted to Markdown format. Until then, symlinks are the mechanism and `agents/kiro/` in each repo is the authoritative source.

**When adding or updating an agent:** edit `agents/kiro/<name>.json` in the appropriate repo, update the symlink if needed, commit and push. Mirror to `.apm/agents/` to keep it in sync for the eventual Phase 3 conversion.

### Which repo for a new agent?

- General dev workflow agent → `dev-skills`
- Guitarizta-specific → `guitarizta-skills`
- Host-only personal/admin → `local-skills`

**Agent vs skill:** If it needs a specific persona, tool restrictions, or MCP config — agent. If it's a workflow the default agent follows — skill.

### Secrets in agents

Never hardcode credentials in agent JSON. Use env vars:
- Set secrets in `~/.secrets.d/<service>.env`
- `~/.zshrc` sources all `~/.secrets.d/*.env` — Kiro inherits them
- In the agent's `mcpServers.env` block, omit the key — the MCP process inherits it from Kiro

## Host Machine Skill Setup

Skills on the host are managed via APM global install. The host manifest lives at `~/.apm/apm.yml`:

```yaml
name: host
version: 1.0.0
targets:
  - kiro
dependencies:
  apm:
    - loxosceles-dev/dev-skills
    - loxosceles-dev/agent-ops-skills
    - loxosceles-dev/shared-skills
    - loxosceles/guitarizta-skills
    - loxosceles/local-skills
  mcp: []
```

Install command (requires `GH_TOKEN` in env for private repos):
```sh
source ~/.secrets.d/gh.env
apm install --global --target kiro --force
```

To update to latest main across all packages:
```sh
source ~/.secrets.d/gh.env
apm update --yes   # re-resolves all SHAs, updates apm.lock.yaml, and installs
```

This deploys physical skill files flat to `~/.kiro/skills/<skill-name>/`.

**The `~/.secrets.d/gh.env` file exports `GH_TOKEN` (not `GITHUB_TOKEN`).**

## Authoring

### 🚨 Local edits are temporary — the repo is the source of truth

**A skill edited only in `.kiro/skills/` is not saved. It will be overwritten on the next `apm update`.**

Local is a scratch pad. The repo is truth. Pushing is mandatory, not a follow-up task.

### Skill edit workflow — follow this exactly

```
1. FIX     — edit the skill in the local .kiro/skills/<name>/SKILL.md
2. TEST    — trigger the skill in a real session; verify the behavior is correct
3. PUSH    — copy the verified change to __tools/<repo>/skills/<name>/SKILL.md
             append an entry to CHANGELOG.md (see skill-writing for log format)
             git add + commit: "fix: Update <name> skill — <one-line reason>"
             git push to main
4. SYNC    — pull from remote (NOT from local edits):
             source ~/.secrets.d/gh.env && apm update --yes
5. VERIFY  — confirm the deployed version matches the intended change
             A skill is not done until this step passes.
```

**Never skip steps 3–5.** If the session ends before step 3, the edit is lost. If you skip step 5, you have no confirmation the correct version was deployed.

**Which repo to edit?**

See `skill-routing` skill for the full decision tree. Quick summary:
- New coding pattern or guideline → `dev-skills`
- Guitarizta domain knowledge or tool → `guitarizta-skills`
- Host-only admin task → `local-skills`
- Project-specific workflow → commit directly to `.kiro/skills/` in the project repo

Other authoring notes:
- Skills are self-contained: `SKILL.md` + `CHANGELOG.md` + any scripts/assets in the same directory
- Push directly to `main` (no PR needed for skill/agent-only changes)

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

## Migration State (as of 2026-08-22)

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Complete | Core projects migrated |
| Phase 1b | ⏳ In progress | Roll out to remaining projects |
| Phase 2 | ✅ Complete | Host machine global APM install — skills deployed flat via APM |
| Phase 3 | 🔵 Separate track | Agent JSON → Markdown (Kiro v3 native format, unblocks APM agent deployment) |

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
