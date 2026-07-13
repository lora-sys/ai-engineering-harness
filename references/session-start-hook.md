# SessionStart Hook — Read `.claude/SESSION.md` if it exists

A read-only hook for Claude Code (and Codex, where supported) that runs at every new session and injects `.claude/SESSION.md` as additional context.

## What it does

| Event | Action |
| --- | --- |
| Session starts (startup, resume, compact) | If `.claude/SESSION.md` exists in CWD, print its contents to stdout → injected into session context |
| `.claude/SESSION.md` does not exist | Silent — no context pollution |
| `.claude/SESSION.md` exists but is empty | Silent — `wc -c == 0` |
| `.claude/SESSION.md` > 64 KB | Print first 64 KB + advisory that the file is oversized |
| `.claude/SESSION.md` is a symlink pointing outside CWD | Refuse to read (defence-in-depth) |
| Any error | Exit 0, log to stderr — never block the session |

**The hook never writes to SESSION.md.** It is read-only by design. This was an explicit user requirement — earlier proposals to *maintain* SESSION.md (auto-write summaries, etc.) were declined.

## Why it matters

Without this hook, the LLM has no idea what's been recorded in `.claude/SESSION.md`. The file might be the project bible for the current session, but unless the user pastes it in or the agent remembers to read it, it stays invisible.

With this hook, every new session starts already-aware of whatever the user wrote there.

## Install

```bash
# Global — applies to every Claude Code session on this machine.
bash scripts/install-session-hook.sh --target global

# Project — applies only when Claude Code is launched from CWD.
bash scripts/install-session-hook.sh --target project

# Both
bash scripts/install-session-hook.sh --target global --target project

# See what would change without changing anything
bash scripts/install-session-hook.sh --target global --dry-run

# Remove
bash scripts/install-session-hook.sh --target global --uninstall
```

The installer is **idempotent**: re-running install on the same target is a no-op (prints "already installed" / rewrites the same JSON). Uninstall strips only the entry tagged with our marker; other hooks in the same `settings.json` are preserved.

## What it writes

After `install-session-hook.sh --target global`:

1. **Hook script** copied to `~/.claude/hooks/session-start-read-session-md.sh` (chmod +x). Owned by the install; safe to edit locally for debugging.
2. **settings.json** (`~/.claude/settings.json`) gains a `hooks.SessionStart` entry pointing at the copied script. Existing entries under `hooks.SessionStart` are preserved; existing entries under other events (`PreToolUse`, etc.) are untouched.

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [
        {
          "type": "command",
          "command": "bash /home/<you>/.claude/hooks/session-start-read-session-md.sh",
          "description": "Read .claude/SESSION.md if it exists; inject as session context (read-only)."
        }
      ]}
    ]
  }
}
```

## Hook protocol

Claude Code sends a JSON event via stdin (we don't need to parse it; we just consume it so the pipe doesn't block). The hook's stdout is captured and injected as additional context for the LLM. Stderr is logged but never injected.

Sample interaction (`scripts/install-session-hook.sh --dry-run`):

```bash
echo '{}' | bash hooks/session-start-read-session-md.sh
# → (no stdout, no context)
# stderr: [session-start-read-session-md] no SESSION.md at .claude/SESSION.md — nothing to inject

echo 'I am a session brief.' > .claude/SESSION.md
echo '{}' | bash hooks/session-start-read-session-md.sh
# → stdout: I am a session brief.    (← injected as LLM context)
# stderr: [session-start-read-session-md] injecting 19 bytes from .claude/SESSION.md
```

## Bootstrap integration

`workflows/00-project-bootstrap.md` does NOT install this hook by default — installing it requires modifying `~/.claude/settings.json` (or `.claude/settings.json` per-project), which is a host-level change rather than a project-level one. Run the installer manually if you want it:

```bash
# After bootstrap completes
bash /path/to/ai-engineering-harness/scripts/install-session-hook.sh --target global
```

## Compatibility

| Agent | SessionStart hook support | Tested |
| --- | --- | --- |
| Claude Code | Yes (settings.json `hooks.SessionStart`) | Yes (this repo) |
| Codex CLI | Limited — see Codex docs; the harness's own bootstrap does not depend on it | No |
| Cursor | No SessionStart hook event | n/a |
| Other | n/a | n/a |

## Security notes

- The hook reads `.claude/SESSION.md` from CWD only. Symlinks that resolve outside CWD are rejected.
- The hook never writes to disk. It is purely a reader.
- The hook reads at most 64 KB. Larger files are truncated with an advisory; the user can choose to slim the file down.
- The hook does not make network calls. It does not run any other binary. It only `cat`s the target file.
