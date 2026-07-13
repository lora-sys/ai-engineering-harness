#!/usr/bin/env bats
# tests/check-templates.bats
#
# Tests for scripts/check-templates.sh.
# Exercises: required-heading assertions, missing-heading detection,
# awk-based start-of-line matching (regression for the --quietly-broken
# grep regex we used in v1.0.3).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/check-templates.sh"
}

@test "check-templates --help exits 0" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "check-templates on real repo passes" {
  cd "$REPO_ROOT"
  run bash "$SCRIPT" --strict
  [ "$status" -eq 0 ]
  [[ "$output" =~ "OK" ]]
}

@test "check-templates detects missing ## CI in pr-description" {
  # Make a temporary harness copy with the heading stripped.
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  # Remove the "## CI" section block (the heading + following bullets + blank).
  python3 -c "
import re
text = open('templates/pr-description.md').read()
text = re.sub(r'^## CI\n(?:^- .+\n)+\n', '', text, count=1, flags=re.MULTILINE)
open('templates/pr-description.md', 'w').write(text)
"
  run bash scripts/check-templates.sh --strict
  [ "$status" -ne 0 ]
  [[ "$output" =~ "## CI" ]]
  rm -rf "$TMPDIR"
}

@test "check-templates does NOT false-positive on inline heading reference" {
  # The body of pr-description.md has a line like '(see `## CI` above)' —
  # that should NOT count as a real heading.
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  python3 -c "
text = open('templates/pr-description.md').read()
# Remove only the real heading, keep the inline reference.
text = text.replace('## CI\n- Workflow run: <github actions URL or run-id>\n- Commit SHA: <full sha of the head of the PR branch>\n- Required checks (each must be green): lint · unit · integration · build · security-scan\n- Captured log: docs/evidence/<id>/ci-log.txt\n- If any check is red: stay in workflows/04-ci-recovery.md — this PR is BLOCKED.\n\n', '')
open('templates/pr-description.md', 'w').write(text)
"
  run bash scripts/check-templates.sh --strict
  [ "$status" -ne 0 ]
  [[ "$output" =~ "## CI" ]]
  rm -rf "$TMPDIR"
}
