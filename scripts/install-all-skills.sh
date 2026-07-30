#!/usr/bin/env bash
# scripts/install-all-skills.sh — bulk-install the entire skill family.
#
# This is the script to use when:
#   - You installed via `npx skills add` (which only carries the main skill's
#     SKILL.md + meta.json — the thin canonical install).
#   - The sibling skills (build-agent-app, frontend-creative, dashboard) are missing from
#     your agent dir.
#   - You want the LLM to actually discover and use the siblings.
#
# What it does (idempotent):
#   1. For each known TARGET dir (~/.codex/skills, ~/.agents/skills, etc.):
#      a. For each of the 4 skills (ai-engineering-harness, build-agent-app,
#         frontend-creative, dashboard):
#         - If a fat install (full SKILL.md + workflows/ + ...) is wanted and
#           the sibling's full directory exists in this repo: copy the full
#           bundle. (Thin canonical: copy only SKILL.md + meta.json.)
#      b. The thin install is the default — npx skills CLI does this for the
#         main skill; we extend the same thin install to the siblings so
#         they're discoverable by the LLM.
#   2. Reports what was installed where.
#
# Usage:
#   scripts/install-all-skills.sh                     # thin install everywhere
#   scripts/install-all-skills.sh --fat              # fat install (full bundle)
#   scripts/install-all-skills.sh --status          # report state, change nothing
#   scripts/install-all-skills.sh --uninstall       # remove the 4 skills everywhere
#
# Exit code 0 on success.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SH="$REPO_DIR/install.sh"

FAT=0
ACTION="install"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fat) FAT=1 ;;
    --status) ACTION="status" ;;
    --uninstall) ACTION="uninstall" ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '[install-all] %s\n' "$*" >&2; }

# All 4 skills in the family. Order matters: main first, siblings after.
SKILLS=(ai-engineering-harness build-agent-app frontend-creative dashboard)

# TARGET paths to install into + the install.sh --target name each maps to.
# Using indexed arrays for Bash 3.2 compat (no declare -A).
PATH_TO_NAME_LIST=(
  "$HOME/.codex/skills|codex"
  "$HOME/.agents/skills|agents"
  "$HOME/.claude/skills|claude"
  "$HOME/.qwen/skills|qwen"
  "$HOME/.gemini/skills|gemini"
  "$HOME/.cursor/skills|cursor"
  "$HOME/.grok/skills|grok"
  "$HOME/.hermes/skills|hermes"
  "$HOME/.hermes/hermes-agent/skills|hermes-agent"
  "$HOME/.aider-desk/skills|aider-desk"
  "$HOME/.augment/skills|augment"
  "$HOME/.config/opencode/skills|opencode"
  "$HOME/.trae/skills|trae"
  "$HOME/.trae-cn/skills|trae-cn"
)

path_to_name() {
  local p="$1"
  for entry in "${PATH_TO_NAME_LIST[@]}"; do
    local path_part="${entry%%|*}"
    local name_part="${entry#*|}"
    if [[ "$p" == "$path_part" ]]; then echo "$name_part"; return; fi
  done
  echo ""
}

# Extract just the path portion for iteration
# Extract just the path portion for iteration
TARGETS=()
for entry in "${PATH_TO_NAME_LIST[@]}"; do
  TARGETS+=("${entry%%|*}")
done

# For each target, run install.sh with --skill <each-skill> --target <target>.
case "$ACTION" in
  install)
    log "installing 4 skills × ${#TARGETS[@]} targets (fat=$FAT)"
    for target in "${TARGETS[@]}"; do
      [[ -d "$target" ]] || continue
      target_name="$(path_to_name "$target")"
      if [[ -z "$target_name" ]]; then
        log "  SKIP  $target (no install.sh TARGET matches; add manually)"
        continue
      fi
      for skill in "${SKILLS[@]}"; do
        if [[ "$FAT" -eq 1 ]]; then
          log "fat  $target/$skill  (target=$target_name)"
          bash "$INSTALL_SH" --fat-install --skill "$skill" --target "$target_name" 2>&1 \
            | sed "s/^/    /" || log "  failed: $target/$skill"
        else
          log "thin $target/$skill  (target=$target_name)"
          bash "$INSTALL_SH" --skill "$skill" --target "$target_name" 2>&1 \
            | sed "s/^/    /" || true
        fi
      done
    done
    log "done"
    ;;
  status)
    log "skill family state across ${#TARGETS[@]} targets:"
    echo
    printf "  %-30s | %-25s | %-25s | %-25s | %-25s\n" "TARGET" "ai-engineering-harness" "build-agent-app" "frontend-creative" "dashboard"
    printf "  %-30s-+-%-25s-+-%-25s-+-%-25s-+-%-25s\n" "$(printf -- '%.0s-' {1..30})" "$(printf -- '%.0s-' {1..25})" "$(printf -- '%.0s-' {1..25})" "$(printf -- '%.0s-' {1..25})" "$(printf -- '%.0s-' {1..25})"
    for target in "${TARGETS[@]}"; do
      [[ -d "$target" ]] || continue
      printf "  %-30s | %-25s | %-25s | %-25s | %-25s\n" \
        "$target" \
        "$(test -f $target/ai-engineering-harness/SKILL.md && echo present || echo MISSING)" \
        "$(test -f $target/build-agent-app/SKILL.md && echo present || echo MISSING)" \
        "$(test -f $target/frontend-creative/SKILL.md && echo present || echo MISSING)" \
        "$(test -f $target/dashboard/SKILL.md && echo present || echo MISSING)"
    done
    ;;
  uninstall)
    log "removing 4 skills from all targets"
    bash "$INSTALL_SH" --uninstall 2>&1 | sed 's/^/    /'
    ;;
esac
