#!/usr/bin/env bash
# scripts/install-all-skills.sh — bulk-install the entire skill family.
#
# This is the script to use when:
#   - You installed via `npx skills add` (which only carries the main skill's
#     SKILL.md + meta.json — the thin canonical install).
#   - The sibling skills (build-agent-app, frontend-creative) are missing from
#     your agent dir.
#   - You want the LLM to actually discover and use the siblings.
#
# What it does (idempotent):
#   1. For each known TARGET dir (~/.codex/skills, ~/.agents/skills, etc.):
#      a. For each of the 3 skills (ai-engineering-harness, build-agent-app,
#         frontend-creative):
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
#   scripts/install-all-skills.sh --uninstall       # remove the 3 skills everywhere
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

# All 3 skills in the family. Order matters: main first, siblings after.
SKILLS=(ai-engineering-harness build-agent-app frontend-creative)

# TARGET paths to install into + the install.sh --target name each maps to.
# Keep in sync with install.sh's TARGETS array. (We hardcode here for speed and
# because install.sh rarely changes its list of supported agents.)
declare -A PATH_TO_NAME
PATH_TO_NAME["$HOME/.codex/skills"]="codex"
PATH_TO_NAME["$HOME/.agents/skills"]="agents"
PATH_TO_NAME["$HOME/.claude/skills"]="claude"
PATH_TO_NAME["$HOME/.qwen/skills"]="qwen"
PATH_TO_NAME["$HOME/.gemini/skills"]="gemini"
PATH_TO_NAME["$HOME/.cursor/skills"]="cursor"
PATH_TO_NAME["$HOME/.grok/skills"]="grok"
PATH_TO_NAME["$HOME/.hermes/skills"]="hermes"
PATH_TO_NAME["$HOME/.hermes/hermes-agent/skills"]="hermes-agent"
PATH_TO_NAME["$HOME/.aider-desk/skills"]="aider-desk"
PATH_TO_NAME["$HOME/.augment/skills"]="augment"
PATH_TO_NAME["$HOME/.config/opencode/skills"]="opencode"
PATH_TO_NAME["$HOME/.trae/skills"]="trae"
PATH_TO_NAME["$HOME/.trae-cn/skills"]="trae-cn"
# Add more here as the family grows.
TARGETS=("${!PATH_TO_NAME[@]}")

# For each target, run install.sh with --skill <each-skill> --target <target>.
# install.sh already handles thin vs fat; we just iterate.
case "$ACTION" in
  install)
    log "installing 3 skills × ${#TARGETS[@]} targets (fat=$FAT)"
    for target in "${TARGETS[@]}"; do
      [[ -d "$target" ]] || continue
      target_name="${PATH_TO_NAME[$target]:-}"
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
    printf "  %-30s | %-25s | %-25s | %-25s\n" "TARGET" "ai-engineering-harness" "build-agent-app" "frontend-creative"
    printf "  %-30s-+-%-25s-+-%-25s-+-%-25s\n" "$(printf -- '%.0s-' {1..30})" "$(printf -- '%.0s-' {1..25})" "$(printf -- '%.0s-' {1..25})" "$(printf -- '%.0s-' {1..25})"
    for target in "${TARGETS[@]}"; do
      [[ -d "$target" ]] || continue
      printf "  %-30s | %-25s | %-25s | %-25s\n" \
        "$target" \
        "$(test -f $target/ai-engineering-harness/SKILL.md && echo present || echo MISSING)" \
        "$(test -f $target/build-agent-app/SKILL.md && echo present || echo MISSING)" \
        "$(test -f $target/frontend-creative/SKILL.md && echo present || echo MISSING)"
    done
    ;;
  uninstall)
    log "removing 3 skills from all targets"
    bash "$INSTALL_SH" --uninstall 2>&1 | sed 's/^/    /'
    ;;
esac
