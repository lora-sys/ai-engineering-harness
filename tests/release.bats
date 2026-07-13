#!/usr/bin/env bats
# tests/release.bats
#
# Smoke tests for scripts/release.sh.
# These don't run a real release — they just verify the script parses,
# rejects bad inputs, and the regex that extracts CHANGELOG notes works.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/release.sh"
}

@test "release.sh rejects missing version arg" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "usage" ]]
}

@test "release.sh detects meta.json version mismatch" {
  run bash "$SCRIPT" 99.99.99
  [ "$status" -ne 0 ]
  [[ "$output" =~ "meta.json version" ]]
}

@test "release.sh CHANGELOG regex extracts the right section" {
  python3 -c "
import re
v = '1.6.0'
text = open('$REPO_ROOT/CHANGELOG.md').read()
m = re.search(r'(##\\s*\\[' + re.escape(v) + r'\\][^\\n]*\\n.*?)(?=\\n##\\s*\\[|\\Z)', text, re.DOTALL)
assert m, 'no match for v1.6.0'
section = m.group(1).strip()
assert 'frontend-creative' in section, 'v1.6.0 section should mention frontend-creative'
print('OK v1.6.0 section found')
"
}
