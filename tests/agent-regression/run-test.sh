#!/usr/bin/env bash
# tests/agent-regression/run-test.sh
#
# Agent regression test. For each (agent × scenario) fixture, invoke the LLM
# with the agent's system prompt + the fixture's input, then parse the response
# for a JSON object matching the expected schema.
#
# Usage:
#   tests/agent-regression/run-test.sh                  # auto-detect LLM CLI
#   tests/agent-regression/run-test.sh --llm codex     # explicit CLI
#   tests/agent-regression/run-test.sh --agent coordinator   # just one agent
#   tests/agent-regression/run-test.sh --dry-run       # validate fixtures, no LLM calls
#
# Cost: ~$0.17 per run (30 fixtures × ~$0.006 each at Sonnet rates).
# Run pre-release only. Exit 0 if all pass, 1 otherwise.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIX="$SCRIPT_DIR/fixtures"

LLM=""
ONLY_AGENT=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --llm=*)    LLM="${1#--llm=}" ;;
    --llm)      shift; LLM="$1" ;;
    --agent=*)  ONLY_AGENT="${1#--agent=}" ;;
    --agent)    shift; ONLY_AGENT="$1" ;;
    --dry-run)  DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

# Auto-detect LLM CLI
if [[ -z "$LLM" && $DRY_RUN -eq 0 ]]; then
  for cmd in claude codex gemini gh; do
    if command -v "$cmd" >/dev/null 2>&1; then
      LLM="$cmd"
      break
    fi
  done
  if [[ -z "$LLM" ]]; then
    echo "FAIL: no LLM CLI found (need claude, codex, gemini, or gh)" >&2
    exit 1
  fi
fi

echo "[agent-regression] using LLM CLI: $LLM" >&2

pass=0
fail=0
total=0

for fixture in "$FIX"/*.json; do
  agent="$(basename "$fixture" .json)"
  [[ -n "$ONLY_AGENT" && "$agent" != "$ONLY_AGENT" ]] && continue
  total=$((total + 6))  # 6 prompts per agent

  if [[ $DRY_RUN -eq 1 ]]; then
    # Validate JSON structure only
    python3 -c "
import json
d = json.load(open('$fixture'))
assert 'agent' in d and 'prompts' in d
for p in d['prompts']:
    assert 'id' in p and 'input' in p and 'expect' in p
" || { echo "  FAIL  fixture validation: $fixture"; fail=$((fail+1)); continue; }
    echo "  ok    $agent (dry-run, fixture valid)"
    continue
  fi

  system_prompt_file="$REPO_DIR/agents/$agent.md"
  if [[ ! -f "$system_prompt_file" ]]; then
    echo "  FAIL  $agent: system prompt not found at $system_prompt_file"
    fail=$((fail+6))
    continue
  fi
  system_prompt="$(cat "$system_prompt_file")"

  # Run the actual agent regression via Python (so the LLM invocation, parsing,
  # and validation are all in one language).
  agent_results=$(LLM="$LLM" AGENT="$agent" SYSTEM_PROMPT="$system_prompt" \
                  REPO="$REPO_DIR" python3 -c "
import json, subprocess, os, re, sys

with open('$fixture') as f:
    data = json.load(f)

llm = os.environ['LLM']
agent = os.environ['AGENT']
system_prompt = os.environ['SYSTEM_PROMPT']

for prompt in data['prompts']:
    pid = prompt['id']
    user_input = prompt['input']
    expect = prompt['expect']

    # Build meta-prompt asking for JSON
    hints = []
    for k in expect.get('required_keys', []):
        hints.append(f'required key: {k}')
    for k, v in expect.get('enum_keys', {}).items():
        hints.append(f'{k} must be one of {v}')
    for k in expect.get('boolean_keys', []):
        hints.append(f'boolean key: {k}')
    for k, n in expect.get('integer_min_keys', {}).items():
        hints.append(f'integer key >= {n}: {k}')
    for k, n in expect.get('array_min_keys', {}).items():
        hints.append(f'array with >= {n} items: {k}')
    for k, n in expect.get('array_max_keys', {}).items():
        hints.append(f'array with <= {n} items: {k}')

    meta = f'''You are the {agent} agent in a test harness. The system prompt defines your role. Read it.
USER INPUT:
{user_input}

Respond with a single JSON object. No prose, no markdown, no commentary. The object must have:
{chr(10).join('  - ' + h for h in hints)}

Output ONLY the JSON, starting with {{ and ending with }}.
'''

    cmd_map = {
        'claude': ['claude', '--system', system_prompt, '-p', meta],
        'codex':  ['codex', 'exec', '--system', system_prompt, meta],
        'gemini': ['gemini', 'chat', '--system', system_prompt, '--prompt', meta],
        'gh':     ['gh', 'models', 'invoke', '--system', system_prompt, meta],
    }
    try:
        result = subprocess.run(cmd_map[llm], capture_output=True, text=True, timeout=120)
        out = result.stdout
    except Exception as e:
        print(f'FAIL  {agent}.{pid}  LLM error: {e}')
        continue

    m = re.search(r'\{[\s\S]*\}', out)
    if not m:
        print(f'FAIL  {agent}.{pid}  no JSON in output (len={len(out)})')
        continue
    try:
        parsed = json.loads(m.group(0))
    except json.JSONDecodeError as e:
        print(f'FAIL  {agent}.{pid}  JSON parse: {e}')
        continue

    errs = []
    for k in expect.get('required_keys', []):
        if k not in parsed:
            errs.append(f'missing key: {k}')
    for k, vs in expect.get('enum_keys', {}).items():
        if k in parsed and parsed[k] not in vs:
            errs.append(f'{k}={parsed[k]!r} not in {vs}')
    for k in expect.get('boolean_keys', []):
        if k in parsed and not isinstance(parsed[k], bool):
            errs.append(f'{k} not boolean: {parsed[k]!r}')
    for k, mn in expect.get('integer_min_keys', {}).items():
        if k in parsed and not isinstance(parsed[k], int):
            errs.append(f'{k} not int: {parsed[k]!r}')
        if k in parsed and parsed[k] < mn:
            errs.append(f'{k}={parsed[k]} < {mn}')
    for k, mn in expect.get('array_min_keys', {}).items():
        if k in parsed and not isinstance(parsed[k], list):
            errs.append(f'{k} not list: {parsed[k]!r}')
        if k in parsed and len(parsed[k]) < mn:
            errs.append(f'{k} has {len(parsed[k])} items, need >= {mn}')
    for k, mx in expect.get('array_max_keys', {}).items():
        if k in parsed and isinstance(parsed[k], list) and len(parsed[k]) > mx:
            errs.append(f'{k} has {len(parsed[k])} items, need <= {mx}')

    if errs:
        print(f'FAIL  {agent}.{pid}')
        for e in errs:
            print(f'      - {e}')
    else:
        print(f'ok    {agent}.{pid}')
")

  # Count pass/fail
  while IFS= read -r line; do
    case "$line" in
      ok*)    pass=$((pass+1)) ;;
      FAIL*)  fail=$((fail+1)) ;;
    esac
  done <<< "$agent_results"
  echo "  results: $agent" >&2
done

echo
echo "[agent-regression] $pass passed, $fail failed" >&2
exit $fail
