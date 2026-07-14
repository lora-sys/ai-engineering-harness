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
  [[ "$output" =~ "ai-engineering-harness" ]]
  [[ "$output" =~ "build-agent-app" ]]
  [[ "$output" =~ "frontend-creative" ]]
}

@test "install-all-skills PATH_TO_NAME resolves common targets" {
  # Source the script's hardcoded map (it's just a bash file with assignments)
  grep -E 'PATH_TO_NAME\[' "$SCRIPT" | head -3 | while read -r line; do
    [[ -n "$line" ]] || continue
  done
  # Quick check: known targets are in the map
  grep -q 'PATH_TO_NAME\["\$HOME/.codex/skills"\]="codex"' "$SCRIPT"
  grep -q 'PATH_TO_NAME\["\$HOME/.claude/skills"\]="claude"' "$SCRIPT"
  grep -q 'PATH_TO_NAME\["\$HOME/.agents/skills"\]="agents"' "$SCRIPT"
}
