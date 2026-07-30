# Bootstrap — Scaffold Dashboard into Target Project

Copies the dashboard templates into `.dashboard/` in the target project and creates the `scripts/dashboard.sh` wrapper. Idempotent — safe to re-run.

## When to run

- First time setting up the dashboard for a project
- After updating the skill (regenerate templates)
- When the user says "bootstrap the dashboard" or "$dashboard. Bootstrap."

## Prerequisites

- Node.js >= 14 installed (for the parser server)
- The project has at least `PROJECT_STATUS.md` (optional but recommended)

## Steps

### 1. Verify project root

Confirm the current working directory is the project root (has `PROJECT_STATUS.md` or is a git repo).

### 2. Create .dashboard/ directory

```bash
mkdir -p .dashboard
```

### 3. Copy parser.js

Copy `templates/parser.js` → `.dashboard/parser.js`. The parser is the Node.js server.

### 4. Copy dashboard.html

Copy `templates/dashboard.html` → `.dashboard/dashboard.html`. This is the single-file dashboard UI.

### 5. Create scripts/dashboard.sh

Create `scripts/dashboard.sh` (if it doesn't exist):

```bash
#!/usr/bin/env bash
# scripts/dashboard.sh — launch the dashboard server
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/.dashboard"
PORT="${DASHBOARD_PORT:-4321}"

if [[ ! -f "$DASHBOARD_DIR/parser.js" ]]; then
  echo "Error: .dashboard/parser.js not found. Run: $dashboard. Bootstrap." >&2
  exit 1
fi

echo "Starting dashboard on http://localhost:$PORT"
echo "Press Ctrl+C to stop."
cd "$DASHBOARD_DIR" && node parser.js
```

Make it executable:
```bash
chmod +x scripts/dashboard.sh
```

### 6. Add to .gitignore

Ensure `.dashboard/` is in `.gitignore` (it's generated output, not source):

```bash
grep -q '^.dashboard/' .gitignore 2>/dev/null || echo '.dashboard/' >> .gitignore
```

### 7. Verify

```bash
bash scripts/dashboard.sh &
sleep 2
curl -s http://localhost:4321/api/health | head -c 200
kill %1 2>/dev/null
```

### 8. Report

Tell the user:
- Dashboard files are at `.dashboard/`
- Run `bash scripts/dashboard.sh` to start
- Open `http://localhost:4321` in browser
- Edit `templates/parser.js` and `templates/dashboard.html` to customize (these are the source files; `.dashboard/` copies are regenerated)

## After bootstrap

- Run `workflows/01-generate.md` if templates were updated
- Run `workflows/02-customize.md` to change theme, title, branding
