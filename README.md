# ai-dev

Coding and project-setup skills and agents for all development projects.

## Install skills into a project

```sh
npx -y skills add loxosceles/ai-dev --agent claude-code github-copilot codex kiro-cli -y
```

## Structure

```
skills/
  guidelines/     — Strict rules. Follow exactly.
  patterns/       — Reference implementations. Learn and adapt, don't copy.
  project-setup/  — Project scaffolding and migration tools.

agents/
  kiro/           — Kiro agent JSON configs (synced into containers via post_create.sh)
```

Skills use category subdirectories because of scale (29 skills). Each category maps to a distinct type of instruction.

## Agents

Containers get these agents on every build via `post_create.sh`. On the host, `~/.kiro/agents/` symlinks point here.

| Agent | Purpose |
|-------|---------|
| `lead-dev` | Default dev agent — loads project skills, defers to specialists |
| `code-reviewer` | PR review with tiered sub-agents (Sonnet + Opus) |
| `critic` | Adversarial review of plans, designs, code, decisions |
| `planner` | Design and architecture docs, auto-runs critic pipeline |
