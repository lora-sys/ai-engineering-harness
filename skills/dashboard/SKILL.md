---
name: dashboard
description: "Visual dashboard for ai-engineering-harness. Dark-themed, zero-dep. Triggers: $dashboard, show dashboard, project health, evidence completeness, kanban, chaos score, quick scan, vibe signs. Run: bash scripts/dashboard.sh → :4321"
---

# Dashboard

Visual web dashboard for any project managed by `ai-engineering-harness`. Dark theme, zero dependencies.

## Trigger

Keywords: show dashboard, project health, evidence completeness, kanban, chaos score, quick scan, vibe signs, takeover audit, what's wrong with this repo.

## Run

```bash
# First time (scaffold into project):
bash workflows/00-bootstrap.md   # creates .dashboard/ + scripts/dashboard.sh

# Every time:
bash scripts/dashboard.sh         # starts parser + opens :4321
```

Or from the main skill: Coordinator auto-starts dashboard before each workflow phase (see §10 in parent `SKILL.md`).

## Architecture

Zero external deps: Node.js `http` + `fs` + `path` (parser.js) + single self-contained HTML (dashboard.html).

| Component | File | Role |
|-----------|------|------|
| Parser + Server | `templates/parser.js` | Scans project, serves JSON API |
| Dashboard UI | `templates/dashboard.html` | Single HTML file, 5 views |
| Wrapper | `scripts/dashboard.sh` | Starts server + opens browser |

### API endpoints

| Route | Data |
|-------|------|
| `GET /api/health` | Project health summary |
| `GET /api/project-status` | PROJECT_STATUS.md parsed |
| `GET /api/evidence` | Evidence pack summaries |
| `GET /api/evidence/:id` | Full detail for one pack |
| `GET /api/kanban` | Issues by closed-loop stage |
| `GET /api/takeover-audit` | Chaos Score + issues |
| `GET /api/quick-scan` | Vibe-signs scan (7 detectors) |
| `GET /` | Serves dashboard.html |

### Views

| View | Hash | Content |
|------|------|---------|
| Project Dashboard | `#/dashboard` | Health cards, evidence, progress |
| Evidence Detail | `#/evidence/:id` | Screenshots, code blocks, reviewers |
| Kanban | `#/kanban` | Now / Backlog / Blocked / Merged |
| Takeover Audit | `#/takeover` | Chaos Score 0-100, categorized issues |
| Quick Scan | button on Takeover | 7 vibe-signs detectors → chaos score + top-5 |

## Hand-off

After dashboard deployed, resume with `$ai-engineering-harness` for Issue-driven development.

## Read on demand

- `workflows/00-bootstrap.md` — scaffold into project
- `workflows/01-generate.md` — regenerate artifacts
- `workflows/02-customize.md` — theme / branding
- `workflows/03-quick-scan.md` — one-click vibe-signs scan
- `references/data-sources.md` — parser file catalog
- `references/parser-spec.md` — API JSON contracts
- `references/chaos-score-algorithm.md` — 0-100 scoring
- `templates/parser.js` — zero-dep Node.js server
- `templates/dashboard.html` — single-file UI
- `$ai-engineering-harness` — sibling skill for engineering orchestration
- `$frontend-creative` — sibling for Awwwards-grade UI (this skill is NOT for creative design)
