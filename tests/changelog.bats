#!/usr/bin/env bats
# tests/changelog.bats
#
# Tests for scripts/changelog.sh.
# The big regression we caught in v1.0.3: this script overwrites an existing
# versioned CHANGELOG.md. The guard added in v1.0.3 must refuse.
#
# These tests copy the script into a tmpdir and run it from there, so the
# script's SCRIPT_DIR-based cd lands in the tmpdir, not in the harness repo.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"
  git init -q .
  git remote add origin https://example.invalid/test.git 2>/dev/null || true
  mkdir -p "$TMPDIR/scripts"
  cp "$REPO_ROOT/scripts/changelog.sh" "$TMPDIR/scripts/changelog.sh"
  chmod +x "$TMPDIR/scripts/changelog.sh"
  # Make an initial commit so git log has something to work with.
  git -c user.email=test@test -c user.name=test commit -q --allow-empty -m "init"
  cat > CHANGELOG.md <<'MD'
# Changelog

## [1.0.0] - 2026-07-12

Some content.
MD
}

teardown() {
  cd /
  rm -rf "$TMPDIR"
}

@test "changelog refuses to overwrite existing versioned CHANGELOG" {
  run bash "$TMPDIR/scripts/changelog.sh"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "REFUSED" ]]
}

@test "changelog --force overwrites anyway" {
  run bash "$TMPDIR/scripts/changelog.sh" --force
  [ "$status" -eq 0 ]
  [[ "$(cat CHANGELOG.md)" =~ "Unreleased" ]]
}
