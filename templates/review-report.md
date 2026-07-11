# Review Report Template

Common skeleton used by bug-hunter, behavior-reviewer, architecture-reviewer, security-reviewer, ui-reviewer.

Each reviewer populates the table and writes a structured summary. Cold-start rule: **no exposure to implementer chat or self-justification**.

```markdown
## Reviewer
<role>

## Inputs Reviewed
- Issue #...
- Implementation Plan: docs/evidence/<id>/implementation-plan.md
- PR diff: <link/commit>
- Evidence: docs/evidence/<id>/

## Findings
| # | Severity | File:Line | Category | Description | Repro / Evidence | Suggested Fix |
|---|----------|-----------|----------|-------------|------------------|---------------|
| 1 | Critical | path:LL  | category | ... | ... | ... |

### Severity Scale
- **Critical** — correctness bug, security vulnerability, data loss, blocking release.
- **High** — incorrect behavior under realistic conditions.
- **Medium** — minor defect or brittleness.
- **Low** — polish / consistency.

## Checklist (role-specific)
- [ ] item
- [ ] item

## Status
❌ Blocking (Critical/High open) | ⚠️ Non-blocking | ✅ Approved

## Notes for Implementer
<one short paragraph>
```

