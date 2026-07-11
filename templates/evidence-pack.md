# Evidence Pack

The minimum evidence bundle per Issue. Stored under `docs/evidence/<issue-id>/`.

## Required

```
docs/evidence/<id>/
├── change-summary.md            # what changed, why, how verified
├── implementation-plan.md       # mirror of the plan (or pointer)
├── verification.md              # pass/fail per Acceptance Criterion
├── test-results/
│   ├── unit.json
│   ├── integration.json
│   ├── e2e.json (Playwright)
│   └── api-trace.json (if API)
├── screenshots/                 # only if UI
│   ├── desktop.png
│   ├── mobile.png
│   ├── empty.png
│   ├── error.png
│   └── loading.png (if applicable)
├── db/                          # only if schema change
│   ├── migration.sql
│   ├── rollback.sql
│   ├── pre-stats.md
│   └── post-stats.md
├── review-<role>.md             # one per reviewer
└── fix-tasks.md                 # from review-aggregator
```

## change-summary.md

```markdown
# Change Summary — Issue #<id>

## What
<bullets>

## Why
<spec/ADR citations>

## How Verified
<test results, evidence>

## Risk & Rollback
<...>
```

## verification.md

```markdown
# Verification — Issue #<id>

| AC # | Description | Method | Result | Evidence |
|------|-------------|--------|--------|----------|
| 1    | ...         | test   | PASS   | test-results/... |
```

