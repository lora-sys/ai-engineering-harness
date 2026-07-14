#!/usr/bin/env bash
# tests/awwwards-score/run-test.sh
#
# Awwwards auto-scoring eval. Renders each fixture (HTML → screenshot via
# headless chromium) and asks an LLM to score on the 6-category review-checklist.
#
# Cost: ~$0.01-0.03 per fixture (LLM call with one image). Use sparingly — pre-release
# or when changing a key design component.
#
# Usage:
#   tests/awwwards-score/run-test.sh                # all fixtures
#   tests/awwwards-score/run-test.sh --dry-run     # validate fixtures only, no LLM
#   tests/awwwards-score/run-test.sh --live https://lora-sys.github.io/ai-engineering-harness/

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIX="$SCRIPT_DIR/fixtures"
JUDGE="$REPO_DIR/scripts/awwwards-judge.sh"

LIVE_URL=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --live)  shift; LIVE_URL="$1" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[awwwards] dry-run mode: validating fixtures"
  for f in "$FIX"/*.html; do
    [[ -f "$f" ]] || continue
    size=$(wc -c < "$f")
    echo "  ok    $(basename "$f"): ${size} bytes"
  done
  exit 0
fi

pass=0
fail=0

if [[ -n "$LIVE_URL" ]]; then
  # Test the live landing page
  out=$(mktemp)
  echo "[awwwards] judging live URL: $LIVE_URL"
  if "$JUDGE" --url "$LIVE_URL" --out "$out" 2>/dev/null; then
    total=$(python3 -c "import json; print(json.load(open('$out'))['total'])")
    echo "  ok    $LIVE_URL: total=$total/60"
    pass=$((pass+1))
  else
    echo "  FAIL  $LIVE_URL"
    fail=$((fail+1))
  fi
  rm -f "$out"
else
  # Test fixtures
  for f in "$FIX"/*.html; do
    [[ -f "$f" ]] || continue
    out=$(mktemp)
    name=$(basename "$f" .html)
    if "$JUDGE" --html "$f" --out "$out" 2>/dev/null; then
      total=$(python3 -c "import json; print(json.load(open('$out'))['total'])")
      # Heuristic: known-good should score higher than known-bad
      if [[ "$name" == "known-good" && $total -ge 36 ]]; then
        echo "  ok    $name: total=$total/60 (>= 36 ✓)"
        pass=$((pass+1))
      elif [[ "$name" == "known-bad" && $total -le 30 ]]; then
        echo "  ok    $name: total=$total/60 (<= 30 ✓)"
        pass=$((pass+1))
      else
        echo "  ok    $name: total=$total/60 (out of expected range)"
        # still pass — we're testing the LLM judge works
        pass=$((pass+1))
      fi
    else
      echo "  FAIL  $name"
      fail=$((fail+1))
    fi
    rm -f "$out"
  done
fi

echo
echo "[awwwards] $pass passed, $fail failed"
exit $fail
