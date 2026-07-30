# Data Sources

The parser reads the following files to build the dashboard. Every source is optional — the parser handles missing files gracefully.

---

## 1. PROJECT_STATUS.md

**Path:** `PROJECT_STATUS.md` (project root)

**Purpose:** Primary source for project state — what's in progress, what's planned, what's blocked.

**Sections parsed:**

| Section | Extracted as |
|---------|-------------|
| `## Now (in progress)` | Array of `{ title, owner, phase, branch }` |
| `## Backlog` | Array of `{ title, size, class }` |
| `## Blocked (Waiting for Approval / external)` | Array of `{ title, blockedOn }` |
| `## Recently Merged` | Array of `{ title, pr, evidencePath }` |
| `## Open Reviewer Threads` | Array of `{ pr, bugHunter, behavior, architecture }` |
| `## Phase` | Array of `{ name, status }` |
| `## Health` | `{ tests, ci, docs, memory }` |
| `## Risks` | Array of risk strings |

**Parser approach:** Regex-based section extraction. Looks for `## Section Name` headers and collects all list items (`- `) until the next `##` header.

**Fallback:** If PROJECT_STATUS.md doesn't exist, all fields return `null` or empty arrays. The dashboard shows "No project status file found."

---

## 2. Evidence Packs

**Path:** `docs/evidence/<id>/` (one directory per issue/feature)

**Purpose:** Evidence of completed work — verification results, screenshots, code, review reports.

**Directory structure (per pack):**

```
docs/evidence/<id>/
├── change-summary.md            # What changed, why, how verified
├── implementation-plan.md       # Mirror of the plan (or pointer)
├── verification.md              # Pass/fail per Acceptance Criterion (AC table)
├── test-results/
│   ├── unit.json
│   ├── integration.json
│   ├── e2e.json (Playwright)
│   └── api-trace.json (if API)
├── screenshots/                 # Only if UI
│   ├── desktop.png
│   ├── mobile.png
│   ├── empty.png
│   ├── error.png
│   └── loading.png (if applicable)
├── db/                          # Only if schema change
│   ├── migration.sql
│   ├── rollback.sql
│   ├── pre-stats.md
│   └── post-stats.md
├── review-<role>.md             # One per reviewer (bug-hunter, behavior-reviewer, etc.)
└── fix-tasks.md                 # From review-aggregator
```

**Files parsed:**

| File | Extracted as |
|------|-------------|
| `verification.md` | AC table → `[{ id, description, method, result, evidence }]` |
| `change-summary.md` | Title, What, Why, How Verified, Risk, Rollback |
| `implementation-plan.md` | Title, Goal, Change Surface, Sequencing |
| `test-results/*.json` | `{ passed, failed, total }` per test type |
| `screenshots/*.{png,jpg,webp}` | Array of `{ name, path }` for gallery display |
| `review-*.md` | `{ role, status, findings: [{ severity, file, line, description }] }` |
| `fix-tasks.md` | Array of fix task strings |

**Parser approach:**
- Regex for markdown tables (AC verification)
- Regex for fenced code blocks (code display in Evidence Detail)
- `fs.readdir` for screenshots (served directly from disk)
- File existence checks for optional files (db/, fix-tasks.md, etc.)

**Fallback:** If an evidence pack is missing files, the parser returns empty arrays or null for those fields. The dashboard shows "No data" placeholders.

---

## 3. Memory Files

**Path:** `memory/*.md`

**Purpose:** Project-level memory — decisions, lessons, architecture notes.

**Parser approach:** Reads all `.md` files in `memory/`, extracts the first heading (title) and first paragraph (summary).

**Returned as:** `[{ file, title, summary, date }]`

**Fallback:** If `memory/` doesn't exist, returns empty array.

---

## 4. Documentation Freshness

**Path:** `docs/.index/freshness.json`

**Purpose:** Tracks when documentation was last updated.

**Parser approach:** Reads JSON directly. Expected schema:

```json
{
  "lastSync": "2026-07-15",
  "files": {
    "CLAUDE.md": "2026-07-15",
    "DESIGN.md": "2026-07-14",
    "ENGINEERING.md": "2026-07-15"
  }
}
```

**Returned as:** `{ lastSync, files: { [filename]: date } }`

**Fallback:** If file doesn't exist, returns `{ lastSync: null, files: {} }`.

---

## 5. Schema Summary

All API responses follow this general shape:

```typescript
// All responses include a `_meta` field with parser info
interface BaseResponse {
  _meta: {
    generatedAt: string;      // ISO timestamp
    projectRoot: string;      // Resolved project root
    sources: string[];        // Files successfully parsed
    missing: string[];        // Files that were expected but missing
  };
}

// Health
interface HealthResponse extends BaseResponse {
  overall: 'healthy' | 'degraded' | 'broken';
  tests: 'pass' | 'fail' | 'unknown';
  ci: 'green' | 'red' | 'unknown';
  docs: 'fresh' | 'stale' | 'unknown';
  evidence: { total: number; complete: number; percentage: number };
  memory: { files: number; lastUpdated: string | null };
}

// Evidence
interface EvidenceSummary {
  id: string;
  title: string;
  status: 'approved' | 'non-blocking' | 'blocking' | 'unknown';
  date: string | null;
  acCount: number;
  acPassed: number;
  reviewerStatus: { [role: string]: 'approved' | 'non-blocking' | 'blocking' | 'unknown' };
}

// Evidence Detail
interface EvidenceDetail extends EvidenceSummary {
  verification: VerificationRow[];
  changeSummary: { what: string; why: string; howVerified: string };
  testResults: { [type: string]: { passed: number; failed: number; total: number } };
  screenshots: { name: string; url: string }[];
  codeBlocks: { language: string; code: string }[];
  reviews: { role: string; status: string; findings: Finding[] }[];
  fixTasks: string[];
}

// Finding (from reviews)
interface Finding {
  severity: 'critical' | 'high' | 'medium' | 'low';
  category: string;
  description: string;
  file: string;
  line: number | null;
}

// Kanban
interface KanbanResponse extends BaseResponse {
  now: IssueItem[];
  backlog: IssueItem[];
  blocked: IssueItem[];
  recentlyMerged: IssueItem[];
}

interface IssueItem {
  id: string;
  title: string;
  owner?: string;
  phase?: string;
  branch?: string;
  blockedOn?: string;
  pr?: string;
  evidencePath?: string;
}

// Takeover Audit
interface TakeoverAuditResponse extends BaseResponse {
  chaosScore: number;        // 0-100
  maxScore: number;          // always 100
  grade: 'A' | 'B' | 'C' | 'D' | 'F';
  issues: Finding[];
  bySeverity: { critical: number; high: number; medium: number; low: number };
  byCategory: { [category: string]: number };
}
```
