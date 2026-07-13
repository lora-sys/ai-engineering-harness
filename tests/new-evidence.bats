#!/usr/bin/env bats
# tests/new-evidence.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/new-evidence.sh"
}

@test "new-evidence with no args exits non-zero and prints Usage" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "new-evidence with valid issue-id creates the directory" {
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"
  mkdir -p docs/evidence
  run bash "$SCRIPT" 42
  [ "$status" -eq 0 ]
  [ -d docs/evidence/42 ]
  rm -rf "$TMPDIR"
}
@test "refuses flag-like arg (issue-id starting with -)" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 2 ]
  [[ "$output" =~ "flag" ]]
}
