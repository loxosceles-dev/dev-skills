---
name: git-commits
description: Commit message format, logical grouping, and branch naming rules. Follow when creating git commits, branches, or PRs.
type: guideline
---

# Git Commits

**This is a strict guideline.** Follow these rules exactly.

How to format and create git commits, branches, and PRs when helping developers.

---

## 🚨 Pre-Commit Gates

Before generating commit messages, run the `pre-commit-check` skill against all staged files. This covers:
1. **Security** — credentials, secrets, `.env` files (delegates to `security-checklist`)
2. **Code quality** — DRY, naming, error handling, dead code (references `core-principles`)
3. **Breakage risks** — build, tests, Lambda invocations, missing env vars

**Do not proceed to commit grouping until all three gates pass.**

After running the gates, briefly confirm the result and which path was used:
- "Pre-commit check passed (via `pre-commit-check` skill) — no security issues, code quality OK, build verified."
- "Pre-commit check passed (inline fallback — `pre-commit-check` skill not found) — no secrets in staged files."

### Security Fallback

If `pre-commit-check` or `security-checklist` are unavailable, apply these rules directly. **Never skip security.**

Scan staged files for:
- `.env` files with real values (any variant: `.env`, `.env.local`, `.env.prod`, `.env.*`)
- Hardcoded secrets, API keys, tokens, passwords in code
- AWS credentials, private keys (`*.pem`, `*.key`), connection strings
- `.git-credentials`, `.netrc`, credential JSON files

**If found: STOP immediately, alert the developer, refuse to proceed until resolved.**

---

## Commit Message Format

**Structure:**
```
<type>: <description>
```

**Rules:**
- One logical change per commit
- Single line only (no multi-line commits)
- Imperative form: "Add", "Create", "Fix", "Update" (not "Added", "Adding")
- Be specific but concise

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code restructuring (no behavior change)
- `docs` - Documentation only
- `style` - Formatting, whitespace
- `test` - Adding/updating tests
- `chore` - Build, config, dependencies

**Examples:**
```
feat: Add user authentication flow
fix: Resolve database connection timeout
docs: Update API endpoint documentation
refactor: Extract validation logic to separate function
```

---

## Commit Grouping Strategy

### Analysis Criteria

**Group files together when they:**
- Implement the same feature
- Fix the same bug
- Are part of the same refactoring
- Have strong dependencies (one requires the other)

**Separate files when they:**
- Serve different purposes (feature vs refactor vs docs)
- Touch different features/components
- Can work independently
- Represent different logical changes

### Grouping by Purpose

**Analyze changes by:**
- **Purpose**: What problem does this solve?
- **Scope**: What area of the codebase?
- **Independence**: Can this stand alone?
- **Dependencies**: Does it depend on other changes?

**Common patterns:**
- New feature = components + types + utilities + docs
- Refactoring = code quality improvements separate from features
- Bug fix = minimal files, specific to issue
- Config = package.json, environment, build files

---

## Process

When developer asks for commit help:

1. **🚨 Pre-commit gates** - Run `pre-commit-check` skill on staged files (security, quality, breakage)
2. **Analyze changes** - Run git commands to see actual changes (don't guess)
3. **Group logically** - Organize by purpose, not file type
4. **Generate messages** - Follow chosen format (simple or conventional)
5. **Present for approval** - Show commit groups with affected files
6. **Wait for approval** - Developer stages and commits in their tool

---

## Example Output

### Simple Format
```
Commit 1: Add user authentication logic
Files:
- auth.ts (authentication functions)
- types.ts (auth types)

Commit 2: Update database schema
Files:
- schema.ts (user table changes)
```

### Conventional Commits
```
📦 Commit 1: feat: Add user authentication flow
Files:
- frontend/contexts/auth-context.tsx (auth state management)
- frontend/hooks/use-auth.ts (auth hook)
- frontend/types/auth.ts (type definitions)
Group: Authentication feature - all related

📦 Commit 2: refactor: Extract API client utils
Files:
- frontend/lib/api-client.ts (extracted from inline code)
- frontend/utils/fetch-helper.ts (helper functions)
Group: Code quality - independent refactoring

📦 Commit 3: docs: Update authentication setup guide
Files:
- docs/guides/authentication.md (auth flow documentation)
Group: Documentation - separate from code
```

---

## Branches and PRs

**Branch naming:**
- Use descriptive, kebab-case names with type prefix: `feat/user-profile`, `fix/auth-timeout`
- **NEVER reference planning phases**: No `phase-1`, `step-2-3`, etc.
- Planning docs are not tracked — references are meaningless in git history

**PR titles — plain descriptive (NOT conventional commits):**
- Describe what the PR does in plain English
- No `feat:`, `fix:`, `chore:` prefixes — the branch name and labels carry the type
- Imperative form, capital letter

```
# ✅ Good PR titles
Add scales browser UI
Fix test runner in CI
Migrate devcontainer to ai-standards

# ❌ Bad PR titles (don't use conventional commit format)
feat: Add scales browser UI
chore: Migrate devcontainer to ai-standards

# ❌ Bad PR titles (auto-generated GitHub defaults)
Dev
Fix/auth timeout on mobile
```

**Why no conventional commits on PRs?** Versioning is label-driven (major/minor/patch labels on PRs to main). The PR title is for humans — keep it clean.

**Examples:**
```bash
# ✅ Good branch names
git checkout -b feat/user-profile
git checkout -b fix/auth-timeout
git checkout -b update-api-endpoints

# ❌ Bad branch names (no planning references)
git checkout -b phase-1-setup
git checkout -b step-2-3-implement-auth
git checkout -b task-1-2-database
```

**Versioning:**
- Handled automatically by GitHub Action on merge to main
- PR labels (`major`, `minor`, `patch`) determine version bump
- Never manually write version numbers in commits or PR titles

---

## Guidelines

- **Pre-commit gates first**: Always run `pre-commit-check` before proceeding
- **Analyze first**: Always run `git status` and `git diff` to see actual changes
- **Logical grouping**: Group by feature/fix, not by file type
- **No line ranges**: Just list files, not specific line numbers
- **Wait for approval**: Don't execute commits without explicit approval
- **No planning references**: Never mention "Step 1.2", "Phase 3", etc. in commits, branches, or PRs
- **Check for issues**: Flag `.env` files, `console.log` in production, missing newlines

---

## What NOT to Do

❌ **NEVER commit without running pre-commit gates** - STOP and run `pre-commit-check` first
❌ Don't stage, commit, or push **unless the developer explicitly asks you to execute** — by default, present the plan and wait for approval
❌ Don't modify files unless asked
❌ Don't guess at changes - always analyze actual diffs

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
