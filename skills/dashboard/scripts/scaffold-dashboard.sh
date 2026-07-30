#!/usr/bin/env bash
# scripts/scaffold-dashboard.sh — copy dashboard templates into target project
# Called by workflows/00-bootstrap.md
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve target project root, then verify it really is one.
# `${1:-}` not `$1`: under `set -u` a bare $1 with no args aborts the script.
TARGET="${1:-$(pwd)}"

if [[ ! -d "$TARGET" ]]; then
  echo "Error: not a directory: $TARGET" >&2
  exit 1
fi

# Validate the explicit-argument path too, not just the cwd fallback. Without
# this, `scaffold-dashboard.sh /some/empty/dir` happily scattered .dashboard/
# and scripts/ into an unrelated directory. See issue #13.
if [[ ! -f "$TARGET/PROJECT_STATUS.md" ]] && [[ ! -f "$TARGET/AGENTS.md" ]]; then
  echo "Error: No PROJECT_STATUS.md or AGENTS.md found in $TARGET" >&2
  echo "Usage: $0 [project-root]" >&2
  exit 1
fi

DASHBOARD_DIR="$TARGET/.dashboard"

echo "Scaffolding dashboard into: $TARGET"

# Create directories
mkdir -p "$DASHBOARD_DIR"
mkdir -p "$TARGET/scripts"

# Copy parser.js
if [[ -f "$TEMPLATE_DIR/parser.js" ]]; then
  cp "$TEMPLATE_DIR/parser.js" "$DASHBOARD_DIR/parser.js"
  echo "  ✓ parser.js → .dashboard/parser.js"
else
  echo "  ✗ parser.js not found in $TEMPLATE_DIR" >&2
  exit 1
fi

# Copy dashboard.html
if [[ -f "$TEMPLATE_DIR/dashboard.html" ]]; then
  cp "$TEMPLATE_DIR/dashboard.html" "$DASHBOARD_DIR/dashboard.html"
  echo "  ✓ dashboard.html → .dashboard/dashboard.html"
else
  echo "  ✗ dashboard.html not found in $TEMPLATE_DIR" >&2
  exit 1
fi

# Create scripts/dashboard.sh if it doesn't exist
DASHBOARD_SH="$TARGET/scripts/dashboard.sh"
if [[ ! -f "$DASHBOARD_SH" ]]; then
  cat > "$DASHBOARD_SH" << 'SCRIPT_EOF'
#!/usr/bin/env bash
# scripts/dashboard.sh — launch the dashboard server
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/.dashboard"
PORT="${DASHBOARD_PORT:-4321}"

if [[ ! -f "$DASHBOARD_DIR/parser.js" ]]; then
  echo "Error: .dashboard/parser.js not found. Run the bootstrap workflow." >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required but not installed." >&2
  echo "Install from https://nodejs.org/" >&2
  exit 1
fi

echo "Starting dashboard on http://localhost:$PORT"
echo "Project: $PROJECT_ROOT"
echo "Press Ctrl+C to stop."
echo

cd "$DASHBOARD_DIR" && node parser.js
SCRIPT_EOF
  chmod +x "$DASHBOARD_SH"
  echo "  ✓ scripts/dashboard.sh created"
else
  echo "  = scripts/dashboard.sh already exists (skipped)"
fi

# Add .dashboard/ to .gitignore
GITIGNORE="$TARGET/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -qE '^\.dashboard/?$' "$GITIGNORE" 2>/dev/null; then
    echo ".dashboard/" >> "$GITIGNORE"
    echo "  ✓ Added .dashboard/ to .gitignore"
  else
    echo "  = .dashboard/ already in .gitignore"
  fi
else
  echo ".dashboard/" > "$GITIGNORE"
  echo "  ✓ Created .gitignore with .dashboard/"
fi

echo
echo "Done. Run with:"
echo "  bash $DASHBOARD_SH"
echo "  # then open http://localhost:4321"
