## 2026-08-30 — Added mandatory repo-push workflow; local edits are not saved

**Problem:** Agent edited skill in project-local `.kiro/skills/` only, never pushed to the canonical repo. The fix was lost as soon as APM would run `apm update`.

**Fix:** Added explicit 5-step workflow (fix locally → test → push to repo → sync from APM → verify deployed version). Made clear that local is a scratch pad, not the source of truth.

**Verified:** Workflow documented and pushed to dev-skills main.
