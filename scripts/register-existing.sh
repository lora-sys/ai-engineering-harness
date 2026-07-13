#!/usr/bin/env bash
# scripts/register-existing.sh — bulk-register pre-existing harness projects.
#
# One-shot command: walk a directory tree, find every project that LOOKS
# like a harness project (AGENTS.md + docs/evidence/), and run
# `sync-project.sh --auto` on it. The result: every previously-taken-over
# project gets a .harness-state.json + the AGENTS.md fenced block, all in
# one command.
#
# Usage:
#   scripts/register-existing.sh                     # scan current working dir
#   scripts/register-existing.sh ~/repos              # scan a specific root
#   scripts/register-existing.sh --dry-run ~/repos   # show what would be done
#   scripts/register-existing.sh --quiet ~/repos     # only print errors
#
# What counts as a "harness project":
#   - has AGENTS.md (the L0 source-of-truth convention)
#   - AND has docs/evidence/ (the evidence-pack convention)
#   - AND does NOT yet have .harness-state.json (only run on the un-registered)
#
# Exit code 0 on success, 1 if any individual registration failed.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
SYNC="$HARNESS_REPO/scripts/sync-project.sh"

DRY_RUN=0
QUIET=0
ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --quiet|-q) QUIET=1 ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) ROOT="$1" ;;
  esac
  shift
done

ROOT="${ROOT:-$PWD}"
ROOT="$(cd "$ROOT" && pwd)"

log()  { [[ $QUIET -eq 0 ]] && printf '[register-existing] %s\n' "$*" >&2 || true; }
fail() { printf '[register-existing] FAIL: %s\n' "$*" >&2; exit 1; }

# Find all candidate projects: dirs that have BOTH AGENTS.md and docs/evidence/
mapfile -t candidates < <(find "$ROOT" -maxdepth 4 -name "AGENTS.md" -type f 2>/dev/null | xargs -n1 dirname 2>/dev/null | sort -u)

if [[ ${#candidates[@]} -eq 0 ]]; then
  log "no projects with AGENTS.md found under $ROOT (max depth 4)"
  exit 0
fi

registered=0
skipped=0
failed=0
already=0

for proj in "${candidates[@]}"; do
  has_agents=$(test -f "$proj/AGENTS.md" && echo 1 || echo 0)
  has_evidence=$(test -d "$proj/docs/evidence" && echo 1 || echo 0)
  has_state=$(test -f "$proj/.harness-state.json" && echo 1 || echo 0)

  if [[ "$has_agents" -ne 1 || "$has_evidence" -ne 1 ]]; then
    continue
  fi
  if [[ "$has_state" -eq 1 ]]; then
    already=$((already + 1))
    log "skip  $proj (already has .harness-state.json)"
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    log "would register  $proj"
    registered=$((registered + 1))
    continue
  fi

  log "register  $proj"
  if bash "$SYNC" --project-dir "$proj" --auto >/dev/null 2>&1; then
    registered=$((registered + 1))
  else
    failed=$((failed + 1))
    log "FAIL  $proj (sync-project.sh exited non-zero; run manually to see)"
  fi
done

log ""
log "Summary: registered=$registered  already=$already  failed=$failed  total-candidates=$((registered + already + failed))"

if [[ $failed -gt 0 ]]; then
  exit 1
fi
