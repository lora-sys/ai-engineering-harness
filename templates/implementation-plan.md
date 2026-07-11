# Implementation Plan

Save as `docs/evidence/<issue-id>/implementation-plan.md`. Authored by the `plan` agent, reviewed by the Coordinator before implementation begins.

```markdown
## Issue
- ID: #
- Title:
- Owner: @<owner>
- Class: M (MVP) | A (architecture) | R (routine)

## Goal Recap
<2–3 lines from Issue>

## Architectural Decisions
- ADR-XXXX: <title>  ← cite if introducing
- Existing ADR impact: ADR-XXXX — applied as-is / needs amendment

## Change Surface

### Files
- Create: path/...
- Modify: path/...
- Delete: path/...

### Public Interfaces
- API: <method> <path> — request/response shape, status codes, errors
- Component: <name> — props, state, events
- DB: <table> — added columns / indexes / constraints

### Schema / Migration
- `db/migrations/<ts>_<name>.up.sql`
- `db/migrations/<ts>_<name>.down.sql`
- Backfill plan: ...
- Row-count impact: ...

## Sequencing
1. <step>
2. <step>
3. <step>
- Parallelizable: <steps that may run concurrently>

## Tests

### Unit
- ...

### Integration
- ...

### E2E / Browser
- ...

### Manual
- ...

## Evidence Plan
- Screenshots: at <route> desktop+mobile, empty/loading/error
- API trace: capture from staging or local
- DB: pre/post stats, sample rows
- Security probes (if applicable):

## Risk
- Reversible / irreversible
- Performance impact
- Compatibility

## Rollback
- ...

## Out of Scope
- Reinforced from Issue Non-Goal

## Reviewer Requirements
- bug-hunter, behavior-reviewer, architecture-reviewer, [security-reviewer], [ui-reviewer]

## Acceptance Criteria (mapped to tests)
| AC | Test |
|----|------|
```

