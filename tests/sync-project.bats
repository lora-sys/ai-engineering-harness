#!/usr/bin/env bats
# tests/sync-project.bats
#
# Tests for scripts/sync-project.sh.
# Each test sets up a fake harness project in a tmpdir and runs sync against it.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/sync-project.sh"
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"
  mkdir -p docs memory
  echo "# Test project" > AGENTS.md
  echo "User content that should be preserved." >> AGENTS.md
}

teardown() {
  cd /
  rm -rf "$TMPDIR"
}

fake_project_with_evidence() {
  mkdir -p docs/evidence/42/test-results
  echo "PASS test_foo" > docs/evidence/42/test-results/unit.log
  cat > docs/evidence/42/implementation-report.md <<'MD'
# Implementation report for #42

branch: feature/42
agent: backend
MD
}

@test "sync-project --help exits 0" {
  run bash "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "sync-project refuses directory with no AGENTS.md" {
  rm AGENTS.md
  run bash "$SCRIPT" --project-dir "$TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "AGENTS.md" ]]
}

@test "sync-project refuses directory with no docs/" {
  rm -rf docs
  run bash "$SCRIPT" --project-dir "$TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "bootstrap" ]]
}

@test "sync-project dry-run does NOT modify project" {
  fake_project_with_evidence
  run bash "$SCRIPT" --project-dir "$TMPDIR"
  [ "$status" -eq 0 ]
  [ ! -f .harness-state.json ]
  [ ! -f docs/evidence/42/compact-report.json ]
  [[ "$output" =~ "dry-run" ]]
}

@test "sync-project --apply writes .harness-state.json" {
  run bash "$SCRIPT" --project-dir "$TMPDIR" --apply
  [ "$status" -eq 0 ]
  [ -f .harness-state.json ]
  harness_v=$(python3 -c "import json; print(json.load(open('$REPO_ROOT/meta.json'))['version'])")
  python3 -c "
import json
d = json.load(open('.harness-state.json'))
assert d['last_synced_to'] == '$harness_v', d['last_synced_to']
"
}

@test "sync-project --apply creates GitHub templates" {
  run bash "$SCRIPT" --project-dir "$TMPDIR" --apply
  [ "$status" -eq 0 ]
  [ -d .github/ISSUE_TEMPLATE ]
  [ -f .github/PULL_REQUEST_TEMPLATE.md ]
  [ -f .github/ISSUE_TEMPLATE/issue.md ]
}

@test "sync-project --apply back-fills compact-report.json" {
  fake_project_with_evidence
  run bash "$SCRIPT" --project-dir "$TMPDIR" --apply
  [ "$status" -eq 0 ]
  [ -f docs/evidence/42/compact-report.json ]
  python3 -c "
import json
d = json.load(open('docs/evidence/42/compact-report.json'))
assert d['branch'] == 'feature/42'
assert d['agent'] == 'backend'
"
}

@test "sync-project does NOT overwrite existing compact-report.json" {
  fake_project_with_evidence
  cat > docs/evidence/42/compact-report.json <<'JSON'
{"marker": "do-not-overwrite"}
JSON
  run bash "$SCRIPT" --project-dir "$TMPDIR" --apply
  [ "$status" -eq 0 ]
  python3 -c "
import json
d = json.load(open('docs/evidence/42/compact-report.json'))
assert d.get('marker') == 'do-not-overwrite', 'compact-report.json was overwritten'
"
}

@test "sync-project AGENTS.md fenced-block patch preserves user content" {
  fake_project_with_evidence
  cat > AGENTS.md <<'MD'
# My project

## User heading
This is user-written content.

<!-- HARNESS:START user-section -->
old user harness content
<!-- HARNESS:END user-section -->

## Another user section
More user content here.
MD
  run bash "$SCRIPT" --project-dir "$TMPDIR" --apply
  [ "$status" -eq 0 ]
  # User content outside fenced blocks is preserved.
  grep -q "This is user-written content" AGENTS.md
  grep -q "More user content here" AGENTS.md
  grep -q "Another user section" AGENTS.md
  # Fenced block was updated.
  grep -q "harness-capabilities" AGENTS.md
}

@test "sync-project is idempotent (running twice produces same state)" {
  fake_project_with_evidence
  bash "$SCRIPT" --project-dir "$TMPDIR" --apply >/dev/null 2>&1
  # Compare everything EXCEPT last_synced_at, which is supposed to move on every
  # sync -- that is what it records. Comparing the whole file made this test a
  # coin flip: `date -Iseconds` is second-resolution, so it passed only when both
  # runs landed inside the same second (measured: 8 of 12 straddled a boundary
  # and failed). bootstrapped_at is in scope here -- it must be *preserved*.
  state1=$(python3 -c 'import json,sys; d=json.load(open(".harness-state.json")); d.pop("last_synced_at",None); print(json.dumps(d,sort_keys=True))')
  agents1=$(awk "/HARNESS:START harness-capabilities/{p=1;next} p&&/HARNESS:END/{exit} p" AGENTS.md | md5sum | cut -c1-32)
  # Run again
  bash "$SCRIPT" --project-dir "$TMPDIR" --apply >/dev/null 2>&1
  state2=$(python3 -c 'import json,sys; d=json.load(open(".harness-state.json")); d.pop("last_synced_at",None); print(json.dumps(d,sort_keys=True))')
  agents2=$(awk "/HARNESS:START harness-capabilities/{p=1;next} p&&/HARNESS:END/{exit} p" AGENTS.md | md5sum | cut -c1-32)
  [ "$state1" = "$state2" ] || { echo "state drifted: $state1 != $state2" >&2; false; }
  [ "$agents1" = "$agents2" ] || { echo "AGENTS.md block drifted" >&2; false; }
}

@test "sync-project preserves bootstrapped_at but advances last_synced_at" {
  # The other half of idempotency, and the reason last_synced_at is excluded
  # from the comparison above: it is *meant* to move. Excluding a field without
  # asserting its behavior somewhere would let a bug that stops updating it --
  # or one that resets bootstrapped_at on every sync -- pass unnoticed.
  fake_project_with_evidence
  bash "$SCRIPT" --project-dir "$TMPDIR" --apply >/dev/null 2>&1
  read -r boot1 sync1 <<<"$(python3 -c 'import json; d=json.load(open(".harness-state.json")); print(d["bootstrapped_at"], d["last_synced_at"])')"

  # Force a distinct second so the comparison is meaningful either way.
  sleep 1.1
  bash "$SCRIPT" --project-dir "$TMPDIR" --apply >/dev/null 2>&1
  read -r boot2 sync2 <<<"$(python3 -c 'import json; d=json.load(open(".harness-state.json")); print(d["bootstrapped_at"], d["last_synced_at"])')"

  [ "$boot1" = "$boot2" ] || { echo "bootstrapped_at was overwritten: $boot1 -> $boot2" >&2; false; }
  [ "$sync1" != "$sync2" ] || { echo "last_synced_at did not advance: $sync1" >&2; false; }
}

@test "sync-project --status reports drift when out of date" {
  cat > .harness-state.json <<'JSON'
{"version": "1.0.0", "bootstrapped_at": "2026-07-01", "last_synced_at": "2026-07-01", "last_synced_to": "1.0.0", "project_root": "/tmp/x"}
JSON
  run bash "$SCRIPT" --project-dir "$TMPDIR" --status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Drift" ]]
}

@test "sync-project --status reports in-sync when current" {
  harness_v=$(python3 -c "import json; print(json.load(open('$REPO_ROOT/meta.json'))['version'])")
  cat > .harness-state.json <<JSON
{"version": "$harness_v", "bootstrapped_at": "2026-07-13", "last_synced_at": "2026-07-13", "last_synced_to": "$harness_v", "project_root": "$TMPDIR"}
JSON
  run bash "$SCRIPT" --project-dir "$TMPDIR" --status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "in sync" ]]
}
