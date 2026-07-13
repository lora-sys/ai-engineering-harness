#!/usr/bin/env bash
# Create the evidence pack directory for an Issue.
# Usage: scripts/new-evidence.sh <issue-id>
set -euo pipefail

issue_id="${1:-}"
if [[ -z "$issue_id" ]]; then
  echo "Usage: $0 <issue-id>" >&2
  exit 1
fi

# Reject flag-like args so '--help' / '-h' is not treated as an issue-id.
if [[ "$issue_id" == -* ]]; then
  echo "Usage: $0 <issue-id>" >&2
  echo "  (got what looks like a flag: $issue_id)" >&2
  exit 2
fi

target="docs/evidence/${issue_id}"
mkdir -p "${target}/test-results"
mkdir -p "${target}/screenshots"
mkdir -p "${target}/db"

# Touch core files
touch "${target}/change-summary.md"
touch "${target}/verification.md"
touch "${target}/implementation-plan.md"

cat > "${target}/change-summary.md" <<CHANGE
# Change Summary — Issue ${issue_id}

## What
<!-- 1-line per change -->

## Why
<!-- Spec / ADR citations -->

## How Verified
<!-- Test results / evidence -->

## Risk & Rollback
<!-- One paragraph -->
CHANGE

cat > "${target}/verification.md" <<VERIFY
# Verification — Issue ${issue_id}

| AC # | Description | Method | Result | Evidence |
|------|-------------|--------|--------|----------|
VERIFY

echo "Created evidence pack at: ${target}"
