#!/usr/bin/env bash
# tests/skill-benchmark/run-test.sh — skill-level benchmark (eval layer 4)
#
# For each fixture project, exercise the harness's automation scripts and
# verify the output matches the expected checkpoints. Runs in a sandboxed
# tempdir (no real project state is touched).
#
# Usage:
#   tests/skill-benchmark/run-test.sh              # all fixtures
#   tests/skill-benchmark/run-test.sh --dry-run   # validate fixtures only

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIX="$SCRIPT_DIR/fixtures"
SYNC="$REPO_DIR/scripts/sync-project.sh"
HEAD_VERSION="$(python3 -c "import json; print(json.load(open('$REPO_DIR/meta.json'))['version'])")"

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

# Sanity: script exists
[[ -f "$SYNC" ]] || { echo "FAIL: sync-project.sh not at $SYNC" >&2; exit 1; }

pass=0
fail=0
fixtures_processed=0

for fixture_dir in "$FIX"/*/; do
  [[ -d "$fixture_dir" ]] || continue
  fixture="$(basename "$fixture_dir")"
  fixtures_processed=$((fixtures_processed + 1))

  if [[ $DRY_RUN -eq 1 ]]; then
    # Validate fixture has an AGENTS.md
    if [[ -f "$fixture_dir/AGENTS.md" ]]; then
      echo "  ok    $fixture (AGENTS.md present)"
      pass=$((pass+1))
    else
      echo "  FAIL  $fixture (no AGENTS.md)"
      fail=$((fail+1))
    fi
    continue
  fi

  # Set up a sandbox
  SANDBOX="$(mktemp -d)"
  trap "rm -rf '$SANDBOX'" EXIT
  cp -r "$fixture_dir/." "$SANDBOX/"

  # Run the harness automation
  HARNESS_REPO="$REPO_DIR" bash "$SYNC" --project-dir "$SANDBOX" --auto 2>/dev/null
  rc=$?

  # Verify checkpoints via Python
  output=$(CHECKPOINTS_DIR="$SANDBOX" EXPECTED_VERSION="$HEAD_VERSION" \
              FIXTURE_NAME="$fixture" \
              python3 - "$fixture_dir" "$HEAD_VERSION" <<'PYEOF'
import os, json, sys, re

fixture_dir = sys.argv[1]
expected_version = sys.argv[2]
sandbox = os.environ['CHECKPOINTS_DIR']
name = os.environ['FIXTURE_NAME']

errs = []
oks = []

def add_err(check, msg):
    errs.append(f"  {check}: {msg}")
def add_ok(check, msg):
    oks.append(f"  {check}: {msg}")

# Common check: state file
import pathlib
state = pathlib.Path(sandbox) / ".harness-state.json"
if not state.exists():
    add_err("state-file", "missing")
else:
    try:
        d = json.loads(state.read_text())
    except Exception as e:
        add_err("state-file", f"JSON parse: {e}")
        d = None
    if d:
        if d.get("version") == expected_version:
            add_ok("state-file", f"version={d['version']} (matches HEAD)")
        else:
            add_err("state-file", f"version={d.get('version')} != {expected_version}")

# Common check: fenced block
agents = pathlib.Path(sandbox) / "AGENTS.md"
if agents.exists():
    text = agents.read_text()
    if re.search(r"<!-- HARNESS:START harness-capabilities -->\n.*<!-- HARNESS:END harness-capabilities -->",
                  text, re.DOTALL):
        add_ok("fenced-block", "HARNESS:START/END harness-capabilities present")
    else:
        add_err("fenced-block", "missing HARNESS:START harness-capabilities / END pair")

# Per-fixture expected checkpoints
expected_path = pathlib.Path(fixture_dir) / "expected.json"
if expected_path.exists():
    expected = json.loads(expected_path.read_text())
    for check, expect in expected.items():
        if check == "user-content-preserved":
            # Verify the user content from the fixture's AGENTS.md is still in the sandbox AGENTS.md
            orig = (pathlib.Path(fixture_dir) / "AGENTS.md").read_text()
            for user_block in expect.get("must-contain", []):
                if user_block in text:
                    add_ok(f"user-content:{user_block[:30]}", "preserved")
                else:
                    add_err(f"user-content:{user_block[:30]}", "NOT in sandbox AGENTS.md")
        elif check == "fenced-block-content":
            m = re.search(r"<!-- HARNESS:START harness-capabilities -->\n(.*?)<!-- HARNESS:END harness-capabilities -->",
                          text, re.DOTALL)
            if m and expect.get("must-contain-in-fence"):
                for snippet in expect["must-contain-in-fence"]:
                    if snippet in m.group(1):
                        add_ok(f"fence-content:{snippet[:30]}", "present")
                    else:
                        add_err(f"fence-content:{snippet[:30]}", "NOT in fence block")
        elif check == "compact-report-backfilled":
            # At least one docs/evidence/<id>/ should have a compact-report.json
            evidence_dirs = list(pathlib.Path(sandbox).glob("docs/evidence/*/"))
            for ed in evidence_dirs:
                if not (ed / "implementation-report.md").exists():
                    continue
                if (ed / "compact-report.json").exists():
                    add_ok(f"compact-report", f"back-filled in {ed.name}")
                else:
                    add_err(f"compact-report", f"missing in {ed.name}")
        elif check == "compact-report-not-overwritten":
            evidence_dirs = list(pathlib.Path(sandbox).glob("docs/evidence/*/"))
            for ed in evidence_dirs:
                if (ed / "compact-report.json").exists():
                    try:
                        d = json.loads((ed / "compact-report.json").read_text())
                        if d.get("_benchmark_marker") == "DO_NOT_OVERWRITE":
                            add_ok(f"compact-report-preserve", f"{ed.name} has marker preserved")
                        else:
                            add_err(f"compact-report-preserve", f"{ed.name} lost marker")
                    except Exception as e:
                        add_err(f"compact-report-preserve", f"{ed.name}: {e}")

# Per-fixture initial-state expectations
if "fresh-project" in name or "needs-backfill" in name or "pre-v14" in name:
    # State file should be NEW (bootstrapped_at == today's date)
    if state.exists():
        d = json.loads(state.read_text())
        if d.get("bootstrapped_at", "").startswith("2026-07-15") or d.get("last_synced_at", "").startswith("2026-07-15"):
            add_ok("fresh-state", f"bootstrapped today")
        else:
            # Date may differ; just check the field exists
            if d.get("bootstrapped_at"):
                add_ok("fresh-state", f"bootstrapped_at={d['bootstrapped_at'][:10]}")
if "v16-project" in name:
    # State file should be UPDATED (not fresh)
    if state.exists():
        d = json.loads(state.read_text())
        if d.get("version") == expected_version:
            add_ok("v16-upgrade", f"upgraded to {expected_version}")

for o in oks:
    print(o)
for e in errs:
    print(e)
if errs:
    print("FAIL")
else:
    print("PASS")
PYEOF
)

  if echo "$output" | grep -q "^FAIL$"; then
    echo "  FAIL  $fixture"
    fail=$((fail+1))
  else
    echo "$output" | sed 's/^/  /'
    echo "  ok    $fixture"
    pass=$((pass+1))
  fi
  rm -rf "$SANDBOX"
done

echo
echo "[skill-benchmark] $pass passed, $fail failed ($fixtures_processed fixtures total)"
exit $fail
