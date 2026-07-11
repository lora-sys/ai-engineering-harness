#!/usr/bin/env bash
# Create a new session directory for an Agent run.
# Usage: scripts/new-session.sh <session-id>
set -euo pipefail

session_id="${1:-}"

if [[ -z "$session_id" ]]; then
  echo "Usage: $0 <session-id>" >&2
  exit 1
fi

# Prefer docs/sessions; fall back to sessions/
target="docs/sessions/${session_id}"
[[ -d "docs/sessions" ]] || target="sessions/${session_id}"

mkdir -p "${target}"
touch "${target}/status.md"
touch "${target}/plan.md"
touch "${target}/execution.md"
touch "${target}/review.md"
touch "${target}/summary.md"

# Seed status
cat > "${target}/status.md" <<STATUS
# Session: ${session_id}
- Started: $(date -Iseconds)
- Owner: @coordinator
- State: starting
- Issue(s): TBD
STATUS

echo "Created session at: ${target}"
