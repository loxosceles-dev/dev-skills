---
name: pr-fixer
description: Fix PR review comments — triage inline comments, implement each fix, commit, and reply to each thread with the commit hash. Use after a reviewer has left comments on your PR.
type: guideline
---

# PR Fixer

**This is a strict guideline.** Follow these rules exactly.

---

## 🚨 Mandatory: announce every step before you take it

Before every action, output a single line stating what you are about to do and which instruction you are following. No exceptions.

Examples:
- `[pr-fixer step 1] Triaging all comments — listing each with fix/defer decision`
- `[pr-fixer step 2] Fixing comment #1234 (path/to/file.ts line 42) — minor rename, trivial risk`
- `[pr-fixer step 3] Committing fix — following git-commits skill`
- `[pr-fixer step 3] Replying to comment #1234 — using gh api command from Reply format section`
- `[pr-fixer step 3] Getting comment IDs — running gh api list command`

If you skip this line, you are not following this skill. The developer uses these announcements to verify you are on track and to stop you if you are not.

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

1. **Triage** — Read all comments first. For each one, decide: fix now, or defer with an issue. Write your decision and one-line rationale on each item. This becomes your working checklist.
2. **Work one by one** — Pick a comment, fix it, test it, commit it. Then move to the next. Do not batch fixes across comments.
3. **Reply** — After each fix is committed, reply to that specific comment thread using the `gh api` command in the **Reply format** section below. Use the full 40-character commit hash. Do not move to the next comment until the reply is posted.

---

## 🚨 Every comment must receive an inline reply — no exceptions

**A comment with no reply is treated as completely unaddressed and will re-enter the pipeline.**

This applies even to deferred or rejected items. If you do not reply inline with either a commit hash or a tracked issue link, the comment is considered open. The reviewer will not assume silence means resolution.

---

## Fix vs. defer decision

The default is to fix. Apply judgment to decide otherwise. For each comment, ask:

**Fix it if:**
- The change is low-friction and low-risk (rename, extract, reformat, add a guard, adjust error handling)
- The correct solution is clear from the codebase
- The cost of not fixing it now is higher than the cost of doing it

**Defer with an issue if:**
- Fixing it correctly requires investigation you cannot complete in this PR (e.g., needs profiling, needs a design decision, touches an area you haven't read)
- The fix is correct in principle but the scope is significantly larger than the PR it belongs to
- The fix introduces new coupling, new dependencies, or new risk that wasn't in the original change

**Do not fix and do not defer if:**
- The comment is factually incorrect and the existing code is right — explain why in the reply
- The suggestion conflicts with a documented pattern in this repo — cite the pattern

When you write your triage checklist, state the reason explicitly:
- "Minor rename — fixing, trivial risk"
- "Requires profiling to know if the optimization matters — deferring to issue"
- "Reviewer misread the intent — explaining in reply, no change needed"

---

## 🚨 Committing — mandatory gate

**Before every commit in this workflow, you MUST follow the `git-commits` skill exactly.** Read it before you commit anything.

This is not optional. The most common failure mode is skipping this step and producing:
- Wrong commit message format (no scope in parentheses, imperative form, single line)
- Missing pre-commit checks (security, code quality, breakage verification)
- Linting errors that break the branch

The gate:
1. Run the `pre-commit-check` skill on staged files — security, quality, breakage
2. Format the commit message per `git-commits`: `<type>: <Description>` — single line, capital letter, imperative, NO scope
3. Only then commit

**If pre-commit-check finds issues: fix them before committing.** Do not commit a broken state just to reply to a thread.

**Never use `--no-verify` or `-n`.** If a hook blocks a commit, the hook is correct. Fix the issue the hook flagged — do not bypass it. `--no-verify` is how linting failures silently land in branches.

---

## Reply format

**The exact command to reply to a comment thread:**
```bash
gh api \
  repos/<owner>/<repo>/pulls/comments/<comment_id>/replies \
  -f body="<reply text>"
```

Get the comment ID from: `gh pr view <PR_NUMBER> --json reviews,comments`  
Or from the URL of the inline comment on GitHub — the number at the end of the URL fragment.

For a fixed comment, the reply text is:
```
Fixed in <full-40-char-commit-hash>

[Brief explanation of what changed and why, when non-obvious]
```

For a deferred comment, the reply text is:
```
Not addressed in this PR. Tracked in <issue-url>.

[One sentence on why deferred]
```

**The issue link is mandatory when deferring.** Create the GitHub issue first, then paste the URL into the reply. A reply that says "not addressed" without a link is incomplete — the issue will be lost.

**Never resolve comment threads.** Resolving a thread on GitHub is the human reviewer's job. After replying, stop. Do not click "Resolve conversation" or call any API that marks a thread as resolved. The human decides when a comment is satisfied.

### Getting comment IDs

```bash
# List all review comments (inline) on the PR
gh api repos/<owner>/<repo>/pulls/<PR_NUMBER>/comments --jq '.[] | {id: .id, path: .path, line: .line, body: .body}'
```

Each comment has a numeric `id`. Use that id in the reply command above. One reply per comment — do not reply to the same comment twice.

### Verify the reply was posted

After running the reply command, immediately verify it landed:

```bash
gh api repos/<owner>/<repo>/pulls/comments/<comment_id>/replies \
  --jq '.[-1] | {id: .id, body: .body}'
```

If the reply is not there, the command failed. Do not move to the next comment until this check passes.

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
