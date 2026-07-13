#!/usr/bin/env bats
# tests/install-session-hook.bats
#
# Tests for scripts/install-session-hook.sh.
# Exercises: install, idempotency, --status, --uninstall, --dry-run,
# and the regression we caught in v1.2.1 (--status MUST NOT create
# settings.json on a missing file).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TMPHOME="$(mktemp -d)"
  export HOME="$TMPHOME"
  mkdir -p "$TMPHOME/.claude/hooks"
  HOOK="$REPO_ROOT/scripts/install-session-hook.sh"
  SETTINGS="$TMPHOME/.claude/settings.json"
  HOOK_DEST="$TMPHOME/.claude/hooks/session-start-read-session-md.sh"
}

teardown() {
  rm -rf "$TMPHOME"
}

@test "install-session-hook --help exits 0" {
  run bash "$HOOK" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "install-session-hook creates SessionStart entry on first install" {
  run bash "$HOOK" --target global
  [ "$status" -eq 0 ]
  [ -f "$SETTINGS" ]
  python3 -c "
import json
d = json.load(open('$SETTINGS'))
ss = d['hooks']['SessionStart']
assert any('session-start-read-session-md' in json.dumps(e) for e in ss), 'no SessionStart entry with marker'
print('OK')
"
}

@test "install-session-hook is idempotent (md5 unchanged on re-run)" {
  bash "$HOOK" --target global
  md5_before=$(md5sum "$SETTINGS" | cut -c1-32)
  bash "$HOOK" --target global >/dev/null 2>&1
  md5_after=$(md5sum "$SETTINGS" | cut -c1-32)
  [ "$md5_before" = "$md5_after" ]
}

@test "install-session-hook --status reports installed when present" {
  bash "$HOOK" --target global >/dev/null 2>&1
  run bash "$HOOK" --status --target global
  [ "$status" -eq 0 ]
  [[ "$output" =~ "installed" ]]
}

@test "install-session-hook --status reports NOT installed on fresh env" {
  run bash "$HOOK" --status --target global
  [ "$status" -ne 0 ]
  [[ "$output" =~ "NOT installed" ]]
}

@test "install-session-hook --status does NOT create settings.json (regression)" {
  # This is the bug we caught in v1.2.1 self-review: the file-creation
  # check ran before the action switch. After the fix, --status on a
  # missing file must NOT create the file.
  [ ! -f "$SETTINGS" ]
  run bash "$HOOK" --status --target global
  [ ! -f "$SETTINGS" ]
}

@test "install-session-hook --uninstall removes the SessionStart entry" {
  bash "$HOOK" --target global >/dev/null 2>&1
  bash "$HOOK" --target global --uninstall >/dev/null 2>&1
  python3 -c "
import json
d = json.load(open('$SETTINGS'))
assert 'SessionStart' not in d.get('hooks', {}), 'SessionStart key not removed'
print('OK')
"
}

@test "install-session-hook --dry-run does NOT modify settings.json" {
  bash "$HOOK" --target global >/dev/null 2>&1
  md5_before=$(md5sum "$SETTINGS" | cut -c1-32)
  bash "$HOOK" --target global --dry-run >/dev/null 2>&1
  md5_after=$(md5sum "$SETTINGS" | cut -c1-32)
  [ "$md5_before" = "$md5_after" ]
}

@test "install-session-hook refuses bad target name" {
  run bash "$HOOK" --target galaxy
  [ "$status" -ne 0 ]
  [[ "$output" =~ "unknown target" ]]
}

@test "install-session-hook preserves other hooks in settings.json" {
  # Pre-seed settings.json with a custom hook under PreToolUse.
  cat > "$SETTINGS" <<JSON
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{"type":"command","command":"echo hi"}] }
    ]
  }
}
JSON
  bash "$HOOK" --target global >/dev/null 2>&1
  python3 -c "
import json
d = json.load(open('$SETTINGS'))
assert len(d['hooks'].get('PreToolUse', [])) == 1, 'PreToolUse preserved'
assert len(d['hooks'].get('SessionStart', [])) == 1, 'SessionStart added'
print('OK')
"
}
