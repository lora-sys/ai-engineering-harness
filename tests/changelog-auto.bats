#!/usr/bin/env bats
# tests/changelog-auto.bats
#
# Tests for scripts/changelog-auto.sh.
# This is the script that the CONTRIBUTING.md blesses for changelog generation.
# It MUST NOT clobber an existing versioned CHANGELOG.md.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"
  git init -q .
  mkdir -p scripts
  cp "$REPO_ROOT/scripts/changelog-auto.sh" scripts/changelog-auto.sh
  chmod +x scripts/changelog-auto.sh
}

teardown() {
  cd /
  rm -rf "$TMPDIR"
}

@test "changelog-auto --help exits 0" {
  run bash scripts/changelog-auto.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "changelog-auto refuses to clobber existing versioned CHANGELOG" {
  cat > CHANGELOG.md <<'MD'
# Changelog

## [1.0.0] - 2026-07-12

Existing content.
MD
  # The script should refuse to clobber. If it does, that's the bug we
  # caught in v1.0.3 with the lower-level changelog.sh.
  run bash scripts/changelog-auto.sh --write
  # We don't care which exit code — we care that CHANGELOG.md was preserved.
  if [[ ! -f CHANGELOG.md ]]; then
    echo "CHANGELOG.md was deleted!" >&2
    return 1
  fi
  if ! grep -q "## \[1.0.0\]" CHANGELOG.md; then
    echo "Existing version entry was clobbered!" >&2
    return 1
  fi
}
