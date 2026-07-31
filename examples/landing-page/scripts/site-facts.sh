#!/usr/bin/env bash
# examples/landing-page/scripts/site-facts.sh — derive the landing page's numbers
# from the repo, so the public site cannot drift from the artefact it describes.
#
# Why this exists: the previous build shipped "9 workflows" (really 10), "14 CLI
# agents" (really 40) and footer "V1.8.6" (VERSION says 0.2.2). Those numbers were
# typed into JSX by hand and then went stale silently -- the same failure the
# READMEs were just fixed for, except on the front door, where it is worst: a page
# arguing for evidence-gated engineering while getting its own counts wrong.
#
# Usage:
#   scripts/site-facts.sh            # write src/facts.json
#   scripts/site-facts.sh --check    # exit 1 if src/facts.json is stale
#
# bash 3.2 compatible (macOS /bin/bash): no mapfile, no declare -A, no process
# substitution, no heredoc inside $( ).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SITE_DIR/../.." && pwd)"
OUT="$SITE_DIR/src/facts.json"

CHECK=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    -h|--help) sed -n 2,20p "$0"; exit 0 ;;
  esac
done

cd "$REPO_ROOT"

count_md() { ls -1 "$1"/*.md 2>/dev/null | wc -l | tr -d ' '; }

agents="$(count_md agents)"
workflows="$(count_md workflows)"
templates="$(count_md templates)"
checklists="$(count_md checklists)"
references="$(count_md references)"
examples="$(ls -1 examples 2>/dev/null | wc -l | tr -d ' ')"
# The skill family is the root harness plus each sibling under skills/.
siblings="$(ls -1d skills/*/ 2>/dev/null | wc -l | tr -d ' ')"
skills=$((siblings + 1))
# install.sh's TARGETS is a bash array, not a glob -- parse it directly.
targets="$(awk '/^TARGETS=\(/{f=1;next} f&&/^\)/{exit} f&&NF{c++} END{print c+0}' install.sh)"
# Numbered detector comments in the dashboard parser. Anchored to `// N. ` with a
# trailing space so prose containing "99.1%" cannot be miscounted -- it was, once.
detectors="$(grep -cE '^[[:space:]]+// (10|[1-9])\. ' skills/dashboard/templates/parser.js)"
bats_files="$(ls -1 tests/*.bats skills/*/tests/*.bats 2>/dev/null | wc -l | tr -d ' ')"
version="$(tr -d ' \n' < VERSION)"

# Test count is deliberately NOT published on the site: it changes on every test
# commit, so a gate on it would fire during routine work and get disabled. The
# file count is stable enough to be interesting and stable enough to guard.

NEW="$(printf '{
  "agents": %s,
  "workflows": %s,
  "templates": %s,
  "checklists": %s,
  "references": %s,
  "examples": %s,
  "skills": %s,
  "targets": %s,
  "detectors": %s,
  "batsFiles": %s,
  "version": "%s"
}
' "$agents" "$workflows" "$templates" "$checklists" "$references" "$examples" \
  "$skills" "$targets" "$detectors" "$bats_files" "$version")"

if [[ $CHECK -eq 1 ]]; then
  if [[ ! -f "$OUT" ]]; then
    echo "FAIL  $OUT missing — run scripts/site-facts.sh" >&2
    exit 1
  fi
  if [[ "$NEW" != "$(cat "$OUT")" ]]; then
    echo "FAIL  src/facts.json is stale. Repo says:" >&2
    printf '%s\n' "$NEW" >&2
    echo "Run: scripts/site-facts.sh" >&2
    exit 1
  fi
  echo "OK    src/facts.json matches the repo"
  exit 0
fi

printf '%s' "$NEW" > "$OUT"
echo "wrote $OUT"
printf '%s' "$NEW" | tr -d '\n{}"' | tr ',' '\n' | sed 's/^ */  /'
