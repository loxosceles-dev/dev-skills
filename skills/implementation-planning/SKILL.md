---
name: implementation-planning
description: Directory convention, numbering system, and workflow for multi-session implementation plans. Follow when creating phased feature plans that span multiple sessions.
type: guideline
---

# Implementation Planning

**This is a strict guideline.** Follow these rules exactly.

Instructions for creating and managing implementation plans that persist across sessions.

---

## Structure

Implementation plans follow this directory structure:

```
docs/planning/implementation/
  {feature-name}/
    index.md              # Navigation hub with progress tracking
    phase-0-*.md          # Prerequisite/setup phase
    phase-1-*.md          # First implementation phase
    phase-2-*.md          # Second implementation phase
    ...
    post-implementation.md # Validation, handoff, troubleshooting
```

(User preferences for plan location override this default.)

### Phases vs Steps

**Phase** = One document containing related work
- Each phase has its own file: `phase-N-descriptive-name.md`
- Keep phases under 500 lines — this ensures each phase fits in LLM context alongside the code being edited
- Phases are executed in numerical order (0, 1, 2, ...)
- Renaming a phase file requires updating all references in index.md

**Step** = One small unit of work within a phase
- Each step is numbered: Step N.1, Step N.2, etc. (where N is the phase number)
- Steps within a phase are executed in order
- Each step should be:
  - Completable in a single focused action (a few minutes, not hours)
  - Independently testable
  - Committable (leaves codebase in working state)

**Example:**
```
phase-1-api-endpoints.md contains:
  - Step 1.1: Write failing test for GET /items
  - Step 1.2: Run test to verify it fails
  - Step 1.3: Implement GET /items handler
  - Step 1.4: Run test to verify it passes
  - Step 1.5: Commit

phase-2-database-setup.md contains:
  - Step 2.1: Write failing test for table access
  - Step 2.2: Run test to verify it fails
  - Step 2.3: Define DynamoDB table in CDK
  - Step 2.4: Run test to verify it passes
  - Step 2.5: Commit
```

### Numbering Rules

- Phase numbers are sequential: 0, 1, 2, 3, ...
- Phase 0 is always prerequisites/setup
- Step format: `{phase}.{step}` — Phase 1 steps: 1.1, 1.2, 1.3
- Steps must be executed in order within a phase
- Use `post-implementation.md` for validation and handoff

---

## File Mapping

Before defining steps in a phase, list the files that will be created or modified and what each one is responsible for. This locks in decomposition decisions upfront.

```markdown
**Files:**
- Create: `src/handlers/get-items.ts` — GET /items Lambda handler
- Create: `tests/handlers/get-items.test.ts` — handler tests
- Modify: `infrastructure/api.ts:45-60` — add route
```

Rules:
- Exact file paths always
- One clear responsibility per file
- Files that change together should live together
- In existing codebases, follow established patterns

---

## Step Content

Steps must contain everything an executing agent needs — no placeholders, no hand-waving.

**Required in every code step:**
- Full code (not stubs or pseudocode)
- Exact commands to run with expected output
- What to verify before moving on

**These are plan failures — never write them:**
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation"
- "Write tests for the above" (without actual test code)
- "Similar to Step N.1" (repeat the content — the agent may load phases independently)
- Steps that describe what to do without showing how

**TDD rhythm** (when applicable):
1. Write the failing test
2. Run it to confirm it fails
3. Write minimal implementation to pass
4. Run it to confirm it passes
5. Commit

Not every step needs TDD (config changes, CDK infra, etc.), but code steps should follow this rhythm when possible.

---

## Index File Structure

The `index.md` serves as the single navigation and progress tracking hub:

```markdown
# {Feature Name} - Implementation Guide

**Last Updated**: YYYY-MM-DD

---

## Quick Navigation

| Phase | Document |
|-------|----------|
| Phase 0 | [Phase Name](./phase-0-*.md) |
| Phase 1 | [Phase Name](./phase-1-*.md) |
| Phase 2 | [Phase Name](./phase-2-*.md) |

---

## Overview

Brief description of what this implementation achieves.

### Prerequisites

Before starting:
- Requirement 1
- Requirement 2

### Implementation Principles

- Key principle 1
- Key principle 2

---

## Progress Tracking

**Current Step**: Phase X, Step X.X - {Step Name}

### Phase 0: {Name}
- [ ] Step 0.1: Description
- [ ] Step 0.2: Description

### Phase 1: {Name}
- [ ] Step 1.1: Description
- [ ] Step 1.2: Description
```

---

## Phase Document Structure

```markdown
## Phase {N}: {Phase Name}

**Goal**: Single sentence describing what this phase achieves.

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts`
- Test: `tests/exact/path/to/test.ts`

---

### Step {N}.1: {Step Name}

**Goal**: What this step accomplishes.

[Full code, exact commands, expected output]

**Verify**: How to confirm this step worked.

**Commit**: `type: description`

---

### Step {N}.2: {Step Name}

...
```

**Limits:**
- Keep total phase document under 500 lines
- If approaching 500 lines, the phase is too big — split into multiple focused phases
- Don't arbitrarily split — reorganize the work so each phase has a single, focused goal

---

## Implementation Workflow

### The Golden Rule: ALWAYS FOLLOW THE PLAN

**Never write code without checking the plan first.**

The executing agent loads only `index.md` + the current phase. It never needs the whole plan in context.

1. **Read index.md** — know which step you're on
2. **Load the current phase** — follow the step exactly
3. **If you need to deviate** → STOP and enter Planning Mode

### Planning Mode

When you discover:
- The current step won't work as written
- A better approach exists
- A dependency is missing
- An assumption was wrong

**Immediately enter Planning Mode:**

1. **STOP writing code**
2. **Discuss the issue** with the developer
3. **Update the plan** with the new approach
4. **Check downstream steps** — does this change affect them?
5. **Verify against principles** — does this follow core principles and patterns?
6. **Update index.md** — reflect any changes in progress tracking
7. **Get confirmation** before resuming implementation

When updating the plan:
- Be specific: document exactly what changes and why
- Don't delete old approaches — mark them as superseded
- Keep index.md current

---

## Alignment Check

A lightweight sanity check after each step, before committing. Catches drift — changes that work in isolation but don't serve the feature's goals.

### Procedure

1. **Skim index.md** — Overview, Implementation Principles, current phase goal. Quick check, not a deep read.
2. **Review the uncommitted diff** against these questions:
   - **Goal alignment**: Does this move toward the feature goal, or did it drift?
   - **Architecture fit**: Does it follow project patterns?
   - **Architecture docs**: Does this project have architecture or design docs (e.g. `docs/architecture/`, ADRs, design decisions)? If so, does this change contradict any recorded decision? Only check docs relevant to the changed area — don't re-read everything.
   - **Scope creep**: Did this step introduce anything not in the plan?
3. **Verdict**:
   - ✅ **On track** — commit.
   - 🟡 **Minor drift** — note the concern in index.md, commit, review at phase end.
   - 🔴 **Off track** — do NOT commit. Enter Planning Mode.

Rules:
- Targets only the current step's diff, not the entire codebase.
- Not a full code review — just a directional check.
- 🟡 must include a one-line note on the step's checkbox in index.md.

---

## Phase Completion

When a phase is complete:
- [ ] All steps executed successfully
- [ ] All alignment checks passed (resolve any 🟡 flags)
- [ ] All tests passing
- [ ] Changes committed
- [ ] Index.md updated to next phase
- [ ] Prerequisites for next phase verified

---

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

---

## Creating a New Implementation Plan

1. **Scope check** — one plan per subsystem
2. **Create index.md** — navigation and progress tracking
3. **Break into phases** — each phase = one document, one focused goal
4. **Map files per phase** — exact paths, clear responsibilities
5. **Break phases into steps** — small, testable, committable, with full code
6. **Self-review** — check spec coverage, placeholder scan, type consistency across phases
7. **Number sequentially** — Phases: 0, 1, 2 | Steps: 1.1, 1.2 | 2.1, 2.2

---

## When to Create Implementation Plans

**Create for:**
- Multi-day features requiring coordination
- Features with multiple dependent phases
- Features requiring careful sequencing
- Features that need progress tracking across sessions

**Don't create for:**
- Single-file changes
- Simple bug fixes
- Routine maintenance tasks
- One-step operations

---

## Reordering Work

**To reorder steps within a phase:**
1. Update step numbers in phase document
2. Update references in index.md
3. Verify no steps are blocked by reordering

**To insert a new phase:**
1. Create new phase file
2. Renumber subsequent phase files and their internal step numbers
3. Update all references in index.md

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
