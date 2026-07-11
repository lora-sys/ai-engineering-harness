# Evidence Formats

Evidence is the system of record. Without it, "Done" doesn't exist.

## Per Change Type

| Type      | Required files                                                                                       |
| --------- | ---------------------------------------------------------------------------------------------------- |
| Frontend  | screenshots/{desktop,mobile,empty,error,loading}.png; test-results/{playwright.json,console.log}; verification.md |
| Backend   | test-results/{api.json,exceptions.log}; verification.md                                              |
| Database  | db/{migration.sql,rollback.sql,pre-stats.md,post-stats.md}; verification.md                          |
| Infra     | deploy/{dry-run.log,env-diff.md}; verification.md                                                    |
| Cross-cut | change-summary.md; review-<role>.md (per reviewer); fix-tasks.md (from aggregator)                  |

## Naming

`docs/evidence/<issue-id>/...` — issue-id is the Issue number or local equivalent (`42` or `ISSUE-42`). Consistent across the project.

## Storage

- Tracked in git (`docs/evidence/...`) so it survives reviewer turnover and CI.
- Large artifacts (videos, traces): store the **conclusions** in git; keep the binary in object storage and link.

## Validity

- Evidence older than the latest push on the branch is stale; re-run before merge.
- A reviewer can request specific evidence to be regenerated even if the artifacts exist.

