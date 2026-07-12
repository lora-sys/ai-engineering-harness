# Case 3 — Refactor a "Broken" Daily Digest Agent

This case shows the **`refactor-broken` workflow**, which is the smallest and most constrained of the three entry points. Six user complaints, six root causes, **one minimal-change proposal**.

## The Symptoms

`01-symptoms/broken-agent-brief.md` lists six complaints observed from real support tickets:

| # | Symptom | Verifiable? |
|---|---|---|
| 1 | "good morning" at 11pm | yes — check `local_hour != 0` |
| 2 | left out the emails I most cared about | yes — compare to a hand-tagged digest |
| 3 | $1.20 for a 7-bullet digest | yes — query the cost log |
| 4 | private Slack channel shown to manager | yes — red-team with private channels |
| 5 | length is wildly inconsistent (1–14 bullets) | yes — distribution over 100 digests |
| 6 | digest of "all emails ever" — missed a flight | yes — window assertion |

## What `02-diagnosis/diagnosis.md` does

It walks **symptom → principle → minimal fix**:

- Step 1 names the symptoms (no fix yet).
- Step 2 maps each complaint to ONE operating principle.
- Step 3 picks the **minimum** contracts that kill all six symptoms — in this case, **5** changes to the Agent + Harness contracts.
- Step 4 is **eval hooks first** — without these we can't tell the fix works.
- Step 5 is the hand-off plan for `$ai-engineering-harness`.

Notice what the diagnosis **does not do**: no refactor planning beyond 5 contracts. The discipline is *minimum diff*. Anything else is a follow-up Issue.

## Re-running

```text
Use $build-agent-app to diagnose examples/real-cases/03-refactor-daily-digest/01-symptoms/broken-agent-brief.md.
```
