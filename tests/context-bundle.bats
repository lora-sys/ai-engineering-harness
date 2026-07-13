#!/usr/bin/env bats
# tests/context-bundle.bats
#
# Tests for scripts/context-bundle.sh.
# Exercises: bundle structure, parallel mode, --commits, --out, --no-parallel.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMPOUT="$(mktemp -d)"
  BUNDLE="$TMPOUT/bundle.md"
  export PATH="$HOME/.local/bin:$PATH"
}

teardown() {
  rm -rf "$TMPOUT"
}

@test "context-bundle --help exits 0" {
  run bash "$REPO_ROOT/scripts/context-bundle.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "context-bundle writes a valid markdown file" {
  run bash "$REPO_ROOT/scripts/context-bundle.sh" --out "$BUNDLE" --quiet
  [ "$status" -eq 0 ]
  [ -f "$BUNDLE" ]
  # Bundle must have all 8 expected sections.
  for section in "Repo identity" "Recent commits" "Working-tree changes" "Top-level layout" "Open issues" "Key harness files" "Memory notes" "Harness roster"; do
    grep -q "^## $section" "$BUNDLE" || { echo "missing section: $section"; return 1; }
  done
}

@test "context-bundle parallel and sequential produce equivalent output" {
  bash "$REPO_ROOT/scripts/context-bundle.sh" --out "$TMPOUT/par.md" --quiet
  bash "$REPO_ROOT/scripts/context-bundle.sh" --out "$TMPOUT/seq.md" --quiet --no-parallel
  # Diff ignores the timestamp line ("_Generated 2026-...")
  diff <(grep -v '^_Generated' "$TMPOUT/par.md") <(grep -v '^_Generated' "$TMPOUT/seq.md")
}

@test "context-bundle --commits N controls depth" {
  bash "$REPO_ROOT/scripts/context-bundle.sh" --out "$BUNDLE" --commits 5 --quiet
  # Count "## Recent commits (last N)" header
  grep -q "^## Recent commits (last 5)" "$BUNDLE"
  # And the actual commits shouldn't exceed N
  commits=$(sed -n '/^## Recent commits/,/^## /p' "$BUNDLE" | grep -cE '^[a-f0-9]{7,40} ')
  [ "$commits" -le 5 ]
}

@test "context-bundle refuses bad --commits" {
  run bash "$REPO_ROOT/scripts/context-bundle.sh" --out "$BUNDLE" --commits abc
  [ "$status" -ne 0 ]
}
