---
name: project-setup
description: How to create new projects using blueprints from the project-blueprints repo. Follow when the user asks to create, scaffold, or initialize a new project.
type: guideline
---

# Project Setup

**This is a strict guideline.** Follow these rules exactly.

New projects are created from blueprints stored at `loxosceles/project-blueprints` on GitHub.

---

## Workflow

1. **Pre-flight: Verify devcontainer-state**: Before anything else, check that `~/.devcontainer-state/.git` exists. If it doesn't, **stop immediately** and instruct:
   ```
   ⛔ ~/.devcontainer-state is not a git repo.
   Docker will auto-create mount targets as empty root-owned directories, breaking the devcontainer.

   Fix: git clone git@github.com:loxosceles/devcontainer-state.git ~/.devcontainer-state

   If ~/.devcontainer-state already exists (empty/root-owned), remove it first:
     sudo rm -rf ~/.devcontainer-state
   ```
   Do not proceed until this is resolved.
2. **Identify the blueprint**: Ask which stack the user wants (e.g., "nextjs-sst", "sst-python"). Read the corresponding blueprint from `blueprints/{stack}.md` in the repo.
2. **Read the full blueprint** before starting. Understand all sections.
3. **Collect variables**: Ask for `project_name`, `git_name`, `git_email`, and any other values the blueprint requires.
4. **Execute sections in order**: Follow the blueprint step by step.
5. **Copy fragments verbatim**: Fragment files from `fragments/` are exact configs. Copy them, then replace `{{template_variables}}` with actual values.
6. **Assemble stack-specific files**: Common fragments (`fragments/common/`) contain `{{INJECTION_MARKERS}}`. Read the matching injection snippets from `fragments/injections/{stack}/` and insert them at the marked points. Pick the Dockerfile from `fragments/dockerfiles/{stack}/`. The result is one clean file per output — no runtime includes or sourcing. For `devcontainer.json`, merge the injection's extensions and settings into the common base.
7. **Pause on version mismatches**: If a tool (create-next-app, SST, etc.) has a new major version compared to what the blueprint specifies, stop and ask: "Should I evaluate the upgrade or use the pinned version?"
8. **Never silently modify fragments**: If a fragment doesn't work with current tool versions, report the conflict and ask.
9. **Run verification**: Execute all verification commands at the end. All must pass.
10. **Install skills**:
    - Run `npx skills add loxosceles/ai-dev --agent claude-code github-copilot codex kiro-cli -y` and ask about additional third-party skills.
    - Pre-create all host mount targets (Docker creates missing sources as root-owned, breaking permissions):
      ```bash
      PROJECT=<project-name>
      mkdir -p ~/.devcontainer-state/cache/${PROJECT}/claude
      mkdir -p ~/.devcontainer-state/cache/${PROJECT}/kiro/settings
      ```
    - The `skills/` directory is always created by the installer as a symlink convenience folder. It cannot be prevented — just gitignore it.
    - `.gitignore` must include: `.agents/`, `.claude/skills/`, `.kiro/skills/`, `skills/`
    - Steering files (mounted ro at `~/.kiro/steering/` from `~/.devcontainer-state/ai/steering/`) handle skill auto-discovery. No agent configs needed — skills cover all workflows.
11. **Verify MCP server config**: Check that `~/.devcontainer-state/ai/mcp/servers.json` exists. If not, warn the user to copy from `servers.json.template`. MCP servers are distributed to all agents (Kiro, Claude, Amazon Q) by `post_start.sh` on every container start.
12. **Verify devcontainer scripts**: The setup uses two scripts:
    - `post_create.sh` — runs once after container creation (validation, symlinks, git identity, skills restore)
    - `post_start.sh` — runs on every container start (Claude CLI install/update, Claude settings copy, MCP server distribution)

## Rules

- Execute in the current directory (must be empty or an empty git repo)
- Git remotes must use SSH, never HTTPS: `git@github.com:user/repo.git`
- Never skip verification steps
- If a step fails, present the error with options — don't silently retry
- Template variables use `{{double_braces}}` syntax
- Fragment files are the source of truth for configs — don't improvise alternatives
- **Consistency with `project-migration`**: This skill and `project-migration` must produce identical results for shared concerns (devcontainer, skills, kiro, linting, CI/CD). If you detect a discrepancy between what this skill instructs and what `project-migration` does, stop and warn the developer before proceeding.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
