---
name: critic-dialogue
description: Iterative critic-and-dev discussion thread for planning docs, architecture decisions, and design specs. Apply when you want an independent critic to challenge a document and the dev to respond — back and forth until the design scores 4/5 or higher, with a planner arbitrating if consensus isn't reached.
type: pattern
---

# Critic Dialogue

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

---

## Problem

Documents get written, self-reviewed, and committed. The writer can't see their own blind spots. One-shot reviews don't close the loop — the dev accepts or ignores findings with no record of the reasoning, and no enforcement that the issues were actually resolved.

## Solution

A persistent discussion thread where an independent critic scores each document and the dev responds point by point. The loop runs until all documents score 4/5 or higher (max 3 passes). If consensus isn't reached, a planner arbitrates — reading the full thread and making explicit OVERRULE / UPHOLD / THIRD_PATH calls per unresolved point. The thread is the complete history of the dialogue.

---

## Pipeline

```
critic → dev-response ⟲ (max 3, gate: score ≥ 4/5) → planner (if needed) → finalizer
```

| Stage | Role | Trigger |
|-------|------|---------|
| critic | Scores docs, writes critique entry | Always first |
| dev-response | Responds point by point | `NEEDS_WORK` in critic output |
| planner | Arbitrates unresolved points | After 3 failed passes |
| finalizer | Applies accepted changes | `APPROVED` or after planner |

The critic outputs `APPROVED` or `NEEDS_WORK` at the end of every entry. The pipeline reads these exact words to decide whether to loop or proceed.

---

## The Score Gate

The critic scores each document 1–5:

| Score | Meaning |
|-------|---------|
| 5/5 | No material issues. Ready to proceed. |
| 4/5 | Minor issues only. Can proceed once addressed. |
| 3/5 | Significant concerns. Must go back to dev. |
| 2/5 | Fundamental problems. Substantial rework needed. |
| 1/5 | Wrong approach. Start over. |

Gate is **4/5**. `APPROVED` only when every document scores 4 or higher. Any document below 4 → `NEEDS_WORK` → loop back to dev.

---

## The Discussion Thread

```
docs/planning/discussions/{topic}.md   ← the thread file
```

Every stage appends a timestamped entry. Never overwrite. The file is the full history from first critique to final resolution.

```markdown
## YYYY-MM-DD HH:MM — Critic
[findings + scores + APPROVED/NEEDS_WORK]

## YYYY-MM-DD HH:MM — Dev
[point-by-point response]

## YYYY-MM-DD HH:MM — Planner   ← only if 3 passes exhausted
[OVERRULE/UPHOLD/THIRD_PATH per unresolved point]
```

---

## The Four Prompt Files

Copy these into your project under `.kiro/prompts/` and paste into subagent stage prompts.

### `critic-lens.md` — critic's turn
Reads the document (and existing thread if present). Writes a critique entry with findings per dimension, per-document scores, and a `APPROVED` or `NEEDS_WORK` gate verdict.

### `dev-respond.md` — dev's turn
Reads the latest critic entry. Responds point by point: where they're pushing back and why, and how they'll resolve what they accept. Notes any topics that need a separate doc reviewed first.

### `planner-arbitrate.md` — planner's turn
Reads the full thread. Makes one call per unresolved point:
- **OVERRULE CRITIC** — concern valid in abstract, not material here, proceed
- **UPHOLD CRITIC** — concern real, dev must address before finalizer runs
- **THIRD PATH** — neither framing is right, here's the alternative

The planner is not a second critic and not the dev's advocate. Their goal is a working solution, not a perfect one.

### (no prompt file needed for finalizer)
Reads the discussion thread, applies all accepted/upheld changes, outputs final documents.

---

## Subagent Stage Configuration

```yaml
stages:
  - name: critic
    role: critic
    model: claude-sonnet-4-5
    prompt: |
      [paste critic-lens.md content]
      Document to review: {path}
      Discussion file: docs/planning/discussions/{topic}.md

  - name: dev-response
    role: lead-dev
    depends_on: [critic]
    prompt: |
      [paste dev-respond.md content]
      Discussion file: docs/planning/discussions/{topic}.md
    loop_to:
      target: critic
      trigger: "NEEDS_WORK"
      max_iterations: 3

  - name: planner
    role: kiro_planner
    depends_on: [dev-response]
    prompt: |
      [paste planner-arbitrate.md content]
      Discussion file: docs/planning/discussions/{topic}.md

  - name: finalizer
    role: lead-dev
    depends_on: [planner]
    prompt: |
      Read docs/planning/discussions/{topic}.md.
      Apply all changes the dev accepted, all points the planner upheld, and any THIRD_PATH alternatives.
      Output final documents with FILE: headers.
```

The finalizer always runs — after `APPROVED` the planner stage is a no-op (nothing to arbitrate), and the finalizer applies the minor accepted changes cleanly.

---

## Entry Points

There are two ways into the pipeline. Same stages, different starting point.

### Entry point 1 — planner agent (proactive, standard path)

Switch to the `planner` agent. Ask it to design or spec something. It writes the document and **automatically kicks off the full pipeline** — you never have to ask for a review. The task isn't done until the gate is cleared.

```
you → planner agent → [writes doc] → critic → dev-response ⟲ → planner (arbitrate) → finalizer
```

### Entry point 2 — any agent (reactive, existing doc)

You're in any agent — lead-dev, or wherever. You have a doc that was written earlier and want it reviewed:

> "Pass `docs/planning/intake-design.md` to the critic"

The agent reads this skill and kicks off the pipeline **from the critic stage** — no writer stage, the doc already exists.

```
existing doc → critic → dev-response ⟲ → planner (arbitrate) → finalizer
```

Both paths use the same subagent stage config. The only difference is whether a writer stage runs first.

---

## When to Use

- Planning documents that gate implementation work
- Architecture decisions that will be cited as records
- Specs that multiple components will be built against
- Any document where "the writer reviewing their own work" is a meaningful risk

## When NOT to Use

- Quick reference notes and dev logs
- In-progress working documents not yet at decision stage
- Single-file changes where the cost of a review cycle exceeds the risk

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
