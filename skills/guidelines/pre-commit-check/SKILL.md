---
name: pre-commit-check
description: Review staged files before committing for security, code quality, and breakage risks. Follow when preparing a commit or when the git-commits skill triggers a pre-commit check.
type: guideline
---

# Pre-Commit Check

**This is a strict guideline.** Follow these rules exactly.

Before any commit, review only the staged files against three gates. All three must pass.

---

## Gate 1: Security

Delegate to the `security-checklist` skill. Scan staged files for:
- Hardcoded secrets, API keys, tokens, passwords
- `.env` files with real values
- Credentials, private keys, connection strings

**If found: STOP. Do not proceed to Gate 2.**

---

## Gate 2: Code Quality

Review staged files against `core-principles` and standard best practices:

- **DRY** — Does this change duplicate logic that already exists elsewhere? Check for copy-pasted code, repeated patterns that should be extracted.
- **Pure functions** — Are helpers pure and testable? Are side effects isolated?
- **Fail fast** — No silent defaults. Missing config or data should throw, not fall back.
- **Naming** — Are variables, functions, and files named clearly?
- **Separation of concerns** — Is business logic mixed with I/O or presentation?
- **Error handling** — Are errors caught at the right level with actionable context?
- **Dead code** — Are there leftover `console.log`, commented-out blocks, or unused imports?

Report issues. Minor style nits can be noted but should not block the commit.

---

## Gate 3: Will It Break?

Before committing, ask: **what will break after push that I can catch right now?**

**Always:**
- Does the code build? Run the build.
- Do existing tests pass? Run them.
- Are there linter errors? Run the linter.

**Infrastructure code (Lambdas, CDK, SST):**
- Deploy to dev and invoke the Lambda directly.
- Check CloudWatch for missing environment variables, permission errors, or import failures.
- Verify any new SSM parameters or secrets actually exist in the target environment.

**Frontend:**
- Does it render without console errors?
- Does the page load in the browser?

**CI-dependent changes (workflows, build configs):**
- Run the relevant step locally if possible (build command, test suite, lint).

**The rule:** If verification takes less than 2 minutes, do it now. Don't push and hope CI catches it.

---

## Output

When reporting findings, use this format:

```
🔴 Blocked — [reason, e.g. "hardcoded API key in config.ts"]
🟡 Fix before commit — [code quality issue with file reference]
✅ Verified — [what was tested, e.g. "build passes, Lambda invoked successfully"]
```

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
