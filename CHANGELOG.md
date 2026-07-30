# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note on versioning for this skill**: The skill's `description` and the
> install instructions *are* the API surface — they're what the agent reads
> to decide whether to invoke. Doc-only changes that clarify routing,
> safety, or onboarding therefore bump the patch number. See `memory/notes-2026-07-11.md`
> for the rationale (decision D-006).

## [0.2.1] - 2026-07-29

Trigger-routing optimization: concise descriptions + keyword table + dashboard auto-start.

### Changed

- **`SKILL.md`** — rewritten trigger rules: keyword→skill routing table (3 rows), dashboard auto-start rule, §10 activation steps include keyword routing + dashboard check
- **`SKILL.md` frontmatter description** — trimmed from ~500 to 266 chars (removed agent name list, kept route verbs)
- **`meta.json` description** — trimmed to match frontmatter
- **`skills/frontend-creative/SKILL.md`** — 102 → 75 lines; moved workflow table, reference list, examples to compact format
- **`skills/frontend-creative/meta.json`** — description trimmed to 285 chars with trigger keywords
- **`skills/build-agent-app/SKILL.md`** — 139 → 84 lines; collapsed principle list + workflow section
- **`skills/build-agent-app/meta.json`** — description trimmed to 289 chars with trigger keywords
- **`skills/dashboard/SKILL.md`** — 126 → 75 lines; moved API table to compact format, merged architecture into run section
- **`skills/dashboard/meta.json`** — description trimmed to 215 chars with trigger keywords + port

### Files changed

```
M SKILL.md                                       trigger rules + dashboard auto-start
M meta.json                                      v0.2.0 → v0.2.1 + trimmed description
M skills/frontend-creative/SKILL.md              102 → 75 lines
M skills/frontend-creative/meta.json              trimmed description
M skills/build-agent-app/SKILL.md                139 → 84 lines
M skills/build-agent-app/meta.json                trimmed description
M skills/dashboard/SKILL.md                      126 → 75 lines
M skills/dashboard/meta.json                      trimmed description
```

## [0.2.0] - 2026-07-30

Dashboard skill Quick Scan — one-click takeover entry experience.

### Added

- **`GET /api/quick-scan`** — new API endpoint scanning source files for vibe signs
- **7 heuristic detectors**: hardcoded secrets (HIGH), missing error handling (MEDIUM), placeholder names (LOW), commented-out code (LOW), TODO without issue links (LOW), duplicate code blocks (MEDIUM), missing test files (MEDIUM)
- **Quick Scan button** on Takeover Audit view in dashboard.html
- **Inline results display**: chaos score gauge + severity bars + issue table + category breakdown
- **Export Report** — download `takeover-report.md` via Blob API
- **`workflows/03-quick-scan.md`** — one-click scan workflow documentation
- **6 new BATS tests** for quick-scan functionality
- Source file test fixtures (config.ts, api.ts, utils.ts with intentional issues)
- `scripts/run-tests.sh` supports `skills/dashboard/tests/` directory

### Changed

- `skills/dashboard/meta.json` — version 0.1.0 → 0.2.0
- `skills/dashboard/SKILL.md` — added `/api/quick-scan` to API table, added Quick Scan view, updated trigger rules and workflow list

### Files changed

```
+ skills/dashboard/workflows/03-quick-scan.md  NEW
M skills/dashboard/templates/parser.js         +detectVibeSigns + /api/quick-scan
M skills/dashboard/templates/dashboard.html    +Quick Scan button + result display
M skills/dashboard/SKILL.md                    +quick-scan references
M skills/dashboard/meta.json                   v0.1.0 → 0.2.0
M skills/dashboard/tests/dashboard.bats        +6 tests + fixtures
M scripts/run-tests.sh                         +dashboard tests dir support
M meta.json                                    v0.1.2 → 0.2.0
M CHANGELOG.md                                 This entry
```

## [0.1.2] - 2026-07-29

New sibling skill **`$dashboard`** — visual web dashboard for the harness. Dark-themed, zero-dependency, developer-friendly dashboard showing project health, evidence completeness, closed-loop progress, evidence detail with screenshots/code blocks, kanban, and Takeover Audit with Chaos Score.

### Added

- **`skills/dashboard/`** (NEW sibling skill):
  - `SKILL.md`, `meta.json`, `QUICKSTART.md`
  - `agents/dashboard-architect.md` — agent persona
  - `references/data-sources.md`, `parser-spec.md`, `chaos-score-algorithm.md`
  - `workflows/00-bootstrap.md`, `01-generate.md`, `02-customize.md`
  - `templates/parser.js` — zero-dep Node.js HTTP server
  - `templates/dashboard.html` — single self-contained HTML dashboard
  - `scripts/serve.sh`, `scaffold-dashboard.sh`
  - `tests/dashboard.bats` — 15 BATS tests
- **4 Dashboard views**: Project Dashboard, Evidence Detail, Kanban, Takeover Audit
- **Zero dependencies** — Node.js stdlib only, no npm install, no build step
- **Graceful degradation** — nullable fields, never crashes on missing data
- **Screenshot serving** — reads from disk, serves with correct MIME types
- **Code blocks** — extracted from markdown, rendered with copy button
- **Auto-refresh** — 30s polling with countdown, manual refresh button

### Changed

- **`install.sh`** — added `dashboard` to `SKILL_SOURCES`
- **`scripts/install-all-skills.sh`** — added `dashboard` to `SKILLS` + status table
- **`SKILL.md`** — updated to 4-skill family, added `$dashboard` trigger rules
- **`skills/build-agent-app/SKILL.md`** — added `$dashboard` reference
- **`skills/frontend-creative/SKILL.md`** — added `$dashboard` (explicitly non-dashboard)
- **All `meta.json`** — bumped to `0.1.2`
- **`VERSION`** — bumped to `0.1.2`

### Dark Theme

```
--bg-base: #0a0e17, --green: #22c55e, --yellow: #eab308, --red: #ef4444, --accent: #3b82f6
```

### Files changed

```
+ skills/dashboard/                          NEW (18 files)
M  install.sh                                +dashboard
M  scripts/install-all-skills.sh             +dashboard
M  SKILL.md                                  +$dashboard
M  skills/build-agent-app/SKILL.md           +$dashboard
M  skills/frontend-creative/SKILL.md         +$dashboard
M  meta.json                                 +sibling-skill:dashboard
M  skills/build-agent-app/meta.json          v0.1.2
M  skills/frontend-creative/meta.json        v0.1.2
M  skills/dashboard/meta.json                NEW
M  VERSION                                   → 0.1.2
M  CHANGELOG.md                              This entry
```


## [1.9.0] - 2026-07-14

**Cross-version regression test (D-017)** — the first eval layer for the harness itself. Catches "upgrading the harness breaks user projects" regressions before they ship.

### Added

- **`tests/cross-version/`** (NEW) — cross-version regression infrastructure.
  - `fixtures/project-alpha/` — a pre-v1.4 project (AGENTS.md + docs/evidence/ + user content, no `.harness-state.json`).
  - `fixtures/project-beta/` — a post-v1.6 project (has `v1.6.0` state file, fenced block, user content).
  - `fixtures/scripts/sync-project-v1.7.0.sh` — frozen copy of v1.7.0's `sync-project.sh`, extracted via `git show v1.7.0:scripts/sync-project.sh`.
  - `run-test.sh` — runs v1.7 then HEAD on each fixture, asserts invariants.
- **`tests/cross-version.bats`** (NEW, 1 test) — bats wrapper that runs `run-test.sh` and asserts exit 0.
- **Cross-version test is automatically picked up by `scripts/run-tests.sh`** (the existing `tests/*.bats` glob includes it). Total bats: 81 (was 80).

### Invariants checked (per fixture)

1. **User content preserved** (the most important — catches "fence block ate user content" regressions). PASS for both fixtures.
2. **HEAD fence block non-empty** (the capabilities list is there). PASS.
3. **State file version == HEAD version** (`1.8.8`). PASS.
4. **Both versions are idempotent** (re-run produces same output). PASS.
5. **Initial state v1.6.0 → HEAD** (the upgrade path works). PASS for project-beta.

### Why cross-version regression first (out of 6 eval layers)

The harness has 6 eval layers (project-level, harness-self-test, cross-version, agent regression, Awwwards auto-scoring, skill benchmark). Cross-version is the **cheapest** (1 second, no LLM, no human) and catches a **class of bugs** the others can't (migration semantics change between versions). The other layers are listed as future work; this one ships now.

### Files changed

```
+ tests/cross-version/                          NEW (fixtures + run-test.sh)
+ tests/cross-version.bats                      NEW (1 bats test)
M  meta.json                                    version: 1.8.8 → 1.9.0
M  skills/build-agent-app/meta.json             version: 1.8.8 → 1.9.0
M  skills/frontend-creative/meta.json           version: 1.8.8 → 1.9.0
M  memory/notes-2026-07-12.md                   D-017 added
M  CHANGELOG.md                                 This entry
```

### Roadmap for the other 5 eval layers (future work)

- **v1.10.0**: Agent regression — `tests/agent-prompts/` with test scenarios per agent. Cheap-ish (LLM-as-judge or just hash compare on agent outputs).
- **v1.11.0**: Awwwards auto-scoring — LLM-as-judge on rendered pages using `templates/review-checklist.md`. Medium effort.
- **v1.12.0**: Skill-level benchmark — 5-10 golden projects with expected outputs. Higher effort.
- **ongoing**: User study — real users, real projects, version-to-version comparison.

