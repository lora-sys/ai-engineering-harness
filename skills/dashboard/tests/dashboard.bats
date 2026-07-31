#!/usr/bin/env bash
# tests/dashboard.bats
#
# Tests for the dashboard skill:
# 1. Bootstrap creates .dashboard/ with parser.js + dashboard.html
# 2. parser.js starts and serves API endpoints
# 3. Dashboard HTML contains expected elements
# 4. serve.sh works
# 5. scaffold-dashboard.sh works
# 6. quick-scan detectors fire on planted findings and stay quiet on clean code
# 7. scan-to-issues.sh groups findings into Issues (never against a real repo)
#
# NOTE on assertions: a failing `[[ ... ]]` aborts the test body, so anything
# after it never runs -- which means a long run of bare `[[ ]]` lines tells a
# reader nothing about which conditions actually carry weight, and a test that
# only checks `[ "$status" -ne 0 ]` passes on a non-zero exit for ANY reason,
# including an unrelated crash. Prefer the assert_* helpers below: they print
# what was actually seen, which turns a bare "assertion failed" into a diagnosis.
#
# Verified, since an earlier version of this comment claimed otherwise: mid-body
# `[[ ]]` failures are NOT swallowed by any version this repo runs. A
# guaranteed-false mid-body `[[ ]]` fails the test under bash 3.2.57 and 5.3.15,
# with bats 1.10.0 and 1.13.0 -- all four combinations. If you are chasing a
# test that passes locally but fails in CI, check first that the local run
# actually included this file; that was the real cause last time.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/templates"
SCAFFOLD_SCRIPT="$REPO_ROOT/scripts/scaffold-dashboard.sh"
SERVE_SCRIPT="$REPO_ROOT/scripts/serve.sh"
S2I_SCRIPT="$REPO_ROOT/scripts/scan-to-issues.sh"

# Assertion helpers. A bare `[[ ... ]]` says only "assertion failed"; these print
# the value that was actually seen, which is the difference between a failure you
# can diagnose and one you have to re-run by hand. Taking the haystack as an
# argument rather than eval'ing a string keeps arbitrary scan output from being
# re-parsed as shell.
assert_has() {   # assert_has <haystack> <substring>
  case "$1" in
    *"$2"*) return 0 ;;
    *) echo "assertion failed: expected to find '$2'" >&2; exit 1 ;;
  esac
}

assert_lacks() { # assert_lacks <haystack> <substring>
  case "$1" in
    *"$2"*) echo "assertion failed: did not expect '$2'" >&2; exit 1 ;;
    *) return 0 ;;
  esac
}

assert_eq() {    # assert_eq <actual> <expected> [label]
  [[ "$1" == "$2" ]] && return 0
  echo "assertion failed: ${3:-value} was '$1', expected '$2'" >&2
  exit 1
}

setup() {
  TMPDIR="$(mktemp -d)"
  PROJECT_DIR="$TMPDIR/test-project"
  mkdir -p "$PROJECT_DIR/docs/evidence/1/screenshots"
  mkdir -p "$PROJECT_DIR/docs/evidence/1/test-results"
  mkdir -p "$PROJECT_DIR/memory"
  cat > "$PROJECT_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status

_Last updated: 2026-07-29 by @coordinator_

## Now (in progress)
- Issue #12 — dashboard skill — Owner: @frontend — Phase: Implementing — branch: feature/12-dashboard

## Backlog
- Issue #13 — redesign docs — size: M — class: M

## Blocked (Waiting for Approval / external)
- Issue #14 — Payment integration — Blocked on: Stripe API key

## Recently Merged
- Issue #11 — Fix login bug — PR #15 — Evidence: docs/evidence/11/

## Open Reviewer Threads
- PR #15 — Bug Hunter: ✅ / Behavior: ✅ / Architecture: ⚠️

## Phase
- Phase 1 — Core shell — Done
- Phase 2 — MVP features — In Progress

## Health
- Tests: green
- CI: green
- Docs: fresh
- Memory: ok

## Risks
- Payment provider rate limits
EOF

  # Create a sample evidence pack
  cat > "$PROJECT_DIR/docs/evidence/1/verification.md" << 'EOF'
# Verification — Issue #1

| # | Description | Method | Result | Evidence |
|---|-------------|--------|--------|----------|
| 1 | Login redirects to dashboard | e2e | PASS | test-results/e2e.json |
| 2 | User can logout | e2e | PASS | test-results/e2e.json |
EOF

  cat > "$PROJECT_DIR/docs/evidence/1/change-summary.md" << 'EOF'
# Change Summary — Issue #1

## What
Fixed redirect after successful login

## Why
Users were stuck on login page after authentication

## How Verified
Playwright e2e test + manual QA
EOF

  echo '{"passed":3,"failed":0}' > "$PROJECT_DIR/docs/evidence/1/test-results/e2e.json"
  echo '{"passed":12,"failed":0}' > "$PROJECT_DIR/docs/evidence/1/test-results/unit.json"
  cp "$REPO_ROOT/skills/dashboard/templates/dashboard.html" "$PROJECT_DIR/docs/evidence/1/screenshots/desktop.png" 2>/dev/null || touch "$PROJECT_DIR/docs/evidence/1/screenshots/desktop.png"

  cat > "$PROJECT_DIR/memory/lessons-2026-07-12.md" << 'EOF'
# Lessons Learned from Auth Migration

Rate limiting on the auth endpoint caused 503s during peak hours.
EOF

  # Source files for quick-scan testing (Issue #8)
  mkdir -p "$PROJECT_DIR/src"
  cat > "$PROJECT_DIR/src/config.ts" << 'EOF'
// API configuration
const API_KEY = "sk-abc123def456ghi789jkl"
const DB_PASSWORD = "super_secret_123"
export default { apiKey: API_KEY, dbPassword: DB_PASSWORD }
EOF

  cat > "$PROJECT_DIR/src/api.ts" << 'EOF'
async function fetchData(url) {
  try {
    const res = await fetch(url)
    const data = await res.json()
    return data
  // Missing catch — intentional for quick-scan testing
  }
}
EOF

  cat > "$PROJECT_DIR/src/utils.ts" << 'EOF'
// Helper functions
function foo(x) { return x * 2 }
function bar(y) { return y + 1 }

// TODO fix this later
// TODO: add validation
// FIXME: edge case

// Commented out old code
// function oldMethod() {
//   return 42
// }
// const OLD_VAR = "legacy"

export { foo, bar }
EOF

  # Intent-mismatch fixtures (Issue #9): code that contradicts its own doc
  # comment. One case per rule, so a regression names which rule broke.
  cat > "$PROJECT_DIR/src/intent.ts" << 'EOF'
/**
 * Adds the given amount to the balance.
 */
function subtractBalance(balance, amount) {
  return balance - amount
}

/**
 * Formats a label.
 * @param {string} prefix - leading text
 * @param {string} suffix - trailing text
 */
function formatLabel(prefix) {
  console.log(prefix)
}

/**
 * Computes the checksum.
 * @returns {number} the checksum
 */
function computeChecksum(bytes) {
  for (const b of bytes) {
    console.log(b)
  }
}
EOF
}

teardown() {
  # Safety net: if a test aborted before its `kill $PID`, a parser server would
  # still hold the inherited fds and bats would never exit (it waits on them).
  # Servers are spawned as `( cd ... && exec node ... ) &` so $! is node's real
  # PID -- without `exec`, $! is the subshell's and the kill misses. See #13.
  pkill -f 'node parser\.js' 2>/dev/null || true
  rm -rf "$TMPDIR"
}

@test "scaffold-dashboard.sh creates .dashboard/ with parser.js and dashboard.html" {
  run bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]
  [ -f "$PROJECT_DIR/.dashboard/parser.js" ]
  [ -f "$PROJECT_DIR/.dashboard/dashboard.html" ]
}

@test "scaffold-dashboard.sh creates scripts/dashboard.sh" {
  run bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]
  [ -f "$PROJECT_DIR/scripts/dashboard.sh" ]
  [ -x "$PROJECT_DIR/scripts/dashboard.sh" ]
}

@test "scaffold-dashboard.sh adds .dashboard/ to .gitignore" {
  run bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]
  run grep -qE '^\.dashboard/?$' "$PROJECT_DIR/.gitignore"
  [ "$status" -eq 0 ]
}

@test "scaffold-dashboard.sh is idempotent (re-run doesn't fail)" {
  run bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]
  run bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR"
  [ "$status" -eq 0 ]
  [ -f "$PROJECT_DIR/.dashboard/parser.js" ]
}

@test "parser.js starts and serves /api/health" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/health
  [ "$status" -eq 0 ]
  assert_has "$output" "overall"
  assert_has "$output" "evidence"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves dashboard.html on /" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/
  [ "$status" -eq 0 ]
  assert_has "$output" "<!DOCTYPE html>"
  assert_has "$output" "Dashboard"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/project-status" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/project-status
  [ "$status" -eq 0 ]
  assert_has "$output" "now"
  assert_has "$output" "backlog"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/evidence" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/evidence
  [ "$status" -eq 0 ]
  assert_has "$output" "packs"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/evidence/1 with detail" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/evidence/1
  [ "$status" -eq 0 ]
  assert_has "$output" "verification"
  assert_has "$output" "changeSummary"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/kanban" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/kanban
  [ "$status" -eq 0 ]
  assert_has "$output" "now"
  assert_has "$output" "backlog"
  assert_has "$output" "blocked"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/takeover-audit" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/takeover-audit
  [ "$status" -eq 0 ]
  assert_has "$output" "chaosScore"
  assert_has "$output" "grade"
  assert_has "$output" "issues"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/memory" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/memory
  [ "$status" -eq 0 ]
  assert_has "$output" "files"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/quick-scan" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  [ "$status" -eq 0 ]
  assert_has "$output" "chaosScore"
  assert_has "$output" "grade"
  assert_has "$output" "issues"
  assert_has "$output" "filesScanned"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects hardcoded secrets" {
  # The planted secrets live in src/config.ts, and the secret detector
  # deliberately skips config files -- a key in a config file is where a key is
  # supposed to be. So assert on a file the detector does look at, or this test
  # is asserting the opposite of the design.
  cat > "$PROJECT_DIR/src/handler.ts" << 'EOF'
export function callUpstream() {
  const token = "ghp_A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7r8"
  return fetch("https://api.example.com", { headers: { Authorization: token } })
}
EOF
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  # The fixture plants keys in src/config.ts. That file used to be exempt from
  # secret scanning entirely, so these assertions were unsatisfiable from the day
  # they were written -- detector and test contradicted each other in the same
  # commit (e9f9c3a). assert_has reports which string was missing.
  assert_eq "$status" 0 status
  assert_has "$output" "security"
  assert_has "$output" "hardcoded secret"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan does NOT flag env indirection or placeholders" {
  # The other half of the secret detector, and the reason the old code exempted
  # config files at all. `apiKey: process.env.KEY` is the *fix* for a hardcoded
  # secret -- flagging it would punish the correct pattern. Without this test,
  # tightening the detector to catch config files could regress into flagging
  # every env lookup in the repo and nothing would notice.
  mkdir -p "$PROJECT_DIR/src"
  cat > "$PROJECT_DIR/src/safe-config.ts" << 'EOF'
const API_KEY = process.env.API_KEY
const DB_PASSWORD = process.env.DB_PASSWORD
export const placeholder = { apiKey: "YOUR_API_KEY_HERE", token: "changeme" }
// const password = "Password used to generate key"
EOF
  rm -f "$PROJECT_DIR/src/config.ts"

  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_eq "$status" 0 status
  assert_lacks "$output" "hardcoded secret"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects missing error handling" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_has "$output" "reliability"
  assert_has "$output" "catch"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan returns A grade for clean repo" {
  # Create a project with no source files
  CLEAN_DIR="$TMPDIR/clean-project"
  mkdir -p "$CLEAN_DIR/docs/evidence/1/screenshots"
  cat > "$CLEAN_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status

## Now (in progress)
- Issue #1 — test

## Health
- Tests: green
- CI: green
- Docs: fresh
- Memory: ok
EOF

  bash "$SCAFFOLD_SCRIPT" "$CLEAN_DIR" > /dev/null 2>&1
  ( cd "$CLEAN_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_has "$output" "A"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects intent mismatch: opposite verb in doc comment" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_eq "$status" 0 status
  assert_has "$output" "intent-mismatch"
  # Doc says "Adds" on a function named subtractBalance
  assert_has "$output" "subtractBalance"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects stale @param not in signature" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_eq "$status" 0 status
  # formatLabel documents `suffix` but only takes `prefix`
  assert_has "$output" "suffix"
  assert_has "$output" "formatLabel"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects @returns on a function that never returns" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_eq "$status" 0 status
  assert_has "$output" "computeChecksum"
  assert_has "$output" "never returns"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan does not flag a doc comment that matches its code" {
  # Guards the false-positive path: a correct docblock must stay silent, or the
  # detector is just noise on every well-documented file.
  MATCH_DIR="$TMPDIR/match-project"
  mkdir -p "$MATCH_DIR/src"
  cat > "$MATCH_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status

## Health
- Tests: green
EOF
  cat > "$MATCH_DIR/src/good.ts" << 'EOF'
/**
 * Subtracts the given amount from the balance.
 * @param {number} balance - starting balance
 * @param {number} amount - amount to remove
 * @returns {number} the new balance
 */
function subtractBalance(balance, amount) {
  return balance - amount
}
EOF

  bash "$SCAFFOLD_SCRIPT" "$MATCH_DIR" > /dev/null 2>&1
  ( cd "$MATCH_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  assert_eq "$status" 0 status
  assert_lacks "$output" "intent-mismatch"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "dashboard.html contains quick-scan button" {
  run grep -c 'quick-scan-btn' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "dashboard.html contains quick-scan result area" {
  run grep -c 'quick-scan-result' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "parser.js returns 404 for non-existent evidence pack" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  ( cd "$PROJECT_DIR/.dashboard" && exec node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/evidence/999
  [ "$status" -eq 0 ]
  assert_has "$output" "not found"

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "dashboard.html contains all 4 view sections" {
  run grep -c 'id="view-dashboard"' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]

  run grep -c 'id="view-evidence"' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]

  run grep -c 'id="view-kanban"' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]

  run grep -c 'id="view-takeover"' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "dashboard.html has screenshot lightbox" {
  run grep -c 'lightbox' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "dashboard.html has code block display" {
  run grep -c 'code-block' "$TEMPLATE_DIR/dashboard.html"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "scaffold-dashboard.sh without args uses current directory" {
  cd "$PROJECT_DIR"
  run bash "$SCAFFOLD_SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$PROJECT_DIR/.dashboard/parser.js" ]
}

@test "scaffold-dashboard.sh errors on non-project directory" {
  EMPTY_DIR="$TMPDIR/empty"
  mkdir -p "$EMPTY_DIR"
  run bash "$SCAFFOLD_SCRIPT" "$EMPTY_DIR"
  [ "$status" -ne 0 ]
}

# ─── scan-to-issues.sh ────────────────────────────────────────────────────────
# These use a scratch DASHBOARD_PORT so they can't collide with the :4321 tests
# above, and never pass --create without a stub `gh` on PATH -- a test that
# files real Issues into whatever repo the runner happens to be in is a bug.

@test "scaffold-dashboard.sh installs scan-to-issues.sh" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  [ -f "$PROJECT_DIR/scripts/scan-to-issues.sh" ]
  [ -x "$PROJECT_DIR/scripts/scan-to-issues.sh" ]
}

@test "scan-to-issues.sh --help does not leak shell directives" {
  run bash "$S2I_SCRIPT" --help
  assert_eq "$status" 0 status
  assert_has "$output" "Usage"
  # The help text is sliced out of this file's own header comment, so an
  # off-by-one in the sed range dumps `set -uo pipefail` at the user.
  assert_lacks "$output" "pipefail"
}

@test "scan-to-issues.sh rejects an unknown flag and a bad severity" {
  run bash "$S2I_SCRIPT" --bogus
  [[ "$status" -ne 0 ]] || { echo "expected non-zero exit" >&2; exit 1; }

  run bash "$S2I_SCRIPT" --min-severity sideways
  [[ "$status" -ne 0 ]] || { echo "expected non-zero exit" >&2; exit 1; }
}

@test "scan-to-issues.sh errors when the project has no dashboard" {
  NODASH_DIR="$TMPDIR/nodash"
  mkdir -p "$NODASH_DIR"
  cat > "$NODASH_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status
EOF
  run bash "$S2I_SCRIPT" --project "$NODASH_DIR"
  [[ "$status" -ne 0 ]] || { echo "expected non-zero exit" >&2; exit 1; }
  assert_has "$output" "parser.js"
}

@test "scan-to-issues.sh dry run prints drafts and files nothing" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1

  # No server running: the script has to start its own scratch one.
  DASHBOARD_PORT=7431 run bash "$S2I_SCRIPT" --project "$PROJECT_DIR"
  assert_eq "$status" 0 status
  assert_has "$output" "DRY RUN"
  assert_has "$output" "Acceptance criteria"
  assert_has "$output" "Issue(s) would be filed"
  # One Issue per category, not one per finding: utils.ts alone plants several
  # code-hygiene findings and they must collapse into a single draft.
  assert_has "$output" "vibe-signs: code-hygiene"
  assert_has "$output" "vibe-signs: reliability"
  run bash -c "printf '%s\n' \"\$1\" | grep -c 'vibe-signs: code-hygiene'" _ "$output"
  assert_eq "$output" 1 "code-hygiene draft count"
}

@test "scan-to-issues.sh --min-severity medium drops the LOW findings" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1

  DASHBOARD_PORT=7432 run bash "$S2I_SCRIPT" --project "$PROJECT_DIR" --min-severity medium
  assert_eq "$status" 0 status
  # reliability (try-without-catch) is MEDIUM so it survives; code-hygiene
  # (TODOs, commented-out code) is LOW so it must be filtered out entirely.
  assert_has "$output" "vibe-signs: reliability"
  assert_lacks "$output" "vibe-signs: code-hygiene"
}

@test "scan-to-issues.sh reports nothing to file for a clean project" {
  CLEAN2_DIR="$TMPDIR/clean2"
  mkdir -p "$CLEAN2_DIR"
  cat > "$CLEAN2_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status

## Health
- Tests: green
EOF
  bash "$SCAFFOLD_SCRIPT" "$CLEAN2_DIR" > /dev/null 2>&1

  DASHBOARD_PORT=7433 run bash "$S2I_SCRIPT" --project "$CLEAN2_DIR"
  assert_eq "$status" 0 status
  assert_has "$output" "Nothing to file"
}

@test "scan-to-issues.sh leaves no scratch server behind" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1

  DASHBOARD_PORT=7434 bash "$S2I_SCRIPT" --project "$PROJECT_DIR" >/dev/null 2>&1
  sleep 1
  # Scratch port is DASHBOARD_PORT + 1000. A survivor here answers a *later*
  # run with the wrong project's findings, so this is a correctness test.
  run bash -c 'lsof -tiTCP:8434 -sTCP:LISTEN 2>/dev/null | wc -l | tr -d " "'
  assert_eq "$output" 0 "listeners on scratch port"
}

@test "scan-to-issues.sh ignores a server that is serving another project" {
  # Put a dashboard for PROJECT_DIR (planted secret, several findings) on the
  # port scan-to-issues checks first, then ask about CLEAN3 (no source at all).
  # Accepting that response would file PROJECT_DIR's findings against CLEAN3.
  # Falling back to its own scratch server is fine -- what we assert is *whose*
  # findings came back, and the only correct answer for CLEAN3 is "none".
  CLEAN3_DIR="$TMPDIR/clean3"
  mkdir -p "$CLEAN3_DIR"
  cat > "$CLEAN3_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status
EOF
  bash "$SCAFFOLD_SCRIPT" "$CLEAN3_DIR" > /dev/null 2>&1
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1

  ( cd "$PROJECT_DIR/.dashboard" && exec env PORT=7435 node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  DASHBOARD_PORT=7435 run bash "$S2I_SCRIPT" --project "$CLEAN3_DIR"
  assert_eq "$status" 0 status
  # CLEAN3 has no source files at all, so "nothing to file" is the only correct
  # answer. Any drafted Issue here came from PROJECT_DIR via the port -- which
  # is the wrong-project bug, and would file Issues against the wrong repo.
  assert_has "$output" "Nothing to file"
  assert_lacks "$output" "vibe-signs:"
  assert_lacks "$output" "would be filed"

  # And it must not have killed the other project's server to get there.
  kill -0 $PID
  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "scan-to-issues.sh fails loudly when the scratch port is another project" {
  # Both ports unusable: primary has nothing, scratch is held by a foreign
  # dashboard. Refusing is the only safe answer -- reporting the squatter's
  # findings would file Issues against the wrong repo.
  CLEAN4_DIR="$TMPDIR/clean4"
  mkdir -p "$CLEAN4_DIR"
  cat > "$CLEAN4_DIR/PROJECT_STATUS.md" << 'EOF'
# Project Status
EOF
  bash "$SCAFFOLD_SCRIPT" "$CLEAN4_DIR" > /dev/null 2>&1
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1

  ( cd "$CLEAN4_DIR/.dashboard" && exec env PORT=8437 node parser.js >/dev/null 2>&1 ) &
  local PID=$!
  sleep 2

  DASHBOARD_PORT=7437 run bash "$S2I_SCRIPT" --project "$PROJECT_DIR"
  [[ "$status" -ne 0 ]] || { echo "expected non-zero exit" >&2; exit 1; }
  assert_has "$output" "could not get a Quick Scan"
  assert_has "$output" "DASHBOARD_PORT"

  kill -0 $PID
  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "scan-to-issues.sh --create files one Issue per category and dedupes" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1

  # Stub gh: records what it was asked to create, reports one title as already
  # open so the dedupe path is exercised too.
  STUB_BIN="$TMPDIR/stubbin"
  mkdir -p "$STUB_BIN"
  cat > "$STUB_BIN/gh" << 'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
  "issue list") echo "vibe-signs: security — 2 findings" ; exit 0 ;;
  "issue create")
    for a in "$@"; do
      [[ "$PREV" == "--title" ]] && echo "$a" >> "$GH_STUB_LOG"
      PREV="$a"
    done
    exit 0 ;;
esac
exit 0
EOF
  chmod +x "$STUB_BIN/gh"
  export GH_STUB_LOG="$TMPDIR/created.txt"
  : > "$GH_STUB_LOG"

  DASHBOARD_PORT=7436 PATH="$STUB_BIN:$PATH" run bash "$S2I_SCRIPT" --project "$PROJECT_DIR" --create
  assert_eq "$status" 0 status
  assert_has "$output" "filed"

  # Something got filed, and no title was filed twice.
  run bash -c "wc -l < '$GH_STUB_LOG' | tr -d ' '"
  [[ "$output" -gt 0 ]] || { echo "nothing was filed" >&2; exit 1; }
  run bash -c "sort '$GH_STUB_LOG' | uniq -d | wc -l | tr -d ' '"
  assert_eq "$output" 0 "duplicate titles filed"
}
