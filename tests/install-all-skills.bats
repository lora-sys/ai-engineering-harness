#!/usr/bin/env bats
# tests/install-all-skills.bats
#
# Tests for scripts/install-all-skills.sh — the bulk-install script.
# Verifies the status output + idempotency.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/install-all-skills.sh"
}

@test "install-all-skills --help exits 0 and shows Usage" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "install-all-skills --status reports 3 skills per target" {
  run bash "$SCRIPT" --status
  [ "$status" -eq 0 ]
  # Single `[[ ]]` chain, not three separate lines: a failing `[[ ]]` aborts the
  # body, so written separately the later checks are only reached when the earlier
  # ones already passed. All three skills are required, and the chain says so.
  [[ "$output" =~ "ai-engineering-harness" ]] \
    && [[ "$output" =~ "build-agent-app" ]] \
    && [[ "$output" =~ "frontend-creative" ]]
}

@test "install-all-skills PATH_TO_NAME resolves common targets" {
  # The map is a Bash 3.2-compatible indexed array of "path|name" entries
  # (macOS ships bash 3.2, which has no `declare -A`).
  grep -q 'PATH_TO_NAME_LIST=(' "$SCRIPT"
  grep -q '"\$HOME/.codex/skills|codex"' "$SCRIPT"
  grep -q '"\$HOME/.claude/skills|claude"' "$SCRIPT"
  grep -q '"\$HOME/.agents/skills|agents"' "$SCRIPT"
  # And the lookup helper that replaces associative-array indexing
  grep -q 'path_to_name()' "$SCRIPT"
}
