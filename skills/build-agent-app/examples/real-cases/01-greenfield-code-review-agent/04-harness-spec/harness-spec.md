# Harness Spec — code-review-agent

## State
- **Long-term store**: ruleset file in repo (`tools/review-rules.yaml`), fetched every run; cached for 5 minutes.
- **Session store**: per-PR scratch — list of check results + draft review body. Dropped at the end.

## Memory
- **Short-term**: in-conversation tool call list + last finding buffer.
- **Long-term**: ruleset's per-repo overrides only. Never store chat. Never store the PR body.

## Eval
- **Per-task**: did the agent post a review (status + severity counts + comments) for this PR? compare to a hand-tagged sample of 50 PRs, expect precision ≥ 0.9 on secrets detection, recall ≥ 0.7. Run on every 10th PR in prod; always on canary projects.
- **Per-capability**: weekly aggregate. False-positive rate over secret detection, retry rate per tool, total $/PR. Page on-call if $/PR p95 > $0.50.

## Observability
- **Log every run** to `s3://review-agent-logs/<repo>/<pr>.json`. Fields: pr, final_status, severity_counts, tool calls (in order, with latency), stop reason, tokens, errors.
- **Dashboard**: per-repo PR-count, $/PR, top 3 finding categories, weekly false-positive rate.

## Failure handling

| Tool | Error | Action |
|---|---|---|
| `get_pr_diff` | 404 | Escalate to user with link |
| `get_pr_diff` | rate-limit | Retry once after 30s |
| any check | timeout | Retry once, then mark `skipped` and continue |
| `post_review` | 401/403 | **Pause for human approval** before retrying |

Run-level failure: a tool failed twice in a row → pause run, post `commented` with the partial summary, ask for human in the PR.

## Human approval gate

| Action class | Approval |
|---|---|
| Read-only (`get_pr_diff`, `get_changed_files`, `run_check_*`) | **No** — these are safe. |
| External visible (`post_review`) | **Yes** — every PR review write is a public message. The harness pauses the run for approval. |
| Anything else (`merge`, `push`, `approve`) | **Disabled** — these tools are NOT exposed; would require a separate identity check. |

## Cost target
- $0.50 / PR ceiling (token budget ceiling).
- Daily ceiling: depends on PR volume.
- Action when exceeded: post `commented` with budget note, do not retry.
