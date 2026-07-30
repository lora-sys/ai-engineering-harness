# Quick Scan — One-Click Takeover Report

Scans the current project for code quality issues ("vibe signs") without any prior setup and generates a human-readable takeover report.

## When to use

- "I found a repo, what's wrong with it?"
- User says "quick scan" or "$dashboard. Quick Scan."
- First 30 seconds of exploring a new project — want a chaos score without configuring anything
- Before deciding whether to take on a project or pass

## Prerequisites

- The dashboard server is running (`bash scripts/dashboard.sh`)
- Node.js >= 14 (for the parser server)

## Steps

### 1. Ensure the server is running

```bash
cd .dashboard && node parser.js
```

In another terminal, confirm it's up:

```bash
curl -s http://localhost:4321/api/health | head -c 100
```

If you see `overall`, it's running.

### 2. Open the dashboard

Go to `http://localhost:4321` in your browser.

Navigate to **Audit** (🔍) in the sidebar.

### 3. Click "Quick Scan"

On the Takeover Audit page, click the **Quick Scan** button.

The dashboard calls `GET /api/quick-scan` which:

- Scans all source files in `src/`, `lib/`, `app/`, `server/`, `pkg/`, `internal/`, `cmd/` directories
- Runs 9 heuristic detectors:
  1. **Hardcoded secrets** — API keys, tokens, passwords in non-config files (HIGH)
  2. **Missing error handling** — try blocks without catch (MEDIUM)
  3. **Placeholder names** — `foo`, `bar`, `temp`, `xxx` as code identifiers (LOW)
  4. **Commented-out code** — 3+ consecutive comment lines (LOW)
  5. **TODO without links** — markers without issue references (LOW)
  6. **Duplicate blocks** — same 3-line code in multiple places (MEDIUM)
  7. **Missing tests** — source files without test counterparts (MEDIUM)
  8. **Style drift** — mixed tabs and spaces in the same file (MEDIUM)
  9. **Dead code after return** — 5+ unreachable lines after `return`/`throw` (LOW)
- Returns: chaos score + severity-ranked top issues + category breakdown

### 4. Review the report

The dashboard displays:

- **Chaos Score gauge** — 0-100 with letter grade (A/B/C/D/F)
- **Severity breakdown** — bar chart showing critical/high/medium/low counts
- **Top issues table** — up to 20 issues, sorted by severity
- **Files scanned** — how many source files were analyzed

### 5. Export the report (optional)

Click **Export Report** to download `takeover-report.md` to the project root.

The report includes:

```markdown
# Takeover Report: <project-name>

**Chaos Score:** 42/100 (Grade: C)
**Generated:** 2026-07-29
**Files scanned:** 47

## Top Issues

1. **[HIGH] Potential hardcoded secret** — `src/config.ts:12`
2. **[MEDIUM] try block without catch handler** — `src/api.ts:45`
3. **[MEDIUM] 12 source files without corresponding test file(s)** — —
4. **[MEDIUM] Duplicate code block (3 copies in 1 file(s))** — `src/utils.ts:8`
5. **[LOW] Placeholder name used in code** — `src/helpers.ts:23`
... (up to 20 issues)

## Category Breakdown

| Category | Count |
|----------|-------|
| security | 1 |
| reliability | 1 |
| testing | 1 |
| duplication | 1 |
| code-hygiene | 1 |
```

## CLI alternative

You can also run quick scan from the command line without the browser:

```bash
curl -s http://localhost:4321/api/quick-scan | jq .
```

To save the report:

```bash
curl -s http://localhost:4321/api/quick-scan | jq -r '
  "# Takeover Report: \(.chaosScore)/100 (Grade: \(.grade))\n\n## Issues (\((.issues | length))\n\n" + (
    (.issues | to_entries[] | "\(.key + 1). [\(.value.severity)] \(.value.description) — `\(.value.file)\(.value.line | if . then ":" + tostring else "" end)`")
  ) + "\n\n## Categories\n\n" + (
    (.byCategory | to_entries[] | "- \(.key): \(.value)")
  )
' > takeover-report.md
```

## After quick scan

- **Grade A (90+)**: Project is healthy. Consider standard workflows.
- **Grade B-D (40-89)**: Use the top issues as a prioritized todo list. Start with HIGH items.
- **Grade F (<40)**: Major refactoring needed. Consider the takeover workflow instead.

If the report reveals structural issues, hand off to `$build-agent-app` for a full takeover plan.

## See also

- `$dashboard` — the full dashboard skill
- `01-generate.md` — regenerate dashboard after template changes
- `02-customize.md` — customize theme and branding
