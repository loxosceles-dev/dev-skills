---
name: setup-pre-commit
description: Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo. Use when user wants to add pre-commit hooks, set up Husky, configure lint-staged, or add commit-time formatting/typechecking/testing.
---

# Setup Pre-Commit Hooks

## Hook System Detection

Two systems are in use across projects. Detect which one applies:

| Signal | System |
|--------|--------|
| `.pre-commit-config.yaml` present | `pre-commit` (Python tool) |
| `.husky/` directory present | Husky (Node.js) |
| Neither | Default to Husky for Node projects, pre-commit for Python projects |

---

## Required Hooks (Both Systems)

Every active project must have these three hooks:

| Hook | Stage | Purpose |
|------|-------|---------|
| `check-secrets` | pre-commit | Block .env files and credentials |
| `commit-msg` | commit-msg | Enforce message format + block phase references |
| `pre-push` | pre-push | Skill checklist + block direct push to main |

Source scripts for all three are in:
```
__tools/project-blueprints/fragments/husky/commit-msg
__tools/project-blueprints/fragments/husky/pre-push
```

---

## Husky Setup

### 1. Detect package manager

Check for `package-lock.json` (npm), `pnpm-lock.yaml` (pnpm), `yarn.lock` (yarn), `bun.lockb` (bun). Default to npm if unclear.

### 2. Install dependencies

```bash
<pm> add -D husky lint-staged prettier
```

### 3. Initialize Husky

```bash
npx husky init
```

Creates `.husky/` and adds `prepare: "husky"` to package.json.

### 4. Copy hook scripts from blueprints

```bash
cp __tools/project-blueprints/fragments/husky/commit-msg .husky/commit-msg
cp __tools/project-blueprints/fragments/husky/pre-push .husky/pre-push
chmod +x .husky/commit-msg .husky/pre-push
```

### 5. Create `.husky/pre-commit`

```
<pm> exec lint-staged
<pm> run typecheck
<pm> run test
```

Omit `typecheck` or `test` lines if those scripts don't exist in package.json. Tell the user.

### 6. Create `.lintstagedrc`

```json
{
  "*": "prettier --ignore-unknown --write"
}
```

### 7. Create `.prettierrc` (if missing)

```json
{
  "useTabs": false,
  "tabWidth": 2,
  "printWidth": 80,
  "singleQuote": false,
  "trailingComma": "es5",
  "semi": true,
  "arrowParens": "always"
}
```

### 8. Verify

- [ ] `.husky/pre-commit`, `.husky/commit-msg`, `.husky/pre-push` all exist and are executable
- [ ] `.lintstagedrc` exists
- [ ] `prepare` script in package.json is `"husky"`
- [ ] `prettier` config exists
- [ ] Smoke-test `commit-msg`: `echo "feat: Phase 1 - test" | bash .husky/commit-msg /dev/stdin` → should block
- [ ] Smoke-test `commit-msg`: `echo "feat: Add thing" | bash .husky/commit-msg /dev/stdin` → should pass

---

## pre-commit (Python tool) Setup

Used in Python-primary projects (e.g. fckpaper). Hook scripts live in `scripts/`.

### 1. Copy hook scripts

```bash
cp __tools/project-blueprints/fragments/husky/commit-msg scripts/check-commit-msg.sh
cp __tools/project-blueprints/fragments/husky/pre-push scripts/pre-push-check.sh
chmod +x scripts/check-commit-msg.sh scripts/pre-push-check.sh
```

### 2. Add hooks to `.pre-commit-config.yaml`

```yaml
- id: check-commit-msg
  name: check commit message format
  entry: scripts/check-commit-msg.sh
  language: script
  stages: [commit-msg]

- id: pre-push-check
  name: pre-push skill checklist
  entry: scripts/pre-push-check.sh
  language: script
  stages: [pre-push]
```

### 3. Install hooks (run inside devcontainer)

```bash
pre-commit install --hook-type commit-msg --hook-type pre-push
```

### 4. Verify

Same smoke tests as husky section above, but against `scripts/check-commit-msg.sh`.

---

## Notes

- Husky v9+ doesn't need shebangs in hook files (the `_/` wrapper handles it), but the scripts themselves use `#!/bin/sh` since they're invoked directly too
- `prettier --ignore-unknown` skips files Prettier can't parse (images, etc.)
- The `pre-push` confirmation prompt is skipped automatically in CI (non-interactive terminal detection via `[ -t 1 ]`)
- `pre-commit install` must run inside the devcontainer where the `pre-commit` Python package is available
