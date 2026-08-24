---
name: pr-fixer
description: Fix PR review comments — triage inline comments, implement each fix, commit, and reply to each thread with the commit hash. Use after a reviewer has left comments on your PR.
type: guideline
---

# PR Fixer

**This is a strict guideline.** Follow these rules exactly.

---

## Skill handover — READ THIS FIRST

This skill covers **responding to** review comments after fixes are pushed. It does NOT cover posting the initial review.

When posting a new review on a PR (running agents, flagging issues, writing inline comments):
**STOP. Switch to the `pr-reviewer` skill.** That skill owns the full review posting workflow.

The boundary is clear:
- `pr-reviewer` = posting the initial review and re-reviewing the diff
- `pr-fixer` = replying to individual comment threads after fixes land

If you are about to post a new review comment and you have not read `pr-reviewer`, stop and read it first.

---

## Workflow

1. **Triage** — Read all comments first. For each one, write a brief description of what needs to change (one line is enough). This becomes your working checklist.
2. **Work one by one** — Pick a comment, fix it, test it, commit it. Then move to the next. Do not batch fixes across comments.
3. **Reply** — After each fix is committed, reply to that comment thread with the commit hash and a brief explanation.

---

## Reply format

For a fixed comment:
```
Fixed in <commit-hash>

[Brief explanation of what changed and why, when non-obvious]
```

For a deferred comment:
```
Not addressed in this PR. Tracked in <issue-url>.

[One sentence on why deferred]
```

**The issue link is mandatory when deferring.** Create the GitHub issue first, then paste the URL into the reply. A reply that says "not addressed" without a link is incomplete — the issue will be lost.

**Never resolve comment threads.** Resolving a thread on GitHub is the human reviewer's job. After replying, stop. Do not click "Resolve conversation" or call any API that marks a thread as resolved. The human decides when a comment is satisfied.

---

## Why this matters

- Each comment maps to exactly one commit or one issue, so nothing falls through the cracks
- The checklist with brief descriptions keeps you focused and prevents drift
- Committing after testing (not before) ensures every commit is clean and deployable

---

## Understanding Review Comment Types

Reviewers leave comments across four categories. Knowing the category helps you implement the fix correctly.

### Architecture
Comments about alignment with patterns, separation of concerns, module boundaries, file organization.

**Fix by:** restructuring the code to match the established pattern, not just making it work.

### Security
Comments about env var handling, auth flows, input validation, token/credential storage, sensitive data exposure.

**Fix by:** applying the correct secure pattern — these are not optional.

### Performance
Comments about inefficient algorithms, unnecessary computations, caching opportunities, bundle size, query optimization.

**Fix by:** evaluating the tradeoff — implement if the concern is valid for the current scale, defer with an issue if not.

### Quality
Comments about readability, naming conventions, error handling, code duplication, test coverage, documentation.

**Fix by:** applying the convention used elsewhere in the codebase — match the existing style, don't introduce a new one.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
