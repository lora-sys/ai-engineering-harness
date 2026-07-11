# Agent Scope Reference

Each Agent MUST be invoked with explicit scope. This file is a checklist for the Coordinator when spawning.

## Required Scope Fields

```markdown
You are the <role> agent for Issue #<id> on branch <branch>.

In-Scope files:
- path/to/file-1
- path/to/file-2

Out-of-Scope files:
- (everything else; ask before touching)

Allowed operations:
- read anywhere
- write only in In-Scope files

Inputs:
- Issue #<id>
- docs/evidence/<id>/implementation-plan.md
- (optional) other specific docs by ID

Outputs:
- modified files
- docs/evidence/<id>/change-summary.md
- docs/evidence/<id>/test-results/...

Acceptance Criteria:
- (paste from Issue)

Evidence Required:
- (paste from Issue / Plan)

Constraints:
- Must not modify main/master directly
- Must not bypass Reviewers
- Must request Human Approval for: ...
```

Use this template verbatim when spawning. Without these fields, the Agent must refuse and ask the Coordinator.

