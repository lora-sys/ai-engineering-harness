# Session Files

The file-system message bus for multi-agent runs. One folder per session under `sessions/<session-id>/` (or `docs/sessions/` when session records are wanted long-term).

```
sessions/<session-id>/
├── status.md         # shared state — read by every agent at start
├── plan.md           # Coordinator's plan for the session
├── execution.md      # append-only log of agent runs
├── review.md         # aggregated review status
└── summary.md        # final summary at session close
```

The Coordinator writes/updates `status.md` on every transition; agents read it before starting.

