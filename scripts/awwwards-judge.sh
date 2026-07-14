#!/usr/bin/env bash
# scripts/awwwards-judge.sh — render a page + LLM-as-judge for Awwwards score.
#
# Usage:
#   scripts/awwwards-judge.sh --url https://example.com
#   scripts/awwwards-judge.sh --html path/to/index.html    # already-built file
#   scripts/awwwards-judge.sh --dir path/to/dist/           # will serve + render
#   scripts/awwwards-judge.sh --shot path/to/screenshot.png  # skip render, just judge
#   scripts/awwwards-judge.sh --out path/to/output.json      # default: /tmp/awwwards.json
#   scripts/awwwards-judge.sh --llm codex                    # override LLM CLI
#
# Output JSON:
#   { "composition": 1-10, "type": 1-10, "color": 1-10, "motion": 1-10,
#     "originality": 1-10, "performance": 1-10, "total": sum, "rationale": "..." }

set -uo pipefail

URL=""
HTML=""
DIR=""
SHOT=""
OUT="/tmp/awwwards-judge.json"
LLM=""
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)    shift; URL="$1" ;;
    --html)   shift; HTML="$1" ;;
    --dir)    shift; DIR="$1" ;;
    --shot)   shift; SHOT="$1" ;;
    --out)    shift; OUT="$1" ;;
    --llm)    shift; LLM="$1" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

# Auto-detect LLM
if [[ -z "$LLM" ]]; then
  for cmd in claude codex gemini gh; do
    command -v "$cmd" >/dev/null 2>&1 && { LLM="$cmd"; break; }
  done
  if [[ -z "$LLM" ]]; then
    echo "FAIL: no LLM CLI found" >&2; exit 1
  fi
fi

# Step 1: get a screenshot
if [[ -z "$SHOT" ]]; then
  if [[ -n "$HTML" ]]; then
    SHOT="$TMPDIR/page.png"
    chromium --headless --no-sandbox --disable-gpu \
      --window-size=1280,800 --screenshot="$SHOT" "file://$HTML" 2>/dev/null
  elif [[ -n "$DIR" ]]; then
    # Serve the dir on a random port, screenshot, kill
    PORT=8765
    cd "$DIR" && python3 -m http.server "$PORT" >/dev/null 2>&1 &
    SERVER_PID=$!
    sleep 1
    SHOT="$TMPDIR/page.png"
    chromium --headless --no-sandbox --disable-gpu \
      --window-size=1280,800 --screenshot="$SHOT" "http://localhost:$PORT/" 2>/dev/null
    kill $SERVER_PID 2>/dev/null
  elif [[ -n "$URL" ]]; then
    SHOT="$TMPDIR/page.png"
    chromium --headless --no-sandbox --disable-gpu \
      --window-size=1280,800 --screenshot="$SHOT" "$URL" 2>/dev/null
  else
    echo "FAIL: need --url, --html, --dir, or --shot" >&2; exit 1
  fi
fi

if [[ ! -f "$SHOT" ]] || [[ ! -s "$SHOT" ]]; then
  echo "FAIL: screenshot not created at $SHOT" >&2
  exit 1
fi

# Step 2: LLM-as-judge
# The screenshot is binary; most CLIs need text input. So we describe the page
# via the URL (if available) or pass the screenshot path.
# For simplicity: judge based on URL + meta description. If we have a URL,
# use that. Otherwise just signal "use the URL/path to view".

META_INFO="Screenshot at: $SHOT"
[[ -n "$URL" ]] && META_INFO="$META_INFO  URL: $URL"

PROMPT="You are an Awwwards-style design judge. The screenshot is at: $SHOT
${META_INFO}

Score this page on 6 categories, each 1-10:
1. composition (asymmetric grid, off-center, full-bleed)
2. type (oversized type, variable font, experimental layout)
3. color (cohesive palette, gradient, not default-Tailwind)
4. motion (layered, GSAP/framer-motion, scroll-driven)
5. originality (unique visual language, not template-y)
6. performance (Lighthouse-equivalent: fast load, no jank)

Then a one-line rationale per category, plus a 'total' (sum) and 'verdict' (one of: 'ship' / 'iterate' / 'redesign').

Respond with a single JSON object, no prose, no markdown, just JSON:
{
  \"composition\": <int>,
  \"type\": <int>,
  \"color\": <int>,
  \"motion\": <int>,
  \"originality\": <int>,
  \"performance\": <int>,
  \"total\": <int>,
  \"rationale\": {\"composition\": \"...\", \"type\": \"...\", \"color\": \"...\", \"motion\": \"...\", \"originality\": \"...\", \"performance\": \"...\"},
  \"verdict\": \"<ship|iterate|redesign>\"
}"

# Invoke LLM
case "$LLM" in
  claude) out="$(claude --system 'You are an Awwwards design judge.' -p "$PROMPT" 2>/dev/null)" ;;
  codex)  out="$(codex exec --system 'You are an Awwwards design judge.' "$PROMPT" 2>/dev/null)" ;;
  gemini) out="$(gemini chat --system 'You are an Awwwards design judge.' --prompt "$PROMPT" 2>/dev/null)" ;;
  gh)     out="$(gh models invoke --system 'You are an Awwwards design judge.' "$PROMPT" 2>/dev/null)" ;;
  *) echo "FAIL: unsupported LLM CLI: $LLM" >&2; exit 1 ;;
esac

# Extract JSON
json="$(echo "$out" | python3 -c '
import sys, re, json
text = sys.stdin.read()
m = re.search(r"\{[\s\S]*\}", text)
print(m.group(0) if m else "")
')"

if [[ -z "$json" ]]; then
  echo "FAIL: LLM did not return JSON" >&2
  echo "Output was: $out" >&2
  exit 1
fi

# Validate the JSON
echo "$json" | python3 -c '
import json, sys
d = json.load(sys.stdin)
required = ["composition", "type", "color", "motion", "originality", "performance", "total", "verdict"]
for k in required:
    if k not in d:
        print(f"FAIL: missing key: {k}")
        sys.exit(1)
for k in ["composition", "type", "color", "motion", "originality", "performance"]:
    v = d[k]
    if not isinstance(v, int) or v < 1 or v > 10:
        print(f"FAIL: {k}={v} not in 1-10")
        sys.exit(1)
total = sum(d[k] for k in ["composition", "type", "color", "motion", "originality", "performance"])
if d["total"] != total:
    print(f"FAIL: total {d[\"total\"]} != sum {total}")
    sys.exit(1)
print(f"OK: total={total} verdict={d[\"verdict\"]}")
' || { echo "FAIL: schema validation" >&2; exit 1; }

# Save
echo "$json" | python3 -c 'import json, sys; d = json.load(sys.stdin); print(json.dumps(d, indent=2, ensure_ascii=False))' > "$OUT"
echo "Saved to $OUT"
cat "$OUT" | python3 -c 'import json, sys; d = json.load(sys.stdin); print(f"\nTotal: {d[\"total\"]}/60  Verdict: {d[\"verdict\"]}")'BASH
chmod +x scripts/awwwards-judge.sh
bash -n scripts/awwwards-judge.sh && echo "syntax OK"