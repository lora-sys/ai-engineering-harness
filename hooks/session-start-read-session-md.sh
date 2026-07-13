#!/usr/bin/env bash
# hooks/session-start-read-session-md.sh
#
# SessionStart hook for Claude Code: read .claude/SESSION.md if it exists,
# print its contents to stdout (which Claude Code injects as additional
# context for this session), and exit 0.
#
# The hook is read-only on the SESSION.md file. It never writes to it.
# This was an explicit user requirement — earlier proposals to maintain
# SESSION.md were declined.
#
# Behaviour:
#   - .claude/SESSION.md exists and is non-empty → cat it to stdout.
#   - .claude/SESSION.md exists but is empty       → soft hint, exit 0.
#   - .claude/SESSION.md does not exist            → silent (no context injection).
#   - $SESSION_MD_PATH env var set                  → read that absolute path
#                                                    instead of the CWD-relative
#                                                    default. Useful for tests.
#   - any error                                      → exit 0 (never block session).
#
# Stderr is reserved for diagnostic logging (visible in the user's session log
# but NOT injected into LLM context).
#
# Part of the ai-engineering-harness skill. Install via:
#   scripts/install-session-hook.sh --target global
#   scripts/install-session-hook.sh --target project

set -uo pipefail

# Resolve SESSION.md path. Allow override via env (useful for tests).
if [[ -n "${SESSION_MD_PATH:-}" ]]; then
  target="$SESSION_MD_PATH"
else
  target=".claude/SESSION.md"
fi

# Diagnostic log to stderr (NOT injected into LLM context).
log() { printf '[session-start-read-session-md] %s\n' "$*" >&2; }

# Soft signal that surfaces in the user's session log without polluting context.
if [[ ! -f "$target" ]]; then
  log "no SESSION.md at $target — nothing to inject"
  exit 0
fi

# Reject symlinks that point outside the project — defence-in-depth so a
# tampered .claude/ entry cannot exfiltrate arbitrary files. Realpath both
# the file and CWD and require the file to live under CWD.
#
# When SESSION_MD_PATH is explicitly set, the user has opted into a specific
# path; the CWD-relative guard does not apply. The override exists for tests
# and for advanced users who want to point at a canonical session file.
if [[ -z "${SESSION_MD_PATH:-}" ]]; then
  real_target="$(readlink -f "$target" 2>/dev/null || echo "")"
  real_cwd="$(readlink -f "." 2>/dev/null || echo "")"
  if [[ -z "$real_target" ]] || [[ -z "$real_cwd" ]]; then
    log "could not resolve paths — skipping"
    exit 0
  fi
  case "$real_target" in
    "$real_cwd"/*) : ;;  # file is inside cwd, ok
    *)
      log "refusing to read $real_target — outside CWD $real_cwd"
      exit 0
      ;;
  esac
fi

# Cap at 64 KB. Beyond that, just print the head and a hint. SESSION.md should
# be a tight brief, not a project history dump.
max_bytes=65536
size=$(wc -c < "$target" 2>/dev/null | tr -d ' ' || echo 0)

if [[ "$size" -eq 0 ]]; then
  log "$target exists but is empty — nothing to inject"
  exit 0
fi

if [[ "$size" -le "$max_bytes" ]]; then
  log "injecting $size bytes from $target"
  cat "$target"
  exit 0
fi

# Oversize — print head + advisory.
log "$target is $size bytes (> $max_bytes) — injecting head only"
head -c "$max_bytes" "$target"
printf '\n\n[…truncated; full %s bytes available at %s]\n' "$size" "$target"
exit 0
