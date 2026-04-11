---
name: project-migration
description: Migrate an existing project to the current devcontainer, skills, linting, and CI/CD standards. Follow when the user asks to "migrate a project", "upgrade project setup", "add devcontainer to existing project", "bring project up to standard", or "modernize project config".
type: guideline
---

# Project Migration

**This is a strict guideline.** Follow these rules exactly.

Migrate an existing project to the current infrastructure and tooling standards. Unlike `project-setup` (which scaffolds from scratch), this skill works with existing code and configs — it must be non-destructive and interactive.

---

## Core Principles

- **Never overwrite without asking.** If a config file already exists, present a diff of what would change and ask before replacing.
- **Work on a branch.** All changes happen on a dedicated branch. Rollback is a branch reset.
- **Ask early, not late.** When intent is ambiguous (e.g., a custom eslint config that partially overlaps with the standard), ask whether to merge, replace, or skip. Do not assume.
- **Fragments are the source of truth.** Use fragment files from `loxosceles/project-blueprints` for all standard configs. Common fragments (`fragments/common/`) are assembled with stack-specific injections (`fragments/injections/{stack}/`) and Dockerfiles (`fragments/dockerfiles/{stack}/`). The result is one clean file per output — no runtime includes or sourcing. Do not improvise alternatives.
- **`devcontainer-state` is the shared config repo.** All containers mount from `~/.devcontainer-state` (overridable via `DEVCONTAINER_STATE` env var). SSH and AWS use `${SSH_PATH:-~/.ssh}` and `${AWS_PATH:-~/.aws}`. All mounts are directories — no file mounts.

---

## Workflow

### Phase 1: Assessment

1. **Pre-flight: Verify devcontainer-state**: Before anything else, check that `~/.devcontainer-state/.git` exists. If it doesn't, **stop immediately** and instruct:
   ```
   ⛔ ~/.devcontainer-state is not a git repo.
   Docker will auto-create mount targets as empty root-owned directories, breaking the devcontainer.

   Fix: git clone git@github.com:loxosceles/devcontainer-state.git ~/.devcontainer-state

   If ~/.devcontainer-state already exists (empty/root-owned), remove it first:
     sudo rm -rf ~/.devcontainer-state
   ```
   Do not proceed until this is resolved.
2. **Identify the project type.** Ask the user what stack this is (e.g., Next.js + SST, Python services, static frontend). This determines which blueprint to reference.
2. **Read the matching blueprint** from `loxosceles/project-blueprints` to understand the target state.
3. **Audit the current project.** Check for the existence and content of:
   - `.devcontainer/` (Dockerfile, docker-compose.yml, devcontainer.json, post_create.sh, post_start.sh)
   - Linting/formatting (eslint config, prettier config, .prettierignore)
   - CI/CD (`.github/workflows/`)
   - Editor config (`.vscode/settings.json`)
   - Project config (`.gitignore`, `.npmrc`, `.envrc`, `.env_TEMPLATE`)
   - Skills setup (`skills-lock.json`, `.agents/`)
   - Husky / lint-staged
   - Docs structure (`docs/`)
   - MCP server config (`~/.devcontainer-state/ai/mcp/servers.json`)
4. **Present a migration plan.** List every file that will be added, updated, or left alone. Group by category (devcontainer, linting, CI/CD, etc.). For each existing file that would change, note whether it's a replace, merge, or skip — and flag items that need user input.

Do not proceed past this phase without user confirmation of the plan.

### Phase 2: Branch Setup

1. **Check for a `dev` branch.** If it exists, branch from it. Otherwise branch from `main` (or the current default branch).
2. **Create the migration branch:**
   ```
   git checkout -b chore/migrate-project-setup
   ```
3. **Verify clean working tree.** If there are uncommitted changes, stop and ask the user to commit or stash first.

### Phase 3: Execute Migration

Work through the plan category by category. After each category, commit the changes with a descriptive message (e.g., `chore: Add devcontainer configuration`).

#### Devcontainer

- If `.devcontainer/` does not exist, copy all fragment files from `project-blueprints/fragments/devcontainer/`.
- If `.devcontainer/` exists, compare each file against the fragment version:
  - **Identical or trivially different** (only project name differs): replace silently.
  - **Structurally different** (custom volumes, extra packages, different base image): present both versions and ask which parts to keep.
- Create `.devcontainer/.env` from template. Ask for `PROJECT_NAME`, `GIT_NAME`, `GIT_EMAIL` if not inferrable from git config.
- Replace `{{project_name}}` in all fragment files.
- **Pre-create host mount targets.** Only per-project cache directories need pre-creation (Docker creates them correctly as directories). The shared `data/zsh_history_tmux/` directory already exists in the `devcontainer-state` repo via `.gitkeep`. After creating the devcontainer files, run:
  ```bash
  PROJECT=<project-name>
  mkdir -p ~/.devcontainer-state/cache/${PROJECT}/claude
  mkdir -p ~/.devcontainer-state/cache/${PROJECT}/kiro/settings
  ```
- **Verify MCP server config.** Check that `~/.devcontainer-state/ai/mcp/servers.json` exists. If not, warn the user to copy from `servers.json.template` and add credentials.
- **Verify devcontainer scripts.** The setup uses two scripts:
  - `post_create.sh` — runs once after container creation (validation, symlinks, git identity, skills restore)
  - `post_start.sh` — runs on every container start (Claude CLI install/update, Claude settings copy, MCP server distribution)
  - `devcontainer.json` must have both `postCreateCommand` and `postStartCommand`.

#### Linting & Formatting

- If no eslint/prettier config exists, copy fragments.
- If configs exist, present the diff and ask: replace with standard, merge, or skip.
- **Preserve project-specific eslint blocks.** The fragment eslint config is a baseline. If the project has additional blocks (e.g., `cli/**/*.ts`), keep them when replacing — merge the fragment with the project-specific additions.
- Check `package.json` for required devDependencies (eslint, prettier, husky, lint-staged). Add missing ones.

#### CI/CD

- If `.github/workflows/` does not exist, copy all workflow fragments.
- If workflows exist, compare each one. Present diffs for any that differ from fragments.
- **Note:** If the project uses a newer version of a CI action than the fragment (e.g., `pnpm/action-setup@v5` vs fragment's `@v4`), keep the newer version and flag the fragment as needing an update.

#### Editor Config

- If `.vscode/settings.json` does not exist, copy fragment.
- If it exists, merge — add missing keys, flag conflicting keys for user decision.
- Generate a unique `statusBar.background` color if not already set.

#### Project Config

- `.gitignore`: merge — append missing entries from the fragment, never remove existing entries.
- `.npmrc`, `.envrc`, `.env_TEMPLATE`: copy if missing, ask if existing version differs.

#### Skills

- **Use the `--agent` flag to limit installation to only the agents we use:**
  ```bash
  npx skills add loxosceles/ai-dev --agent claude-code github-copilot codex kiro-cli -y
  ```
  Without `--agent`, using `--yes` installs for ALL agents (dozens of directories). Without `--yes`, it prompts interactively (won't work in scripts).
- The `skills/` directory is always created by the installer as a symlink convenience folder. It cannot be prevented — just gitignore it.
- `.gitignore` must include: `.agents/`, `.claude/skills/`, `.kiro/skills/`, `skills/`
- Ask about additional third-party skills (e.g., `anthropics/claude-code`, `browser-use/browser-use`).
- Steering files (mounted ro at `~/.kiro/steering/` from `~/.devcontainer-state/ai/steering/`) handle skill auto-discovery. No agent configs needed — skills cover all workflows.

#### Husky & Lint-Staged

- If not configured, initialize: `npx husky init`, set pre-commit hook to `pnpm exec lint-staged`.
- If already configured, check the hook content. Ask before modifying.

#### Docs Structure

- Create `docs/architecture/`, `docs/guides/`, `docs/reference/` with `.gitkeep` if they don't exist.
- Never touch existing docs content.

### Phase 4: Verification

Run the appropriate checks for the project type:

```bash
pnpm lint          # or equivalent
pnpm format:check  # or equivalent
pnpm build         # if applicable
pnpm test          # if applicable
```

If any check fails, debug and fix. If the fix requires changing something the user approved in the plan, ask again before modifying.

### Phase 5: Summary

Present a summary of everything that was done:
- Files added
- Files modified (with what changed)
- Files left untouched (and why)
- Branch name and how to merge or rollback

---

## Rules

- Git remotes must use SSH, never HTTPS: `git@github.com:user/repo.git`
- Template variables use `{{double_braces}}` syntax
- Commit after each category, not at the end — this makes partial rollback possible
- If a fragment doesn't work with the project's current tool versions, report the conflict and ask
- Never modify source code files (components, pages, lib, etc.) — only infrastructure and config
- Never remove entries from `.gitignore` — only append
- **Consistency with `project-setup`**: This skill and `project-setup` must produce identical results for shared concerns (devcontainer, skills, kiro, linting, CI/CD). If you detect a discrepancy between what this skill instructs and what `project-setup` does, stop and warn the developer before proceeding.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
