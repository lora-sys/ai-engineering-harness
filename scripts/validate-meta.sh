#!/usr/bin/env bash
# Validate the skill's meta.json against the embedded schema.
#
# Usage:
#   scripts/validate-meta.sh                  # validates ./meta.json
#   scripts/validate-meta.sh <path>           # validates a specific file
#   scripts/validate-meta.sh --strict        # also fail on warnings (unknown fields, version drift, etc.)
#   scripts/validate-meta.sh --json          # print a JSON line on stdout (for CI)
#
# Exit codes:
#   0  OK (no errors; warnings are tolerated unless --strict)
#   1  schema errors (one or more fields fail validation)
#   2  file missing / unreadable / not valid JSON
#   3  tool (python3) missing
#   4  validator internal error (Python exception)

set -uo pipefail

# Resolve script location and cd to repo root (parent of scripts/).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

PATH_ARG=""
STRICT=0
JSON_OUT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    --json)   JSON_OUT=1 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $arg" >&2; exit 1 ;;
    *)   PATH_ARG="$arg" ;;
  esac
done

HAS_ERRS=0
HAS_WARNS=0

# Family walk: when no file arg given, validate every meta.json in this repo.
if [[ -z "$PATH_ARG" ]]; then
  echo "Family walk:"
  ok=0; failed=0
  for f in ./meta.json skills/*/meta.json; do
    [[ -f "$f" ]] || continue
    echo "── $f ──"
    if "$0" "$f" 2>&1; then ok=$((ok+1)); else failed=$((failed+1)); fi
  done
  echo
  echo "Summary: $ok passed, $failed failed"
  [[ $failed -eq 0 ]] && exit 0 || exit 1
fi

FILE="${PATH_ARG:-./meta.json}"


if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found in PATH" >&2
  exit 3
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: file not found: $FILE" >&2
  [[ $JSON_OUT -eq 1 ]] && printf '{"file":"%s","ok":false,"internal_error":true}\n' "$FILE"
  exit 2
fi

# Run validator. Capture JSON line. Surface stderr only if validator failed.
RESULT=$(python3 - "$FILE" <<'PY'
import json, re, os, sys, traceback

def main(path):
    data = json.load(open(path))
    errs, warns = [], []

    def err(field, msg):  errs.append(f"{field}: {msg}")
    def warn(field, msg): warns.append(f"{field}: {msg}")

    REQUIRED = ["id", "version", "name", "description", "category", "priority", "tags",
                "install", "license", "repository", "entry"]

    for k in REQUIRED:
        if k not in data:
            err(k, "missing required field")

    for k in ("id", "name", "description", "category", "license", "repository", "entry"):
        if k in data and not isinstance(data[k], str):
            err(k, f"expected string, got {type(data[k]).__name__}")

    if "version" in data and isinstance(data["version"], str):
        if not re.match(r"^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$", data["version"]):
            err("version", f"{data['version']!r} is not valid semver (e.g., 1.0.2)")

    if "priority" in data and not isinstance(data["priority"], int):
        err("priority", f"expected int, got {type(data['priority']).__name__}")

    if "tags" in data:
        if not isinstance(data["tags"], list):
            err("tags", "expected array")
        else:
            for i, t in enumerate(data["tags"]):
                if not isinstance(t, str):
                    err(f"tags[{i}]", f"expected string, got {type(t).__name__}")
            if len(data["tags"]) > 12:
                warn("tags", f"{len(data['tags'])} tags is a lot; indexes usually pick top 5-8")

    if "install" in data:
        if not isinstance(data["install"], dict):
            err("install", "expected object")
        else:
            for k, v in data["install"].items():
                if not isinstance(v, str):
                    err(f"install.{k}", f"expected string, got {type(v).__name__}")

    if "id" in data and isinstance(data["id"], str):
        if not re.match(r"^[a-z0-9][a-z0-9-]{0,63}$", data["id"]):
            err("id", "must be kebab-case, 1-64 chars, lowercase, ASCII only")

    if "description" in data and isinstance(data["description"], str):
        n = len(data["description"])
        if n < 40:
            warn("description", f"only {n} chars; agents often need 60-160 to decide routing")
        if n > 300:
            warn("description", f"{n} chars exceeds typical 300-char cap of skill indexes")

    if "priority" in data and isinstance(data["priority"], int):
        if not 0 <= data["priority"] <= 100:
            err("priority", f"{data['priority']} out of range [0, 100]")

    if "license" in data and isinstance(data["license"], str):
        if not re.match(r"^[A-Z][A-Z0-9.+-]{1,15}(-[A-Z0-9.+-]+)?$", data["license"]):
            warn("license", f"{data['license']!r} doesn't look like an SPDX identifier")

    if "repository" in data and isinstance(data["repository"], str):
        if not data["repository"].startswith(("https://", "http://", "git@")):
            err("repository", "must be an https/http URL or git@ URL")

    if "version" in data and isinstance(data["version"], str):
        try:
            import subprocess
            tags = subprocess.check_output(["git", "tag", "--sort=-v:refname",
                                            "--format=%(refname:short)"],
                                           stderr=subprocess.DEVNULL).decode().splitlines()
            semver_tags = [t for t in tags if re.match(r"^v[0-9]+\.[0-9]+\.[0-9]+$", t)]
            if semver_tags:
                latest = semver_tags[0]  # e.g. "v1.0.4"
                # If HEAD is exactly at a tagged commit, compare to that tag
                # (handles the "checked out older tag" case cleanly).
                # Otherwise compare to the latest tag (the "haven't released yet" case).
                try:
                    head_tag = subprocess.check_output(
                        ["git", "describe", "--tags", "--exact-match", "HEAD"],
                        stderr=subprocess.DEVNULL
                    ).decode().strip()
                except Exception:
                    head_tag = ""
                compare_tag = head_tag if head_tag else latest
                compare_ver = compare_tag.lstrip("v")
                if data["version"] != compare_ver:
                    warn("version",
                         f"meta.json version {data['version']} != "
                         f"{('checked-out tag ' + head_tag) if head_tag else ('latest tag ' + latest)} "
                         f"(drift)")
        except Exception:
            pass  # no git available, or no tags — skip silently

    # D-006 enforcement: description is part of the routing surface. A change to
    # description between two adjacent versions should bump at least minor.
    # If only patch bumped while description changed, warn (likely missed bump).
    if "version" in data and isinstance(data["version"], str) and "description" in data:
        try:
            import subprocess
            tags_raw = subprocess.check_output(["git", "tag", "--sort=-v:refname",
                                                "--format=%(refname:short)"],
                                               cwd=os.path.dirname(os.path.abspath(path)) or ".",
                                               stderr=subprocess.DEVNULL).decode().splitlines()
            semver_tags = [t for t in tags_raw if re.match(r"^v[0-9]+\.[0-9]+\.[0-9]+$", t)]
            if len(semver_tags) >= 2:
                cur_v = data["version"]
                latest_tag, prev_tag = semver_tags[0], semver_tags[1]
                if cur_v == latest_tag.lstrip("v"):
                    # Find the description at prev_tag and compare.
                    # `path` is relative to repo root (e.g. "./meta.json" or
                    # "skills/build-agent-app/meta.json"). Use it directly.
                    repo_rel_path = path.lstrip("./")
                    try:
                        prev_desc_blob = subprocess.check_output(
                            ["git", "show", f"{prev_tag}:{repo_rel_path}"],
                            stderr=subprocess.DEVNULL
                        ).decode()
                    except Exception:
                        prev_desc_blob = None
                    if prev_desc_blob:
                        try:
                            prev_data = json.loads(prev_desc_blob)
                        except Exception:
                            prev_data = {}
                    if "description" in prev_data and prev_data["description"] != data["description"]:
                        # Parse prev_tag into major.minor.patch
                        pv = prev_tag.lstrip("v").split(".")
                        cv = cur_v.split(".")
                        if len(pv) == 3 and len(cv) == 3:
                            if pv[0] == cv[0] and pv[1] == cv[1] and int(cv[2]) - int(pv[2]) >= 1 and pv[0:2] == cv[0:2]:
                                warn("description",
                                     f"description changed but only patch bumped ({prev_tag} → v{cur_v}); "
                                     f"D-006 says description is routing surface, should bump minor")
        except Exception:
            pass

    if "entry" in data and isinstance(data["entry"], str):
        base = os.path.dirname(os.path.abspath(path))
        entry_path = os.path.join(base, data["entry"])
        if not os.path.isfile(entry_path):
            err("entry", f"{data['entry']} not found next to meta.json ({entry_path})")

    if "agents_supported" in data:
        if not isinstance(data["agents_supported"], int):
            err("agents_supported", "expected int")
        elif data["agents_supported"] < 1:
            err("agents_supported", "must be >= 1")

    if isinstance(data.get("id"), str) and isinstance(data.get("name"), str):
        if data["id"].replace("-", " ").lower() not in data["name"].lower():
            warn("name", f"name {data['name']!r} doesn't reflect id {data['id']!r}")

    ALLOWED = set(REQUIRED + ["agents_supported"])
    extra = set(data.keys()) - ALLOWED
    for k in sorted(extra):
        warn(k, "unknown field (indexers may ignore)")

    print(json.dumps({"ok": len(errs) == 0, "errors": errs, "warnings": warns}))

try:
    main(sys.argv[1])
except Exception:
    print(json.dumps({"ok": False, "errors": [f"validator crashed: {type(e).__name__}: {e}" for e in [sys.exc_info()[1]]], "warnings": []}))
    sys.exit(0)  # don't propagate; main() catches its own errors anyway
PY
) || RESULT='{"ok":false,"errors":["python3 crashed"],"warnings":[]}'

# Parse the JSON result
if command -v python3 >/dev/null 2>&1; then
  ERR_COUNT=$(printf '%s' "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d.get('errors',[])))")
  WARN_COUNT=$(printf '%s' "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d.get('warnings',[])))")
  IS_OK=$(printf '%s' "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print('yes' if d.get('ok') else 'no')")
  DETAILS=$(printf '%s' "$RESULT" | python3 -c "
import sys,json
d = json.load(sys.stdin)
for e in d.get('errors', []): print(f'ERROR {e}')
for w in d.get('warnings', []): print(f'WARN  {w}')
")
else
  ERR_COUNT=0; WARN_COUNT=0; IS_OK=yes; DETAILS=
fi

# Print details (suppressed in --json mode)
if [[ $JSON_OUT -eq 0 ]]; then
  [[ -n "$DETAILS" ]] && echo "$DETAILS" >&2
fi

# Decide exit
if [[ "$IS_OK" != "yes" ]]; then
  [[ $JSON_OUT -eq 0 ]] && echo "FAILED: $ERR_COUNT error(s), $WARN_COUNT warning(s) in $FILE" >&2
  [[ $JSON_OUT -eq 1 ]] && printf '{"file":"%s","ok":false,"errors":%d,"warnings":%d,"strict":%s}\n' \
    "$FILE" "$ERR_COUNT" "$WARN_COUNT" "$([[ $STRICT -eq 1 ]] && echo true || echo false)"
  exit 1
fi

if [[ $STRICT -eq 1 && $WARN_COUNT -gt 0 ]]; then
  [[ $JSON_OUT -eq 0 ]] && echo "FAILED (strict): $WARN_COUNT warning(s) in $FILE" >&2
  [[ $JSON_OUT -eq 1 ]] && printf '{"file":"%s","ok":false,"errors":0,"warnings":%d,"strict":true}\n' "$FILE" "$WARN_COUNT"
  exit 1
fi

[[ $JSON_OUT -eq 0 ]] && echo "OK: $FILE passes schema validation ($WARN_COUNT warning(s))"
[[ $JSON_OUT -eq 1 ]] && printf '{"file":"%s","ok":true,"errors":0,"warnings":%d,"strict":%s}\n' \
  "$FILE" "$WARN_COUNT" "$([[ $STRICT -eq 1 ]] && echo true || echo false)"
exit 0
