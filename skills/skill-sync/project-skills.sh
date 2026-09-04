#!/usr/bin/env bash
# project-skills — build the cross-harness global skill projection.
#
# The home-level global directories (~/.agents/skills, ~/.claude/skills) are
# read by Claude Code, Codex, and opencode. They must contain ONLY universal
# skills. Guitarizta domain skills and host-only local skills must not leak
# into them.
#
# Universal = everything deployed into ~/.kiro/skills EXCEPT the skills owned
# by guitarizta-skills and local-skills. This keeps Matt Pocock / other
# third-party *coding* skills (code-review, tdd, …) available globally while
# excluding the domain- and machine-specific ones.
#
# The projection is a symlink farm pointing at the reconciled ~/.kiro/skills
# tree, so a single `git pull` + `apm update` + `host-sync.sh --apply` keeps it
# current.
#
#   bash project-skills.sh                    # dry run
#   bash project-skills.sh --apply            # write the projection
#   bash project-skills.sh --apply --prune    # also remove non-universal entries
#
# Removal is opt-in via --prune; take a backup first (see the migration doc).

set -euo pipefail

TOOLS_BASE="${TOOLS_BASE:-/Volumes/DATA EXT/Development/Repositories/__tools}"
# Only guitarizta (domain) skills are excluded from the cross-harness global
# dirs. Host-admin skills (local-skills) stay global per the accepted decision
# ("accept the bleed"), so they are NOT excluded here.
EXCLUDE_REPOS=(guitarizta-skills)
SRC="$HOME/.kiro/skills"
TARGETS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
)

APPLY=0
PRUNE=0
for arg in "${@}"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --prune) PRUNE=1 ;;
    *) echo "Usage: bash project-skills.sh [--apply] [--prune]"; exit 1 ;;
  esac
done

# 1. Exclusion set = skills owned by guitarizta-skills + local-skills.
declare -A EXCLUDE=()
for repo in "${EXCLUDE_REPOS[@]}"; do
  skills_dir="$TOOLS_BASE/$repo/skills"
  [[ -d "$skills_dir" ]] || continue
  for d in "$skills_dir"/*/; do
    EXCLUDE["$(basename "$d")"]=1
  done
done

# 2. Universal set = live ~/.kiro/skills minus the exclusion set.
declare -A UNIVERSAL=()
if [[ -d "$SRC" ]]; then
  for d in "$SRC"/*/; do
    name="$(basename "$d")"
    [[ -n "${EXCLUDE[$name]:-}" ]] && continue
    UNIVERSAL["$name"]=1
  done
fi

if [[ ${#UNIVERSAL[@]} -eq 0 ]]; then
  echo "❌ No universal skills found under $SRC"
  exit 1
fi

echo "🔍 project-skills — universal projection"
echo "   source: $SRC"
echo "   universal skills: ${#UNIVERSAL[@]}   excluded: ${#EXCLUDE[@]}"
echo ""

for target in "${TARGETS[@]}"; do
  echo "   → $target"
  [[ "$APPLY" -eq 1 ]] && mkdir -p "$target"

  # Add / refresh universal symlinks.
  for name in "${!UNIVERSAL[@]}"; do
    link="$target/$name"
    if [[ "$target" == *".claude/skills" ]]; then
      src="../../.agents/skills/$name"
    else
      src="$SRC/$name"
    fi
    if [[ "$APPLY" -eq 1 ]]; then
      if [[ -L "$link" ]]; then
        cur="$(readlink "$link")"
        [[ "$cur" == "$src" ]] && continue
        ln -sfn "$src" "$link"
      elif [[ -e "$link" ]]; then
        echo "   ✎  $name — real dir present, replacing with symlink"
        rm -rf "$link"
        ln -s "$src" "$link"
      else
        ln -s "$src" "$link"
      fi
    else
      if [[ -L "$link" ]]; then
        cur="$(readlink "$link")"
        [[ "$cur" == "$src" ]] || echo "   ↗  $name (update → $src)"
      elif [[ -e "$link" ]]; then
        echo "   ✎  $name (replace real dir with symlink)"
      else
        echo "   +  $name"
      fi
    fi
  done

  # Optionally prune non-universal entries.
  if [[ "$PRUNE" -eq 1 && "$APPLY" -eq 1 && -d "$target" ]]; then
    for entry in "$target"/*; do
      [[ -e "$entry" || -L "$entry" ]] || continue
      name="$(basename "$entry")"
      if [[ -z "${UNIVERSAL[$name]:-}" ]]; then
        echo "   ✕  $name (non-universal, removed)"
        rm -rf "$entry"
      fi
    done
  elif [[ "$PRUNE" -eq 1 ]]; then
    for entry in "$target"/*; do
      [[ -e "$entry" || -L "$entry" ]] || continue
      name="$(basename "$entry")"
      if [[ -z "${UNIVERSAL[$name]:-}" ]]; then
        echo "   ✕  $name (non-universal — would remove with --apply --prune)"
      fi
    done
  fi

  echo ""
done

if [[ "$APPLY" -eq 1 ]]; then
  echo "✅ projection written."
else
  echo "✅ dry run complete. Re-run with --apply (and --prune to remove non-universal entries)."
fi
