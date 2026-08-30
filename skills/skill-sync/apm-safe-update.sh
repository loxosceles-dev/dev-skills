#!/usr/bin/env bash
# apm-safe-update — safe wrapper around `apm update --yes`
#
# Blocks if any APM-owned file in .kiro/ (skills, hooks) has local edits newer than
# what the lockfile expects. That means: you edited locally but haven't pushed
# yet — running apm update would destroy your work.
#
# Agents are NOT checked — they are managed via symlinks, not deployed by APM.
#
# Safe case (allows update):
#   local SHA != lockfile SHA, but local mtime <= lockfile mtime
#   → repo moved forward, you just haven't synced yet. Normal update.
#
# Dangerous case (blocks):
#   local SHA != lockfile SHA, and local mtime > lockfile mtime
#   → you edited locally after the last sync. Push first.

set -euo pipefail

LOCK_FILE="apm.lock.yaml"

echo ""
echo "🔍 apm-safe-update — checking for unpushed local skill edits..."
echo ""

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "❌ No apm.lock.yaml found. Run from project root."
  exit 1
fi

blocked=()
checked=0
clean=0

# Parse lockfile: extract pairs of (path, expected_sha) for all APM-owned .kiro/ paths
# Lines look like: "    .kiro/skills/pr-fixer/SKILL.md: sha256:abc123..."
#                  "    .kiro/hooks/dev-skills-shell-audit-pretooluse-1.json: sha256:abc123..."
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]+(\.kiro/[^:]+):[[:space:]]+sha256:([a-f0-9]+) ]]; then
    rel_path="${BASH_REMATCH[1]}"
    expected_sha="${BASH_REMATCH[2]}"

    [[ -f "$rel_path" ]] || continue

    checked=$((checked + 1))
    actual_sha=$(shasum -a 256 "$rel_path" | awk '{print $1}')

    if [[ "$actual_sha" == "$expected_sha" ]]; then
      clean=$((clean + 1))
      echo "  ✓  $rel_path"
      continue
    fi

    # SHAs differ — check which is newer
    local_mtime=$(stat -f "%m" "$rel_path" 2>/dev/null || stat -c "%Y" "$rel_path")
    lock_mtime=$(stat -f "%m" "$LOCK_FILE" 2>/dev/null || stat -c "%Y" "$LOCK_FILE")

    if [[ "$local_mtime" -gt "$lock_mtime" ]]; then
      echo "  ✎  $rel_path  ← unpushed local edit"
      blocked+=("$rel_path")
    else
      # Local is older — repo moved forward, normal update case
      echo "  ↑  $rel_path  ← will be updated from repo"
      clean=$((clean + 1))
    fi
  fi
done < "$LOCK_FILE"

echo ""
echo "  Checked $checked file(s) — $clean clean, ${#blocked[@]} blocked"
echo ""

if [[ ${#blocked[@]} -gt 0 ]]; then
  echo "🚫 Blocked — these files have unpushed local edits that would be overwritten:"
  echo ""
  for f in "${blocked[@]}"; do
    echo "  ✎  $f"
  done
  echo ""
  echo "Push your changes to the canonical repo first, then re-run."
  echo ""
  echo "  Workflow: fix locally → test → push to repo → apm-safe-update → verify"
  echo ""
  exit 1
fi

echo "✅ Safe to update. Pulling from remote..."
echo ""

# Source GH_TOKEN if available
if [[ -f "$HOME/.secrets.d/gh.env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.secrets.d/gh.env"
fi

apm update --yes
