## 2026-08-30 — Added fix/defer decision framework and mandatory reply rule

**Problem:** Skill assumed "fix everything" without giving the agent criteria to reason about it. In practice, developer had to say "yes fix all of it unless complexity is out of bounds or there are risks" every time — the skill should have encoded this. Also: unreplied comments were silently treated as resolved, causing them to re-enter the review pipeline.

**Fix:** Added explicit Fix vs. defer decision section with criteria for each case. Added mandatory reply rule: every comment must receive an inline reply with either a commit hash or a tracked issue link, otherwise it is treated as completely unaddressed. Updated triage step to require a decision+rationale per item, not just a description.

**Verified:** Pushed to dev-skills main (8dd648d).
