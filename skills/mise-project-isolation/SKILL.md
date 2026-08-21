---
name: mise-project-isolation
description: Per-project toolchain isolation using mise. Apply when setting up a new project, adding Node or Python version requirements, or replacing devcontainer toolchain management on the host machine.
type: pattern
---

# mise Project Isolation Pattern

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Problem**: Multiple projects on the same machine share runtimes. A global Node or Python version satisfies no project precisely and contaminates others.

**Solution**: `mise` activates per-project tool versions automatically on `cd`. One `.mise.toml` per project replaces the need for nvm, pyenv, fnm, rbenv, and asdf individually.

---

## Pattern

### Per-project: `.mise.toml`

Place at the repo root. Pin **exact** versions — never ranges.

```toml
[tools]
python = "3.11"
node = "22.22.3"
```

Only include the runtimes the project actually uses. A Python-only service omits `node`.

### Optional: non-secret env vars in `.mise.toml`

mise can inject environment variables directly — no direnv needed for simple cases:

```toml
[tools]
python = "3.11"

[env]
ENVIRONMENT = "dev"
LOG_LEVEL = "debug"
```

Use this for committed, static, non-secret values. Use direnv `.envrc` when you need values to **unload on cd-out**, or when sourcing secrets.

### uv compatibility: `.python-version`

`uv` reads `.python-version` for its own resolution. Add it alongside `.mise.toml` so both tools agree:

```
3.11
```

### `.gitignore` for build artefacts

```
.venv/
node_modules/
dist/
```

---

## Shell Integration

`mise` must be activated in the shell to enable automatic version switching. Add to your zsh modules (chezmoi-managed):

**`~/.config/zsh/modules/mise.zsh`**:
```zsh
# mise — per-project toolchain version manager
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
fi
```

---

## First-time Setup on a New Machine

```bash
# 1. Install mise
curl -fsSL https://mise.run | sh

# 2. Activate in shell (add to zsh modules — see above)

# 3. Trust and install project tools (run from repo root)
mise trust
mise install
```

---

## Adding a New Project

1. Create `.mise.toml` at repo root with the required tool versions
2. Create `.python-version` if the project uses Python (matches the `python` version in `.mise.toml`)
3. Add `node_modules/` and `dist/` to `.gitignore` where relevant
4. Run `mise trust && mise install` from the repo root
5. Verify: `mise current` should show the pinned versions

---

## Full onboarding sequence (after clone)

```bash
mise trust && mise install   # 1. runtime
uv sync                      # 2. python deps (if Python project)
pnpm install                 # 3. node deps (if Node project)
apm install --frozen         # 4. agent skills
direnv allow                 # 5. env vars (if .envrc exists)
```

---

## Finding the Right Version to Pin

Pin the version already in use, not whatever is latest:

```bash
# What's the venv already using?
cat .venv/pyvenv.cfg | grep version

# What Node version is running?
node --version

# What versions does mise have available?
mise ls-remote python | grep "^3.11"
mise ls-remote node | grep "^22"
```

---

## Why This Pattern?

- **Automatic** — versions switch on `cd`, no manual activation
- **Single tool** — replaces nvm, pyenv, fnm, rbenv, asdf
- **Declarative** — `.mise.toml` is the source of truth, committed to the repo
- **Compatible** — works alongside `uv`; mise handles runtime selection, uv handles packages
- **No daemon** — activation is fast and stateless

---

## Tradeoffs

- Requires `mise activate` in the shell — new team members must install mise
- `mise trust` must be run once per project (security model: opt-in per directory)
- Does not replace `uv` for Python package management — the two tools are complementary
- Version bumps in `.mise.toml` do NOT auto-rebuild `.venv`. Must `rm -rf .venv && uv sync` after changing the Python version.

---

## What mise Does NOT Replace

- `uv` for Python dependency and virtualenv management
- `direnv` for environment variable unloading (mise `[env]` doesn't unload on cd-out)
- Docker for service dependencies (databases, queues, etc.)
- CI/CD environment setup — pin versions there explicitly

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
