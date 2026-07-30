#!/usr/bin/env bash
# scripts/dashboard.sh — one-liner to launch the dashboard parser + server
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/.dashboard"
PORT="${DASHBOARD_PORT:-4321}"

if [[ ! -f "$DASHBOARD_DIR/parser.js" ]]; then
  echo "Error: .dashboard/parser.js not found." >&2
  echo "Run: $dashboard. Bootstrap." >&2
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

cd "$DASHBOARD_DIR" && node parser.js "$@"
