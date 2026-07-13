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

### 3.0 — Bundle context (one-shot, parallel)

Before spawning the Owner Agent, Coordinator dumps a context bundle so sub-agents don't each re-explore the repo:

```bash
bash scripts/context-bundle.sh \
  --out docs/evidence/<id>/context-bundle.md \
  --commits 20
```

The bundle (`references/context-bundle.md`) includes repo identity, recent commits, working-tree state, top-level layout, open issues/PRs (if `gh` is authenticated), key harness files, recent memory notes, and the harness roster. Sections run in parallel; wall time ~5–8 s.

Sub-agents spawned in Phase 3+ read `docs/evidence/<id>/context-bundle.md` from their context manifest instead of running their own `git log` / `ls` / `find`.

### 3.1 — Spawn Owner

Spawn Owner Agent (frontend / backend / database, possibly parallel — see `references/worktree-discipline.md`).

Owner produces:

- Code modifications in allow-list.
- Self-tests.
- Commit history with conventional messages: `feat(scope): description (#<id>)`.
- Free-form `implementation-report.md` in `docs/evidence/<id>/`.

When Owner finishes, Coordinator (or Owner itself) calls `scripts/compact-report.sh --evidence-dir docs/evidence/<id>/ --branch <branch> --agent <name>` to produce a `compact-report.json` the parent can read in 200 bytes instead of 20 KB. See `references/compact-report.md`.

## Phase 4 — Self-test

Owner runs their own tests before opening PR. Captures results in `docs/evidence/<id>/test-results/`.

## Phase 5 — Evidence Assembly

QA agent (or Owner) compiles `docs/evidence/<id>/` with everything required by `checklists/evidence-gate.md` for the change type.

## Phase 6 — Open Draft PR

PR template from `templates/pr-description.md`. Mark Draft until reviews run.

## Phase 7 — CI  (BLOCKING GATE — do not advance while red)

**Behavior**: Owner Agent keeps eyes on CI from the moment the first commit lands on the branch. Coordinator does not allow Phase 8 until CI is green.

**Sequence**:

1. Owner pushes first commit.
2. Owner (and Coordinator) watch CI dashboard. Polling cadence: every ~60–120 s until green, then once on every subsequent push.
3. Push → wait → CI finishes:
   - **Green** → Phase 8 (Adversarial Review).
   - **Red** → Owner does NOT say "Done". `04-ci-recovery.md` runs. Loop until green.
4. Coordinator blocks any of: requesting review, requesting merge, marking Issue Done, or closing the Issue.

**Hard rules**:

- A red CI is the only failure that is observable without subjective judgment. The harness **never** treats it as "best effort".
- A flaky test failure still counts as a defect until proven otherwise (see `04-ci-recovery.md` re-run policy: at most one re-run before real-defect triage).
- Merging while CI is red, or asking for review while CI is red, are both classified as **anti-patterns** (see SKILL.md §13).

**What the Owner watches for**:

- Failing unit / integration test → read the trace, fix the test or the code, push.
- Lint / type error → fix the lint or the type signature, push.
- Build error → read the build log, fix the dependency / toolchain breakage, push.
- Integration / environment error → Coordinator (with Owner) checks secrets, env, network; may pause for Human Approval.
- Infra / runner flake → Coordinator files a CI Issue, possibly re-runs.

If the same class fails twice in a row → file a CI Issue tagged `ci` (template: `templates/issue-bug.md`) and a one-line `memory/lessons.md` entry.

**Hand-off**: only Phase 8 (review) starts. Everything else (request review, merge, close Issue, plan next Issue) is suspended until CI is green.

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

