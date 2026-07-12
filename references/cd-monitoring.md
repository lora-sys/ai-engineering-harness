# CI/CD Monitoring Pattern

A red CI is the only failure that is observable without subjective judgment. The harness treats it as a **blocking gate**, not a checkpoint. This document is the operational pattern for that gate.

## Roles

| Role | What they own |
| --- | --- |
| **QA Agent** (`agents/qa.md`) | Polls CI every ~60–120 s after each push. First-class owner of "is it green?" |
| **Owner Agent** | Watches CI, fixes red runs, pushes fixes, restarts the polling |
| **Coordinator** | Confirms green before Phase 8. Blocks reviews, merges, and Issue-closes while red. |
| **Release Agent** | Final CI gate before `gh release create`. Re-runs `references/evidence-formats.md`. |

## Polling cadence

| State | Cadence |
| --- | --- |
| Just pushed, waiting for first run | every 60 s |
| Failed, Owner is fixing | every 120 s; Owner pushes → restart |
| Green, no follow-up pushes | one terminal check, then stop |
| Same class failed twice in a row | every 60 s, AND file a CI Issue tagged `ci` |

Polling is intentionally not aggressive. 60 s is enough to catch the first state transition; hammering the API every 5 s adds load without insight.

## Failure classification

Use `workflows/04-ci-recovery.md` Step 1. The triage matrix:

| Class | Action | Rescuer |
| --- | --- | --- |
| Test flake (intermittent) | one re-run, then real-defect triage on second pass | Owner / QA |
| Real test failure | fix or roll back; push; restart | Owner |
| Lint / type | fix; push; restart | Owner |
| Build / dependency | read log; fix toolchain; push; restart | Owner |
| Integration / env | check secrets, env, network; may pause for Human Approval | Coordinator + Owner |
| Infra / runner | file a CI Issue; possibly re-run | Coordinator |
| Security scan (secrets, deps) | STOP — open Human Approval gate | Coordinator |

Anything beyond "test / lint / build" should pause for human eyes.

## Hard rules (no negotiation)

1. **Red CI = phase blocked.** No review-queue skipping. No "we'll fix it after". Coordinator enforces this in `PROJECT_STATUS.md` by leaving the Issue in **Implementing** until green.
2. **No partial CI as green.** "Lint passed, tests pending" is still red. All configured checks must pass before Phase 8.
3. **Flaky ≠ green.** A flaky test still counts as a defect until proven otherwise. One re-run, then `04-ci-recovery.md` triage on second failure.
4. **No "I read the diff and it looks fine" override.** If CI says red, CI says red. Owner pushes a fix.
5. **Merging while CI is red is an anti-pattern**, listed in `SKILL.md §13`.

## What an Owner Agent does on red

```text
1. Read failing job's log (download, don't skim — re-run the relevant step locally first).
2. Classify the failure using the matrix above.
3. If test / lint / build / dependency: fix in the same Worktree, push, return to Phase 7.
4. If integration / env / security: STOP, escalate to Coordinator.
5. If you see the same class fail twice in a row: open a CI Issue (`templates/issue-bug.md`)
   tagged `ci` AND add a line to `memory/lessons.md`. Do not silently retry.
```

## What Coordinator does on long-red (>2 builds, >30 min)

1. The Owner is either stuck, gone, or unable to fix. Re-spawn is not enough — confirm the Owner actually has the failing log.
2. If the failure looks environment-level, escalate to **Human Approval Gate** with: failing-job URL, last 200 lines of log, Owner hypothesis, options.
3. **Pause Phase 8 / Phase 11 / Phase 12 / Issue close** until either: green, Human Approval to override, or Issue re-classified as "won't fix".

## What QA Agent keeps an eye on

(From `agents/qa.md` v1.0.2 — added explicitly because it was implicit before.)

- `pull_request.opened` event → start polling
- Every push to the PR branch → restart polling from t=0
- Poll every 60–120 s until a verdict
- Capture the verdict (`docs/evidence/<id>/ci-log.txt`) on both green and first-red runs
- On second red of same class → file `ci`-tagged Issue, add to `memory/lessons.md`

## What "Done" looks like

An Issue is **Done** when, all of these hold:

- CI is **green** on the latest commit at the head of the PR branch
- Adversarial Review approvals are filed (≥2 reviewers per SKILL.md §7)
- Evidence is complete per `checklists/evidence-gate.md`
- Human Approval has been acquired if any blocker fired

Remove any one of these and **the Issue is not Done**, full stop.

## Cross-references

- `agents/coordinator.md` — added "Red CI = blocked phase" decision rule.
- `agents/qa.md` — added "CI/CD watching role" (this doc).
- `workflows/01-feature-delivery.md` Phase 7 — strengthened to BLOCKING GATE.
- `workflows/04-ci-recovery.md` — triage matrix; this doc extends it with the polling loop and "no partial CI as green" rule.
- `templates/issue-bug.md` — used to file CI-class Issues with the `ci` tag.
- `memory/lessons.md` — single-line entry per recurring CI pattern.
