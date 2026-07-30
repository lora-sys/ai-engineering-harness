---
name: dashboard
description: Visual web dashboard for the ai-engineering-harness. Generates a dark-themed, developer-friendly dashboard showing project health, evidence completeness, closed-loop progress, evidence detail with screenshots, kanban view, and Takeover Audit with Chaos Score. Zero dependencies — Node.js parser + single self-contained HTML. Install alongside the main skill, run `bash scripts/dashboard.sh`, open http://localhost:4321. Triggers: $dashboard.
---

# Dashboard

A skill for generating a **visual web dashboard** for any project managed by the `ai-engineering-harness`. Shows project health, evidence completeness, closed-loop progress, evidence detail with screenshots and code blocks, kanban view, and a Takeover Audit with Chaos Score. Dark theme, developer-friendly, strong status colors.

## When to use

Trigger this skill when the user asks for:
- "Show me a dashboard of my project"
- "Visualize the harness state"
- "I want to see project health / evidence completeness"
- "Run the dashboard / open the dashboard"
- "Takeover audit / chaos score"
- "Show me the kanban / what's in progress"

## Architecture

Two components, zero external dependencies:

| Component | File | Role |
|-----------|------|------|
| Parser + Server | `templates/parser.js` | Node.js HTTP server, scans project files, serves JSON API |
| Dashboard UI | `templates/dashboard.html` | Single self-contained HTML/CSS/JS, renders 4 views |

### Parser reads

| Source | What it extracts |
|--------|-----------------|
| `PROJECT_STATUS.md` | Now, Backlog, Blocked, Phase, Health, Risks |
| `docs/evidence/<id>/` | Evidence pack summaries + full detail |
| `memory/*.md` | Memory file summaries |
| `docs/.index/freshness.json` | Documentation freshness |

### API endpoints

| Route | Data |
|-------|------|
| `GET /api/health` | Project health summary |
| `GET /api/project-status` | Full PROJECT_STATUS.md parsed |
| `GET /api/evidence` | All evidence pack summaries |
| `GET /api/evidence/:id` | Full detail for one pack |
| `GET /api/memory` | Memory summary |
| `GET /api/kanban` | Issues grouped by closed-loop stage |
| `GET /api/takeover-audit` | Chaos Score + categorized issues |
| `GET /` | Serves dashboard.html |

Graceful degradation: every field nullable, no crashes on missing data.

### 4 Views

| View | Route hash | Content |
|------|-----------|---------|
| Project Dashboard | `#/dashboard` | Health cards, evidence completeness, closed-loop progress, recent activity |
| Evidence Detail | `#/evidence/:id` | AC verification table, screenshots, code blocks, reviewer reports |
| Kanban | `#/kanban` | Columns: Now / Backlog / Blocked / Recently Merged |
| Takeover Audit | `#/takeover` | Chaos Score 0-100, categorized issues, severity breakdown |

## Quick start

### 1. Bootstrap (first time)

Run `workflows/00-bootstrap.md` which copies `templates/dashboard.html` and `templates/parser.js` to `.dashboard/` in the target project, plus a `scripts/dashboard.sh` wrapper.

### 2. Serve

```bash
bash scripts/dashboard.sh
# Opens http://localhost:4321
```

### 3. View

- `#/dashboard` — Project Dashboard (landing page)
- `#/evidence/:id` — Evidence Detail for a specific pack
- `#/kanban` — Kanban board
- `#/takeover` — Takeover Audit with Chaos Score

## Dark theme design system

```
--bg-base: #0a0e17      (near-black blue)
--bg-surface: #111827    (card)
--bg-elevated: #1a2332   (hover)
--text-primary: #e2e8f0
--text-secondary: #94a3b8
--green: #22c55e         (PASS, Approved, Healthy)
--yellow: #eab308        (Warning, Non-blocking)
--red: #ef4444           (FAIL, Blocking, Critical)
--accent: #3b82f6        (primary actions)
```

System font stack + SF Mono. SVG/CSS-only charts. Zero external dependencies.

## Anti-patterns

- ❌ Adding external JS/CSS libraries (no build step, no npm install).
- ❌ Generic SaaS dashboard layout (header → 3 cards → table → footer).
- ❌ Letting the parser crash on missing files (graceful degradation is mandatory).
- ❌ Forgetting to display screenshots from evidence packs (the visual evidence is the point).

## See also

- `workflows/00-bootstrap.md` — scaffold dashboard into a target project
- `workflows/01-generate.md` — regenerate dashboard artifacts
- `workflows/02-customize.md` — customize theme, title, branding
- `references/data-sources.md` — catalog of files the parser reads + schemas
- `references/parser-spec.md` — JSON output contract for each API endpoint
- `references/chaos-score-algorithm.md` — 0-100 Takeover Audit scoring
- `agents/dashboard-architect.md` — the agent persona that builds dashboards
- `templates/dashboard.html` — the single-file dashboard UI
- `templates/parser.js` — the zero-dep Node.js server
- `scripts/serve.sh` — one-liner to launch parser + server

## Hand-off

After the dashboard is approved and deployed, hand off to `$ai-engineering-harness` for ongoing project management.

> Dashboard deployed at `.dashboard/`. Evidence packs at `docs/evidence/`. Continue with `$ai-engineering-harness` for Issue-driven development.
