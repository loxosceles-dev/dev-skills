---
name: skill-routing
description: "Where does a new or updated skill belong? Use this before creating or modifying any skill to avoid placing it in the wrong repo. Resolves agent confusion about the four possible destinations."
type: guideline
---

# Skill Routing

**This is a strict guideline.** Use this decision tree every time before creating or modifying a skill. Wrong placement causes skills to not load in the right context, or to pollute contexts where they don't belong.

---

## The Four Destinations

| Destination | When | Examples |
|------------|------|---------|
| **Project `.kiro/skills/`** | Applies to THIS project only, not reusable elsewhere | `guitarizta-services` domain rules, this project's CI pattern |
| **`loxosceles/ai-dev`** | Universal coding skill, any developer on any project would use it | `git-commits`, `core-principles`, `tdd`, `code-review` |
| **`loxosceles/guitarizta-skills`** | Guitarizta business/product/ops skill, not general coding | `guitarizta-comms`, `crm`, `inbox-processing`, `transcript-extraction` |
| **`loxosceles/local-skills`** | Only makes sense on this specific machine, never in projects | `aws-invoice-download`, `meeting-recorder`, `hermes-vps` |

---

## Decision Tree

```
Is the skill useful in ANY coding project (not just this one)?
│
├─ YES → Is it universally applicable regardless of domain?
│         │
│         ├─ YES → ai-dev repo
│         │         (git-commits, core-principles, tdd, code-review, etc.)
│         │
│         └─ NO, it's Guitarizta-specific coding → guitarizta-skills repo
│
└─ NO → Does it require being on THIS machine (paths, secrets, local tools)?
          │
          ├─ YES → local-skills repo
          │         (invoice download, VPS management, machine-specific paths)
          │
          └─ NO, it's project-specific → commit to .kiro/skills/ in the project
                  (domain rules, project-specific workflows, this repo's patterns)
```

---

## Common Cases, Decided

| Skill | Where it goes | Why |
|-------|--------------|-----|
| How to write git commits | `ai-dev` | Universal coding |
| How to review PRs | `ai-dev` | Universal coding |
| How to write tests TDD-style | `ai-dev` | Universal coding |
| How to write a Kiro skill | `ai-dev` | Universal coding tooling |
| Guitarizta voice/comms guidelines | `guitarizta-skills` | Domain-specific |
| How to use the Guitarizta CRM | `guitarizta-skills` | Domain-specific |
| How to process transcripts | `guitarizta-skills` | Domain-specific |
| How to manage the Hermes VPS | `local-skills` | Machine-specific |
| How to download AWS invoices | `local-skills` | Machine-specific |
| Domain rules for guitarizta-services | project `.kiro/skills/` | Project-specific |
| This project's deployment workflow | project `.kiro/skills/` | Project-specific |

---

## Where to Edit the File

Once you know the destination, the file path follows:

```
Project skill:    <project-root>/.kiro/skills/<name>/SKILL.md

ai-dev:           /Volumes/DATA EXT/Development/Repositories/__tools/ai-dev/skills/<name>/SKILL.md

guitarizta-skills: /Volumes/DATA EXT/Development/Repositories/__tools/guitarizta-skills/skills/<name>/SKILL.md

local-skills:     /Volumes/DATA EXT/Development/Repositories/__tools/local-skills/skills/<name>/SKILL.md
```

After editing `ai-dev`, `guitarizta-skills`, or `local-skills`, push to `main` directly — no PR needed for skill-only changes. Then copy to host manually until Phase 2 APM migration completes:

```sh
cp "/Volumes/DATA EXT/Development/Repositories/__tools/ai-dev/skills/<name>/SKILL.md" \
   ~/.kiro/skills/<name>/SKILL.md
```

---

## What Goes in a Skill

See `skill-writing` skill for format and frontmatter rules.

The critical fields:
- `name` — matches the directory name
- `description` — one sentence that tells an agent WHEN to use this skill
- `type` — `guideline` (strict, follow exactly) or `pattern` (adapt to context)

---

## Anti-Patterns

❌ **Do not create a skill in `ai-dev` that references Guitarizta-specific paths or tools.** `ai-dev` is public and project-agnostic.

❌ **Do not put a project-specific skill in `guitarizta-skills`.** The guitarizta-skills repo is for domain skills that apply across all Guitarizta work, not for one project's patterns.

❌ **Do not hard-code machine paths in `ai-dev` or `guitarizta-skills`.** Machine paths (`/Volumes/DATA EXT/...`) belong in `local-skills` or project skills only.

❌ **Do not duplicate a skill across repos.** If a skill already exists in `ai-dev`, don't copy it to `guitarizta-skills`. Reference it or link to it.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
