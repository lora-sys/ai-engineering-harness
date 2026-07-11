# Workflow — CI Recovery

Trigger: PR CI failed.

## Step 1 — Triage in 60 seconds

Coordinator (or `qa` agent) reads the failing job's logs and the PR diff. Classify:

| Failure class     | Action                                                       |
| ----------------- | ------------------------------------------------------------ |
| Test flake        | Re-run once, then capture history. If 2nd pass fails, treat as real defect. |
| Real test failure | Owner fixes; new commit; re-run CI.                          |
| Lint / type       | Owner fixes; new commit.                                     |
| Build             | Owner fixes; new commit.                                     |
| Integration / env | Coordinator + Owner; check secrets, env, network. May need Human Approval. |
| Infra / runner    | Coordinator documents, files an Issue against CI, possibly re-runs. |

## Step 2 — Owner Loop

Spawn Owner Agent with the failing log + a single-page fix plan. Owner commits. Push. CI re-runs.

## Step 3 — Verify

Coordinator confirms CI green before letting the PR move forward. No human pass-through is required for class-level fixes.

## Step 4 — Recurrence Signal

If the same class fails twice in a row → file a CI Issue (`templates/issue-bug.md`) tagged `ci`, with the relevant logs. `memory/lessons.md` gets a one-line entry on the pattern.

