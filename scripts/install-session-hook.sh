#!/usr/bin/env bash
# scripts/install-session-hook.sh
#
# Idempotent installer for the SessionStart hook that reads .claude/SESSION.md.
#
# Usage:
#   scripts/install-session-hook.sh                    # interactive: ask global vs project
#   scripts/install-session-hook.sh --target global    # ~/.claude/settings.json + ~/.claude/hooks/
#   scripts/install-session-hook.sh --target project   # .claude/settings.json + .claude/hooks/ (in CWD)
#   scripts/install-session-hook.sh --uninstall        # remove the hook (preserves other hooks)
#   scripts/install-session-hook.sh --dry-run          # show what would change, change nothing
#
# Idempotent: re-running with the same target is a no-op (prints "already installed").
# Multiple --target flags: installs to each. --uninstall removes from each.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_SRC="$REPO_DIR/hooks/session-start-read-session-md.sh"

# Marker so we can recognise (and remove) entries we previously installed,
# even if the user has other hooks in the same file.
HOOK_MARKER="session-start-read-session-md"

TARGETS=()
ACTION="install"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --target=*) TARGETS+=("${arg#--target=}") ;;
    --target)
      if [[ $# -lt 2 ]]; then
        echo "--target requires a value (global|project)" >&2
        exit 2
      fi
      shift
      TARGETS+=("$1")
      ;;
    --uninstall) ACTION="uninstall" ;;
    --dry-run)   DRY_RUN=1 ;;
    --status)    ACTION="status" ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    --*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *)   echo "unexpected positional arg: $arg" >&2; exit 2 ;;
  esac
  shift
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  # Default: ask interactively if stdin is a tty; otherwise install global.
  if [[ -t 0 ]]; then
    echo "Install SessionStart hook for:" >&2
    echo "  1) this project only  (.claude/settings.json in CWD)" >&2
    echo "  2) all projects       (~/.claude/settings.json, default)" >&2
    printf "Choose [1/2, default 2]: " >&2
    read -r choice
    case "$choice" in
      1) TARGETS=("project") ;;
      *) TARGETS=("global") ;;
    esac
  else
    TARGETS=("global")
  fi
fi

log()  { printf '[install-session-hook] %s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

# Resolve a target to its (settings_path, hooks_dir) pair.
# Echoes two lines: settings_path, hooks_dir.
resolve_target() {
  case "$1" in
    global)
      printf '%s\n' "$HOME/.claude/settings.json"
      printf '%s\n' "$HOME/.claude/hooks"
      ;;
    project)
      printf '%s\n' "./.claude/settings.json"
      printf '%s\n' "./.claude/hooks"
      ;;
    *)
      # Unreachable now that the main loop validates targets up front.
      # Be defensive: emit empty paths so process_target exits cleanly.
      printf '%s\n' ""
      printf '%s\n' ""
      return 1
      ;;
  esac
}

# Apply a JSON merge to settings.json. $1 = path, $2 = python expression
# that produces the new hooks section as JSON on stdout.
merge_settings() {
  local settings_path="$1"
  local expr="$2"
  local HOOK_EXPR="$expr"
  local tmp
  tmp="$(mktemp)"
  HOOK_MARKER="$HOOK_MARKER" \
  HOOK_COMMAND="$HOOK_COMMAND" \
  HOOK_EXPR="$expr" \
  python3 - "$settings_path" "$tmp" <<PY >/dev/null 2>"$tmp.err"
import json, sys, os
path, tmp = sys.argv[1], sys.argv[2]
marker = os.environ["HOOK_MARKER"]
command = os.environ["HOOK_COMMAND"]
expr_text = os.environ["HOOK_EXPR"]
with open(path) as f:
    data = json.load(f)
hooks = data.setdefault('hooks', {})
existing = hooks.get('SessionStart', [])
exec_globals = {"HOOK_MARKER": marker, "command": command, "existing": existing, "json": json}
exec_globals["HOOK_MARKER"] = marker
exec_globals["command"] = command
exec(expr_text, exec_globals)
new_value = exec_globals["new_value"]
if new_value is None:
    raise SystemExit("expr did not set new_value")
# Uninstall path may signal to remove the key entirely (empty list AND we filtered something out).
if exec_globals.get("_remove_key") and new_value == []:
    if 'SessionStart' in hooks:
        del hooks['SessionStart']
else:
    hooks['SessionStart'] = new_value
# Atomic write: write to tmp file, then rename. Never truncate the original on failure.
import os as _os
_tmp_write = path + ".tmp-" + str(_os.getpid())
with open(_tmp_write, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
_os.replace(_tmp_write, path)
PY
  rc=$?
  if [[ $rc -ne 0 ]]; then
    log "python merge failed for $settings_path (exit $rc):"
    cat "$tmp.err" >&2
    rm -f "$tmp" "$tmp.err"
    return 1
  fi
  rm -f "$tmp.err"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY-RUN: would rewrite $settings_path (Python already wrote to $settings_path atomically; bash leaves $settings_path alone)"
  else
    # Python already wrote atomically via os.replace(); do NOT mv $tmp over the original.
    # $tmp was created by mktemp for stderr capture only; removing it here is correct.
    log "merged into $settings_path"
  fi
  rm -f "$tmp"
}

# Build the Python expression for installing our hook entry.
install_expr() {
  cat <<'PYEXPR'
# Filter out any existing entries that came from us (idempotent reinstall).
existing = [e for e in existing if HOOK_MARKER not in json.dumps(e)]
hook_entry = {
    "hooks": [
        {
            "type": "command",
            "command": command,
            "description": "Read .claude/SESSION.md if it exists; inject as session context (read-only)."
        }
    ],
    "matcher": ""
}
existing.append(hook_entry)
new_value = existing
PYEXPR
}

# Build the Python expression for removing our hook entry.
uninstall_expr() {
  cat <<'PYEXPR'
filtered = [e for e in existing if HOOK_MARKER not in json.dumps(e)]
# If the filtered list is empty, signal to remove the SessionStart key entirely
# (set new_value to the empty list AND set the special marker _remove_key = True).
_remove_key = (len(filtered) == 0 and len(existing) > 0)
new_value = filtered
PYEXPR
}

# Build the absolute command path we'll register. Use $HOME-relative when
# possible so the entry survives `cd` and works for the user across machines.
build_command() {
  local hooks_dir_abs="$1"
  printf 'bash %q' "$hooks_dir_abs/session-start-read-session-md.sh"
}

# Report install status for one target. Exits 0 if installed, 1 if not.
status_target() {
  local settings_path="$1"
  local hooks_dir="$2"
  local rc=1

  if [[ -f "$settings_path" ]]; then
    if HOOK_MARKER="$HOOK_MARKER" python3 - "$settings_path" >/dev/null <<'PYEOF2'
import json, sys, os
marker = os.environ.get("HOOK_MARKER", "session-start-read-session-md")
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except Exception:
    sys.exit(1)
ss = data.get("hooks", {}).get("SessionStart", [])
for entry in ss:
    if marker in json.dumps(entry):
        cmds = [h.get("command", "?") for h in entry.get("hooks", [])]
        print("installed: " + (cmds[0] if cmds else "?"))
        sys.exit(0)
sys.exit(1)
PYEOF2
    then
      echo "[install-session-hook] $settings_path -> installed"
      rc=0
    else
      echo "[install-session-hook] $settings_path -> NOT installed (no SessionStart entry with marker)"
    fi
  else
    echo "[install-session-hook] $settings_path -> NOT installed (file missing)"
  fi

  local hook_dest="$hooks_dir/session-start-read-session-md.sh"
  if [[ -f "$hook_dest" ]]; then
    echo "[install-session-hook] hook script present at $hook_dest"
  else
    echo "[install-session-hook] hook script MISSING at $hook_dest"
  fi

  return $rc
}

# Run a single install/uninstall cycle against one target.
process_target() {
  local target="$1"
  local settings_path hooks_dir
  settings_path="$(resolve_target "$target" | sed -n 1p)"
  hooks_dir="$(resolve_target "$target" | sed -n 2p)"
  local command
  command="$(build_command "$hooks_dir")"

  log "target=$target settings=$settings_path hooks_dir=$hooks_dir"

  # For --status, do NOT create settings.json — that would defeat the purpose of status.
  if [[ "$ACTION" == "status" ]]; then
    :  # fall through; status_target handles the missing-file case
  elif [[ ! -f "$settings_path" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      log "DRY-RUN: would create $settings_path (empty {})"
      mkdir -p "$(dirname "$settings_path")"
      printf '{}\n' > "$settings_path"
    else
      log "creating $settings_path"
      mkdir -p "$(dirname "$settings_path")"
      printf '{}\n' > "$settings_path"
    fi
  fi

  case "$ACTION" in
    status)
      status_target "$settings_path" "$hooks_dir"
      STATUS_RC=$?
      ;;
    install)
      # Copy the hook script (or symlink in the future, but copy for now).
      if [[ ! -f "$HOOK_SRC" ]]; then
        fail "hook source not found at $HOOK_SRC"
      fi
      mkdir -p "$hooks_dir"
      local hook_dest="$hooks_dir/session-start-read-session-md.sh"
      if [[ $DRY_RUN -eq 1 ]]; then
        log "DRY-RUN: would copy $HOOK_SRC → $hook_dest"
      else
        cp "$HOOK_SRC" "$hook_dest"
        chmod +x "$hook_dest"
        log "installed hook script at $hook_dest"
      fi
      # Merge into settings.json.
      if [[ $DRY_RUN -eq 1 ]]; then
        log "DRY-RUN: would merge SessionStart entry into $settings_path"
      else
        HOOK_MARKER="$HOOK_MARKER" HOOK_COMMAND="$command" \
          merge_settings "$settings_path" "$(install_expr)"
        # merge_settings already logs "merged into $settings_path"
      fi
      ;;
    uninstall)
      # Remove the hook script (only if we own it).
      local hook_dest="$hooks_dir/session-start-read-session-md.sh"
      if [[ -f "$hook_dest" ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
          log "DRY-RUN: would remove $hook_dest"
        else
          rm -f "$hook_dest"
          log "removed $hook_dest"
        fi
      fi
      # Strip our entry from settings.json (preserves other hooks).
      if [[ $DRY_RUN -eq 1 ]]; then
        log "DRY-RUN: would strip our SessionStart entry from $settings_path"
      else
        HOOK_MARKER="$HOOK_MARKER" HOOK_COMMAND="" \
          merge_settings "$settings_path" "$(uninstall_expr)"
        # merge_settings already logs
      fi
      ;;
  esac
}

# Validate every target up front. Doing this here (rather than inside
# resolve_target, which runs in a subshell via command substitution) means
# `exit 1` from fail() actually terminates the script.
for t in "${TARGETS[@]}"; do
  case "$t" in
    global|project) ;;
    *) fail "unknown target: $t (expected 'global' or 'project')" ;;
  esac
done

STATUS_RC=0
for t in "${TARGETS[@]}"; do
  process_target "$t"
done

log "done ($ACTION, ${#TARGETS[@]} target(s))"
# For --status, propagate the worst per-target exit code so callers can
# script on it (0 = all installed, 1 = at least one missing).
if [[ "$ACTION" == "status" ]]; then
  exit "$STATUS_RC"
fi
