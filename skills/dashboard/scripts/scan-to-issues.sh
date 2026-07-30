#!/usr/bin/env bash
# scripts/scan-to-issues.sh — turn Quick Scan findings into trackable Issues
# Called by workflows/03-quick-scan.md, and by the takeover path in
# workflows/00-project-bootstrap.md.
#
# Groups vibe-signs findings by category (one Issue per category, not per
# finding — 40 separate Issues for 40 TODOs is noise, not a backlog) and
# either prints the drafts or files them with `gh`.
#
# Usage:
#   bash scan-to-issues.sh                 # dry run: print drafts, file nothing
#   bash scan-to-issues.sh --create        # actually file the Issues
#   bash scan-to-issues.sh --min-severity medium
#   bash scan-to-issues.sh --project /path/to/repo
#
# Dry run is the default on purpose: filing Issues writes to a shared tracker,
# so it takes an explicit --create.
set -uo pipefail

CREATE=0
MIN_SEVERITY="low"
TARGET="$(pwd)"
PORT="${DASHBOARD_PORT:-4321}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --create) CREATE=1; shift ;;
    --min-severity)
      MIN_SEVERITY="${2:-low}"
      shift 2 ;;
    --project)
      TARGET="${2:-$(pwd)}"
      shift 2 ;;
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "Error: unknown argument: $1" >&2
      echo "Usage: $0 [--create] [--min-severity low|medium|high] [--project DIR]" >&2
      exit 1 ;;
  esac
done

case "$MIN_SEVERITY" in
  low|medium|high|critical) ;;
  *) echo "Error: --min-severity must be low, medium, high, or critical" >&2; exit 1 ;;
esac

if [[ ! -d "$TARGET" ]]; then
  echo "Error: not a directory: $TARGET" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js is required but not installed." >&2
  exit 1
fi

PARSER="$TARGET/.dashboard/parser.js"
if [[ ! -f "$PARSER" ]]; then
  echo "Error: $PARSER not found. Run: \$dashboard. Bootstrap." >&2
  exit 1
fi

# Canonical target path, to compare against whatever a server reports. On macOS
# /tmp is a symlink to /private/tmp, so compare resolved paths or every check
# fails spuriously.
TARGET_REAL="$(cd "$TARGET" && pwd -P)"

# Reuse a running dashboard if there is one; otherwise start a throwaway server
# on a scratch port and stop it on the way out. Either way the caller doesn't
# have to have remembered to start anything.
SCAN_JSON=""
STARTED_PID=""
SCRATCH_PORT=""
PREEXISTING=""

# Kill the scratch server on the way out.
#
# Both of these bit during testing:
#  1. `$!` is not reliably node's PID — bash sometimes forks again for the
#     redirections, so killing `$!` leaves node running. It then reparents to
#     init and answers a *later* run with the wrong project's data.
#  2. A plain `kill` returns before the process is gone, and a port sweep run
#     the instant we exit finds nothing if node has not bound yet — it binds a
#     moment later and survives.
#
# So the real PID is resolved at startup from whoever holds the port (see
# below), and here we kill it and then wait for the port to actually go quiet,
# sweeping any straggler. Bounded: a cleanup that hangs is worse than a stray.
cleanup() {
  [[ -n "$STARTED_PID" ]] && kill "$STARTED_PID" 2>/dev/null
  [[ -z "$SCRATCH_PORT" ]] && return 0
  command -v lsof >/dev/null 2>&1 || return 0

  local holders attempt quiet=0 pid
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    holders="$(lsof -tiTCP:"$SCRATCH_PORT" -sTCP:LISTEN 2>/dev/null || true)"
    # Never kill a process that already held the port before we started — that
    # is somebody else's server, and we only failed to bind because of it.
    for pid in $PREEXISTING; do
      holders="$(printf '%s\n' $holders | grep -vx "$pid" || true)"
    done
    if [[ -n "$holders" ]]; then
      quiet=0
      for pid in $holders; do
        kill "$pid" 2>/dev/null || true
      done
    else
      # Two consecutive quiet reads, not one: a single empty result also
      # happens in the window before a starting node binds.
      quiet=$((quiet + 1))
      [[ "$quiet" -ge 2 ]] && return 0
    fi
    sleep 0.3
  done
  return 0
}
trap cleanup EXIT

# Only accept a response that is actually about $TARGET. A dashboard left
# running for another project — or a stale scratch server on the port we were
# about to use — otherwise reports that project's findings as if they were
# this one's, and we file Issues against the wrong repo.
fetch_scan() {
  local port="$1" body
  body="$(curl -sf --max-time 60 "http://localhost:$port/api/quick-scan" 2>/dev/null)" || return 1
  [[ -z "$body" ]] && return 1
  printf '%s' "$body" | TARGET_REAL="$TARGET_REAL" node -e '
    let raw = ""; process.stdin.on("data", d => raw += d);
    process.stdin.on("end", () => {
      let scan; try { scan = JSON.parse(raw); } catch { process.exit(1); }
      const root = scan && scan._meta && scan._meta.projectRoot;
      const fs = require("fs");
      const same = (a, b) => { try { return fs.realpathSync(a) === fs.realpathSync(b); } catch { return a === b; } };
      if (!root || !same(root, process.env.TARGET_REAL)) process.exit(1);
      process.stdout.write(raw);
    });
  ' 2>/dev/null
}

SCAN_JSON="$(fetch_scan "$PORT")" || SCAN_JSON=""

if [[ -z "$SCAN_JSON" ]]; then
  SCRATCH_PORT=$((PORT + 1000))
  # Snapshot the port's current occupants before we touch it, so cleanup can
  # tell our own server apart from someone else's.
  if command -v lsof >/dev/null 2>&1; then
    PREEXISTING="$(lsof -tiTCP:"$SCRATCH_PORT" -sTCP:LISTEN 2>/dev/null | tr '\n' ' ' || true)"
  fi
  # parser.js resolves its project root from cwd, so cd first and cd back.
  OLD_PWD_SCAN="$(pwd)"
  cd "$TARGET/.dashboard" || exit 1
  PORT="$SCRATCH_PORT" node parser.js >/dev/null 2>&1 &
  STARTED_PID=$!
  cd "$OLD_PWD_SCAN" || exit 1
  # Poll rather than sleep-and-hope; a cold Node start is usually well under 1s
  # but a large repo scan can push the first response out further.
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    SCAN_JSON="$(fetch_scan "$SCRATCH_PORT")" || SCAN_JSON=""
    if [[ -n "$SCAN_JSON" ]]; then
      # It answered, so it is bound: whoever holds the port is the process we
      # actually have to kill. Trust that over `$!`, which may be a bash fork
      # that has already exited.
      if command -v lsof >/dev/null 2>&1; then
        REAL_PID="$(lsof -tiTCP:"$SCRATCH_PORT" -sTCP:LISTEN 2>/dev/null | head -1 || true)"
        [[ -n "$REAL_PID" ]] && STARTED_PID="$REAL_PID"
      fi
      break
    fi
    kill -0 "$STARTED_PID" 2>/dev/null || break  # server died (e.g. port in use)
    sleep 0.5
  done
fi

if [[ -z "$SCAN_JSON" ]]; then
  echo "Error: could not get a Quick Scan for $TARGET_REAL." >&2
  echo "Tried port $PORT and scratch port $((PORT + 1000))." >&2
  echo "If another project's dashboard is on those ports, set DASHBOARD_PORT to a free one." >&2
  exit 1
fi

# Group findings into per-category Issue drafts. Node does the JSON work — it's
# already a dependency here, and jq often isn't installed.
DRAFTS="$(printf '%s' "$SCAN_JSON" | node -e '
const RANK = { low: 0, medium: 1, high: 2, critical: 3 };
const min = RANK[process.argv[1]] ?? 0;

let raw = "";
process.stdin.on("data", d => raw += d);
process.stdin.on("end", () => {
  let scan;
  try { scan = JSON.parse(raw); } catch { console.error("Error: bad JSON from /api/quick-scan"); process.exit(1); }

  const issues = (scan.issues || []).filter(i => (RANK[i.severity] ?? 0) >= min);
  if (issues.length === 0) {
    console.log("__NO_FINDINGS__");
    return;
  }

  const byCategory = new Map();
  for (const i of issues) {
    if (!byCategory.has(i.category)) byCategory.set(i.category, []);
    byCategory.get(i.category).push(i);
  }

  // Worst-first, so the HIGH security Issue is the one the reader sees first.
  const worst = list => Math.max(...list.map(i => RANK[i.severity] ?? 0));
  const ordered = [...byCategory.entries()].sort((a, b) => worst(b[1]) - worst(a[1]));

  const LABEL = { security: "security", reliability: "bug", testing: "testing",
    duplication: "refactor", "code-hygiene": "chore", "style-drift": "chore",
    "dead-code": "refactor", "intent-mismatch": "docs" };

  const out = [];
  for (const [category, list] of ordered) {
    const sev = Object.keys(RANK).find(k => RANK[k] === worst(list)) || "low";
    const title = `vibe-signs: ${category} — ${list.length} finding${list.length === 1 ? "" : "s"}`;
    const lines = [];
    lines.push(`Found by Quick Scan (\`/api/quick-scan\`) on ${scan.filesScanned} source file(s).`);
    lines.push("");
    lines.push(`Chaos score at time of scan: **${scan.chaosScore}/100 (grade ${scan.grade})**`);
    lines.push("");
    lines.push("## Findings");
    lines.push("");
    lines.push("| Severity | Location | Detail |");
    lines.push("|----------|----------|--------|");
    for (const i of list) {
      const loc = i.file ? (i.line ? `\`${i.file}:${i.line}\`` : `\`${i.file}\``) : "—";
      lines.push(`| ${i.severity.toUpperCase()} | ${loc} | ${i.description} |`);
    }
    lines.push("");
    lines.push("## Acceptance criteria");
    lines.push("");
    lines.push("- [ ] Every finding above is either fixed or explicitly waived in a comment here");
    lines.push("- [ ] A re-run of Quick Scan reports zero `" + category + "` findings");
    lines.push("- [ ] Evidence recorded under `docs/evidence/<issue-id>/`");
    lines.push("");
    lines.push("<sub>Filed by `scan-to-issues.sh`. Detector list: `skills/dashboard/workflows/03-quick-scan.md`.</sub>");

    out.push(JSON.stringify({ title, body: lines.join("\n"), label: LABEL[category] || "chore", severity: sev, count: list.length }));
  }
  console.log(out.join("\n"));
});
' "$MIN_SEVERITY")"

if [[ -z "$DRAFTS" ]]; then
  echo "Error: failed to build Issue drafts from scan output." >&2
  exit 1
fi

if [[ "$DRAFTS" == "__NO_FINDINGS__" ]]; then
  echo "No findings at or above severity '$MIN_SEVERITY'. Nothing to file."
  exit 0
fi

DRAFT_COUNT="$(printf '%s\n' "$DRAFTS" | grep -c '^{' || true)"

if [[ "$CREATE" -eq 0 ]]; then
  echo "════════════════════════════════════════════════════════════"
  echo " Quick Scan → Issue drafts (DRY RUN — nothing filed)"
  echo "════════════════════════════════════════════════════════════"
  echo
  printf '%s\n' "$DRAFTS" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    printf '%s' "$line" | node -e '
      let raw = ""; process.stdin.on("data", d => raw += d);
      process.stdin.on("end", () => {
        const d = JSON.parse(raw);
        console.log("── " + d.title + "  [label: " + d.label + "]");
        console.log(d.body.split("\n").map(l => "   " + l).join("\n"));
        console.log("");
      });
    '
  done
  echo "════════════════════════════════════════════════════════════"
  echo "$DRAFT_COUNT Issue(s) would be filed. To file them:"
  echo "  bash $0 --create"
  exit 0
fi

# --create from here on.
if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI is required for --create. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

# Existing open titles, so re-running doesn't pile up duplicates.
EXISTING="$(gh issue list --state open --limit 200 --json title \
  --jq '.[].title' 2>/dev/null || true)"

printf '%s\n' "$DRAFTS" | while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  TITLE="$(printf '%s' "$line" | node -e 'let r="";process.stdin.on("data",d=>r+=d);process.stdin.on("end",()=>process.stdout.write(JSON.parse(r).title))')"
  LABEL="$(printf '%s' "$line" | node -e 'let r="";process.stdin.on("data",d=>r+=d);process.stdin.on("end",()=>process.stdout.write(JSON.parse(r).label))')"

  if printf '%s\n' "$EXISTING" | grep -Fqx "$TITLE" 2>/dev/null; then
    echo "  = skipped (already open): $TITLE"
    continue
  fi

  BODY_FILE="$(mktemp -t vibe-issue)"
  printf '%s' "$line" | node -e 'let r="";process.stdin.on("data",d=>r+=d);process.stdin.on("end",()=>process.stdout.write(JSON.parse(r).body))' > "$BODY_FILE"

  # Label may not exist in the repo; fall back to filing without one rather
  # than losing the Issue.
  if gh issue create --title "$TITLE" --body-file "$BODY_FILE" --label "$LABEL" >/dev/null 2>&1; then
    echo "  ✓ filed [$LABEL]: $TITLE"
  elif gh issue create --title "$TITLE" --body-file "$BODY_FILE" >/dev/null 2>&1; then
    echo "  ✓ filed (no label): $TITLE"
  else
    echo "  ✗ failed: $TITLE" >&2
  fi
  rm -f "$BODY_FILE"
done

echo
echo "Done. Review with: gh issue list --state open"
