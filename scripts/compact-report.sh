#!/usr/bin/env bash
# scripts/compact-report.sh
#
# Compress a sub-agent's free-form output into a single structured JSON report
# for the parent Coordinator to consume. The original implementation-report.md
# stays in docs/evidence/<id>/; this script produces the *summary* the
# parent actually needs to decide "advance to Phase N+1" or "loop back".
#
# Required input:
#   --evidence-dir <path>   Path to docs/evidence/<id>/ containing:
#                             - implementation-report.md  (free-form sub-agent output)
#                             - test-results/            (test output files, optional)
#                             - screenshots/             (screenshots, optional)
#                             - any other evidence files
#   --branch <name>         The branch the sub-agent worked on (required).
#   --commit <sha>          The HEAD commit the sub-agent pushed (optional;
#                           auto-detected from current HEAD if omitted).
#   --agent <name>          Which agent produced the report (e.g., 'frontend',
#                           'backend', 'qa'). Required.
#   --files-changed <n>     Override file count (otherwise auto-counted via
#                           git diff --name-only base..HEAD).
#   --test <status>         Test result: pass | fail | skipped. Auto-detected
#                           from test-results/ if omitted.
#   --blocker <text>        Add a blocker (can be passed multiple times).
#
# Output:
#   Writes the structured report to <evidence-dir>/compact-report.json
#   Prints the same JSON to stdout.
#   Exit 0 on success; non-zero on missing required inputs.
#
# Example:
#   scripts/compact-report.sh \
#     --evidence-dir docs/evidence/42 \
#     --branch feature/42-ci-gate \
#     --agent backend \
#     --blocker "needs review from security-reviewer"
#
# Output JSON shape:
#   {
#     "agent": "backend",
#     "branch": "feature/42-ci-gate",
#     "commit": "5a65b7a...",
#     "files": 7,
#     "test": "pass",
#     "blockers": ["..."],
#     "evidence_paths": [...],
#     "evidence_size_bytes": 12345,
#     "report_md": "implementation-report.md",
#     "generated_at": "2026-07-13T..."
#   }

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

EVIDENCE_DIR=""
BRANCH=""
COMMIT=""
AGENT=""
FILES_CHANGED_OVERRIDE=""
TEST_STATUS=""
BLOCKERS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence-dir=*) EVIDENCE_DIR="${1#--evidence-dir=}" ;;
    --evidence-dir)   shift; EVIDENCE_DIR="${1:-}" ;;
    --branch=*)       BRANCH="${1#--branch=}" ;;
    --branch)         shift; BRANCH="${1:-}" ;;
    --commit=*)       COMMIT="${1#--commit=}" ;;
    --commit)         shift; COMMIT="${1:-}" ;;
    --agent=*)        AGENT="${1#--agent=}" ;;
    --agent)          shift; AGENT="${1:-}" ;;
    --files-changed=*)FILES_CHANGED_OVERRIDE="${1#--files-changed=}" ;;
    --files-changed)  shift; FILES_CHANGED_OVERRIDE="${1:-}" ;;
    --test=*)         TEST_STATUS="${1#--test=}" ;;
    --test)           shift; TEST_STATUS="${1:-}" ;;
    --blocker=*)      BLOCKERS+=("${1#--blocker=}") ;;
    --blocker)        shift; BLOCKERS+=("${1:-}") ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)   echo "unexpected positional arg: $1" >&2; exit 2 ;;
  esac
  shift
done

log()  { printf '[compact-report] %s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

# Validate required inputs.
[[ -n "$EVIDENCE_DIR" ]] || fail "--evidence-dir is required"
[[ -n "$BRANCH"       ]] || fail "--branch is required"
[[ -n "$AGENT"        ]] || fail "--agent is required"
[[ -d "$EVIDENCE_DIR" ]] || fail "evidence dir not found: $EVIDENCE_DIR"

cd "$REPO_DIR"

# Auto-detect commit if not provided.
if [[ -z "$COMMIT" ]]; then
  COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

# Auto-detect file count.
if [[ -n "$FILES_CHANGED_OVERRIDE" ]]; then
  FILES_CHANGED="$FILES_CHANGED_OVERRIDE"
else
  base="origin/main"
  if ! git rev-parse --verify "$base" >/dev/null 2>&1; then
    base="main"
  fi
  if git rev-parse --verify "$base" >/dev/null 2>&1; then
    FILES_CHANGED="$(git diff --name-only "$base"...HEAD 2>/dev/null | wc -l | tr -d ' ')"
  else
    FILES_CHANGED="$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')"
  fi
fi

# Auto-detect test status from test-results/ if not provided.
# Decision order: any FAIL → fail; else any PASS → pass; else unknown.
if [[ -z "$TEST_STATUS" ]]; then
  if compgen -G "$EVIDENCE_DIR/test-results/*" >/dev/null; then
    fail_found=0
    pass_found=0
    while IFS= read -r -d "" f; do
      if grep -qiE "FAIL|ERROR|failed|tests failed" "$f" 2>/dev/null; then
        fail_found=1
      fi
      if grep -qiE "PASS|OK|passed|all tests pass" "$f" 2>/dev/null; then
        pass_found=1
      fi
    done < <(find "$EVIDENCE_DIR/test-results/" -type f -print0 2>/dev/null)
    if [[ $fail_found -eq 1 ]]; then
      TEST_STATUS="fail"
    elif [[ $pass_found -eq 1 ]]; then
      TEST_STATUS="pass"
    else
      TEST_STATUS="unknown"
    fi
  else
    TEST_STATUS="skipped"
  fi
fi

# Collect evidence paths (relative to EVIDENCE_DIR — not repo root, since
# evidence dirs can live outside the repo when the harness is invoked
# against an external project).
EVIDENCE_PATHS=()
EVIDENCE_SIZE=0
if [[ -d "$EVIDENCE_DIR" ]]; then
  while IFS= read -r -d '' f; do
    # Make path relative to EVIDENCE_DIR.
    case "$f" in
      "$EVIDENCE_DIR"/*) rel="${f#"$EVIDENCE_DIR"/}" ;;
      *) rel="$f" ;;
    esac
    EVIDENCE_PATHS+=("$rel")
    sz=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
    EVIDENCE_SIZE=$((EVIDENCE_SIZE + ${sz:-0}))
  done < <(find "$EVIDENCE_DIR" -type f -print0 2>/dev/null)
fi

REPORT_MD="implementation-report.md"
[[ ! -f "$EVIDENCE_DIR/$REPORT_MD" ]] && REPORT_MD=""

GENERATED_AT="$(date -Iseconds)"

# Build JSON via Python (avoids escape hell).
BLOCKERS_JSON="$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1:]))' "${BLOCKERS[@]+"${BLOCKERS[@]}"}")"
EVIDENCE_PATHS_JSON="$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1:]))' "${EVIDENCE_PATHS[@]+"${EVIDENCE_PATHS[@]}"}")"

JSON="$(BLOCKERS_JSON="$BLOCKERS_JSON" \
        EVIDENCE_PATHS_JSON="$EVIDENCE_PATHS_JSON" \
        EVIDENCE_SIZE="$EVIDENCE_SIZE" \
        REPORT_MD_NAME="$REPORT_MD" \
        python3 - "$EVIDENCE_DIR" "$BRANCH" "$COMMIT" "$AGENT" "$FILES_CHANGED" "$TEST_STATUS" "$GENERATED_AT" <<'PY'
import json, sys, os

(evidence_dir, branch, commit, agent, files_changed, test_status, generated_at) = sys.argv[1:8]

try:
    blockers = json.loads(os.environ.get("BLOCKERS_JSON", "[]"))
except Exception:
    blockers = []
try:
    evidence_paths = json.loads(os.environ.get("EVIDENCE_PATHS_JSON", "[]"))
except Exception:
    evidence_paths = []

evidence_size = int(os.environ.get("EVIDENCE_SIZE", "0"))
report_md = os.environ.get("REPORT_MD_NAME", "implementation-report.md")

report = {
    "agent": agent,
    "branch": branch,
    "commit": commit,
    "files": int(files_changed),
    "test": test_status,
    "blockers": blockers,
    "evidence_paths": evidence_paths,
    "evidence_size_bytes": evidence_size,
    "report_md": report_md,
    "generated_at": generated_at,
}
print(json.dumps(report, indent=2, ensure_ascii=False))
PY
)"

if [[ -z "$JSON" ]]; then
  fail "Python JSON emission returned empty"
fi

# Write to evidence dir.
OUT="$EVIDENCE_DIR/compact-report.json"
printf '%s\n' "$JSON" > "$OUT"
log "wrote $OUT"

# Also print to stdout so the calling shell can pipe it.
printf '%s\n' "$JSON"
