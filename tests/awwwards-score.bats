#!/usr/bin/env bats
# tests/awwwards-score.bats
#
# Bats wrapper for tests/awwwards-score/run-test.sh. Dry-run only by default
# (the LLM call is expensive).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "awwwards-score: dry-run validates fixtures" {
  run bash "$REPO_ROOT/tests/awwwards-score/run-test.sh" --dry-run
  [ "$status" -eq 0 ]
}
