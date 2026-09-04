## 2026-09-04 — Fixed host-mode drift; added reconciliation and projection scripts

**Problem:** `apm install --global` writes to `~/.apm/.kiro/` but Kiro reads
`~/.kiro/`, so host `apm update` never reached Kiro. The `apm-safe-update.sh`,
`skill-dev.sh`, and `skill-release.sh` scripts also assumed a project-root
`apm.lock.yaml` and were broken on the host.

**Fix:**
- Added `host-sync.sh` to reconcile `~/.apm/.kiro/{skills,hooks}` → `~/.kiro/`.
- Added `project-skills.sh` to project the universal skill subset into the
  cross-harness global dirs (`~/.agents/skills`, `~/.claude/skills`), excluding
  `guitarizta-skills` and `local-skills`.
- Made `apm-safe-update.sh`, `skill-dev.sh`, and `skill-release.sh` detect host
  vs project mode and, in host mode, run `apm update` from `~/.apm` and follow
  with `host-sync.sh --apply`.
- Documented the host/project topology, the universal/domain/local scope split,
  and the per-project override model in `SKILL.md`.

**Verified:** `host-sync.sh --apply` run on the host; Kiro's `~/.kiro/skills`
now matches the APM output (`component-organization`, `frontend-code-quality`
present).
