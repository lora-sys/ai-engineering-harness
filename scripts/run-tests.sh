#!/usr/bin/env bash
# scripts/run-tests.sh — run all bats tests for the harness's own scripts.
#
# Why bats:
#   - Bash-native assertions (`@test`, `run`, `[ ... ]`)
#   - Per-test setup/teardown via setup()/teardown()
#   - Easy to debug (each test is just a bash function)
#   - Standard in the bash ecosystem (apt install bats / brew install bats-core
#     / npm install -g bats)
#
# Usage:
#   scripts/run-tests.sh           # run everything
#   scripts/run-tests.sh install   # only install-session-hook.bats
#   scripts/run-tests.sh -h        # help
#
# Exit codes:
#   0  all tests passed
#   1  bats not installed (with install hint)
#   2  some tests failed

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$REPO_DIR/tests"

log() { printf '[run-tests] %s\n' "$*" >&2; }

# Locate bats. Allow BATS env override (for CI / non-standard installs).
BATS_BIN="${BATS:-}"
if [[ -z "$BATS_BIN" ]] || ! command -v "$BATS_BIN" >/dev/null 2>&1; then
  if command -v bats >/dev/null 2>&1; then
    BATS_BIN=bats
  elif [[ -x "$HOME/.local/bin/bats" ]]; then
    BATS_BIN="$HOME/.local/bin/bats"
  else
    log "FAIL: bats not installed."
    log "  Install with one of:"
    log "    apt-get install bats"
    log "    brew install bats-core"
    log "    npm install -g bats && ln -sf \$(npm root -g)/bats/bin/bats ~/.local/bin/bats"
    exit 1
  fi
fi

filter=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  filter="$1" ;;
  esac
  shift
done

cd "$REPO_DIR"

if [[ -n "$filter" ]]; then
  log "running $BATS_BIN tests/$filter.bats"
  "$BATS_BIN" "tests/$filter.bats"
else
  log "running $BATS_BIN tests/*.bats"
  "$BATS_BIN" tests/
fi
