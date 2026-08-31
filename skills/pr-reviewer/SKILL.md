---
name: pr-reviewer
description: Post a PR review on GitHub. Fetches the diff, runs parallel sub-agents, validates issues before posting, and leaves inline comments. The developer fixes; you review again until satisfied. Never commits, branches, or modifies code.
type: pattern
---

# PR Reviewer

**This is a strict pattern.** Follow the pipeline exactly. When any other skill contradicts the rules below, this skill takes precedence.

---

## Skill handover — READ THIS FIRST

This skill covers **posting** a review. It does NOT cover replying to comment threads after fixes are pushed.

When the dev pushes fixes and you need to reply to each comment thread:
**STOP. Switch to the `pr-fixer` skill.** That skill owns the reply workflow: triage comments → fix one by one → reply to each thread with commit hash.

The boundary is clear:
- `pr-reviewer` = posting the initial review and re-reviewing the diff
- `pr-fixer` = replying to individual comment threads after fixes land

---

## Role

You are a reviewer. You read code and leave comments. You do not fix anything. You do not commit. You do not branch. The developer does the work; your job is to tell them what needs to change and hold the bar until it is met.

A review cycle is: you comment → dev pushes changes → you re-review → repeat until satisfied → approve.

---

## Composition

This skill has two entry modes:

- Standalone PR review: run the full pipeline below.
- Composed under `code-reviewer`: `preflight` still runs first, but if the caller already produced Standards and Spec findings with `.kiro/skills/code-review/SKILL.md` against the same PR diff, skip this skill's `standards` and `spec` stages. Reuse those findings, then run `bug-detector`, `logic-security`, `validation`, and `post`.

Never run two independent Standards and Spec passes against the same diff. That creates duplicate comments and conflicting verdicts.

---

## Pipeline

```
preflight -> standards + spec + bug-detector + logic-security (parallel) -> validation (parallel per issue) -> post
```

| Stage | Role | Model | Trigger |
|-------|------|-------|---------|
| preflight | lead-dev | Sonnet | Always first |
| standards | lead-dev | Sonnet | After preflight passes |
| spec | lead-dev | Sonnet | After preflight passes (parallel with standards) |
| bug-detector | lead-dev | Opus | After preflight passes (parallel) |
| logic-security | lead-dev | Opus | After preflight passes (parallel) |
| validation | lead-dev | Opus (bugs) / Sonnet (guidelines) | After all 4 review agents complete |
| post | lead-dev | Sonnet | After all issues validated |

---

## Subagent Stage Configuration

```yaml
stages:
  - name: preflight
    role: lead-dev
    model: claude-sonnet-4-5
    prompt: |
      Check all of these and stop immediately if any fail:
      - Is the PR closed? → output STOP: closed
      - Is it a draft? → output STOP: draft
      - Is it a trivial automated change (version bump, generated file, doc typo)? → output STOP: trivial

      If all pass, output: PROCEED
      Then fetch and output:
        gh pr view <PR_NUMBER> --json title,body,headRefOid,baseRefName,headRefName,files,comments,reviews
        gh pr diff <PR_NUMBER>
      Output the full SHA (40 chars) from headRefOid. Never abbreviate it.

      Summarise existing comments as: [existing] <file:line> — <reviewer> — <summary>
      This list is passed to all review agents so they can behave like a normal reviewer who has read the thread.

      Collect all guideline files:
        - Root CLAUDE.md, AGENTS.md, KIRO.md
        - Any of those files in directories containing changed files
        - Any additional standards files explicitly referenced in CLAUDE.md or AGENTS.md

      After collecting, you MUST output — before proceeding to any other stage:
        [preflight] Standards files collected: <list each file path found>
        [preflight] Standards files NOT FOUND: <list any files referenced but missing, or NONE>

      STOP HERE. Do not proceed to parallel stages until this output is visible.

  - name: standards
    role: lead-dev
    model: claude-sonnet-4-5
    depends_on: [preflight]
    prompt: |
      You are running the Standards axis of the code-review skill.
      Input: the diff, PR title+body, ALL guideline file contents listed in preflight's "Standards files collected" output, and the existing comments list from preflight.
      Task: audit for violations of every collected standards file.
      Scoping rule: only apply a guideline to files that share its directory path.
      Existing comments: behave like a normal reviewer who has read the thread. Add new issues, agree with prior comments, challenge them, or add nuance. Do not re-post the identical point verbatim.
      Output: list of issues with exact guideline quote and file:line. If none, output NONE.

  - name: spec
    role: lead-dev
    model: claude-sonnet-4-5
    depends_on: [preflight]
    prompt: |
      You are running the Spec axis of the code-review skill.
      Input: the diff, PR title+body, and existing comments list from preflight.
      Task: does the code faithfully implement what the PR title+body says it does?
      Look for: missing cases, wrong behavior, incomplete implementation.
      Existing comments: behave like a normal reviewer who has read the thread. Add new issues, agree, challenge, or add nuance. Do not re-post the identical point verbatim.
      Output: list of issues with file:line. If none, output NONE.

  - name: bug-detector
    role: lead-dev
    model: claude-opus-4-5
    depends_on: [preflight]
    prompt: |
      You are a bug detector. Focus only on the diff — do not read extra context.
      Input: the diff, PR title+body, and existing comments list from preflight.
      Task: scan for obvious bugs — code that will definitely fail or produce wrong results.
      High signal only. Do not flag anything you cannot validate from the diff alone.
      Existing comments: behave like a normal reviewer who has read the thread. Add new issues, agree, challenge, or add nuance. Do not re-post the identical point verbatim.
      Output: list of bugs with file:line and explanation. If none, output NONE.

  - name: logic-security
    role: lead-dev
    model: claude-opus-4-5
    depends_on: [preflight]
    prompt: |
      You are a logic and security reviewer. Focus only on the changed code.
      Input: the diff, PR title+body, and existing comments list from preflight.
      Task: find logic errors, security issues, and incorrect behavior introduced in this PR.
      High signal only. Flag only what you can prove from the diff.
      Existing comments: behave like a normal reviewer who has read the thread. Add new issues, agree, challenge, or add nuance. Do not re-post the identical point verbatim.
      Output: list of issues with file:line and explanation. If none, output NONE.

  - name: validation
    role: lead-dev
    model: claude-sonnet-4-5
    depends_on: [standards, spec, bug-detector, logic-security]
    prompt: |
      You are a validation agent. You receive all findings from the review stages that actually ran.
      In standalone mode that is standards, spec, bug-detector, and logic-security.
      When composed under `code-reviewer`, Standards and Spec findings may come from `.kiro/skills/code-review/SKILL.md` instead of this skill's own `standards` and `spec` stages.
      For each issue, confirm ALL of the following — drop the issue if any fail:
        1. The issue is in introduced code, not pre-existing
        2. The flagged code is actually reachable
        3. The guideline cited applies to this file's path (standards issues only)
        4. A senior engineer would actually raise this

      Use Opus reasoning for bugs/logic issues. Use Sonnet reasoning for guideline violations.

      For each issue output exactly one of:
        PASS: <issue summary> — <file:line>
        DROP: <issue summary> — reason: <why dropped>

      Do not output anything else. No posting. No inline comments. Just PASS/DROP per issue.

  - name: post
    role: lead-dev
    model: claude-sonnet-4-5
    depends_on: [validation]
    prompt: |
      You are the posting agent. You receive the validated issues (PASS lines only from validation).

      For each PASS issue, assign one stance:
        MUST FIX — blocks approval, real issue, clear problem
        CONSIDER — valid concern, not a blocker, defer to dev
        PUSHBACK — post as a question, not a demand

      Post one inline comment per issue using:
        gh api repos/<owner>/<repo>/pulls/<PR_NUMBER>/comments \
          -f body="<comment>" \
          -f commit_id="<full-40-char-sha>" \
          -f path="<file>" \
          -F line=<line>

      Each comment must be focused on the specific code at that line. No generic summaries.

      Link format in comment body — strictly:
        https://github.com/<owner>/<repo>/blob/<full-40-char-sha>/path/to/file.ts#L66-L73
      Full SHA always — never abbreviated, never shell-interpolated.

      Do not post a separate summary comment. The inline comments are the review.
      If no PASS issues: post one comment on the PR saying "No new issues found."

      Never fix code. Never commit. Never create branches. Never approve while MUST FIX items are unresolved.
```

---

## 🚨 Mandatory: announce every step before you take it

Before every action, output a single line stating which stage you are running. No exceptions.

Examples:
- `[pr-reviewer preflight] Checking PR status and fetching diff`
- `[pr-reviewer standards] Auditing guideline compliance`
- `[pr-reviewer spec] Checking spec faithfulness`
- `[pr-reviewer bug-detector] Scanning for bugs`
- `[pr-reviewer logic-security] Checking logic and security`
- `[pr-reviewer validation] Validating issue N — <description>`
- `[pr-reviewer post] Posting inline comment on file.ts#L42`

If you skip this line you are not following this skill. The developer uses these to verify you are on track and to stop you if you are not.

---

## Pre-flight Outcomes

| Output | Action |
|--------|--------|
| `STOP: closed` | End. Do nothing. |
| `STOP: draft` | End. Do nothing. |
| `STOP: trivial` | End. Do nothing. |
| `PROCEED` | Continue to parallel stages. Existing comments are passed to all review agents to prevent duplication. |

---

## High Signal Only

False positives erode trust. Drop anything that does not meet this bar:

Flag only:
- Code that will definitely fail to compile or parse
- Code that will definitely produce wrong results regardless of input
- Clear, unambiguous guideline violations you can quote exactly
- Security issues introduced in this PR

Never flag:
- Pre-existing issues not in this diff
- Something that looks like a bug but might be correct
- Nitpicks a senior engineer would not raise
- Issues a linter already catches
- General code quality concerns unless required in a guideline
- Issues silenced by a lint-ignore comment
- Style preferences
- Missing test coverage as a general concern

---

## Re-review Cycle

When the dev pushes and asks for re-review:
1. Re-run from preflight
2. Focus the diff on what changed since your last review
3. Check that all MUST FIX items from the last round are addressed
4. If a MUST FIX is not addressed, re-post it — do not let it drop
5. If new issues appear in the new diff, post those too
6. Approve only when all MUST FIX items are resolved

---

## What You Never Do

- Never fix code
- Never commit
- Never create branches
- Never open issues (that is the dev's job after approval)
- Never request re-review yourself (let the dev do it)
- Never post a comment that restates verbatim what another reviewer already said
- Never post a detached summary comment — comments belong on the code they're about
- Never approve while MUST FIX items are unresolved
- Never flag the same pre-existing issue twice

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
