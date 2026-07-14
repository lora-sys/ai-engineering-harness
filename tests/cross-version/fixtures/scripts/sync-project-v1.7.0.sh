#!/usr/bin/env bash
# scripts/sync-project.sh
#
# Sync an already-bootstrapped harness project to the current harness version.
#
# What it does:
#   - Reads .harness-state.json (or detects "pre-v1.0" if missing).
#   - Plans a list of migrations (back-fill compact-report.json in evidence dirs,
#     patch AGENTS.md fenced blocks for new harness capabilities, ensure GitHub
#     templates exist, update .harness-state.json).
#   - Default mode: dry-run (prints the plan, makes NO changes).
#   - --apply: actually do each migration.
#   - --status: just report project state vs current harness version.
#
# Safety:
#   - Backs up .harness-state.json before overwriting it.
#   - AGENTS.md / CONTRIBUTING.md edits are scoped to fenced blocks:
#       <!-- HARNESS:START section-name --> ... <!-- HARNESS:END section-name -->
#     User content outside these blocks is never touched.
#   - Existing compact-report.json files are NEVER overwritten (only added when missing).
#   - Refuses to run if the directory doesn't look like a harness project
#     (no AGENTS.md or no docs/).
#
# Usage:
#   scripts/sync-project.sh                       # dry-run in CWD
#   scripts/sync-project.sh --apply               # actually sync
#   scripts/sync-project.sh --project-dir /path   # sync a specific project
#   scripts/sync-project.sh --status             # report only
#   scripts/sync-project.sh --help
#
# State file format (.harness-state.json):
#   {
#     "version": "1.2.1",
#     "bootstrapped_at": "2026-07-11",
#     "last_synced_at": "2026-07-13T10:30:00+08:00",
#     "last_synced_to": "1.3.0",
#     "project_root": "/abs/path/to/project"
#   }

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

# Read current harness version from this repo's meta.json.
HARNESS_VERSION="$(python3 -c "import json; print(json.load(open('$HARNESS_REPO/meta.json'))['version'])")"

PROJECT_DIR=""
ACTION="plan"  # plan | apply | status

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir=*) PROJECT_DIR="${1#--project-dir=}" ;;
    --project-dir)   shift; PROJECT_DIR="${1:-}" ;;
    --apply)         ACTION="apply" ;;
    --status)        ACTION="status" ;;
    -h|--help)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)   echo "unexpected positional arg: $1" >&2; exit 2 ;;
  esac
  shift
done

PROJECT_DIR="${PROJECT_DIR:-$PWD}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

log()  { printf '[sync-project] %s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

STATE_FILE="$PROJECT_DIR/.harness-state.json"

# ─── Detect project ─────────────────────────────────────────────────────
detect_project() {
  if [[ ! -f "$PROJECT_DIR/AGENTS.md" ]] && [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
    fail "no AGENTS.md or CLAUDE.md in $PROJECT_DIR — does this look like a harness project?"
  fi
  if [[ ! -d "$PROJECT_DIR/docs" ]]; then
    fail "no docs/ directory in $PROJECT_DIR — bootstrap first"
  fi
}

read_state() {
  if [[ -f "$STATE_FILE" ]]; then
    python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_FILE'))
    print(d.get('version', 'unknown'))
except Exception as e:
    print('parse-error', file=sys.stderr)
    sys.exit(1)
"
  else
    echo "pre-v1.0"
  fi
}

# ─── Migration actions ──────────────────────────────────────────────────
# Each prints a one-line description when called with "describe", and does
# the migration when called with "apply". Returns 0 on success, 1 on failure.

# Read current fenced-block contents (if any) from AGENTS.md.
get_fenced() {
  local file="$1" section="$2"
  python3 - "$file" "$section" <<'PY'
import sys, re
path, section = sys.argv[1], sys.argv[2]
try:
    text = open(path).read()
except FileNotFoundError:
    print("")
    sys.exit(0)
m = re.search(
    r'<!-- HARNESS:START ' + re.escape(section) + r' -->\n(.*?)<!-- HARNESS:END ' + re.escape(section) + r' -->',
    text, re.DOTALL,
)
print(m.group(1).rstrip("\n") if m else "")
PY
}

# Apply a fenced block to a file. The block is the new content for that section.
# If the section exists, replace it. If not, append. User content outside is
# preserved.
set_fenced() {
  local file="$1" section="$2" new_content="$3"
  python3 - "$file" "$section" <<PY
import sys, os, tempfile, re
path, section = sys.argv[1], sys.argv[2]
new_block = '''<!-- HARNESS:START ''' + section + ''' -->
''' + '''$new_content''' + '''
<!-- HARNESS:END ''' + section + ''' -->'''

try:
    with open(path) as f:
        text = f.read()
except FileNotFoundError:
    text = ""

pattern = re.compile(
    r'<!-- HARNESS:START ' + re.escape(section) + r' -->.*?<!-- HARNESS:END ' + re.escape(section) + r' -->\n?',
    re.DOTALL,
)
if pattern.search(text):
    new_text = pattern.sub(new_block + "\n", text, count=1)
else:
    if text and not text.endswith("\n"):
        text += "\n"
    new_text = text + "\n" + new_block + "\n"

# Atomic write
fd, tmp = tempfile.mkstemp(prefix=".harness-sync.", dir=os.path.dirname(path) or ".")
try:
    with os.fdopen(fd, "w") as f:
        f.write(new_text)
    os.replace(tmp, path)
except Exception:
    os.unlink(tmp)
    raise
PY
}

# Migration 1: write/update .harness-state.json
mig_state_file_describe() {
  local from_v="$1" to_v="$2"
  echo "write .harness-state.json (mark project at harness v${to_v})"
}
mig_state_file_apply() {
  local from_v="$1" to_v="$2"
  local now
  now="$(date -Iseconds)"
  if [[ -f "$STATE_FILE" ]]; then
    cp "$STATE_FILE" "$STATE_FILE.bak"
  fi
  python3 - "$STATE_FILE" "$from_v" "$to_v" "$PROJECT_DIR" "$now" <<'PY'
import json, sys, os
path, from_v, to_v, project_root, now = sys.argv[1:6]
data = {
    "version": to_v,
    "bootstrapped_at": now if from_v == "pre-v1.0" else None,
    "last_synced_at": now,
    "last_synced_to": to_v,
    "project_root": project_root,
}
# Preserve bootstrapped_at if it was already set.
if os.path.exists(path):
    try:
        old = json.load(open(path))
        if old.get("bootstrapped_at"):
            data["bootstrapped_at"] = old["bootstrapped_at"]
    except Exception:
        pass
data["bootstrapped_at"] = data["bootstrapped_at"] or now
open(path, "w").write(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
PY
}

# Migration 2: ensure GitHub templates exist
mig_github_templates_describe() {
  echo "ensure .github/ISSUE_TEMPLATE/ + .github/PULL_REQUEST_TEMPLATE.md exist"
}
mig_github_templates_apply() {
  mkdir -p "$PROJECT_DIR/.github/ISSUE_TEMPLATE"
  for tmpl in issue.md issue-bug.md issue-feature.md issue-refactor.md issue-spike.md; do
    src="$HARNESS_REPO/templates/$tmpl"
    dst="$PROJECT_DIR/.github/ISSUE_TEMPLATE/$tmpl"
    if [[ -f "$src" ]] && [[ ! -f "$dst" ]]; then
      cp "$src" "$dst"
    fi
  done
  if [[ -f "$HARNESS_REPO/templates/pr-description.md" ]] && \
     [[ ! -f "$PROJECT_DIR/.github/PULL_REQUEST_TEMPLATE.md" ]]; then
    cp "$HARNESS_REPO/templates/pr-description.md" "$PROJECT_DIR/.github/PULL_REQUEST_TEMPLATE.md"
  fi
}

# Migration 3: add a fenced "harness-capabilities" section to AGENTS.md
# describing the new harness features since the project was bootstrapped.
mig_agents_capabilities_describe() {
  echo "patch AGENTS.md fenced block 'harness-capabilities' (current harness features)"
}
mig_agents_capabilities_apply() {
  local agents_file="$PROJECT_DIR/AGENTS.md"
  [[ -f "$agents_file" ]] || agents_file="$PROJECT_DIR/CLAUDE.md"
  local content
  content=$(cat <<BLOCK
This project uses **ai-engineering-harness v${HARNESS_VERSION}**. Key capabilities:

- **Closed loop with CI as a blocking gate.** A red CI must BLOCK review, merge, and Issue-close. See workflows/04-ci-recovery.md.
- **Adversarial review.** Every PR gets ≥2 cold-start reviewers (Bug Hunter + Behavior Reviewer).
- **Evidence pack per Issue.** docs/evidence/\`<id>\`/ holds change-summary, test-results, screenshots, review-report.md.
- **Compact report (v1.2.0+).** After each Owner Agent finishes, a compact-report.json summarises the work for the Coordinator.
- **Context bundle (v1.2.0+).** Coordinator dumps docs/evidence/\`<id>\`/context-bundle.md once per Issue so sub-agents don't each re-explore.
- **SessionStart hook (v1.1.0+).** Host-level Claude Code hook reads .claude/SESSION.md if it exists. Optional — install with scripts/install-session-hook.sh.

To update the harness: run \`npx -y skills update lora-sys/ai-engineering-harness -g\` and then \`bash scripts/sync-project.sh --apply\` in this project.
BLOCK
)
  set_fenced "$agents_file" "harness-capabilities" "$content"
}

# Migration 4: back-fill compact-report.json for each existing evidence/<id>/
mig_backfill_compact_reports_describe() {
  echo "back-fill compact-report.json in existing docs/evidence/<id>/ dirs (v1.2.0+)"
}
mig_backfill_compact_reports_apply() {
  if [[ ! -d "$PROJECT_DIR/docs/evidence" ]]; then
    return 0
  fi
  local d
  for d in "$PROJECT_DIR/docs/evidence"/*/; do
    [[ -d "$d" ]] || continue
    if [[ -f "$d/compact-report.json" ]]; then
      continue  # never overwrite
    fi
    if [[ ! -f "$d/implementation-report.md" ]]; then
      continue  # nothing to summarise
    fi
    # Auto-detect branch / agent from implementation-report.md front matter if present.
    local branch="unknown" agent="unknown"
    if [[ -f "$d/implementation-report.md" ]]; then
      branch=$(grep -m1 -oE 'branch:[[:space:]]*[a-zA-Z0-9/_.-]+' "$d/implementation-report.md" 2>/dev/null | head -1 | sed 's/branch:[[:space:]]*//' || echo "unknown")
      agent=$(grep -m1 -oE 'agent:[[:space:]]*[a-zA-Z0-9_-]+' "$d/implementation-report.md" 2>/dev/null | head -1 | sed 's/agent:[[:space:]]*//' || echo "unknown")
    fi
    # Best-effort back-fill: skip silently on failure (don't break sync).
    if [[ -x "$HARNESS_REPO/scripts/compact-report.sh" ]]; then
      bash "$HARNESS_REPO/scripts/compact-report.sh" \
        --evidence-dir "$d" \
        --branch "$branch" \
        --agent "$agent" >/dev/null 2>&1 || true
    fi
  done
}

# ─── Migration table ─────────────────────────────────────────────────────
# Each entry: "describe_fn|apply_fn"
# describe/apply take (from_v, to_v) and return 0 on success.

MIGRATIONS=(
  "mig_state_file_describe|mig_state_file_apply"
  "mig_github_templates_describe|mig_github_templates_apply"
  "mig_agents_capabilities_describe|mig_agents_capabilities_apply"
  "mig_backfill_compact_reports_describe|mig_backfill_compact_reports_apply"
)

# ─── Main ──────────────────────────────────────────────────────────────
main() {
  detect_project
  local from_v
  from_v="$(read_state)"

  case "$ACTION" in
    status)
      echo "Project:    $PROJECT_DIR"
      echo "Harness:    $HARNESS_VERSION (this repo)"
      echo "Project at: $from_v"
      if [[ "$from_v" != "$HARNESS_VERSION" ]]; then
        echo "Drift:      project is at v$from_v, harness is at v$HARNESS_VERSION"
        echo
        echo "Run 'scripts/sync-project.sh' (dry-run) to see the migration plan,"
        echo "or 'scripts/sync-project.sh --apply' to apply it."
      else
        echo "Status:     in sync"
      fi
      return 0
      ;;
  esac

  echo "Project:  $PROJECT_DIR"
  echo "From:     v$from_v"
  echo "To:       v$HARNESS_VERSION"
  echo "Mode:     $ACTION"
  echo
  echo "Migration plan:"
  echo "─────────────────────────────────────────────────────────────────────"
  local i=1
  for m in "${MIGRATIONS[@]}"; do
    local describe_fn="${m%|*}"
    local apply_fn="${m#*|}"
    local desc
    desc="$($describe_fn "$from_v" "$HARNESS_VERSION")"
    printf "  %d. %s\n" "$i" "$desc"
    i=$((i+1))
  done
  echo "─────────────────────────────────────────────────────────────────────"

  if [[ "$ACTION" == "plan" ]]; then
    echo
    echo "(dry-run; pass --apply to actually run these)"
    return 0
  fi

  echo
  echo "Applying..."
  local failed=0
  for m in "${MIGRATIONS[@]}"; do
    local describe_fn="${m%|*}"
    local apply_fn="${m#*|}"
    local desc
    desc="$($describe_fn "$from_v" "$HARNESS_VERSION")"
    printf "  → %s ... " "$desc"
    if "$apply_fn" "$from_v" "$HARNESS_VERSION"; then
      echo "ok"
    else
      echo "FAILED"
      failed=$((failed+1))
    fi
  done

  if [[ $failed -gt 0 ]]; then
    log "$failed migration(s) failed"
    return 1
  fi
  echo
  echo "Done. Project now at v$HARNESS_VERSION."
  echo "(backup of any pre-existing .harness-state.json saved at .harness-state.json.bak)"
}

main
