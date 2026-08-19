# APM Migration Plan

## Context

Migration from the current hand-rolled symlink system to APM (Agent Package Manager) for managing skills, agents, and hooks across all environments.

**Current state:** Skills via `npx skills add` + manual symlinks in `~/.kiro/skill-sets/` + real dirs in `~/.agents/skills/`. Agents are JSON files symlinked from repos into `~/.kiro/agents/`. No lockfile, no reproducibility guarantee, manual maintenance required.

**Target state:** APM manages all primitives via `apm.yml` manifests and SHA-pinned lockfiles. Single install command. Same mechanism on host, devcontainers, and VPS.

---

## Why APM over alternatives

**Pinned `npx skills add`** — no lockfile, no content integrity, no multi-repo composition, no hooks support.

**Chezmoi-managed clone scripts** — manages files but not the dependency graph. No content hash verification. Still requires manual symlink maintenance.

**Continue symlink farm** — VirtioFS on macOS Docker Desktop silently breaks symlinks that cross volume boundaries. Already producing inconsistencies.

**APM validated 2026-08-19 in clean devcontainer:**
- `--frozen` reproducible install: identical output from same lockfile ✓
- `--target kiro` skill deployment: 45 skills from 3 repos (20 + 18 + 7) ✓
- `--global` host install: deploys to `~/.kiro/skills/` ✓
- Private repo auth (`GITHUB_APM_PAT_LOXOSCELES`): `guitarizta-skills` + `local-skills` resolved ✓
- Multi-repo single manifest: all 3 repos in one `apm.yml` ✓
- Hook deployment to `.kiro/hooks/`: Kiro v1 format, namespaced ✓
- `apm audit`: no issues ✓
- `includes: auto`: discovers all skills from repo root ✓

---

## Repo Architecture

Three repos, three life scopes:

| Repo | Scope | Access | Containers |
|------|-------|--------|------------|
| `loxosceles/ai-dev` | Professional — dev craft | Public | Yes |
| `loxosceles/guitarizta-skills` | Company — Guitarizta IP | Private | Guitarizta projects only |
| `loxosceles/local-skills` | Personal — host-only | Private | **Never** |

`loxosceles/loxosceles-dev-tooling` — opinionated stack patterns, per-project install alongside `ai-dev`.

**Agents:** lead-dev, planner, code-reviewer, critic (ai-dev) · guitarizta (guitarizta-skills) · personal, destructor (local-skills)

---

## What APM Replaces

| Current | Replaced by |
|---------|------------|
| `npx skills add loxosceles/ai-dev` | `apm install --frozen` from `apm.yml` |
| Manual symlinks in `~/.kiro/skill-sets/` | `apm install --global --target kiro` |
| Real dirs in `~/.agents/skills/` | `apm install --global --target agent-skills` |
| Hand-maintained `~/.kiro/skills/` symlinks | APM-deployed physical files |
| No lockfile | `apm.lock.yaml` with SHA-256 per file |

Not replaced in this plan:
- **Agent JSON files** — Kiro v2 is JSON-only. Phase 3 (Kiro v3 + `/upgrade-agent`) handles this, decoupled.
- **`~/.kiro/skill-sets/` agent resource paths** — stay as-is until Phase 3.

---

## Pre-Migration Backup

Must be restorable, not just logged. Run before any phase:

```sh
set -e
BACKUP_DIR=~/apm-migration-backup/$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

cp -rL ~/.kiro/skills     "$BACKUP_DIR/kiro-skills"
cp -rL ~/.agents/skills   "$BACKUP_DIR/agents-skills"
cp -rL ~/.kiro/skill-sets "$BACKUP_DIR/skill-sets"
cp -r  ~/.kiro/agents     "$BACKUP_DIR/agents"

# Verify all four dirs are present and non-empty before proceeding
for dir in kiro-skills agents-skills skill-sets agents; do
  [ -d "$BACKUP_DIR/$dir" ] || { echo "ABORT: $dir missing from backup"; exit 1; }
  [ "$(ls -A "$BACKUP_DIR/$dir")" ] || { echo "ABORT: $dir is empty"; exit 1; }
done

echo "Backup sizes:"
du -sh "$BACKUP_DIR"/*/
echo "Backup complete: $BACKUP_DIR"
```

**Rollback procedure:**
```sh
set -e
# Set explicitly — never rely on a variable
BACKUP_DIR=~/apm-migration-backup/20260819   # replace with actual date

# Verify all four dirs exist before destroying anything
for dir in kiro-skills agents-skills skill-sets agents; do
  [ -d "$BACKUP_DIR/$dir" ] || { echo "ABORT: $dir not found in backup"; exit 1; }
done

rm -rf ~/.kiro/skills     && cp -r "$BACKUP_DIR/kiro-skills"   ~/.kiro/skills
rm -rf ~/.agents/skills   && cp -r "$BACKUP_DIR/agents-skills" ~/.agents/skills
rm -rf ~/.kiro/skill-sets && cp -r "$BACKUP_DIR/skill-sets"    ~/.kiro/skill-sets
rm -rf ~/.kiro/agents     && cp -r "$BACKUP_DIR/agents"        ~/.kiro/agents

# Revert post_create.sh in project-blueprints to npx block
```

---

## Required Repo Changes

`apm-test` branches already have these. Merge to `main` as part of this migration.

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

Host-only. Must NOT target `agent-skills` (that would allow installation in containers via flat pool).

```yaml
name: local-skills
version: 1.0.0
description: Host-only personal skills — never installed in containers
author: loxosceles
targets:
  - kiro
includes: auto
dependencies:
  apm: []
  mcp: []
```

---

## Lockfile Strategy

**Reproducibility is the primary justification for APM.** Lockfiles must be committed and used from day one — not after migration is "stable".

Workflow:
1. Generate lockfile once: `apm lock` (resolves without installing)
2. Commit `apm.lock.yaml` alongside `apm.yml`
3. All subsequent installs use `--frozen` to replay exact SHAs
4. To update: `apm update` → generates new lockfile → commit the change

Branch tips are fine in the manifest (`loxosceles/ai-dev` without SHA) because the lockfile pins the resolved SHA at lock-time. `--frozen` replays that SHA on every subsequent install regardless of what `main` has since received.

**`includes: auto` audit:** after any `apm lock` or `apm update`, run `apm list` and diff against the known-good baseline to confirm that `includes: auto` did not pick up unexpected files (e.g. READMEs, config files, or test fixtures accidentally placed in a skills directory). If new unexpected entries appear, add an explicit `includes:` list to the offending repo's `apm.yml`.

---

## Credential Requirements

**Host and VPS only.** Private repos (`guitarizta-skills`, `local-skills`) require:

```sh
GITHUB_APM_PAT_LOXOSCELES="<token from: gh auth token>"
```

- Host: `~/.secrets.d/github.env` — sourced by zsh at login
- VPS (Hermes): Hermes secrets store
- **Devcontainers:** `ai-dev` is public — standard coding projects need no PAT. Guitarizta project containers that install `guitarizta-skills` need the PAT passed in at container build time.

  The mechanism is Docker's `runArgs` in `devcontainer.json`:
  ```json
  "runArgs": ["--env-file", "${localWorkspaceFolder}/.devcontainer/.env"]
  ```
  `.devcontainer/.env` is gitignored and contains:
  ```sh
  GITHUB_APM_PAT_LOXOSCELES=<token>
  ```
  The variable is then available to `post_create.sh` during container setup.

- `local-skills` is never installed in any container — no container ever needs it.

Update the `credentials` skill to document this PAT after adding it.

---

## `~/.apm-host/` — Host Manifest Location

Lives in chezmoi dotfiles repo — not an orphaned directory:

```
~/.dotfiles/
  dot_apm-host/
    apm.yml          ← manifest
    apm.lock.yaml    ← committed lockfile
```

Chezmoi manages `~/.apm-host/` → `~/.dotfiles/dot_apm-host/`.

**Update workflow when skills change:**
```sh
cd ~/.apm-host
apm update                          # re-resolves, writes new apm.lock.yaml
cd ~/.dotfiles
git add dot_apm-host/apm.lock.yaml
git commit -m "chore: Update host skill lockfile"
chezmoi apply                       # propagates lockfile to ~/.apm-host/
cd ~/.apm-host && apm install --frozen --global --target kiro   # apply the update
```

**Resolve before Phase 2.** Add to dotfiles repo first.

---

## APM Installation

Use `uv` (modern Python tool runner) instead of pip:

```sh
# Install uv if not present
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install APM
uv tool install apm-cli==0.28.0
```

`uv tool install` creates an isolated environment — no `--break-system-packages` needed, no system Python pollution. Pin the version explicitly everywhere.

To upgrade APM later: `uv tool install apm-cli==<new-version>` — test in devcontainer first.

---

## Migration Phases

### Phase 1 — Single devcontainer pilot

**Goal:** validate APM in a real devcontainer before touching the blueprint.

1. Pick `can-do-it` (non-critical, runs regularly)
2. Add `apm.yml` to project root:
   ```yaml
   name: can-do-it
   version: 1.0.0
   dependencies:
     apm:
       - loxosceles/ai-dev
   ```
3. Generate and commit lockfile:
   ```sh
   # In the container or with uv on host
   uv tool run apm-cli==0.28.0 lock
   git add apm.yml apm.lock.yaml
   git commit -m "chore: Add APM manifest and lockfile"
   ```
4. Update `.devcontainer/post_create.sh` — replace the skills install block:
   ```sh
   # OLD
   [ -f "${WORKSPACE_ROOT}/skills-lock.json" ] && \
     cd "${WORKSPACE_ROOT}" && npx -y skills experimental_install && \
     npx -y skills add loxosceles/ai-dev --agent kiro-cli -y && \
     ln -sf "${WORKSPACE_ROOT}/.agents/skills" "$HOME/.kiro/skills"

   # NEW — APM deploys physical files to .kiro/skills/, no symlink needed
   curl -LsSf https://astral.sh/uv/install.sh | sh && \
   uv tool install apm-cli==0.28.0 && \
   cd "${WORKSPACE_ROOT}" && apm install --frozen --target kiro
   ```
5. Rebuild container, run per-devcontainer verification checklist (see below)
6. If pass: update blueprint `post_create.sh` in `project-blueprints`
7. Roll out to remaining devcontainers on next rebuild

**Rollback:** revert `post_create.sh` to old block, rebuild.

### Phase 2 — Host machine

**Prerequisites (all must be true before starting):**
- [ ] Phase 1 stable for ≥ 1 week with no regressions
- [ ] `~/.apm-host/` added to chezmoi dotfiles and applied
- [ ] `GITHUB_APM_PAT_LOXOSCELES` in `~/.secrets.d/github.env`
- [ ] Backup taken and verified (sizes non-zero)

**Steps:**
1. Take and verify backup
2. Install uv (if not already present): `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. Install APM: `uv tool install apm-cli==0.28.0`
3. Source the PAT and verify it is loaded:
   ```sh
   source ~/.secrets.d/github.env
   echo $GITHUB_APM_PAT_LOXOSCELES | wc -c   # must be > 1
   ```
4. Generate lockfile: `cd ~/.apm-host && apm lock`
5. Commit lockfile to dotfiles
6. Install: `apm install --frozen --global --target kiro`
7. Verify skill count: `ls ~/.kiro/skills/ | wc -l` (expect 45)
8. Run host verification checklist
9. After checklist passes, remove old symlink farm:
   ```sh
   rm -rf ~/.kiro/skill-sets/coding    # was real dir, now superseded
   rm -rf ~/.kiro/skill-sets/shared    # was real dir, now superseded
   # Leave guitarizta/ and personal/ — still used as agent resources/ paths
   # until Phase 3 converts agents to Markdown format
   ```

**Rollback:** run backup restore script above.

### Phase 3 — Agent migration to Kiro v3 (decoupled)

**Prerequisites:** Kiro v3 out of early access and stable.

1. Run `kiro-cli --v3` for ≥ 1 week — verify no session regressions
2. `/upgrade-agent` on each agent JSON → Markdown format
3. Move `.md` files into `.apm/agents/` in each repo
4. Test: `apm install --target kiro` deploys to `.kiro/agents/`
5. Remove JSON symlinks from `~/.kiro/agents/`
6. At this point `~/.kiro/skill-sets/guitarizta/` and `personal/` can also be removed — agent resource paths now point at APM-deployed locations

### Phase 4 — VPS / Hermes

**Prerequisites:** Phase 2 stable on host for ≥ 2 weeks.

1. Add `GITHUB_APM_PAT_LOXOSCELES` to Hermes secrets store (via `hermes-vps` skill)
2. Install uv on VPS: `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. `uv tool install apm-cli==0.28.0`
4. Create `~/.apm-host/apm.yml` on VPS (no `local-skills`):
   ```yaml
   name: hermes-host
   version: 1.0.0
   dependencies:
     apm:
       - loxosceles/ai-dev
       - loxosceles/guitarizta-skills
   ```
5. Source PAT from Hermes secrets store
6. `cd ~/.apm-host && apm lock` — generates `~/.apm-host/apm.lock.yaml`
7. Commit the VPS lockfile to `guitarizta-skills` repo for version control:
   ```sh
   cp ~/.apm-host/apm.lock.yaml /path/to/guitarizta-skills/.apm/hermes.lock.yaml
   git -C /path/to/guitarizta-skills add .apm/hermes.lock.yaml
   git -C /path/to/guitarizta-skills commit -m "chore: Add Hermes VPS lockfile"
   ```
   On reprovision, restore with:
   ```sh
   mkdir -p ~/.apm-host
   cp /path/to/guitarizta-skills/.apm/hermes.lock.yaml ~/.apm-host/apm.lock.yaml
   ```
8. `apm install --frozen --global --target kiro`
9. Run VPS checklist

**VPS Rollback:** Hermes agent is stateless for skills — skills are re-installed, not migrated. If APM install fails:
```sh
# Remove failed install
rm -rf ~/.kiro/skills ~/.kiro/hooks
# Revert to npx install temporarily
npx -y skills add loxosceles/ai-dev --agent kiro-cli -y
```
Then diagnose the failure before retrying `apm install`.

---

## Verification Checklists

### Baseline record (generate once before Phase 1, commit to `ai-dev`)

```sh
# Run on host before any migration work
ls ~/.kiro/skills/ | sort > ~/.apm-host/skills-baseline.txt
git -C ~/.dotfiles add dot_apm-host/skills-baseline.txt
git -C ~/.dotfiles commit -m "chore: Record pre-migration skill baseline"
```

Post-install diff check (use this instead of `wc -l`):
```sh
ls ~/.kiro/skills/ | sort > /tmp/skills-after.txt
diff ~/.apm-host/skills-baseline.txt /tmp/skills-after.txt
# Expected: only additions (new APM-namespaced files), no deletions
```

### Per-devcontainer (Phase 1)
- [ ] `apm audit` reports no issues — primary integrity check
- [ ] `ls .kiro/skills/ | sort | diff - <expected-list>` — no unexpected additions or deletions
- [ ] `kiro-cli chat` starts without errors inside container
- [ ] `lead-dev` finds `git-commits`, `core-principles`
- [ ] `planner` finds `critic-dialogue`
- [ ] `.kiro/hooks/ai-dev-shell-audit-pretooluse-1.json` exists

### Host (Phase 2)
- [ ] `apm audit` reports no issues
- [ ] `diff ~/.apm-host/skills-baseline.txt <(ls ~/.kiro/skills/ | sort)` — no unexpected deletions
- [ ] `kiro-cli chat` starts without errors
- [ ] `planner` finds `critic-dialogue`
- [ ] `lead-dev` finds `git-commits`, `core-principles`
- [ ] `guitarizta` finds `crm`, `guitarizta-comms`, `inbox-processing`
- [ ] `personal` finds `markdown-to-pdf`, `correspondence-manager`, `mitschnitt`
- [ ] `code-reviewer` finds `review-responder`, `code-review`
- [ ] `~/.kiro/hooks/` contains `ai-dev-shell-audit-pretooluse-1.json`
- [ ] `apm.lock.yaml` committed in dotfiles

### VPS (Phase 4)
- [ ] `apm audit` reports no issues
- [ ] `diff <(cat guitarizta-skills/.apm/hermes.lock.yaml | grep name) <(apm list | grep name)` — installed matches lockfile
- [ ] `ls ~/.kiro/skills/ | wc -l` ≥ 38 (ai-dev + guitarizta, no local-skills)
- [ ] Hermes agent starts without errors
- [ ] `guitarizta` finds `crm`, `guitarizta-comms`, `inbox-processing`
- [ ] `lead-dev` finds `git-commits`, `core-principles`
- [ ] `~/.kiro/hooks/ai-dev-shell-audit-pretooluse-1.json` exists
- [ ] `apm.lock.yaml` present at `~/.apm-host/apm.lock.yaml`

---

## Known Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| PAT missing at install time | Medium | Verify with `echo $GITHUB_APM_PAT_LOXOSCELES \| wc -c` before each phase |
| Skill name mismatch (`environment-deployment` vs `-strategy`) | Low | Audit `ls .kiro/skills/` post-install vs baseline; fix in source repo |
| `apm.lock.yaml` not committed before `--frozen` | Low | `apm lock` step is explicit in each phase |
| Kiro v3 regressions blocking Phase 3 | Low | Phase 3 is optional; v2 stays functional indefinitely |
| APM 0.28.0 has an untested bug | Medium | Pin version; test container before host; rollback is proven |
| Chezmoi dotfiles update delays Phase 2 | Low | Phase 2 prerequisites gate on it explicitly |
| uv not available in container base image | Low | Install script in post_create.sh handles this |

---

## Resolved Decisions

1. **`loxosceles-dev-tooling` in manifests?** — Per-project for AWS/CDK stack; not in global host manifest.
2. **Pin SHAs or branch tips?** — Branch tips in `apm.yml`; SHAs pinned in `apm.lock.yaml` from day one via `--frozen`.
3. **`~/.apm-host/` location?** — Chezmoi dotfiles repo.
4. **pip vs pipx vs uv?** — `uv tool install` (isolated, modern, no system pollution).
5. **`guitarizta-skills` and `agent-skills` target?** — Acceptable. Single user, personal machine, IP separation not yet enforced elsewhere.
6. **VPS lockfile home?** — Committed to `guitarizta-skills/.apm/hermes.lock.yaml`; restored from repo on reprovision.
7. **`.devcontainer/.env` injection?** — Docker `runArgs` `--env-file` in `devcontainer.json`; file is gitignored.

---

## Files Changed

**Repos — merge `apm-test` → `main`:**
- `ai-dev/apm.yml` + `ai-dev/.apm/hooks/shell-audit.json`
- `guitarizta-skills/apm.yml`
- `local-skills/apm.yml` (kiro target only)

**Chezmoi dotfiles — before Phase 2:**
- `dot_apm-host/apm.yml`
- `dot_apm-host/apm.lock.yaml`
- `dot_apm-host/skills-baseline.txt` ← generate once before Phase 1

**Host credentials — before Phase 2:**
- `~/.secrets.d/github.env` (PAT)
- `credentials` skill — update to document GitHub PAT

**Devcontainer blueprint — Phase 1:**
- `project-blueprints/fragments/common/post_create.sh`

**Guitarizta containers that need PAT — Phase 1b:**
- `.devcontainer/devcontainer.json` — add `runArgs` with `--env-file`
- `.devcontainer/.env` — create, gitignore, document in `mcp-server-setup` or `credentials` skill

**Host cleanup — after Phase 2 verification:**
- `~/.kiro/skill-sets/coding/` — remove
- `~/.kiro/skill-sets/shared/` — remove

**VPS — Phase 4:**
- `guitarizta-skills/.apm/hermes.lock.yaml` — new (VPS lockfile)
