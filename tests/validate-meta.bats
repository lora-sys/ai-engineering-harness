#!/usr/bin/env bats
# tests/validate-meta.bats
#
# Tests for scripts/validate-meta.sh.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/validate-meta.sh"
}

@test "validate-meta --help exits 0" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
}

@test "validate-meta on real repo passes --strict" {
  cd "$REPO_ROOT"
  run bash "$SCRIPT" --strict
  [ "$status" -eq 0 ]
}

@test "validate-meta rejects meta.json missing required version" {
  TMPDIR="$(mktemp -d)"
  cat > "$TMPDIR/meta.json" <<'JSON'
{
  "id": "test",
  "name": "Test",
  "description": "Test description that is at least forty characters long to satisfy validator rules.",
  "category": "test",
  "priority": 10,
  "tags": ["test"],
  "install": {"global": "echo"},
  "license": "MIT",
  "repository": "https://github.com/test/test",
  "entry": "SKILL.md"
}
JSON
  # No version field — should error.
  run bash "$SCRIPT" "$TMPDIR/meta.json"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "version" ]]
  rm -rf "$TMPDIR"
}

@test "validate-meta rejects invalid semver in version" {
  TMPDIR="$(mktemp -d)"
  cat > "$TMPDIR/meta.json" <<'JSON'
{
  "id": "test",
  "version": "v1.0.0",
  "name": "Test",
  "description": "Test description that is at least forty characters long to satisfy validator rules.",
  "category": "test",
  "priority": 10,
  "tags": ["test"],
  "install": {"global": "echo"},
  "license": "MIT",
  "repository": "https://github.com/test/test",
  "entry": "SKILL.md"
}
JSON
  run bash "$SCRIPT" "$TMPDIR/meta.json"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not valid semver" ]]
  rm -rf "$TMPDIR"
}

@test "validate-meta family walk finds both skills on real repo" {
  cd "$REPO_ROOT"
  run bash "$SCRIPT"
  [[ "$output" =~ "Summary: 2 passed" ]]
}
