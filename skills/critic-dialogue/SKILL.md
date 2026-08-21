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
| 5/5 | No material issues. |
| 4/5 | Minor issues only — document is ready, dev handles in implementation. |
| 3/5 | Significant concerns. Must go back to dev. |
| 2/5 | Fundamental problems. Substantial rework needed. |
| 1/5 | Wrong approach. Start over. |

Gate is **4/5**. Score ≥ 4 → `APPROVED`. Score < 4 → `NEEDS_WORK`. The gate decision is mechanical — minor issues at 4/5 do not trigger another loop.

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

### `final-gate.md` — lead-dev's turn
Reads the full thread and the resulting proposed changes. Checks against project conventions, right problem, right angle, integration, testability, scope, and conflicts. Outputs SHIP or HOLD with a specific blocker for each HOLD. This is the merge decision — not more critique, not more design, just acceptance or rejection.

### (no prompt file needed for finalizer)
Reads the discussion thread, applies all accepted/upheld changes, outputs final documents.

---

## Large Document Pipeline

When a document is too large for a single critic pass — implementation plans with multiple phases, large PRs, strategy docs, books — use the chunked pipeline instead. The standard pipeline above is for single documents or small focused specs.

### The problem it solves

A critic reading a 6-phase implementation plan will flag gaps in phase 4 that were already handled in phase 1. The critic has no way to know. The result is noise: the dev spends cycles explaining that the missing thing exists, the critic loops, nothing improves.

### How it works

```
chunker → [critic-1 ⟲ dev-1, critic-2 ⟲ dev-2, ... critic-N ⟲ dev-N] (parallel) → aggregator → final-gate
```

The chunker reads the full document, identifies natural boundaries (phases, modules, sections, chapters), and wraps each chunk in a context envelope: what's already settled in preceding chunks, what's coming in following chunks, and the chunk content itself. The critic for each chunk only sees its envelope — focused scope, correct context.

Each chunk runs a full critic/dev loop independently and in parallel. The dev responds to the critic's findings for that chunk; the critic loops back if unresolved (max 3 passes). No per-chunk planner — unresolved threads after 3 passes are flagged by the aggregator instead.

The aggregator runs after all pairs are done. It receives 10 settled, closed threads (resolved positions, not open findings) and checks for cross-chunk issues that isolated critics couldn't see: contradictions, orphaned dependencies, scope overlaps, ordering violations. It produces a unified gate verdict before final-gate runs.

### Chunk envelope format

Each envelope has exactly three sections:

```markdown
## Chunk: {name}

### Already in place (do not flag as missing)
{verbatim outcomes from preceding chunks}

### Coming later (not your concern)
{verbatim intentions from following chunks}

### Your scope — review this
{verbatim chunk content}
```

### File layout

```
docs/planning/discussions/{topic}/
  chunks/
    manifest.md                  ← chunk list with order and descriptions
    {chunk-id}-envelope.md       ← one per chunk, written by chunker
    {chunk-id}-discussion.md     ← one per chunk, written by critic/dev loop
  aggregated-findings.md         ← written by aggregator
```

### Prompt files

- `chunker.md` — reads the full doc, splits into chunks, writes envelopes and manifest
- `aggregator.md` — collects per-chunk threads, runs cross-chunk consistency check, produces unified gate verdict
- `critic-lens.md`, `dev-respond.md`, `planner-arbitrate.md`, `final-gate.md` — same as standard pipeline, used once per chunk

### Subagent Stage Configuration (large document)

The chunker runs first. Then N parallel critic/dev pairs — one per chunk, each running its own loop to resolution. The aggregator runs after all pairs are done. Then final-gate.

```yaml
stages:
  - name: chunker
    role: lead-dev
    model: claude-sonnet-4.6
    prompt: |
      [paste chunker.md content]
      path: {document path}
      topic: {topic slug}

  # Repeat this critic/dev-response pair once per chunk (all depend on chunker, all run in parallel).
  - name: critic-{chunk-id}
    role: critic
    model: claude-opus-4.5
    depends_on: [chunker]
    prompt: |
      [paste critic-lens.md content]
      Document to review: docs/planning/discussions/{topic}/chunks/{chunk-id}-envelope.md
      Discussion file: docs/planning/discussions/{topic}/chunks/{chunk-id}-discussion.md

  - name: dev-response-{chunk-id}
    role: lead-dev
    model: claude-opus-4.5
    depends_on: [critic-{chunk-id}]
    prompt: |
      [paste dev-respond.md content]
      Discussion file: docs/planning/discussions/{topic}/chunks/{chunk-id}-discussion.md
    loop_to:
      target: critic-{chunk-id}
      trigger: "NEEDS_WORK"
      max_iterations: 3

  # No per-chunk planner. Unresolved threads after 3 passes are flagged by the aggregator.

  # aggregator depends on ALL dev-response stages
  - name: aggregator
    role: lead-dev
    model: claude-sonnet-4.6
    depends_on: [dev-response-chunk-0, dev-response-chunk-1, ...]
    prompt: |
      [paste aggregator.md content]
      topic: {topic slug}

  - name: final-gate
    role: lead-dev
    model: claude-opus-4.5
    depends_on: [aggregator]
    prompt: |
      [paste final-gate.md content]
      Discussion file: docs/planning/discussions/{topic}/aggregated-findings.md
```

### When to use which pipeline

| Situation | Pipeline |
|-----------|----------|
| Single focused spec, ADR, short design doc | Standard |
| Implementation plan with 3+ phases | Large document |
| PR touching multiple unrelated modules | Large document |
| Strategy doc, long-form writing | Large document |
| Unsure | Count the natural sections. More than 3 → large document. |

---

## Subagent Stage Configuration

```yaml
stages:
  - name: critic
    role: critic
    model: claude-opus-4.5
    prompt: |
      [paste critic-lens.md content]
      Document to review: {path}
      Discussion file: docs/planning/discussions/{topic}.md

  - name: dev-response
    role: lead-dev
    model: claude-opus-4.5
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

  - name: final-gate
    role: lead-dev
    model: claude-opus-4.5
    depends_on: [planner]
    prompt: |
      [paste final-gate.md content]
      Discussion file: docs/planning/discussions/{topic}.md
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
