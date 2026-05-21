---
name: branch-policy
description: Branch model and merge flow for this project. Feature branches merge to dev via PR, dev merges to main via PR. Use when creating branches, opening PRs, pushing code, committing, or starting any new work — prevents incorrect base branch selection and direct pushes.
---

# Branch Policy

## Branch Model

```
main        ← production. Updated ONLY by PR from dev. Never push directly.
dev         ← integration branch. Updated ONLY by PR from feature branches.
feat/*      ← feature work, branched FROM dev
fix/*       ← bug fixes, branched FROM dev
chore/*     ← maintenance, branched FROM dev
```

## The #1 Rule: Always Create a Branch First

**Before writing ANY code — even a one-line fix — create a feature/fix/chore branch from dev.**

Do NOT:
- Start coding on `dev` and "move it to a branch later"
- Push a "quick fix" directly to `dev`
- Assume small changes don't need a branch

If you're on `dev` and about to make changes, STOP and run:
```bash
git checkout -b feat/descriptive-name dev
```

## One Feature = One Branch

A feature branch lives until the feature is complete. All related work happens on that branch:
- PR review feedback → fix on the same branch, push
- Copilot comments → fix on the same branch, push
- Multiple rounds of iteration → same branch

Do NOT create a new `fix/` branch for issues found during review of an open PR. Stay on the feature branch until the PR is merged.

A new branch is only needed when starting **genuinely new, unrelated work**.

## Flow

1. `git checkout -b feat/thing dev` — create branch BEFORE any code changes
2. Make commits on the feature branch
3. Push feature branch, open PR **to dev** (never to main)
4. Address review feedback on the same branch, push again
5. Merge PR to dev when approved
6. When dev is stable, open PR **from dev to main**

## Push Rules

| Action | Allowed? |
|---|---|
| Push to feature branch | ✅ Always |
| Push to `dev` | ❌ Only if user explicitly says "push to dev" |
| Push to `main` | ❌ Never. Main is updated only by merging a PR. |

If the user says "commit this" or "let's commit" while on `dev`, do NOT push. Ask: "Should I create a feature branch for this?"

## PR Base Branch

| Source branch | PR base |
|---|---|
| `feat/*`, `fix/*`, `chore/*` | `dev` |
| `dev` | `main` |

If you're about to create a PR with `--base main` from a feature branch, **STOP** — the base must be `dev`.

## Common Mistakes to Avoid

1. **Starting work without a branch** — Always check `git branch --show-current` before coding. If it says `dev`, create a branch first.
2. **Pushing "small fixes" to dev** — No fix is small enough to skip the branch+PR flow. This causes cherry-pick pain later.
3. **Opening PR to main from a feature branch** — Feature branches always target dev.
4. **Forgetting to create a branch after the user says "let's do X"** — The first action for any new task is `git checkout -b`.
5. **Creating a new branch for review fixes** — Stay on the current feature branch. One feature = one branch until merged.
