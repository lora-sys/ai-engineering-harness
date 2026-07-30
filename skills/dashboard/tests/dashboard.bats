#!/usr/bin/env bash
# tests/dashboard.bats
#
# Tests for the dashboard skill:
# 1. Bootstrap creates .dashboard/ with parser.js + dashboard.html
# 2. parser.js starts and serves API endpoints
# 3. Dashboard HTML contains expected elements
# 4. serve.sh works
# 5. scaffold-dashboard.sh works

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/skills/dashboard/templates"
SCAFFOLD_SCRIPT="$REPO_ROOT/skills/dashboard/scripts/scaffold-dashboard.sh"
SERVE_SCRIPT="$REPO_ROOT/skills/dashboard/scripts/serve.sh"

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
}

teardown() {
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
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/health
  [ "$status" -eq 0 ]
  [[ "$output" =~ "overall" ]]
  [[ "$output" =~ "evidence" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves dashboard.html on /" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/
  [ "$status" -eq 0 ]
  [[ "$output" =~ "<!DOCTYPE html>" ]]
  [[ "$output" =~ "Dashboard" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/project-status" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/project-status
  [ "$status" -eq 0 ]
  [[ "$output" =~ "now" ]]
  [[ "$output" =~ "backlog" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/evidence" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/evidence
  [ "$status" -eq 0 ]
  [[ "$output" =~ "packs" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/evidence/1 with detail" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/evidence/1
  [ "$status" -eq 0 ]
  [[ "$output" =~ "verification" ]]
  [[ "$output" =~ "changeSummary" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/kanban" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/kanban
  [ "$status" -eq 0 ]
  [[ "$output" =~ "now" ]]
  [[ "$output" =~ "backlog" ]]
  [[ "$output" =~ "blocked" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/takeover-audit" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/takeover-audit
  [ "$status" -eq 0 ]
  [[ "$output" =~ "chaosScore" ]]
  [[ "$output" =~ "grade" ]]
  [[ "$output" =~ "issues" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/memory" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/memory
  [ "$status" -eq 0 ]
  [[ "$output" =~ "files" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js serves /api/quick-scan" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  [ "$status" -eq 0 ]
  [[ "$output" =~ "chaosScore" ]]
  [[ "$output" =~ "grade" ]]
  [[ "$output" =~ "issues" ]]
  [[ "$output" =~ "filesScanned" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects hardcoded secrets" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  [[ "$output" =~ "security" ]]
  [[ "$output" =~ "hardcoded secret" ]]

  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
}

@test "parser.js quick-scan detects missing error handling" {
  bash "$SCAFFOLD_SCRIPT" "$PROJECT_DIR" > /dev/null 2>&1
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  [[ "$output" =~ "reliability" ]]
  [[ "$output" =~ "catch" ]]

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
  cd "$CLEAN_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/quick-scan
  [[ "$output" =~ "A" ]]

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
  cd "$PROJECT_DIR/.dashboard" && node parser.js &
  local PID=$!
  sleep 2

  run curl -s http://localhost:4321/api/evidence/999
  [ "$status" -eq 0 ]
  [[ "$output" =~ "not found" ]]

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
