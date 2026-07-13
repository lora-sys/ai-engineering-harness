#!/usr/bin/env bats
# tests/compact-report.bats
#
# Tests for scripts/compact-report.sh.
# Exercises: required inputs, JSON shape, auto-detection of test status.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  EVDIR="$(mktemp -d)"
  mkdir -p "$EVDIR/test-results"
  echo "Test report" > "$EVDIR/implementation-report.md"
}

teardown() {
  rm -rf "$EVDIR"
}

@test "compact-report --help exits 0" {
  run bash "$REPO_ROOT/scripts/compact-report.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "compact-report refuses missing --evidence-dir" {
  run bash "$REPO_ROOT/scripts/compact-report.sh" --branch x --agent y
  [ "$status" -ne 0 ]
  [[ "$output" =~ "evidence-dir" ]]
}

@test "compact-report refuses missing --branch" {
  run bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --agent y
  [ "$status" -ne 0 ]
  [[ "$output" =~ "branch" ]]
}

@test "compact-report refuses missing --agent" {
  run bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch x
  [ "$status" -ne 0 ]
  [[ "$output" =~ "agent" ]]
}

@test "compact-report refuses nonexistent evidence-dir" {
  run bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir /tmp/does-not-exist-xyz --branch x --agent y
  [ "$status" -ne 0 ]
}

@test "compact-report emits valid JSON" {
  output="$(bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend 2>/dev/null)"
  echo "$output" | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
assert d['agent'] == 'backend'
assert d['branch'] == 'feat/x'
assert d['test'] == 'skipped'  # no test-results/
assert isinstance(d['blockers'], list)
assert isinstance(d['evidence_paths'], list)
"
}

@test "compact-report auto-detects PASS" {
  echo "PASS test_foo" > "$EVDIR/test-results/unit.log"
  bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['test']=='pass', d"
}

@test "compact-report auto-detects FAIL" {
  echo "FAIL test_foo" > "$EVDIR/test-results/unit.log"
  bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['test']=='fail', d"
}

@test "compact-report any FAIL wins over PASS" {
  echo "PASS test_foo" > "$EVDIR/test-results/unit.log"
  echo "FAIL test_bar" >> "$EVDIR/test-results/unit.log"
  bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['test']=='fail', d"
}

@test "compact-report accumulates multiple --blocker flags" {
  bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend \
    --blocker "needs review" --blocker "waiting on infra" 2>/dev/null \
    | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
assert d['blockers'] == ['needs review', 'waiting on infra'], d['blockers']
"
}

@test "compact-report --files-changed override" {
  bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend --files-changed 42 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['files']==42, d"
}

@test "compact-report writes compact-report.json into evidence-dir" {
  bash "$REPO_ROOT/scripts/compact-report.sh" --evidence-dir "$EVDIR" --branch feat/x --agent backend 2>/dev/null >/dev/null
  [ -f "$EVDIR/compact-report.json" ]
  python3 -c "import json; json.load(open('$EVDIR/compact-report.json'))"
}
