---
name: skill-routing
description: "Where does a new or updated skill belong? Use this before creating or modifying any skill to avoid placing it in the wrong package. Resolves agent confusion about the six possible destinations."
type: guideline
---

# Skill Routing

**This is a strict guideline.** Use this decision tree every time before creating or modifying a skill. Wrong placement causes skills to not load in the right context, or to pollute contexts where they don't belong.

---

## The Six Packages

| Package | Directory | Contains | Repo |
|---------|-----------|----------|------|
| `dev-skills` | `~/.kiro/skills/dev-skills/` | Code quality, software craft | `loxosceles-dev/dev-skills` |
| `agent-ops` | `~/.kiro/skills/agent-ops/` | How agents work: review pipelines, research, handoff, orchestration | `loxosceles/agent-ops-skills` |
| `shared` | `~/.kiro/skills/shared/` | Domain-agnostic tools: pdf, html, browser, publishing | `loxosceles/shared-skills` |
| `guitarizta` | `~/.kiro/skills/guitarizta/` | Guitarizta business, product, KB | `loxosceles/guitarizta-skills` |
| `local` | `~/.kiro/skills/local/` | This machine only: VPS, invoices, host-admin | `loxosceles/local-skills` |
| `3p/<vendor>` | `~/.kiro/skills/3p/<vendor>/` | Third-party packages, full install, never edited | upstream vendor repos |
| project | `.kiro/skills/` in the project repo | This project only | committed to the project |

---

## Decision Tree

```
Is this a third-party skill you don't own?
│
└─ YES → 3p/<vendor>/ — install full package via APM, cherry-pick per agent

Is this specific to one project only?
│
└─ YES → commit to .kiro/skills/ in that project repo

Is this about HOW agents work as agents?
(review pipelines, research, handoff, grilling, orchestration, synthesis)
│
└─ YES → agent-ops

Is this a tool any agent might use regardless of domain?
(pdf conversion, html reports, browser automation, publishing)
│
└─ YES → shared

Is this about code quality or software craft?
(git conventions, testing patterns, security, code review, frontend standards)
│
└─ YES → dev-skills

Is this Guitarizta business/product/KB?
│
└─ YES → guitarizta

Does it only make sense on this specific machine?
(hardcoded paths, host-specific services, machine-admin)
│
└─ YES → local
```

---

## Common Cases, Decided

| Skill | Package | Why |
|-------|---------|-----|
| `critic-dialogue` | `agent-ops` | Review pipeline — how agents do design reviews |
| `research` | `agent-ops` | How agents delegate investigation |
| `handoff` | `agent-ops` | Session continuity — agent workflow |
| `grilling` / `grill-me` | `agent-ops` | Thinking tool — agent workflow |
| `wayfinder` | `agent-ops` | Planning pipeline — agent workflow |
| `to-spec` | `agent-ops` | Synthesis workflow — agent workflow |
| `to-tickets` | `agent-ops` | Synthesis workflow — agent workflow |
| `prototype` | `agent-ops` | Exploration pattern — agent workflow |
| `markdown-to-pdf` | `shared` | Tool — domain-agnostic capability |
| `publish-html-report` | `shared` | Tool — domain-agnostic capability |
| `wizard` | `shared` | Tool — domain-agnostic capability |
| `playwright-service` | `shared` | Tool — browser automation |
| `git-commits` | `dev-skills` | Software craft |
| `core-principles` | `dev-skills` | Software craft |
| `tdd` | `dev-skills` | Software craft |
| `pr-reviewer` | `dev-skills` | Software craft |
| `pr-fixer` | `dev-skills` | Software craft |
| `skill-writing` | `dev-skills` | Meta — how to write skills (coding tooling) |
| `guitarizta-comms` | `guitarizta` | Domain-specific |
| `crm` | `guitarizta` | Domain-specific |
| `inbox-processing` | `guitarizta` | Domain-specific |
| `aws-invoice-download` | `local` | Machine-specific |
| `hermes-vps` | `local` | Machine-specific |
| `meeting-recorder` | `local` | Machine-specific |
| `grill-me` (mattpocock) | `3p/matt-pocock` | Third-party |

---

## The Glob Rule

**Own packages → directory glob in agent JSON. Third-party → exact paths.**

```json
// In an agent's resources field:
"skill://~/.kiro/skills/dev-skills/*/SKILL.md",       // glob — own package
"skill://~/.kiro/skills/agent-ops/*/SKILL.md",    // glob — own package
"skill://~/.kiro/skills/3p/matt-pocock/grill-me/SKILL.md",  // exact — 3p
```

Adding a new skill to an owned package = auto-discovered by all agents with that glob. No agent JSON update needed.

Adding a 3p skill = add the exact path to the specific agent(s) that need it.

---

## Where to Edit the File

```
dev-skills skill:    /Volumes/DATA EXT/Development/Repositories/__tools/dev-skills/skills/<name>/SKILL.md
agent-ops skill:     /Volumes/DATA EXT/Development/Repositories/__tools/agent-ops-skills/skills/<name>/SKILL.md
shared skill:        /Volumes/DATA EXT/Development/Repositories/__tools/shared-skills/skills/<name>/SKILL.md
guitarizta skill:    /Volumes/DATA EXT/Development/Repositories/__tools/guitarizta-skills/skills/<name>/SKILL.md
local skill:         /Volumes/DATA EXT/Development/Repositories/__tools/local-skills/skills/<name>/SKILL.md
project skill:       <project-root>/.kiro/skills/<name>/SKILL.md
3p skill:            do not edit — pull from upstream
```

After editing any owned repo, push to `main` directly. Then sync to host until Phase 2 APM migration completes:
```sh
cp "/Volumes/DATA EXT/Development/Repositories/__tools/<repo>/skills/<name>/SKILL.md" \
   ~/.kiro/skills/<package>/<name>/SKILL.md
```

---

## When a 3p Skill Needs to Diverge

If an upstream 3p skill doesn't behave the way you need:
1. Copy it into the appropriate owned package (`agent-ops/` or `shared/`)
2. Edit your copy
3. Remove the exact path from the agent JSON (the directory glob picks it up)
4. Remove that package from the APM dependency if you're no longer using any of its skills

---

## Anti-Patterns

❌ **Do not glob over `3p/`** — always cherry-pick 3p skills by exact path per agent.

❌ **Do not edit files in `~/.kiro/skills/3p/`** — they're overwritten on `apm update`.

❌ **Do not put a project-specific skill in any shared package** — commit it to the project's `.kiro/skills/` instead.

❌ **Do not add a skill to `dev-skills` that references Guitarizta-specific paths** — `dev-skills` is public and project-agnostic.

❌ **Do not hardcode machine paths in `dev-skills`, `agent-ops`, or `shared`** — machine paths belong in `local` or project skills only.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
