#!/usr/bin/env bats
# tests/cross-version.bats
#
# Bats wrapper for tests/cross-version/run-test.sh.
# Runs the cross-version regression check and reports pass/fail.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "cross-version regression: run-test.sh exits 0" {
  run bash "$REPO_ROOT/tests/cross-version/run-test.sh"
  [ "$status" -eq 0 ]
}
