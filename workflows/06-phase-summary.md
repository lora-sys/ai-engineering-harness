# Workflow — Phase Summary

At the end of each phase (a group of related merged Issues, e.g. "Phase 2: Auth"), the Coordinator and `memory-curator` produce a phase summary.

## Trigger

- Last Issue of a phase merged, OR explicit milestone decision (release, MVP freeze, etc.).

## Input

- All Evidence dirs of issues in the phase.
- Diff vs previous phase tag.
- Review Aggregator reports.

## Output

`docs/sessions/phase-<n>/summary.md` covering:

- Goals & exit criteria — what we said we'd ship.
- Shipped — bullet list with PR + Evidence links.
- Diffed — what changed structurally (new modules, deleted modules, schema migrations).
- Reviewer patterns — recurring findings by Reviewer.
- Decisions — new ADRs, changed ADRs.
- Lessons — recurring themes that became memory entries.
- Open follow-up Issues — pointer list.
- Next phase — what we plan, with risks.

Also update `memory/architecture-memory.md` and (if novel patterns) promote an Agent or template.

