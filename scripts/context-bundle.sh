#!/usr/bin/env bash
# scripts/context-bundle.sh
#
# Dump a one-shot "context bundle" markdown file for sub-agents to read instead
# of each one running its own git/ls/find exploration. Coordinator runs this
# before Phase 5 (spawn implementer); sub-agents read docs/evidence/<id>/context-bundle.md
# (or wherever --out points) and skip the exploration phase.
#
# Why:
#   - One slow discovery pass replaces N agent discoveries.
#   - Bundle is reproducible (same input → same output) so reviewers can diff.
#   - Parallel discovery inside the script keeps wall-clock low even when N is large.
#
# What goes in the bundle:
#   - Repo identity (remote URL, branch, HEAD, dirty status).
#   - Top-level layout + key directories (workflows/, agents/, scripts/, references/, templates/).
#   - Recent commits (default 20).
#   - Working-tree changes (status + diff stats).
#   - Open issues / PRs (if gh CLI is available; silently skipped if not).
#   - Key harness files: CLAUDE.md / AGENTS.md / PROJECT_STATUS.md / CHANGELOG.md / SKILL.md.
#   - Recent memory notes (last 3 files in memory/).
#   - Workflow + agent roster (lists from the harness itself).
#
# Usage:
#   scripts/context-bundle.sh                              # writes ./context-bundle.md
#   scripts/context-bundle.sh --out docs/evidence/x.md     # custom path (recommended)
#   scripts/context-bundle.sh --commits 50                 # deeper recent history
#   scripts/context-bundle.sh --no-parallel                # sequential (debugging)
#   scripts/context-bundle.sh --quiet                      # suppress progress to stderr
#
# Exit code: 0 on success, 1 if any section failed (the bundle still gets written,
# but with [error] markers for the failed sections).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OUT="./context-bundle.md"
COMMITS=20
PARALLEL=1
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out=*)      OUT="${1#--out=}" ;;
    --out)        shift; OUT="${1:-./context-bundle.md}" ;;
    --commits=*)  COMMITS="${1#--commits=}" ;;
    --commits)    shift; COMMITS="${1:-20}" ;;
    --no-parallel) PARALLEL=0 ;;
    --quiet|-q)   QUIET=1 ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)   echo "unexpected positional arg: $1" >&2; exit 2 ;;
  esac
  shift
done

log()  { [[ $QUIET -eq 1 ]] || printf '[context-bundle] %s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

# Ensure we run from the repo root so relative paths in sections make sense.
cd "$REPO_DIR"

# Temp dir for section outputs (parallel mode).
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Each section is a function that writes its markdown body to stdout.
# Sections are independent and may run in parallel.

section_repo_identity() {
  cat <<'MD'
## Repo identity

MD
  if ! git remote get-url origin 2>/dev/null | head -1 | awk '{printf "- **origin**: `%s`\n", $0}'; then :; fi
  if ! git rev-parse --abbrev-ref HEAD 2>/dev/null | awk '{printf "- **branch**: `%s`\n", $0}'; then :; fi
  if ! git rev-parse --short HEAD 2>/dev/null | awk '{printf "- **HEAD**: `%s`\n", $0}'; then :; fi
  if ! git describe --tags --exact-match HEAD 2>/dev/null | awk '{sub(/^v/,""); printf "- **tag**: `v%s`\n", $0}'; then
    git describe --tags --abbrev=0 2>/dev/null | awk '{printf "- **nearest tag**: `%s`\n", $0}' || true
  fi
  if git status --porcelain 2>/dev/null | grep -q .; then
    echo "- **working tree**: dirty"
  else
    echo "- **working tree**: clean"
  fi
  echo
}

section_recent_commits() {
  cat <<MD
## Recent commits (last $COMMITS)

MD
  git log --oneline -n "$COMMITS" 2>/dev/null || echo "[error: git log failed]"
  echo
}

section_working_tree() {
  cat <<'MD'
## Working-tree changes

MD
  if git status --porcelain 2>/dev/null | grep -q .; then
    git status --short 2>/dev/null
    echo
    echo "### Diff stats"
    echo
    git diff --stat 2>/dev/null || echo "[error: git diff failed]"
    if [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
      echo
      echo "### Untracked files"
      echo
      git ls-files --others --exclude-standard 2>/dev/null | sed 's/^/  - /'
    fi
  else
    echo "(clean)"
  fi
  echo
}

section_layout() {
  cat <<'MD'
## Top-level layout

MD
  ls -la 2>/dev/null | tail -n +2 | head -40 | awk '{printf "  %s\n", $0}'
  echo
  echo "### Harness subdirs"
  echo
  for d in workflows agents scripts references templates checklists memory docs; do
    if [[ -d "$d" ]]; then
      count=$(ls -1 "$d" 2>/dev/null | wc -l | tr -d ' ')
      printf "  - \`%s/\` — %d entries\n" "$d" "$count"
    fi
  done
  echo
}

section_open_issues_prs() {
  cat <<'MD'
## Open issues & PRs

MD
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      echo "### Open PRs"
      echo
      gh pr list --limit 20 --state open --json number,title,headRefName,author,createdAt 2>/dev/null         | python3 -c 'import json,sys;d=json.load(sys.stdin);print("(none)" if not d else "\n".join("  - #%s \`%s\` — %s (%s)" % (p["number"], p["headRefName"], p["title"], p["author"]["login"]) for p in d))' 2>/dev/null || echo "[error: gh pr list failed]"
      echo
      echo "### Open issues"
      echo
      gh issue list --limit 20 --state open --json number,title,labels,createdAt 2>/dev/null         | python3 -c 'import json,sys;d=json.load(sys.stdin);print("(none)" if not d else "\n".join("  - #%s — %s%s" % (i["number"], i["title"], " ["+",".join(l["name"] for l in i.get("labels", []))+"]" if i.get("labels") else "")) for i in d))' 2>/dev/null || echo "[error: gh issue list failed]"
    else
      echo "(gh CLI present but not authenticated; skipping)"
    fi
  else
    echo "(gh CLI not installed; skipping)"
  fi
  echo
}

section_key_files() {
  cat <<'MD'
## Key harness files

MD
  for f in CLAUDE.md AGENTS.md PROJECT_STATUS.md CONTRIBUTING.md CHANGELOG.md SKILL.md DESIGN.md ENGINEERING.md TESTING.md; do
    if [[ -f "$f" ]]; then
      bytes=$(wc -c < "$f" | tr -d ' ')
      lines=$(wc -l < "$f" | tr -d ' ')
      printf "  - \`%s\` (%d lines, %d bytes)\n" "$f" "$lines" "$bytes"
    fi
  done
  echo
}

section_memory() {
  cat <<'MD'
## Memory notes (most recent 3 files)

MD
  if [[ -d memory ]]; then
    files=$(ls -1t memory/*.md 2>/dev/null | head -3)
    if [[ -z "$files" ]]; then
      echo "(no memory files yet)"
    else
      for f in $files; do
        echo
        echo "### $f"
        echo
        echo '```'
        head -60 "$f" 2>/dev/null
        echo '```'
      done
    fi
  else
    echo "(no memory/ directory)"
  fi
  echo
}

section_harness_roster() {
  cat <<'MD'
## Harness roster

MD
  echo "### Workflows"
  echo
  for f in workflows/*.md; do
    [[ -f "$f" ]] || continue
    title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
    printf "  - \`%s\`%s\n" "$(basename "$f")" "${title:+ — $title}"
  done
  echo
  echo "### Agents"
  echo
  for f in agents/*.md; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .md)
    desc=$(awk '/^> / || /^## Role/ || /^Executes/ || /^Takes/ || /^Builds/ {sub(/^[#>] /,""); print; exit}' "$f" 2>/dev/null)
    printf "  - \`%s\`%s\n" "$name" "${desc:+ — $desc}"
  done
  echo
  echo "### Templates"
  echo
  for f in templates/*.md; do
    [[ -f "$f" ]] || continue
    printf "  - \`%s\`\n" "$(basename "$f")"
  done
  echo
}

SECTIONS=(
  section_repo_identity
  section_recent_commits
  section_working_tree
  section_layout
  section_open_issues_prs
  section_key_files
  section_memory
  section_harness_roster
)

log "writing bundle to $OUT (parallel=$PARALLEL, commits=$COMMITS)"
mkdir -p "$(dirname "$OUT")"

if [[ $PARALLEL -eq 1 ]]; then
  log "running ${#SECTIONS[@]} sections in parallel..."
  pids=()
  i=0
  for fn in "${SECTIONS[@]}"; do
    ("$fn" > "$WORK/$i.md") &
    pids+=($!)
    i=$((i+1))
  done
  failed=0
  for pid in "${pids[@]}"; do
    wait "$pid" || failed=$((failed+1))
  done
  log "$failed section(s) failed"
else
  i=0
  for fn in "${SECTIONS[@]}"; do
    "$fn" > "$WORK/$i.md" || log "section $i ($fn) failed"
    i=$((i+1))
  done
fi

# Assemble in canonical order (not parallel-order).
{
  echo "# Context bundle"
  echo
  echo "_Generated $(date -Iseconds) by scripts/context-bundle.sh_"
  echo "_Repo: $(git remote get-url origin 2>/dev/null || echo 'local')_"
  echo "_HEAD: $(git rev-parse --short HEAD 2>/dev/null)_"
  echo
  i=0
  for fn in "${SECTIONS[@]}"; do
    cat "$WORK/$i.md"
    i=$((i+1))
  done
} > "$OUT"

log "wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes, $(wc -l < "$OUT" | tr -d ' ') lines)"
log "done"
