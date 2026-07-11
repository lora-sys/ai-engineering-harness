# Workflow — Feature Delivery

The full life cycle of one Issue from "open" to "merged". Used for MVP and architecture-impacting work.

## Phase 0 — Classify

On Issue intake, decide:

| Signal | Class | Workflow |
|--------|-------|----------|
| MVP / first feature | `M` | This workflow in full |
| Touches auth, schema, infra, paid APIs | `A` (architecture) | This workflow + Human Approval Gate |
| Touches docs only, small UI fix, copy edit | `R` (routine) | Lean workflow: Plan → Implement → Self-test → Reviewers → PR |

Coordinator writes its decision into the Issue comment.

## Phase 1 — Plan

1. Spawn `context-assembly` → `context-manifest.md` for the issue.
2. Spawn `plan` → `implementation-plan.md` (use `templates/implementation-plan.md`).
3. Coordinator reviews the plan; if it introduces an architectural decision, draft a new ADR (`templates/adr.md`).
4. For class `A`: request Human Approval on the ADR.

## Phase 2 — Branch + Worktree

The implementing Agent (or Coordinator) creates:

```bash
git worktree add ../<project>-issue-<id> -b feature/<id>-<slug> main
cd ../<project>-issue-<id>
```

Document in `PROJECT_STATUS.md` and on the Issue.

## Phase 3 — Implement

Spawn Owner Agent (frontend / backend / database, possibly parallel — see `references/worktree-discipline.md`).

Owner produces:

- Code modifications in allow-list.
- Self-tests.
- Commit history with conventional messages: `feat(scope): description (#<id>)`.

## Phase 4 — Self-test

Owner runs their own tests before opening PR. Captures results in `docs/evidence/<id>/test-results/`.

## Phase 5 — Evidence Assembly

QA agent (or Owner) compiles `docs/evidence/<id>/` with everything required by `checklists/evidence-gate.md` for the change type.

## Phase 6 — Open Draft PR

PR template from `templates/pr-description.md`. Mark Draft until reviews run.

## Phase 7 — CI

Wait for CI. If it fails → `04-ci-recovery.md`. If it passes → reviewers.

## Phase 8 — Adversarial Review

Run `workflows/03-adversarial-pr-review.md`. Minimum 2 reviewers (Bug Hunter + Behavior Reviewer). Conditional: Architecture Reviewer always for `A`/large diffs, Security Reviewer if sensitive, UI Reviewer if UI.

## Phase 9 — Aggregator

`review-aggregator.md` produces `fix-tasks.md`. Coordinator re-spawns Owner(s) with the task list. Loop until Aggregator reports ✅ Approved.

## Phase 10 — Evidence Gate

Run `checklists/evidence-gate.md`. Coordinator signs off.

## Phase 11 — Human Approval Gate (conditional)

For class `A`: Coordinator pauses, posts a clear summary, awaits approval.

## Phase 12 — Merge

```bash
# Squash or rebase per repo policy; default: squash with refs.
gh pr ready
gh pr merge --squash --delete-branch
```

## Phase 13 — Post-merge

- Issue auto-closes.
- `PROJECT_STATUS.md` updated.
- `docs/evidence/<id>/` linked from the closest phase summary.
- `memory/*` updated by `memory-curator` if patterns are stable.
- `git worktree remove` for the merged branch.

## Phase 14 — Next

Coordinator picks the next Todo from `PROJECT_STATUS.md` and re-enters at Phase 0.

