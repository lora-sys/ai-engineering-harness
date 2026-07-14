#!/usr/bin/env bats
# tests/skill-benchmark.bats
#
# Bats wrapper for tests/skill-benchmark/run-test.sh (dry-run mode).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "skill-benchmark: dry-run validates fixtures" {
  run bash "$REPO_ROOT/tests/skill-benchmark/run-test.sh" --dry-run
  [ "$status" -eq 0 ]
}
