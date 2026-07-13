# Implementation Report — feature/15-install-status

## What
Added `scripts/install-session-hook.sh --status` that reports whether the hook
is currently installed per target without modifying any files.

## Why
Users had no way to ask "is the hook installed?" without either running a
dry-run install (which still copies the hook script) or grepping
`~/.claude/settings.json` by hand. `--status` makes this one command.

## Behaviour
- `--status` reads `~/.claude/settings.json` (or `./.claude/settings.json` for
  `--target project`) and reports whether the SessionStart entry tagged with
  the hook marker exists.
- Also reports whether the hook script itself is on disk at
  `~/.claude/hooks/session-start-read-session-md.sh`.
- Exits 0 if installed, 1 if not.
- **Does not create settings.json** when the file is missing (caught by self-test).

## Tests
7 manual tests covering install, idempotency, status (installed/not), uninstall
round-trip, status-on-missing-file (no creation), validator pass.

## Files changed
- scripts/install-session-hook.sh (added status_target() function, --status action)
