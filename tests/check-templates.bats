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
  # The exit code alone is not enough: it would be non-zero for ANY reason,
  # including an unrelated crash, so the test would pass while proving nothing
  # about the heading rule. The guard pins the failure to `## CI` and prints what
  # was actually emitted when it does not match.
  [ "$status" -ne 0 ]
  [[ "$output" =~ "## CI" ]] || { echo "expected the failure to name '## CI', got: $output" >&2; exit 1; }
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
  # Same reasoning as the previous test: a non-zero exit alone would also be
  # produced by an unrelated crash, so the guard pins the failure to `## CI`.
  [ "$status" -ne 0 ]
  [[ "$output" =~ "## CI" ]] || { echo "expected the failure to name '## CI', got: $output" >&2; exit 1; }
  rm -rf "$TMPDIR"
}

# --- markdown structure checks (Part B) -----------------------------------
# These guard the fence-pairing bug from issue #11: README.md shipped with an
# unfenced shell block and an orphaned ```, inverting fence pairing for 248
# lines. Total fence count stayed even, so parity checks saw nothing.

@test "check-templates detects an unclosed code fence" {
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  printf '# Doc\n\n```bash\necho hi\n' > docs/fence-victim.md
  git add docs/fence-victim.md 2>/dev/null || true
  run bash scripts/check-templates.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "never closed" ]]
  rm -rf "$TMPDIR"
}

@test "check-templates detects a heading trapped inside a bash fence" {
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  printf '# Doc\n\n```bash\necho hi\n\n## Trapped Section\n\nmore text\n```\n' > docs/fence-victim.md
  git add docs/fence-victim.md 2>/dev/null || true
  run bash scripts/check-templates.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "inside a code fence" ]]
  rm -rf "$TMPDIR"
}

@test "check-templates does NOT flag headings inside a markdown fence" {
  # The guardrail against the obvious over-broad version of this rule: templates
  # legitimately quote markdown, and '## Section' inside ```markdown is content.
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  printf '# Doc\n\n```markdown\n## This is quoted markdown\n\n| a | b |\n```\n' > docs/fence-ok.md
  git add docs/fence-ok.md 2>/dev/null || true
  run bash scripts/check-templates.sh --strict
  [ "$status" -eq 0 ]
  rm -rf "$TMPDIR"
}

@test "check-templates warns (not errors) on an image inside a fence" {
  # An image in a fence never renders -- that is how the closed-loop diagram was
  # invisible for months -- but it is not itself a structural break, so it is a
  # warning that only --strict escalates.
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  printf '# Doc\n\n```\n![pic](assets/x.svg)\n```\n' > docs/fence-img.md
  git add docs/fence-img.md 2>/dev/null || true
  run bash scripts/check-templates.sh
  [ "$status" -eq 0 ]
  run bash scripts/check-templates.sh --strict
  [ "$status" -ne 0 ]
  rm -rf "$TMPDIR"
}

# --- count drift (Part C) -------------------------------------------------

@test "check-templates detects a count marker that disagrees with the filesystem" {
  TMPDIR="$(mktemp -d)"
  cp -r "$REPO_ROOT" "$TMPDIR/harness"
  cd "$TMPDIR/harness"
  # Claim one fewer workflow than exists on disk.
  python3 -c "
import re
t = open('README.md').read()
t = re.sub(r'\| 10 <!-- count:workflows -->', '| 9 <!-- count:workflows -->', t, count=1)
open('README.md','w').write(t)
"
  run bash scripts/check-templates.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "count:workflows" ]]
  rm -rf "$TMPDIR"
}
