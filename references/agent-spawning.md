# Agent Spawning Patterns

This is the contract for how the Coordinator summons sub-agents. The pattern below is used for every spawn in this skill.

## Required Spawn Prompt Skeleton

```
You are the <role> agent for Issue #<id> on branch <branch>.

Inputs (cite by document ID):
- Issue #<id>
- docs/evidence/<id>/implementation-plan.md
- <other doc IDs>

In-scope files (you may modify):
- path/to/file-1
- path/to/file-2

Out-of-scope files (do not modify):
- everything else; ask Coordinator before touching

Allowed operations:
- read anywhere
- write only the In-Scope files above
- run tests
- capture evidence to docs/evidence/<id>/

Outputs (specific paths):
- modified files in scope
- docs/evidence/<id>/change-summary.md
- docs/evidence/<id>/test-results/<...>
- <other outputs>

Acceptance Criteria (from Issue):
- ... (paste from Issue)

Evidence Required (from Issue):
- ... (paste from Issue)

Hard Constraints:
- do not modify main/master
- do not bypass Reviewers
- request Human Approval for: schema/auth/release changes
- cannot run destructive commands without explicit Permission

If any input is missing or contradictory, refuse and report to Coordinator.
Do not invent.
```

## Backgrounding

When the host supports it, parallel sub-agents can run with `run_in_background: true`. The Coordinator gathers via `TaskOutput` and continues the conversation in the same thread via `SendMessage` for stateful handoff.

## TaskList as Shared Kanban

The Coordinator maintains a `TaskList` that mirrors `PROJECT_STATUS.md`. Each sub-agent's task has:

- status: in_progress | pending | completed | blocked
- active-form: <what's happening now>
- content: short

The Coordinator updates statuses only after the agent returns — not optimistically.

