# APM Migration Plan

## Context

This document describes the migration from the current hand-rolled symlink system to APM (Agent Package Manager) for managing skills, agents, and hooks across all environments.

**Current state:** Skills are managed via a mix of `npx skills add`, manual symlinks in `~/.kiro/skill-sets/`, and real directories in `~/.agents/skills/`. Agents are JSON files symlinked from repos into `~/.kiro/agents/`. There is no lockfile, no reproducibility guarantee, and the system requires manual maintenance when skills are added or moved.

**Target state:** APM manages all primitives (skills, hooks, agents) via declarative `apm.yml` manifests and SHA-pinned lockfiles. Installation is a single command. The host machine, devcontainers, and VPS all use the same mechanism.

---

## Repo Architecture (unchanged)

Three repos, three life scopes:

| Repo | Scope | Access |
|------|-------|--------|
| `loxosceles/ai-dev` | Professional — general dev craft | Public |
| `loxosceles/guitarizta-skills` | Company — Guitarizta IP | Private |
| `loxosceles/local-skills` | Personal — host-only | Private |

`loxosceles/loxosceles-dev-tooling` — opinionated stack patterns, installed alongside `ai-dev` on relevant projects.

---

## What APM Replaces

| Current mechanism | Replaced by |
|-------------------|------------|
| `npx skills add loxosceles/ai-dev` | `apm install` (from `apm.yml`) |
| Manual symlinks in `~/.kiro/skill-sets/` | `apm install --global --target kiro` |
| Real dirs in `~/.agents/skills/` | `apm install --global --target agent-skills` |
| Hand-maintained `~/.kiro/skills/` symlinks | APM deploys physical files, no symlinks needed |
| No lockfile | `apm.lock.yaml` with SHA-256 content hashes |

What APM does **not** replace (yet):
- Agent JSON files — Kiro v2 only reads `.json`. Migration requires upgrade to Kiro v3 and `/upgrade-agent` conversion. This is a separate step, not part of this plan.
- `~/.kiro/skill-sets/` agent resource paths — agent `resources` fields stay as-is until v3 upgrade.

---

## Pre-Migration Backup

Before touching anything on `main` or the host:

```sh
# Snapshot current ~/.kiro/skills symlinks
ls -la ~/.kiro/skills/ > ~/apm-migration-backup/kiro-skills-$(date +%Y%m%d).txt

# Snapshot current ~/.agents/skills
ls ~/.agents/skills/ > ~/apm-migration-backup/agents-skills-$(date +%Y%m%d).txt

# Snapshot skill-sets
find ~/.kiro/skill-sets -maxdepth 2 | sort > ~/apm-migration-backup/skill-sets-$(date +%Y%m%d).txt

# Snapshot agent files
cp -r ~/.kiro/agents ~/apm-migration-backup/agents-$(date +%Y%m%d)/
```

Rollback: restore snapshots + revert `post_create.sh` in `project-blueprints` to `npx skills add`.

---

## Required Repo Changes

Each repo needs an `apm.yml` at its root. The `apm-test` branches already have these — merge to `main` as part of this migration.

### `ai-dev/apm.yml`
```yaml
name: ai-dev
version: 1.0.0
description: Universal coding and project-setup skills, agents, and hooks
author: loxosceles
targets:
  - kiro
  - agent-skills
includes: auto
dependencies:
  apm: []
  mcp: []
```

### `guitarizta-skills/apm.yml`
```yaml
name: guitarizta-skills
version: 1.0.0
description: Guitarizta domain skills for Kiro
author: loxosceles
targets:
  - kiro
  - agent-skills
includes: auto
dependencies:
  apm: []
  mcp: []
```

### `local-skills/apm.yml`
```yaml
name: local-skills
version: 1.0.0
description: Host-only personal skills for Kiro
author: loxosceles
targets:
  - kiro
  - agent-skills
includes: auto
dependencies:
  apm: []
  mcp: []
```

---

## Credential Requirements

Private repo access requires a GitHub PAT with `repo` scope available as:

```sh
export GITHUB_APM_PAT_LOXOSCELES="<token>"
```

On the host: add to `~/.secrets.d/github.env` and document in the `credentials` skill.
In devcontainers: pass via `.devcontainer/.env` as `GITHUB_APM_PAT_LOXOSCELES`.
On VPS (Hermes): add to the Hermes secrets store.

`ai-dev` is public — no PAT needed for projects that only use `ai-dev`.

---

## Migration Phases

### Phase 1 — Devcontainers (lowest risk, fully reversible)

Target: replace `npx skills add` with `apm install` in one project's `post_create.sh`.

1. Pick one non-critical project (e.g. `can-do-it`)
2. Add `apm.yml` + `apm.lock.yaml` to project root:
   ```yaml
   name: can-do-it
   version: 1.0.0
   dependencies:
     apm:
       - loxosceles/ai-dev
   ```
3. Update `.devcontainer/post_create.sh` — replace the skills install block:
   ```sh
   # OLD
   npx -y skills experimental_install && \
   npx -y skills add loxosceles/ai-dev --agent kiro-cli -y && \
   ln -sf "${WORKSPACE_ROOT}/.agents/skills" "$HOME/.kiro/skills"

   # NEW
   pip3 install apm-cli --break-system-packages --quiet && \
   apm install --frozen --target kiro && \
   ln -sf "${WORKSPACE_ROOT}/.kiro/skills" "$HOME/.kiro/skills"
   ```
4. Rebuild the container, verify skills are present and identical to before
5. If OK, update the blueprint `post_create.sh` in `project-blueprints`
6. Roll out to remaining devcontainers on next rebuild

**Rollback:** revert `post_create.sh` to `npx skills add`.

### Phase 2 — Host machine (medium risk)

Target: replace the symlink farm on the host with APM global install.

1. Take backup (see Pre-Migration Backup above)
2. Install APM on host: `pip3 install apm-cli`
3. Add PAT to `~/.secrets.d/github.env`
4. Create `~/.apm-host/apm.yml`:
   ```yaml
   name: host
   version: 1.0.0
   dependencies:
     apm:
       - loxosceles/ai-dev
       - loxosceles/guitarizta-skills
       - loxosceles/local-skills
   ```
5. Run: `cd ~/.apm-host && apm install --global --target kiro`
6. Verify `~/.kiro/skills/` has all expected skills (45 total)
7. Verify `~/.agents/skills/` has the flat collection
8. Remove the old symlink farm directories once verified:
   - `~/.kiro/skill-sets/coding/` (real dir → no longer needed)
   - `~/.kiro/skill-sets/shared/` (real dir → no longer needed)
   - Individual symlinks in `~/.kiro/skills/` pointing at old locations

**Rollback:** restore symlinks from backup snapshot.

### Phase 3 — Agent migration to Kiro v3 (separate track)

Prerequisite: upgrade Kiro CLI to v3 (`kiro-cli --v3` opt-in first, then full upgrade).

1. Run `/upgrade-agent` on each agent to convert JSON → Markdown
2. Move converted agents into `.apm/agents/` in each repo
3. Test APM deploys them correctly to `.kiro/agents/`
4. Remove old JSON symlinks from `~/.kiro/agents/`

This phase is **decoupled** from phases 1 and 2. Agents work fine as JSON symlinks while skills and hooks migrate to APM.

### Phase 4 — VPS / Hermes (after host is stable)

Same as Phase 2 but on the VPS. Add `GITHUB_APM_PAT_LOXOSCELES` to Hermes secrets, run `apm install --global --target kiro`.

---

## Verification Checklist (per phase)

After each phase:

- [ ] Skill count matches pre-migration baseline
- [ ] `kiro-cli chat` starts without errors
- [ ] Each agent can list its skills (`/context` shows skills loaded)
- [ ] `planner` finds `critic-dialogue`
- [ ] `guitarizta` finds `crm`, `comms`, `inbox-processing`
- [ ] `personal` finds `markdown-to-pdf`, `correspondence-manager`
- [ ] Hook deployed and appears in `.kiro/hooks/`
- [ ] `apm audit` reports no issues

---

## Known Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| APM install fails for private repos (PAT missing) | Medium | Document PAT requirement clearly; test before each phase |
| Skills land with different names than current (`environment-deployment` vs `environment-deployment-strategy`) | Low | Audit names post-install; fix in repo if needed |
| `apm.lock.yaml` in project root conflicts with existing files | Low | Check each project before adding |
| Kiro v3 `--v3` flag has breaking changes for current sessions | Low | Test with `kiro-cli --v3` before full upgrade; Phase 3 is optional |
| VirtioFS symlink issues in containers (resolved by APM physical files) | None | APM deploys physical files — this is the fix |

---

## Open Questions

1. Should `loxosceles-dev-tooling` be added to project `apm.yml` manifests that use the AWS/CDK stack? (Probably yes — add as optional dep per project)
2. Pin specific commit SHAs in `apm.lock.yaml` for production stability, or stay on branch tips? (Recommendation: pin after migration is stable)
3. Where does `~/.apm-host/apm.yml` live long-term — should it be in a dotfiles repo managed by chezmoi?

---

## Files Changed

**Repos (apm-test branches, merge to main):**
- `ai-dev/apm.yml` — new
- `ai-dev/.apm/hooks/shell-audit.json` — new
- `guitarizta-skills/apm.yml` — new
- `local-skills/apm.yml` — new

**Host (Phase 2):**
- `~/.apm-host/apm.yml` — new
- `~/.secrets.d/github.env` — new (PAT)
- `~/.kiro/skill-sets/coding/` — remove
- `~/.kiro/skill-sets/shared/` — remove
- `~/.kiro/skills/` symlinks — replace with APM-managed physical files

**Project blueprint (Phase 1):**
- `project-blueprints/fragments/common/post_create.sh` — update skills install block
