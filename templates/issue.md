# Issue Template — Generic

Use this template when creating an Issue. The Coordinator refuses to start work on an Issue missing required fields.

```markdown
## Context
<why this matters; reference PRD/spec sections by file:line or doc ID>

## Goal
<one sentence>

## Scope
- In: <module/area>
- In: <module/area>

## Non-Goal
- Out: <what we are NOT doing in this Issue>
- Out: <...>

## Related Docs
- docs/product/prd.md §<anchor>
- docs/architecture/<module>.md
- ADR-XXXX (if applicable)

## Implementation Plan
<file path to plan, or inline summary>

## Acceptance Criteria
- [ ] ...
- [ ] ...

## Evidence Requirements
- [ ] Tests:
- [ ] Frontend screenshots:
- [ ] API/contract tests:
- [ ] Migration + rollback:
- [ ] Perf / security / a11y (if applicable):

## Reviewer Requirements
- [ ] bug-hunter
- [ ] behavior-reviewer
- [ ] architecture-reviewer (if applicable)
- [ ] security-reviewer (if applicable)
- [ ] ui-reviewer (if applicable)

## Owner
@<owner>

## Estimate
small | medium | large

## Risk Notes
- ...
```

