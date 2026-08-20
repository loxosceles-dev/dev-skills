You are aggregating the findings from N parallel critic passes into a single unified review. Each critic reviewed one chunk of the document in isolation. Your job is two things: collect, then cross-check.

## Step 1 — Read all chunk discussion files

Read every file at `docs/planning/discussions/{topic}/chunks/*-discussion.md`. These are the per-chunk critic/dev threads. Read them all before writing anything.

Also read the manifest at `docs/planning/discussions/{topic}/chunks/manifest.md` so you know the document structure and chunk order.

## Step 2 — Collect findings

For each chunk, extract:
- All findings that reached APPROVED (critic was satisfied)
- All findings that were NEEDS_WORK but resolved by the dev
- Any findings the planner arbitrated, and how they were resolved
- Any open HOLDs that were never resolved

Do not re-litigate resolved findings. If the critic and dev reached agreement, it's settled. Your job is to surface what is still open, not to reopen what is closed.

## Step 3 — Cross-chunk consistency check

This is the critical step that parallel isolated critics cannot do. Look across all chunks for:

**Contradictions** — Does a decision in chunk A conflict with a decision in chunk B? Does chunk 3 assume something that chunk 1 explicitly ruled out?

**Orphaned dependencies** — Does a chunk reference something ("this will be handled later" / "as established earlier") that no other chunk actually delivers?

**Scope overlap** — Do two chunks claim ownership of the same thing? Which one is authoritative?

**Implicit ordering violations** — Does a chunk depend on an output from a later chunk in a way that breaks the stated sequence?

For each cross-chunk issue found, write it as a new finding with the affected chunks named explicitly.

## Step 4 — Write the aggregated report

Write to `docs/planning/discussions/{topic}/aggregated-findings.md`:

```markdown
# Aggregated Findings: {topic}

## Per-Chunk Status

| Chunk | Score | Status |
|-------|-------|--------|
| {chunk} | {N}/5 | APPROVED / OPEN HOLDS |

## Open Findings

{Any per-chunk findings not yet resolved, numbered, most critical first.
 Same format as individual critic findings.}

## Cross-Chunk Issues

{Issues that only became visible when looking across all chunks.
 Number these continuing from Open Findings.
 If none: write "No cross-chunk issues found."}

## Aggregated Gate

**APPROVED** — all chunks approved, no cross-chunk issues
**NEEDS_WORK** — one or more open findings or cross-chunk issues remain
```

## Step 5 — Hand off

If the aggregated gate is APPROVED, the final-gate stage runs next.

If the aggregated gate is NEEDS_WORK, the dev responds to the aggregated findings and the affected chunks are re-reviewed. Write which chunks need re-review:

```
Chunks requiring re-review: {list}
```
