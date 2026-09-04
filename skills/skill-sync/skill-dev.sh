#!/usr/bin/env bash
# skill-dev <skill-name>
#
# Activates a skill for live development by replacing the APM-deployed directory
# in .kiro/skills/ with a symlink into the canonical __tools/ repo.
#
# Kiro reads from .kiro/skills/ — once symlinked, edits in __tools/ are
# immediately visible without any copying or redeployment.
#
# When done: run skill-release.sh to verify the push and restore the real deployed file.

set -euo pipefail

TOOLS_BASE="/Volumes/DATA EXT/Development/Repositories/__tools"
SKILL_NAME="${1:-}"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: skill-dev <skill-name>"
  echo ""
  echo "Example: bash .kiro/skills/skill-sync/skill-dev.sh pr-fixer"
  exit 1
fi

# Resolve where .kiro/skills/ lives: project (./apm.lock.yaml) or host (~/.kiro).
if [[ -f "apm.lock.yaml" ]]; then
  SKILL_TARGET="$(pwd)/.kiro/skills/$SKILL_NAME"
else
  SKILL_TARGET="$HOME/.kiro/skills/$SKILL_NAME"
fi

# Find which repo owns this skill
REPOS=(dev-skills agent-ops-skills shared-skills guitarizta-skills local-skills)
SOURCE_PATH=""
SOURCE_REPO=""

for repo in "${REPOS[@]}"; do
  candidate="$TOOLS_BASE/$repo/skills/$SKILL_NAME"
  if [[ -d "$candidate" ]]; then
    SOURCE_PATH="$candidate"
    SOURCE_REPO="$repo"
    break
  fi
done

if [[ -z "$SOURCE_PATH" ]]; then
  echo "❌ Skill '$SKILL_NAME' not found in any __tools/ repo."
  echo ""
  echo "   Searched:"
  for repo in "${REPOS[@]}"; do
    echo "     $TOOLS_BASE/$repo/skills/$SKILL_NAME"
  done
  exit 1
fi

# Check current state of .kiro/skills/<name>
if [[ -L "$SKILL_TARGET" ]]; then
  current_link=$(readlink "$SKILL_TARGET")
  echo "⚠️  '$SKILL_NAME' is already a symlink → $current_link"
  echo "   Run skill-release.sh first if you want to re-link."
  exit 1
fi

if [[ ! -d "$SKILL_TARGET" ]]; then
  echo "⚠️  '$SKILL_NAME' is not currently deployed in .kiro/skills/."
  echo "   Creating symlink anyway — run apm-safe-update.sh after release to deploy properly."
fi

# Replace deployed directory with symlink
if [[ -d "$SKILL_TARGET" ]]; then
  rm -rf "$SKILL_TARGET"
fi

ln -s "$SOURCE_PATH" "$SKILL_TARGET"

echo ""
echo "✅ '$SKILL_NAME' is now live from:"
echo "   $SOURCE_REPO → $SOURCE_PATH"
echo ""
echo "   Kiro will read your edits in __tools/$SOURCE_REPO/skills/$SKILL_NAME/ directly."
echo ""
echo "   When done: bash .kiro/skills/skill-sync/skill-release.sh $SKILL_NAME"
echo ""
