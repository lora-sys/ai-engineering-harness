# Workflow — Memory Evolution

Memory is durable improvement, not decoration.

## When to Run

- End of each phase (paired with `06-phase-summary.md`).
- After a hard bug or surprising incident.
- After a pattern of repeated mistakes (≥3 in `lessons.md`).

## Inputs

- Phase summary.
- Latest reviewer reports.
- Recent PR diffs.

## Outputs (patches, not whole rewrites)

- Add to `memory/project-memory.md` if product truth changed.
- Add to `memory/architecture-memory.md` if pattern strengthened.
- Add to `memory/lessons.md` if a class of mistake recurred.
- Promote to ADR if a decision became binding.
- If a pattern is reusable, create or update a skill/template under `skills/` or `templates/`.

## Rules

- One bullet = one fact.
- Date every entry (so freshness can be checked).
- Tag entry status: `durable` / `tentative` / `stale`. Stale entries get deprecated.
- Never enshrine single-incident trivia.

