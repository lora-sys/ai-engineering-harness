#!/usr/bin/env bats
# tests/agent-regression.bats
#
# Bats wrapper for tests/agent-regression/run-test.sh.
# Runs in --dry-run mode (no LLM calls — just validates fixtures).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "agent-regression: fixtures validate (dry-run)" {
  run bash "$REPO_ROOT/tests/agent-regression/run-test.sh" --dry-run
  [ "$status" -eq 0 ]
}
