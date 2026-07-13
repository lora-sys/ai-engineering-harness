#!/usr/bin/env bats
# tests/new-session.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/new-session.sh"
}

@test "new-session with no args exits non-zero and prints Usage" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "new-session with valid session-id creates the directory" {
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"
  mkdir -p sessions
  run bash "$SCRIPT" test-session-1
  [ "$status" -eq 0 ]
  [ -d sessions/test-session-1 ]
  rm -rf "$TMPDIR"
}
@test "refuses flag-like arg (session-id starting with -)" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 2 ]
  [[ "$output" =~ "flag" ]]
}
