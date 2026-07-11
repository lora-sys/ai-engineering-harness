#!/usr/bin/env bash
# Validate the skill's meta.json against the embedded schema.
#
# Usage:
#   scripts/validate-meta.sh                  # validates ./meta.json
#   scripts/validate-meta.sh <path>           # validates a specific file
#   scripts/validate-meta.sh --strict        # also fail on warnings (unknown fields, etc.)
#   scripts/validate-meta.sh --json          # print a JSON line on stdout (for CI)
#
# Exit codes:
#   0  OK (no errors; warnings are tolerated unless --strict)
#   1  schema errors (one or more fields fail validation)
#   2  file missing / unreadable / not valid JSON
#   3  tool (python3) missing
#   4  validator internal error (Python exception)

set -uo pipefail

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

FILE="${PATH_ARG:-./meta.json}"
HAS_ERRS=0
HAS_WARNS=0

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

    REQUIRED = ["id", "name", "description", "category", "priority", "tags",
                "install", "license", "repository", "entry"]

    for k in REQUIRED:
        if k not in data:
            err(k, "missing required field")

    for k in ("id", "name", "description", "category", "license", "repository", "entry"):
        if k in data and not isinstance(data[k], str):
            err(k, f"expected string, got {type(data[k]).__name__}")

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
