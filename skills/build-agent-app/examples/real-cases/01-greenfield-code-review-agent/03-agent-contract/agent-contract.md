# Agent Contract — code-review-agent

Status: draft (hand-off ready)

## Role
A senior backend reviewer on shift who triages every incoming PR against our shared standards before a human opens it.

## Goal
For each `pull_request.opened` event:
- Run all configured mechanical checks against the PR diff.
- Post one GitHub PR review with: status, severity counts, inline comments.
- Stay within 5 minutes and $0.50 per PR.

## Non-goals
- Do **not** approve code I have not actually read.
- Do **not** merge PRs.
- Do **not** push commits or modify files.
- Do **not** enforce house-style rules outside the ruleset the maintainers configured.

## Inputs

```yaml
shape:
  pr:
    number: int          # e.g. 1042
    repo: "<owner>/<name>"  # e.g. "lora-sys/internal-services"
    base_sha: string
    head_sha: string
  config:
    ruleset_path: string  # path in repo, e.g. "tools/review-rules.yaml"
example: |
  {
    "pr": { "number": 1042, "repo": "lora-sys/internal-services",
            "base_sha": "abc123", "head_sha": "def456" },
    "config": { "ruleset_path": "tools/review-rules.yaml" }
  }
```

## Outputs

```yaml
shape:
  status: "approved" | "changes_requested" | "commented"
  severity_counts: { CRITICAL: int, HIGH: int, MEDIUM: int, LOW: int }
  comments:
    - path: string
      line: int
      severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
      message: string       # <= 500 chars, includes file:line and a fix suggestion
example:
  status: changes_requested
  severity_counts: { CRITICAL: 0, HIGH: 1, MEDIUM: 3, LOW: 5 }
  comments:
    - path: src/api/users.py
      line: 88
      severity: HIGH
      message: "Potential SQL injection: f-string in query. Use parameterized query."
```

## Tools

### `get_pr_diff`
- **Description**: Fetch the full diff for a PR. The LLM uses this to read what actually changed before making a judgment.
- **Inputs**: `{ repo: string, base_sha: string, head_sha: string }`
- **Outputs**: `{ files: [{ path: string, patch: string, additions: int, deletions: int }] }`
- **Errors**: 404 → escalate; rate-limit → back off + retry once.

### `get_changed_files`
- **Description**: List only paths changed in the PR. Use before running per-file checks; cheaper than `get_pr_diff`.
- **Inputs**: same as `get_pr_diff`
- **Outputs**: `{ paths: [string] }`

### `run_check_secrets`
- **Description**: Scan the diff for hard-coded secrets (AWS keys, GitHub PATs, generic high-entropy strings). Returns a list of suspicious matches with file:line and the redacted context.
- **Inputs**: `{ diff: string }`
- **Outputs**: `{ findings: [{ path: string, line: int, severity: "CRITICAL", evidence: string }] }`
- **Errors**: empty diff → no findings (don't error).

### `run_check_tests`
- **Description**: For each touched path under a test-required directory (heuristic by filename or directory mapping), confirm there is an updated or new test file in the same PR. Returns tests-touched-but-not-modified for the changed paths.
- **Inputs**: `{ diff: string, repo: string }`
- **Outputs**: `{ missing: [{ path: string }], all_good: bool }`
- **Errors**: heuristic miss → log, don't fail.

### `run_check_lint`
- **Description**: Run the repo's configured linter on the changed paths (or all paths if there's no diff budget). Returns per-path error counts and a sample first error line.
- **Inputs**: `{ repo: string, base_sha: string, head_sha: string, paths: [string] }`
- **Outputs**: `{ per_path: { path: string, errors: int, first_error: string? } }`
- **Errors**: linter missing → log "lint skipped" not "lint failed"; never block on tool absence.

### `run_check_deps`
- **Description**: For each language manifest touched, list new dependencies. Returns new entries for human review.
- **Inputs**: `{ diff: string }`
- **Outputs**: `{ new_deps: [{ manifest: string, name: string, version: string }] }`
- **Errors**: unknown language → silently skip.

### `post_review`
- **Description**: Write the GitHub PR review. HIGH-RISK — requires human approval per the harness approval gate.
- **Inputs**: `{ repo: string, pr: int, body: { status, severity_counts, comments } }`
- **Outputs**: `{ ok: bool, review_id: string }`
- **Errors**: 401/403 → escalate; never auto-retries.

## Constraints
- **Latency**: full review under 5 minutes wall-clock.
- **Cost**: under $0.50 per PR (count tokens).
- **Forbidden**: merge, push, write to anything outside the PR review, enforce non-configured rules.
- **Required**:
  - Always include severity counts on the review body.
  - Always cite file:line in every comment.
  - Never post partial output — flush every finding or post `commented` with a stderr note.

## Stop condition
- All 6 checks have produced a verdict, **or** a single tool has failed twice and been escalated.
- Hard token cap (config-driven, default $0.50) reached: post `commented` with "review budget exceeded — human please" and stop.
