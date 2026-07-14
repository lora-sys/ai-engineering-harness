#!/usr/bin/env bash
# tests/cross-version/run-test.sh
#
# Cross-version regression test. Register fixtures with the OLD (v1.7.0) sync-project.sh,
# then with the CURRENT (HEAD) sync-project.sh, and verify migration invariants.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIX="$SCRIPT_DIR/fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$REPO_DIR"

V17_SCRIPT="$FIX/scripts/sync-project-v1.7.0.sh"
CUR_SCRIPT="$REPO_DIR/scripts/sync-project.sh"

[[ -f "$V17_SCRIPT" ]] || { echo "FAIL: v1.7 script not at $V17_SCRIPT" >&2; exit 1; }
[[ -f "$CUR_SCRIPT" ]] || { echo "FAIL: current script not at $CUR_SCRIPT" >&2; exit 1; }

export FAKE_HOME="$(mktemp -d)"
mkdir -p "$FAKE_HOME/.claude/hooks"

extract_fence() {
  python3 - "$1" <<'PY'
import sys, re
text = open(sys.argv[1]).read()
m = re.search(r'<!-- HARNESS:START harness-capabilities -->\n(.*?)<!-- HARNESS:END harness-capabilities -->',
              text, re.DOTALL)
print(m.group(1).rstrip() if m else '')
PY
}

extract_user_content() {
  python3 - "$1" <<'PY'
import sys, re
text = open(sys.argv[1]).read()
# Strip full HARNESS fenced blocks (tags + content between them).
# Use a non-greedy match from HARNESS:START through HARNESS:END.
out = re.sub(r'<!-- HARNESS:START [^\n]*\n.*?<!-- HARNESS:END [^\n]*\n?', '', text, flags=re.DOTALL)
# Also remove any leftover standalone HARNESS:START/END tags.
out = re.sub(r'<!-- HARNESS:(START|END)[^\n]*\n?', '', out)
print(out.strip())
PY
}

run_sync() {
  bash "$1" --project-dir "$2" --auto >/dev/null 2>&1
}

fail=0
for fixture in project-alpha project-beta; do
  echo "── Fixture: $fixture ──"
  FRESH="$(mktemp -d)"
  cp -r "$FIX/$fixture/." "$FRESH/"

  # Run v1.7
  run_sync "$V17_SCRIPT" "$FRESH"
  v17_state="$(cat "$FRESH/.harness-state.json" 2>/dev/null || echo '{}')"
  v17_fence="$(extract_fence "$FRESH/AGENTS.md")"
  v17_user="$(extract_user_content "$FRESH/AGENTS.md")"
  v17_version="$(python3 -c "import json; print(json.loads('''$v17_state''').get('version','?'))")"
  echo "  v1.7: state.version=$v17_version, fence_len=${#v17_fence}, user_len=${#v17_user}"

  # v1.7 re-run idempotent
  v17_fence_before="$v17_fence"
  run_sync "$V17_SCRIPT" "$FRESH"
  v17_fence_after="$(extract_fence "$FRESH/AGENTS.md")"
  if [[ "$v17_fence_before" != "$v17_fence_after" ]]; then
    echo "  ✗ v1.7 re-run: fence block CHANGED (should be idempotent)"
    fail=$((fail+1))
  else
    echo "  ✓ v1.7 re-run: fence block idempotent"
  fi

  # Run current (HEAD)
  run_sync "$CUR_SCRIPT" "$FRESH"
  cur_state="$(cat "$FRESH/.harness-state.json" 2>/dev/null || echo '{}')"
  cur_fence="$(extract_fence "$FRESH/AGENTS.md")"
  cur_user="$(extract_user_content "$FRESH/AGENTS.md")"
  cur_version="$(python3 -c "import json; print(json.loads('''$cur_state''').get('version','?'))")"
  echo "  HEAD:  state.version=$cur_version, fence_len=${#cur_fence}, user_len=${#cur_user}"

  # Invariant 1: user content preserved
  if [[ "$v17_user" != "$cur_user" ]]; then
    echo "  ✗ REGRESSION: user content (outside fence) changed across v1.7 → HEAD"
    diff <(echo "$v17_user") <(echo "$cur_user") | head -20
    fail=$((fail+1))
  else
    echo "  ✓ user content preserved (v1.7 == HEAD user content)"
  fi

  # Invariant 2: HEAD fence non-empty
  if [[ -z "$cur_fence" ]]; then
    echo "  ✗ REGRESSION: HEAD fence block empty"
    fail=$((fail+1))
  else
    echo "  ✓ HEAD fence block non-empty (${#cur_fence} chars)"
  fi

  # Invariant 3: state file version == HEAD version
  if [[ "$cur_version" != "1.8.8" ]]; then
    echo "  ✗ state file version mismatch: expected 1.8.8, got $cur_version"
    fail=$((fail+1))
  else
    echo "  ✓ state file version == 1.8.8"
  fi

  # Invariant 4: HEAD re-run idempotent
  cur_fence_before="$cur_fence"
  run_sync "$CUR_SCRIPT" "$FRESH"
  cur_fence_after="$(extract_fence "$FRESH/AGENTS.md")"
  if [[ "$cur_fence_before" != "$cur_fence_after" ]]; then
    echo "  ✗ HEAD re-run: fence block CHANGED"
    fail=$((fail+1))
  else
    echo "  ✓ HEAD re-run: fence block idempotent"
  fi

  # Invariant 5: initial state was upgraded
  if [[ -f "$FIX/$fixture/.harness-state.json" ]]; then
    initial_v="$(python3 -c "import json; print(json.load(open('$FIX/$fixture/.harness-state.json'))['version'])")"
    if [[ "$cur_version" != "1.8.8" && "$initial_v" != "1.8.8" ]]; then
      echo "  ✗ Initial state $initial_v was not upgraded to current"
      fail=$((fail+1))
    else
      echo "  ✓ Initial state $initial_v → current $cur_version (upgrade path)"
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
