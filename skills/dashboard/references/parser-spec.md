# Parser Spec — JSON API Contract

Each API endpoint returns JSON with a specific schema. All endpoints include a `_meta` field.

## Base Response

```json
{
  "_meta": {
    "generatedAt": "2026-07-29T10:30:00.000Z",
    "projectRoot": "/Users/lora/repos/my-project",
    "sources": ["PROJECT_STATUS.md", "docs/evidence/1/verification.md"],
    "missing": ["memory/lessons.md"]
  }
}
```

---

## GET /api/health

Project health summary.

```json
{
  "_meta": { ... },
  "overall": "healthy",
  "tests": "pass",
  "ci": "green",
  "docs": "fresh",
  "evidence": {
    "total": 5,
    "complete": 4,
    "percentage": 80
  },
  "memory": {
    "files": 3,
    "lastUpdated": "2026-07-28"
  }
}
```

**Computation:**
- `overall`: `healthy` if all green/yellow, `degraded` if any yellow, `broken` if any red.
- `evidence.percentage`: `(complete / total) * 100`. Rounded to nearest integer.
- `evidence.complete`: count of packs that have all required files (verification.md + at least 1 test-result + at least 1 screenshot if UI pack).
- Sources: `PROJECT_STATUS.md` Health section + evidence pack file inventory.

---

## GET /api/project-status

Full PROJECT_STATUS.md parsed.

```json
{
  "_meta": { ... },
  "now": [
    { "title": "Add user auth", "owner": "@frontend", "phase": "Implementing", "branch": "feature/12-user-auth" }
  ],
  "backlog": [
    { "title": "Dashboard redesign", "size": "L", "class": "M" }
  ],
  "blocked": [
    { "title": "Payment integration", "blockedOn": "Stripe API key" }
  ],
  "recentlyMerged": [
    { "title": "Fix login bug", "pr": "15", "evidencePath": "docs/evidence/11/" }
  ],
  "reviewerThreads": [
    { "pr": "15", "bugHunter": "approved", "behavior": "approved", "architecture": "non-blocking" }
  ],
  "phases": [
    { "name": "Phase 1 — Core shell", "status": "Done" },
    { "name": "Phase 2 — MVP features", "status": "In Progress" }
  ],
  "health": {
    "tests": "green",
    "ci": "green",
    "docs": "fresh",
    "memory": "ok"
  },
  "risks": ["Payment provider rate limits", "Auth migration is irreversible"]
}
```

All arrays are empty `[]` if the section is missing. All string fields are `null` if the section is missing.

---

## GET /api/evidence

List of all evidence pack summaries.

```json
{
  "_meta": { ... },
  "packs": [
    {
      "id": "1",
      "title": "Fix login bug",
      "status": "approved",
      "date": "2026-07-25",
      "acCount": 4,
      "acPassed": 4,
      "reviewerStatus": {
        "bug-hunter": "approved",
        "behavior-reviewer": "approved",
        "architecture-reviewer": "non-blocking"
      }
    }
  ]
}
```

**Status computation:** `approved` if all reviewers approved, `non-blocking` if any non-blocking (no blocking), `blocking` if any blocking, `unknown` if no reviews found.

**Sort order:** By date descending (newest first).

---

## GET /api/evidence/:id

Full detail for one evidence pack.

```json
{
  "_meta": { ... },
  "id": "1",
  "title": "Fix login bug",
  "status": "approved",
  "date": "2026-07-25",
  "verification": [
    { "id": "1", "description": "Login redirects to dashboard", "method": "e2e", "result": "PASS", "evidence": "test-results/e2e.json" }
  ],
  "changeSummary": {
    "what": "Fixed redirect after successful login",
    "why": "Users were stuck on login page after auth",
    "howVerified": "Playwright e2e test + manual QA"
  },
  "testResults": {
    "unit": { "passed": 12, "failed": 0, "total": 12 },
    "integration": { "passed": 5, "failed": 0, "total": 5 },
    "e2e": { "passed": 3, "failed": 0, "total": 3 }
  },
  "screenshots": [
    { "name": "desktop.png", "url": "/api/screenshots/1/desktop.png" },
    { "name": "mobile.png", "url": "/api/screenshots/1/mobile.png" }
  ],
  "codeBlocks": [
    { "language": "typescript", "code": "function login() { ... }" }
  ],
  "reviews": [
    {
      "role": "bug-hunter",
      "status": "approved",
      "findings": [
        { "severity": "low", "category": "style", "description": "Unused import", "file": "src/auth.ts", "line": 42 }
      ]
    }
  ],
  "fixTasks": ["Remove unused import in src/auth.ts"]
}
```

**Screenshots served separately:** The `url` field points to `GET /api/screenshots/:id/:file` which serves the actual image binary.

**Code blocks:** Extracted from fenced code blocks in `change-summary.md` and `verification.md`.

---

## GET /api/memory

Memory file summaries.

```json
{
  "_meta": { ... },
  "files": [
    {
      "name": "lessons-2026-07-12.md",
      "title": "Lessons learned from auth migration",
      "summary": "Rate limiting on the auth endpoint caused 503s during peak hours.",
      "date": "2026-07-12"
    }
  ]
}
```

**Parser approach:** First `<h1>` or `<h2>` heading = title. First paragraph after heading = summary. Filename = `name`.

---

## GET /api/kanban

Issues grouped by closed-loop stage.

```json
{
  "_meta": { ... },
  "now": [
    { "id": "12", "title": "Add user auth", "owner": "@frontend", "phase": "Implementing", "branch": "feature/12-user-auth" }
  ],
  "backlog": [
    { "id": "13", "title": "Dashboard redesign", "size": "L", "class": "M" }
  ],
  "blocked": [
    { "id": "14", "title": "Payment integration", "blockedOn": "Stripe API key" }
  ],
  "recentlyMerged": [
    { "id": "11", "title": "Fix login bug", "pr": "15", "evidencePath": "docs/evidence/11/" }
  ]
}
```

**Sources:** `PROJECT_STATUS.md` sections. If the file doesn't exist, all arrays are empty.

---

## GET /api/takeover-audit

Chaos Score + categorized issues.

```json
{
  "_meta": { ... },
  "chaosScore": 73,
  "maxScore": 100,
  "grade": "B",
  "issues": [
    { "severity": "high", "category": "evidence", "description": "Evidence pack #5 missing screenshots", "file": "docs/evidence/5/", "line": null },
    { "severity": "medium", "category": "review", "description": "PR #12 has no architecture review", "file": "PROJECT_STATUS.md", "line": 23 }
  ],
  "bySeverity": { "critical": 0, "high": 1, "medium": 3, "low": 2 },
  "byCategory": { "evidence": 2, "review": 2, "documentation": 1, "testing": 1 }
}
```

**See `chaos-score-algorithm.md` for the scoring rules.**

---

## GET /api/screenshots/:id/:file

Serves an image file from an evidence pack's `screenshots/` directory.

- **Method:** `fs.createReadStream` with correct `Content-Type` based on file extension.
- **Supported formats:** `.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`
- **404:** If the file doesn't exist, returns JSON error: `{ "error": "Screenshot not found" }`

---

## Error Responses

All endpoints return errors as JSON:

```json
{
  "error": "Human-readable error message",
  "_meta": { ... }
}
```

HTTP status codes:
- `200` — success
- `404` — resource not found (evidence pack, screenshot)
- `500` — internal error (parser crash — should never happen due to try/catch wrappers)
- `503` — parser initialization failed
