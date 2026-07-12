# PRD: PR Review Agent for internal-services monorepo

## Goal
Give every PR a fast, consistent first-pass review before a human reviewer opens it.

## Why
- Current bottleneck: human reviewers spend ~30-60 min per PR on mechanical checks.
- Junior reviewers give inconsistent feedback on style/safety.
- Senior reviewers get pulled into routine work.

## Must do
- Check every PR for: secrets in code, broken tests in the diff, lint errors, migration without rollback, new dep without security audit.
- Annotate with a comment per finding, with file:line and a suggested fix.
- Approve or request-changes based on a numeric severity threshold.

## Must NOT do
- Approve / merge PRs.
- Push commits or modify code.
- Comment on style preferences outside the configured rules.

## Inputs
- PR URL (GitHub PR hook) or PR diff (raw git format-patch).

## Outputs
- A PR review with: status (approved | changes_requested | commented), severity counts (CRITICAL/HIGH/MEDIUM/LOW), and inline comments.

## Constraints
- Latency: emit review within 5 minutes of `pull_request.opened` event.
- Cost: under $0.50 per PR.
- Privacy: never echo the PR body back to the user.
