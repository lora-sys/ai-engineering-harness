# Workflow — Conflict Resolution

Trigger: merge conflict on a PR, or two Agents/PRs touching the same code.

## Step 1 — Identify Owners

For each conflicting side, capture: branch / Agent, Issue ID, Plan excerpt, recent commits.

## Step 2 — Spawn Conflict Resolver

`agents/conflict-resolver.md` reads both sides and writes `docs/evidence/<merge-id>/conflict-resolution.md`.

## Step 3 — Classify

- **Textual conflict, no semantic overlap** → Resolver proposes patch; Coordinator approves; Owner applies.
- **Semantic overlap** → split into sub-tasks; each Owner owns the branch that better fits the architecture; the other Owner re-scopes.
- **Architectural disagreement** → Coordinator blocks and spawns ADR authors; escalate to Human Approval.

## Step 4 — Apply

- Trivial textual: Coordinator may direct the Owner to apply.
- Anything else: Owner Agent applies with a structured commit `merge(<ids>): <what>`.

## Step 5 — Verify

Re-run tests + adversarial review on the merged branch. A conflict resolution does not bypass Reviewers.

## Anti-Patterns

- "Take theirs" or "take mine" without rationale.
- Auto-resolution in git when conflict has semantic content.
- Continuing to merge in CI failure.

