# Quickstart — Dashboard Skill

> **Visual web dashboard for the ai-engineering-harness.** One command to serve a dark-themed, developer-friendly dashboard showing your project's health, evidence, and closed-loop progress.

This document is a working tutorial. Read it top-to-bottom once, then refer back as needed.

---

## 1 · What this skill does

Generates a **visual web dashboard** for any project managed by the `ai-engineering-harness`. One script (`bash scripts/dashboard.sh`) launches a Node.js server that parses your project files and serves a self-contained HTML dashboard with 4 views:

| View | What you see |
|------|-------------|
| **Project Dashboard** | Health cards, evidence completeness %, closed-loop progress, recent activity |
| **Evidence Detail** | AC verification table, screenshots, code blocks, reviewer reports |
| **Kanban** | Issues grouped by Now / Backlog / Blocked / Recently Merged |
| **Takeover Audit** | Chaos Score 0-100, categorized issues, severity breakdown |

**Use this skill for**: any project that uses the harness and needs a visual overview of its state.

**Don't use this skill for**: non-harness projects, internal tools without evidence packs, or anything that needs a build step / npm install.

---

## 2 · Quick start (3 steps)

### Step 1 — Bootstrap (one-shot)

```
$dashboard. Bootstrap into this project.
```

The LLM:
1. Creates `skills/dashboard/` with all templates, scripts, and workflows
2. Copies `templates/dashboard.html` + `templates/parser.js` to `.dashboard/` in the target project
3. Creates `scripts/dashboard.sh` wrapper

**You verify:** `ls .dashboard/` shows `parser.js` + `dashboard.html`.

### Step 2 — Serve

```bash
bash scripts/dashboard.sh
# Serves on http://localhost:4321
```

**You verify:** Open the URL in a browser. The Project Dashboard loads with your project's data.

### Step 3 — Explore views

Click the nav or use hash URLs:
- `#/dashboard` — Project Dashboard
- `#/evidence/1` — Evidence pack #1 (replace with actual ID)
- `#/kanban` — Kanban board
- `#/takeover` — Takeover Audit with Chaos Score

---

## 3 · End-to-end example: first time

You have a harness-managed project with a few evidence packs. You want to see everything at a glance.

```
$dashboard. Bootstrap and serve.
```

The LLM:
1. Checks if `.dashboard/` exists (idempotent — doesn't overwrite user data)
2. Copies the parser + dashboard HTML
3. Runs `node .dashboard/parser.js` on a background port
4. Opens `http://localhost:4321` in your browser

**You see:**
- **Dashboard view**: green/yellow/red health cards, evidence completion bar, phase progress
- **Evidence view**: click any evidence pack to see AC table, screenshots, code blocks
- **Kanban**: your issues in Now / Backlog / Blocked columns
- **Takeover Audit**: Chaos Score + list of issues to fix

**Auto-refresh**: the dashboard refreshes every 30 seconds. Click the refresh button for manual refresh.

---

## 4 · Customization

### Change the port

Edit `scripts/dashboard.sh` — change the `PORT` variable:

```bash
PORT=4321 node .dashboard/parser.js
```

### Change the title

Edit `.dashboard/parser.js` — change the `PROJECT_NAME` constant at the top:

```javascript
const PROJECT_NAME = 'My Project';  // Change this
```

### Customize the theme

The dashboard uses CSS custom properties. Edit the `:root` block in `templates/dashboard.html`:

```css
:root {
  --bg-base: #0a0e17;
  --green: #22c55e;
  /* ... etc */
}
```

---

## 5 · How it works

### Parser (Node.js, zero dependencies)

`templates/parser.js` is a single ~500-line Node.js script that:
1. Scans `PROJECT_STATUS.md` with regex (no markdown library)
2. Walks `docs/evidence/*/` to find all evidence packs
3. Reads `memory/*.md` for memory summaries
4. Reads `docs/.index/freshness.json` if present
5. Serves JSON on 8 API endpoints
6. Serves `dashboard.html` on `/`

Graceful degradation: if any source file is missing, the API returns `null` for that field. The dashboard renders empty states instead of crashing.

### Dashboard UI (single HTML file)

`templates/dashboard.html` is a single self-contained file (~1200 lines) with:
- All CSS in a `<style>` block
- All JS in a `<script>` block
- No external dependencies (no CDN, no npm, no build step)
- Hash-based routing between 4 views
- Pure CSS/SVG charts (no chart library)

### Screenshot display

Screenshots from evidence packs are served via `GET /api/screenshots/:id/:file`. The parser reads the actual files from disk and serves them with correct MIME types. The dashboard displays them in a responsive image grid with lazy loading.

### Code blocks

Code from `verification.md` and `review-*.md` files is displayed in syntax-highlighted `<pre><code>` blocks. The parser extracts code fences from markdown and returns them as HTML strings.

---

## 6 · Cheat sheet

### Always do
- ✅ Bootstrap first, then serve.
- ✅ Keep `.dashboard/` in `.gitignore` (it's generated, not source).
- ✅ Check the browser console for errors if the dashboard looks broken.
- ✅ Regenerate with `$dashboard. Regenerate dashboard.` if templates are updated.

### Never do
- ❌ Edit `.dashboard/parser.js` or `.dashboard/dashboard.html` directly — they get overwritten on bootstrap. Edit `templates/` instead.
- ❌ Run the parser as root or with elevated permissions (it reads your project files).
- ❌ Expect the dashboard to work without Node.js installed (it's a hard requirement).
- ❌ Commit `.dashboard/` to git (it's generated output).

---

## 7 · Where to read more

- `references/data-sources.md` — what files the parser reads and what it extracts from each
- `references/parser-spec.md` — the JSON output contract for each API endpoint
- `references/chaos-score-algorithm.md` — how the 0-100 Takeover Audit score is calculated
- `agents/dashboard-architect.md` — the agent persona that builds and maintains dashboards

### Workflows
- `workflows/00-bootstrap.md` — scaffold dashboard into a target project
- `workflows/01-generate.md` — regenerate dashboard artifacts
- `workflows/02-customize.md` — customize theme, title, branding

### One-sentence summary

> **Run `$dashboard. Bootstrap and serve.` — one command to see your entire project's health, evidence, and progress in a dark-themed dashboard.**
