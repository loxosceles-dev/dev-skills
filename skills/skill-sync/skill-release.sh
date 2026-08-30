#!/usr/bin/env bash
# skill-release <skill-name>
#
# Releases a skill from development mode:
#   1. Verifies the skill is currently symlinked (i.e. in dev mode)
#   2. Verifies the __tools/ repo has no uncommitted changes to this skill
#   3. Verifies the local commits have been pushed to remote
#   4. Removes the symlink
#   5. Runs apm-safe-update to deploy the real file from remote
#
# Refuses to proceed if the skill hasn't been pushed — no silent data loss.

set -euo pipefail

SKILL_NAME="${1:-}"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: skill-release <skill-name>"
  echo ""
  echo "Example: bash .kiro/skills/skill-sync/skill-release.sh pr-fixer"
  exit 1
fi

PROJECT_ROOT="$(pwd)"
SKILL_TARGET="$PROJECT_ROOT/.kiro/skills/$SKILL_NAME"

echo ""
echo "🔍 skill-release: checking '$SKILL_NAME'..."
echo ""

# 1. Must be a symlink
if [[ ! -L "$SKILL_TARGET" ]]; then
  echo "❌ '$SKILL_NAME' is not in dev mode (not a symlink)."
  echo "   Only skills activated with skill-dev.sh can be released."
  exit 1
fi

SOURCE_PATH=$(readlink "$SKILL_TARGET")
SOURCE_REPO=$(basename "$(dirname "$(dirname "$SOURCE_PATH")")")

echo "   Symlink: $SKILL_TARGET"
echo "   Source:  $SOURCE_PATH ($SOURCE_REPO)"
echo ""

# 2. No uncommitted changes in the source repo for this skill
REPO_ROOT=$(dirname "$(dirname "$SOURCE_PATH")")
RELATIVE_SKILL_PATH="skills/$SKILL_NAME"

cd "$REPO_ROOT"

unstaged=$(git diff --name-only -- "$RELATIVE_SKILL_PATH" 2>/dev/null)
staged=$(git diff --cached --name-only -- "$RELATIVE_SKILL_PATH" 2>/dev/null)

if [[ -n "$unstaged" || -n "$staged" ]]; then
  echo "❌ Uncommitted changes in $SOURCE_REPO for '$SKILL_NAME':"
  [[ -n "$unstaged" ]] && echo "$unstaged" | sed 's/^/     unstaged: /'
  [[ -n "$staged" ]]   && echo "$staged"   | sed 's/^/     staged:   /'
  echo ""
  echo "   Commit your changes first, then re-run skill-release."
  exit 1
fi

echo "   ✓ No uncommitted changes"

# 3. Local commits pushed to remote
git fetch --quiet origin main 2>/dev/null || true

local_sha=$(git rev-parse HEAD)
remote_sha=$(git rev-parse origin/main 2>/dev/null || echo "")

if [[ -z "$remote_sha" ]]; then
  echo "⚠️  Could not reach remote — skipping push check."
elif [[ "$local_sha" != "$remote_sha" ]]; then
  # Check if the skill file specifically is part of the unpushed commits
  unpushed_files=$(git diff --name-only origin/main HEAD -- "$RELATIVE_SKILL_PATH" 2>/dev/null)
  if [[ -n "$unpushed_files" ]]; then
    echo "❌ '$SKILL_NAME' has commits that haven't been pushed to remote:"
    echo "$unpushed_files" | sed 's/^/     /'
    echo ""
    echo "   Push first: cd $REPO_ROOT && git push"
    exit 1
  fi
fi

echo "   ✓ Changes pushed to remote"

# 4. Remove the symlink
cd "$PROJECT_ROOT"
rm "$SKILL_TARGET"
echo "   ✓ Symlink removed"
echo ""

# 5. Deploy from remote via apm-safe-update
SAFE_UPDATE="$PROJECT_ROOT/.kiro/skills/skill-sync/apm-safe-update.sh"

if [[ -f "$SAFE_UPDATE" ]]; then
  echo "🔄 Deploying from remote..."
  echo ""
  bash "$SAFE_UPDATE"
else
  echo "⚠️  apm-safe-update.sh not found. Run manually:"
  echo "   source ~/.secrets.d/gh.env && apm update --yes"
fi
