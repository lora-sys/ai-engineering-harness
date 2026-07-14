#!/usr/bin/env bash
# tests/cross-version/run-test.sh
#
# Cross-version regression test. Register fixtures with the FROZEN
# (v1.8.0) sync-project.sh, then with the CURRENT (HEAD) sync-project.sh,
# and verify the migration invariants.
#
# Invariants checked (per fixture):
#   1. User content outside the harness fenced block is preserved.
#   2. HEAD's fenced block is non-empty (the capabilities list is there).
#   3. State file version == the current HEAD version.
#   4. Both versions are idempotent (re-run produces same fenced content).
#   5. If the fixture had a state file at v1.6, HEAD upgrades it to the
#      current version (the upgrade path works).

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIX="$SCRIPT_DIR/fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$REPO_DIR"

OLD_SCRIPT="$FIX/scripts/sync-project-v1.8.0.sh"
CUR_SCRIPT="$REPO_DIR/scripts/sync-project.sh"
HEAD_VERSION="$(python3 -c "import json; print(json.load(open('$REPO_DIR/meta.json'))['version'])")"

[[ -f "$OLD_SCRIPT" ]] || { echo "FAIL: v1.8 script not at $OLD_SCRIPT" >&2; exit 1; }
[[ -f "$CUR_SCRIPT" ]] || { echo "FAIL: current script not at $CUR_SCRIPT" >&2; exit 1; }

# Forward HARNESS_REPO so the frozen script (under tests/cross-version/fixtures/scripts/)
# can find meta.json at the real repo root.
run_sync() {
  HARNESS_REPO="$REPO_DIR" bash "$1" --project-dir "$2" --auto >/dev/null 2>&1
}

# Extract the HARNESS fenced block.
extract_fence() {
  python3 - "$1" <<'PY'
import sys, re
text = open(sys.argv[1]).read()
m = re.search(
    r'<!-- HARNESS:START harness-capabilities -->\n(.*?)<!-- HARNESS:END harness-capabilities -->',
    text, re.DOTALL,
)
print(m.group(1).rstrip() if m else '')
PY
}

# Extract user content (everything except the fenced blocks).
extract_user_content() {
  python3 - "$1" <<'PY'
import sys, re
text = open(sys.argv[1]).read()
out = re.sub(
    r'<!-- HARNESS:START [^\n]*\n.*?<!-- HARNESS:END [^\n]*\n?',
    '',
    text,
    flags=re.DOTALL,
)
out = re.sub(r'<!-- HARNESS:(START|END)[^\n]*\n?', '', out)
print(out.strip())
PY
}

# Get version from a state.json string.
get_version() {
  python3 -c "import json; print(json.loads('''$1''').get('version', '?'))" 2>/dev/null || echo "?"
}

fail=0

for fixture in project-alpha project-beta; do
  echo "── Fixture: $fixture ──"
  FRESH="$(mktemp -d)"
  cp -r "$FIX/$fixture/." "$FRESH/"

  # Run OLD version
  run_sync "$OLD_SCRIPT" "$FRESH"
  old_state="$(cat "$FRESH/.harness-state.json" 2>/dev/null || echo '{}')"
  old_fence="$(extract_fence "$FRESH/AGENTS.md")"
  old_user="$(extract_user_content "$FRESH/AGENTS.md")"
  old_v="$(get_version "$old_state")"
  echo "  OLD (v1.8.0): state.version=$old_v, fence_len=${#old_fence}, user_len=${#old_user}"

  # OLD re-run idempotent
  old_fence_before="$old_fence"
  run_sync "$OLD_SCRIPT" "$FRESH"
  old_fence_after="$(extract_fence "$FRESH/AGENTS.md")"
  if [[ "$old_fence_before" != "$old_fence_after" ]]; then
    echo "  ✗ OLD re-run: fence block CHANGED (should be idempotent)"
    fail=$((fail + 1))
  else
    echo "  ✓ OLD re-run: fence block idempotent"
  fi

  # Run current (HEAD)
  run_sync "$CUR_SCRIPT" "$FRESH"
  cur_state="$(cat "$FRESH/.harness-state.json" 2>/dev/null || echo '{}')"
  cur_fence="$(extract_fence "$FRESH/AGENTS.md")"
  cur_user="$(extract_user_content "$FRESH/AGENTS.md")"
  cur_v="$(get_version "$cur_state")"
  echo "  HEAD:          state.version=$cur_v, fence_len=${#cur_fence}, user_len=${#cur_user}"

  # Invariant 1: user content preserved
  if [[ "$old_user" != "$cur_user" ]]; then
    echo "  ✗ REGRESSION: user content (outside fence) changed across v1.8.0 → HEAD"
    diff <(echo "$old_user") <(echo "$cur_user") | head -20
    fail=$((fail + 1))
  else
    echo "  ✓ user content preserved (v1.8.0 == HEAD user content)"
  fi

  # Invariant 2: HEAD fence non-empty
  if [[ -z "$cur_fence" ]]; then
    echo "  ✗ REGRESSION: HEAD fence block is empty"
    fail=$((fail + 1))
  else
    echo "  ✓ HEAD fence block non-empty (${#cur_fence} chars)"
  fi

  # Invariant 3: state file version == HEAD version
  if [[ "$cur_v" != "$HEAD_VERSION" ]]; then
    echo "  ✗ state file version mismatch: expected $HEAD_VERSION, got $cur_v"
    fail=$((fail + 1))
  else
    echo "  ✓ state file version == $HEAD_VERSION"
  fi

  # Invariant 4: HEAD re-run idempotent
  cur_fence_before="$cur_fence"
  run_sync "$CUR_SCRIPT" "$FRESH"
  cur_fence_after="$(extract_fence "$FRESH/AGENTS.md")"
  if [[ "$cur_fence_before" != "$cur_fence_after" ]]; then
    echo "  ✗ HEAD re-run: fence block CHANGED"
    fail=$((fail + 1))
  else
    echo "  ✓ HEAD re-run: fence block idempotent"
  fi

  # Invariant 5: initial state was upgraded
  if [[ -f "$FIX/$fixture/.harness-state.json" ]]; then
    initial_v="$(python3 -c "import json; print(json.load(open('$FIX/$fixture/.harness-state.json'))['version'])")"
    if [[ "$cur_v" != "$HEAD_VERSION" && "$initial_v" != "$HEAD_VERSION" ]]; then
      echo "  ✗ Initial state $initial_v was not upgraded to current"
      fail=$((fail + 1))
    else
      echo "  ✓ Initial state $initial_v → current $cur_v (upgrade path)"
    fi
  fi

  rm -rf "$FRESH"
done

echo
if [[ $fail -eq 0 ]]; then
  echo "════════════════════════════════════"
  echo " CROSS-VERSION REGRESSION: PASS"
  echo "════════════════════════════════════"
  exit 0
else
  echo "════════════════════════════════════"
  echo " CROSS-VERSION REGRESSION: $fail failure(s)"
  echo "════════════════════════════════════"
  exit 1
fi
