---
name: project-migration
description: Migrate an existing project to the current host-native toolchain standards (mise, direnv, uv, pnpm, APM). Follow when the user asks to "migrate a project", "upgrade project setup", "bring project up to standard", "remove devcontainer from project", or "modernize project config".
type: guideline
---

# Project Migration

**This is a strict guideline.** Follow these rules exactly.

Migrate an existing project to the host-native toolchain. Unlike `project-setup` (which scaffolds from scratch), this skill works with existing code — it must be non-destructive and interactive.

The target state is defined in `~/Hermes-Shared/guitarizta/docs/dev-toolchain-architecture.md`. Read that document for the canonical reference. This skill is the operational workflow for reaching that state.

---

## Core Principles

- **Never overwrite without asking.** Present diffs for any file that already exists.
- **Work on a branch.** All changes happen on `chore/migrate-project-setup`.
- **Ask early, not late.** When intent is ambiguous, ask before assuming.
- **No devcontainers.** Never add or preserve `.devcontainer/` config. If it exists, plan to remove it.

---

## Workflow

### Phase 1: Assessment

1. **Identify the project type.** Ask if not clear — Python, Node.js, or mixed?
2. **Read the matching blueprint** from `loxosceles/project-blueprints` to understand the target structure.
3. **Audit the current project.** Check for:

   | File/Dir | Current state | Target |
   |----------|---------------|--------|
   | `.mise.toml` | exists? what versions? | must exist, exact versions pinned |
   | `.python-version` | exists? | must exist if Python project |
   | `pyproject.toml` + `uv.lock` | exists? | must exist if Python project |
   | `package.json` + `pnpm-lock.yaml` | exists? | must exist if Node project |
   | `package.json packageManager` field | set? | must be pinned (pnpm@x.y.z) |
   | `.envrc` | exists? | should exist with non-secret env vars |
   | `.envrc.local.example` | exists? | should exist documenting secrets needed |
   | `apm.yml` + `apm.lock.yaml` | exists? | must exist |
   | `.kiro/steering/` | exists? | should exist with relevant context |
   | `.devcontainer/` | exists? | must be removed |
   | `.gitignore` | correct? | must include: `.venv/`, `.envrc.local`, `apm_modules/` |

4. **Present a migration plan.** Group by category. For each existing file that changes, show what changes and why. Flag items needing user input.

**Do not proceed past this phase without user confirmation.**

### Phase 2: Branch Setup

```bash
git checkout dev 2>/dev/null || git checkout main
git checkout -b chore/migrate-project-setup
```

Verify clean working tree first. If uncommitted changes exist, stop and ask.

### Phase 3: Execute Migration

Work category by category. Commit after each.

#### Runtime Pinning (mise)

- If `.mise.toml` exists: compare current pinned versions to what the project is actually using. Confirm with user before changing any version.
- If `.mise.toml` does not exist: determine current runtime versions and create it.

```toml
# .mise.toml
[tools]
python = "3.11"   # or whatever version the project is using
node = "22.22.3"  # if Node project
```

- Create `.python-version` for Python projects (must match `.mise.toml` python version).

Commit: `chore: Add mise toolchain pinning`

#### Python Packages (uv)

- If `pyproject.toml` exists and `uv.lock` exists: verify it's current (`uv sync`).
- If `requirements.txt` exists but no `pyproject.toml`: propose migration to uv. Ask for project name and description. Create `pyproject.toml`, run `uv add` for each dep, generate `uv.lock`.
- Add `.venv/` to `.gitignore`.

Commit: `chore: Migrate to uv dependency management`

#### Node Packages (pnpm)

- If `package.json` exists:
  - Check for `packageManager` field. If missing, determine current pnpm version (`pnpm --version`) and add it.
  - Ensure `pnpm-lock.yaml` exists and is committed.
  - Ensure `node_modules/` is in `.gitignore`.
- If `npm` or `yarn` lockfiles exist alongside `pnpm-lock.yaml`: flag for user — decide which to keep.

Commit: `chore: Pin pnpm version, verify lockfile`

#### Environment Variables (direnv)

- If `.envrc` does not exist: create a minimal one.
  ```bash
  # .envrc
  export ENVIRONMENT=dev
  # Add project-specific non-secret vars here
  # Load machine-local secrets if file exists (gitignored)
  [[ -f "${PWD}/.envrc.local" ]] && source_env "${PWD}/.envrc.local"
  ```
- If `.envrc` exists: review for any secrets that should be moved to `.envrc.local`.
- Create `.envrc.local.example` documenting any secrets needed:
  ```bash
  # .envrc.local.example — copy to .envrc.local, fill in values, never commit
  # export DATABASE_URL=postgres://localhost:5432/myproject_dev
  # export STRIPE_SECRET_KEY=sk_test_...
  ```
- Add `.envrc.local` to `.gitignore`.

Commit: `chore: Add direnv environment configuration`

#### Agent Skills (APM)

- If `apm.yml` does not exist: create it with the standard `ai-dev` dependency.
  ```yaml
  name: <project-name>
  version: 1.0.0
  targets:
    - kiro
    - claude
    - codex
    - copilot
    - agent-skills
  dependencies:
    apm:
      - loxosceles/ai-dev#main
    mcp: []
  ```
- Run `apm install` to generate `apm.lock.yaml`.
- Add `apm_modules/` to `.gitignore`.
- Add `.kiro/hooks/` to `.gitignore`.

Commit: `chore: Add APM skill dependencies`

#### Devcontainer Removal

If `.devcontainer/` exists:

1. Show the user what's in it.
2. Confirm: "This will delete `.devcontainer/`. The project will use mise/uv/pnpm directly. Confirm?"
3. After confirmation: `git rm -r .devcontainer/`
4. Check `docker-compose.devcontainer.yml` or similar — remove if it's devcontainer-specific. Preserve any `docker-compose.yml` that provides service dependencies (Postgres, Redis, etc.).

Commit: `chore: Remove devcontainer configuration`

#### .gitignore Cleanup

Ensure these are present:
```
.venv/
node_modules/
.envrc.local
.env
.env.*
apm_modules/
.kiro/hooks/
dist/
```

Commit: `chore: Update gitignore for host-native toolchain`

### Phase 4: Verification

```bash
mise trust && mise install   # runtimes installed
uv sync                      # if Python project
pnpm install                 # if Node project
apm install --frozen         # skills installed
direnv allow                 # env vars loaded
```

Run the project's own build/test commands to confirm nothing broke.

### Phase 5: Summary

Present:
- Files added
- Files modified (what changed)
- Files deleted (devcontainer artifacts)
- Branch name: `chore/migrate-project-setup`
- Next step: open PR to `dev`

---

## Rules

- Never remove entries from `.gitignore` — only append
- Never modify source code files — only infrastructure and config
- If a devcontainer `.env` file contains real secrets, flag them — do not commit them
- Commit after each category, not all at the end
- Git remotes must use SSH: `git@github.com:user/repo.git`

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
