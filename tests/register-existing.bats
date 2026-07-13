#!/usr/bin/env bats
# tests/register-existing.bats
#
# Tests for scripts/register-existing.sh.
# Uses a tempdir tree of fake harness projects to exercise the discovery + apply.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/register-existing.sh"
  SYNC="$REPO_ROOT/scripts/sync-project.sh"
  ROOT="$(mktemp -d)"
}

teardown() {
  rm -rf "$ROOT"
}

make_harness_project() {
  local dir="$1"
  mkdir -p "$dir/docs/evidence"
  echo "# Fake" > "$dir/AGENTS.md"
  echo "PASS test" > "$dir/docs/evidence/test.log"
}

@test "register-existing finds projects with AGENTS.md + docs/evidence/" {
  make_harness_project "$ROOT/projA"
  make_harness_project "$ROOT/projB"
  run bash "$SCRIPT" --dry-run "$ROOT"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "projA" ]]
  [[ "$output" =~ "projB" ]]
}

@test "register-existing skips projects without .harness-state.json (none registered by dry-run)" {
  make_harness_project "$ROOT/projA"
  run bash "$SCRIPT" --dry-run "$ROOT"
  [ "$status" -eq 0 ]
  [ ! -f "$ROOT/projA/.harness-state.json" ]
}

@test "register-existing registers all un-registered projects" {
  make_harness_project "$ROOT/projA"
  make_harness_project "$ROOT/projB"
  run bash "$SCRIPT" --quiet "$ROOT"
  [ "$status" -eq 0 ]
  [ -f "$ROOT/projA/.harness-state.json" ]
  [ -f "$ROOT/projB/.harness-state.json" ]
  python3 -c "
import json
for p in ['$ROOT/projA', '$ROOT/projB']:
    d = json.load(open(p + '/.harness-state.json'))
    assert d['version'] == '1.8.0', d
"
}

@test "register-existing skips already-registered projects" {
  make_harness_project "$ROOT/projA"
  bash "$SYNC" --project-dir "$ROOT/projA" --auto >/dev/null 2>&1
  md5_before=$(md5sum "$ROOT/projA/.harness-state.json" | cut -c1-32)
  bash "$SCRIPT" --quiet "$ROOT" 2>&1
  md5_after=$(md5sum "$ROOT/projA/.harness-state.json" | cut -c1-32)
  # State file should not have been touched again (only timestamp changes; md5 may differ)
  [ "$(jq -r .version "$ROOT/projA/.harness-state.json")" = "1.8.0" ]
}

@test "register-existing ignores dirs without AGENTS.md" {
  mkdir -p "$ROOT/not-a-harness-project/docs/evidence"
  echo "no" > "$ROOT/not-a-harness-project/docs/evidence/foo.log"
  run bash "$SCRIPT" --dry-run "$ROOT"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "not-a-harness-project" ]]
}

@test "register-existing ignores dirs without docs/evidence/" {
  mkdir -p "$ROOT/missing-evidence"
  echo "x" > "$ROOT/missing-evidence/AGENTS.md"
  run bash "$SCRIPT" --dry-run "$ROOT"
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "missing-evidence" ]]
}

@test "register-existing --dry-run does NOT create state files" {
  make_harness_project "$ROOT/projA"
  bash "$SCRIPT" --dry-run "$ROOT" >/dev/null 2>&1
  [ ! -f "$ROOT/projA/.harness-state.json" ]
}

@test "register-existing fails loudly if sync-project fails" {
  make_harness_project "$ROOT/projA"
  SYNC_BAK="$SYNC.bak"
  mv "$SYNC" "$SYNC_BAK"
  run bash "$SCRIPT" --quiet "$ROOT"
  mv "$SYNC_BAK" "$SYNC"
  [ "$status" -ne 0 ]
}
