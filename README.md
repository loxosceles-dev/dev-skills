# ai-dev

Universal coding and project-setup skills and agents for all development projects.

**Scope:** General engineering practices — conventions, patterns, and tooling that apply regardless of stack. Safe to share with other developers and install in any project.

**Not here:** Opinionated stack-specific patterns (AWS/CDK/Lambda/SST/TypeScript stack decisions) live in [loxosceles/loxosceles-dev-tooling](https://github.com/loxosceles/loxosceles-dev-tooling). Those were factored out because they encode personal stack choices that are too specific to distribute as general dev tooling.

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
