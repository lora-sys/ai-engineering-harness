# PROJECT_STATUS.md

The live kanban + summary state. Updated by the Coordinator at every Issue transition. Authoritative for human readers.

```markdown
# Project Status

_Last updated: YYYY-MM-DD by @coordinator_

## Now (in progress)
- Issue #ID — title — Owner: @x — Phase: Implementing — branch: feature/...

## Backlog
- Issue #ID — title — size: M — class: M

## Blocked (Waiting for Approval / external)
- Issue #ID — title — Blocked on: <human | vendor | spec>

## Recently Merged
- Issue #ID — title — PR #N — Evidence: docs/evidence/<id>/

## Open Reviewer Threads
- PR #N — Bug Hunter: ❌ / Behavior: ✅ / Architecture: ⚠️

## Phase
- Phase 0 — Bootstrap — Done
- Phase 1 — Core shell — In Progress
- Phase 2 — MVP features — Planned

## Health
- Tests: green | red
- CI: green | red
- Docs freshness: see docs/.index/freshness.json
- Memory: see memory/

## Risks
- ...
```

