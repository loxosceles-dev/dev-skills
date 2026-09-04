#!/usr/bin/env bash
# host-sync — reconcile the APM output tree into the live Kiro tree.
#
# APM installs with --global into the APM root (~/.apm), so skills and hooks
# land in ~/.apm/.kiro/{skills,hooks}. Kiro reads ~/.kiro/{skills,hooks}.
# This script copies the APM output into the live tree so `apm update` actually
# reaches Kiro.
#
#   bash host-sync.sh             # dry run — print what would change
#   bash host-sync.sh --apply     # perform the sync
#
# It merges, never deletes: skills that exist only in the live tree are left
# alone. Deleting is a deliberate, separate operation.

set -euo pipefail

APM_ROOT="${APM_ROOT:-$HOME/.apm}"
LIVE_ROOT="${LIVE_ROOT:-$HOME/.kiro}"

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: bash host-sync.sh [--apply]"
  exit 1
fi

SRC_SKILLS="$APM_ROOT/.kiro/skills"
SRC_HOOKS="$APM_ROOT/.kiro/hooks"
DST_SKILLS="$LIVE_ROOT/skills"
DST_HOOKS="$LIVE_ROOT/hooks"

if [[ ! -d "$SRC_SKILLS" ]]; then
  echo "❌ APM output not found: $SRC_SKILLS"
  echo "   Run: source ~/.secrets.d/gh.env && apm update --yes (from $APM_ROOT)"
  exit 1
fi

if [[ "$APPLY" -eq 0 ]]; then
  echo "🔍 host-sync — dry run (nothing changed)."
  echo ""
fi

sync_tree() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  mkdir -p "$dst"
  if [[ "$APPLY" -eq 1 ]]; then
    rsync -a --no-perms --no-owner --no-group "$src/" "$dst/"
  else
    rsync -ani --no-perms --no-owner --no-group "$src/" "$dst/"
  fi
}

echo "   $SRC_SKILLS"
echo "     → $DST_SKILLS"
sync_tree "$SRC_SKILLS" "$DST_SKILLS"

if [[ -d "$SRC_HOOKS" ]]; then
  echo "   $SRC_HOOKS"
  echo "     → $DST_HOOKS"
  sync_tree "$SRC_HOOKS" "$DST_HOOKS"
fi

echo ""
if [[ "$APPLY" -eq 1 ]]; then
  echo "✅ host-sync complete."
else
  echo "✅ dry run complete. Re-run with --apply to perform the sync."
fi
