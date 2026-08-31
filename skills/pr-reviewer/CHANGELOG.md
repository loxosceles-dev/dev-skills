## 2026-08-31 — Fixed code-reviewer composition and pr-reviewer preflight commands

**Problem:** The reviewer workflow tried to concatenate Matt Pocock's `code-review` and the local PR review pipeline without a shared source of truth. That caused duplicated Standards and Spec passes, let the top-level reviewer assume local `HEAD` matched the PR diff, and left `pr-reviewer` with invalid preflight instructions (`headRefSha` and `gh pr review --json ...`).

**Fix:** Documented the composed `code-reviewer` entry mode for `pr-reviewer`, corrected the pipeline description so the active stages are explicit, and fixed preflight to use `gh pr view --json ...,headRefOid,...,comments,reviews`. Rewrote the `code-reviewer` agent prompt so PR preflight runs first, Matt's review owns Standards and Spec, and `pr-fixer` only runs on explicit remediation requests.

**Verified:** Compared the rewritten flow against the working `critic-dialogue` pipeline structure, checked `gh pr view --help` and `gh pr review --help`, and kept the live `agents/kiro` and mirrored `.apm/agents` reviewer configs in sync.
