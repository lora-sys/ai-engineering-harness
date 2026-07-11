# Workflow — Issue Lifecycle

States an Issue moves through, plus the kanban columns in `PROJECT_STATUS.md`.

## Kanban Columns

| Column | Meaning | Entry criteria | Exit criteria |
|--------|---------|----------------|----------------|
| Todo | Backlog, prioritized, deps identified | Validated against PRD/MVP roadmap | Plan + Owner assigned |
| Planning | Plan/ADR being written | Classified (M / A / R) | Implementation Plan exists |
| Implementing | Code being written in a Worktree | Plan exists and approved by Coordinator | Draft PR open |
| Review | Reviewers + CI running | Draft PR + Evidence seeded | Aggregator ✅ Approved |
| Testing | Active QA / e2e verification | Aggregator passed or routine | Evidence Gate passed |
| Blocked | Stuck (CI, review, deps, spec ambiguity) | Coordinator or Owner marked | Unblocked note + owner |
| Done | Merged + Issue closed + memory updated | PR merged | — |

## Required Fields on Every Issue

The Coordinator verifies before moving to Implementation:

- Context — why this matters, cited doc IDs.
- Goal — single sentence.
- Scope — explicit files/modules.
- Non-Goal — explicit exclusions.
- Related Docs — `docs/...` IDs.
- Implementation Plan — pointer (file in evidence/) or draft in the Issue.
- Acceptance Criteria — bullet checklist.
- Evidence Requirements — what proof counts as Done.
- Reviewer Requirements — which reviewers must sign.
- Owner — single human/agent handle.
- Estimate — small / medium / large.

If any field is missing, Issue stays in Todo.

