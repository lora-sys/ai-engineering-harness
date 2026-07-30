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

## Taking over an existing repo

If the project already had code before you bootstrapped it — i.e. this is a
takeover, not a greenfield start — do not stop at step 8. The whole point of
bootstrapping onto inherited code is to find out what you inherited, and the
user should not have to know to ask.

Run the scan yourself and say what it found, unprompted:

```bash
bash scripts/dashboard.sh &
sleep 2
curl -s http://localhost:4321/api/quick-scan
```

Then **name the vibe residue out loud** rather than burying it in a score. Lead
with the categories, not the number:

> Quick Scan on 47 files: chaos score 42/100 (grade C).
> Typical vibe residue here — 1 hardcoded secret in `src/config.ts:12`,
> 12 source files with no test, and 3 functions whose doc comment
> contradicts the code. The secret is the one to fix today.

A grade with no named findings is not a report; it tells the user their repo is
bad without telling them what to do. Always list the specific categories and at
least the highest-severity location.

### Turn the findings into a backlog

Findings that live only in a terminal scroll get lost. Group them into Issues:

```bash
bash scripts/scan-to-issues.sh                    # dry run — prints drafts, files nothing
bash scripts/scan-to-issues.sh --create           # actually files them
bash scripts/scan-to-issues.sh --min-severity medium --create   # skip the LOW noise
```

Dry run is the default because filing writes to a shared tracker. Show the
drafts, then ask before passing `--create` — one Issue per category, with
acceptance criteria already filled in.

For a greenfield project there is nothing to scan yet; skip this section.

## After bootstrap

- Run `workflows/01-generate.md` if templates were updated
- Run `workflows/02-customize.md` to change theme, title, branding
- Run `workflows/03-quick-scan.md` for the full scan walkthrough and the detector list
