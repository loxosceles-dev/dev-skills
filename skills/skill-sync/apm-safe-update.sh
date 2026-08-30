#!/usr/bin/env bash
# apm-safe-update — safe wrapper around `apm update --yes`
#
# Blocks if any APM-owned file in .kiro/skills/ has local edits newer than
# what the lockfile expects. That means: you edited locally but haven't pushed
# yet — running apm update would destroy your work.
#
# Safe case (allows update):
#   local SHA != lockfile SHA, but lockfile mtime > local mtime
#   → repo moved forward, you just haven't synced yet. Normal update.
#
# Dangerous case (blocks):
#   local SHA != lockfile SHA, and local mtime > lockfile mtime
#   → you edited locally after the last sync. Push first.

set -euo pipefail

LOCK_FILE="apm.lock.yaml"

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "❌ No apm.lock.yaml found. Run from project root."
  exit 1
fi

blocked=()

# Parse lockfile: extract pairs of (path, expected_sha)
# Lines look like: "    .kiro/skills/pr-fixer/SKILL.md: sha256:abc123..."
while IFS= read -r line; do
  # Match lines with .kiro/skills/ path and sha256
  if [[ "$line" =~ ^[[:space:]]+(\.kiro/skills/[^:]+):[[:space:]]+sha256:([a-f0-9]+) ]]; then
    rel_path="${BASH_REMATCH[1]}"
    expected_sha="${BASH_REMATCH[2]}"

    [[ -f "$rel_path" ]] || continue

    # Compute actual SHA of deployed file (sha256, strip filename)
    actual_sha=$(shasum -a 256 "$rel_path" | awk '{print $1}')

    if [[ "$actual_sha" == "$expected_sha" ]]; then
      continue  # File matches lockfile — clean
    fi

    # SHAs differ. Check which is newer: local file vs lockfile itself.
    # If local file is newer than the lockfile, it has unpushed edits.
    local_mtime=$(stat -f "%m" "$rel_path" 2>/dev/null || stat -c "%Y" "$rel_path")
    lock_mtime=$(stat -f "%m" "$LOCK_FILE" 2>/dev/null || stat -c "%Y" "$LOCK_FILE")

    if [[ "$local_mtime" -gt "$lock_mtime" ]]; then
      blocked+=("$rel_path")
    fi
  fi
done < "$LOCK_FILE"

if [[ ${#blocked[@]} -gt 0 ]]; then
  echo ""
  echo "🚫 apm update blocked — local edits would be overwritten:"
  echo ""
  for f in "${blocked[@]}"; do
    echo "  ✎  $f"
  done
  echo ""
  echo "These files were edited locally after the last apm sync."
  echo "Push your changes to the canonical repo first, then re-run."
  echo ""
  echo "  Workflow: fix locally → test → push to repo → apm-safe-update → verify"
  echo ""
  exit 1
fi

echo "✅ No unpushed local skill edits detected. Running apm update..."
echo ""

# Source GH_TOKEN if available
if [[ -f "$HOME/.secrets.d/gh.env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.secrets.d/gh.env"
fi

apm update --yes
