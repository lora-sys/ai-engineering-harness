#!/usr/bin/env bats
# tests/install.bats
#
# Tests for install.sh — specifically the arg-parser fix and the new
# frontend-creative skill path.
#
# Each test sets HOME to a tempdir so the install targets a throwaway
# location and doesn't touch the user's real ~/.claude or ~/.codex.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/install.sh"
  TMPDIR="$(mktemp -d)"
  export HOME="$TMPDIR"
}

teardown() {
  unset HOME
  rm -rf "$TMPDIR"
}

@test "install.sh --help exits 0 and shows Usage" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "install.sh --skill frontend-creative --target codex installs the skill" {
  run bash "$SCRIPT" --skill frontend-creative --target codex
  [ "$status" -eq 0 ]
  [ -d "$HOME/.codex/skills/frontend-creative" ]
  [ -f "$HOME/.codex/skills/frontend-creative/SKILL.md" ]
  [ -f "$HOME/.codex/skills/frontend-creative/meta.json" ]
  python3 -c "
import json
d = json.load(open('$HOME/.codex/skills/frontend-creative/meta.json'))
assert d['id'] == 'frontend-creative'
assert d['version']  # version present
"
}

@test "install.sh --skill frontend-creative does NOT install main harness" {
  bash "$SCRIPT" --skill frontend-creative --target codex
  [ ! -d "$HOME/.codex/skills/ai-engineering-harness" ]
}

@test "install.sh --skill build-agent-app still works (regression)" {
  run bash "$SCRIPT" --skill build-agent-app --target codex
  [ "$status" -eq 0 ]
  [ -d "$HOME/.codex/skills/build-agent-app" ]
}

@test "install.sh --uninstall removes only the named skill" {
  bash "$SCRIPT" --skill frontend-creative --target codex
  bash "$SCRIPT" --skill build-agent-app --target codex
  bash "$SCRIPT" --skill frontend-creative --target codex --uninstall
  [ ! -d "$HOME/.codex/skills/frontend-creative" ]
  [ -d "$HOME/.codex/skills/build-agent-app" ]
}

@test "install.sh --skill all installs the family" {
  bash "$SCRIPT" --skill all --target codex
  [ -d "$HOME/.codex/skills/ai-engineering-harness" ]
  [ -d "$HOME/.codex/skills/build-agent-app" ]
  [ -d "$HOME/.codex/skills/frontend-creative" ]
}

@test "install.sh rejects unknown arg (regression)" {
  run bash "$SCRIPT" --garbage
  [ "$status" -ne 0 ]
  [[ "$output" =~ "unknown arg" ]]
}

@test "install.sh combined --skill and --target parses both args (regression)" {
  # This is the bug we fixed: outer shift consumed the --target value.
  # With the fix, both args land in their respective variables.
  run bash "$SCRIPT" --skill frontend-creative --target codex
  # If we got here without "unknown arg: codex", the parser worked.
  [[ "$output" != *"unknown arg"* ]]
}
