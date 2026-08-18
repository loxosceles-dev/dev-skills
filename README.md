# ai-dev

Coding and project-setup skills and agents for all development projects.

## Install skills into a project

```sh
npx -y skills add loxosceles/ai-dev --agent claude-code github-copilot codex kiro-cli -y
```

## Structure

```
skills/
  {skill-name}/   — flat, one dir per skill (same as guitarizta-skills and local-skills)
    SKILL.md
    scripts/      ← where applicable

agents/
  kiro/           — Kiro agent JSON configs (synced into containers via post_create.sh)
```

## Agents

Containers get these agents on every build via `post_create.sh`. On the host, `~/.kiro/agents/` symlinks point here.

| Agent | Purpose |
|-------|---------|
| `lead-dev` | Default dev agent — loads project skills, defers to specialists |
| `code-reviewer` | PR review with tiered sub-agents (Sonnet + Opus) |
| `critic` | Adversarial review of plans, designs, code, decisions |
| `planner` | Design and architecture docs, auto-runs critic pipeline |
