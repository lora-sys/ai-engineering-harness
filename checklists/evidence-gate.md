# Evidence Gate

The Coordinator must complete **every box** relevant to the change type before declaring Done. Anything missing → back to the Owner Agent.

## Universal

- [ ] `docs/evidence/<id>/change-summary.md` exists, has Issue link.
- [ ] `docs/evidence/<id>/verification.md` walks each Acceptance Criterion with PASS/FAIL.
- [ ] All required reviewers' reports exist in `docs/evidence/<id>/`.
- [ ] Aggregator status: ✅ Approved.
- [ ] **CI is GREEN on the latest commit at the head of the PR branch.** A red CI — even with passing reviews — fails this gate. Polling cadence per `references/cd-monitoring.md`. Capture the CI log at `docs/evidence/<id>/ci-log.txt`. If CI failed ≥2x on the same class: a `ci`-tagged Issue exists, and `memory/lessons.md` carries a one-line entry.
- [ ] No "partial CI as green". All configured checks must pass — lint, tests, build, security scan.
- [ ] Branch is up to date with main/rebase target.

## Frontend (UI)

- [ ] Playwright run on Chromium + Firefox (or whatever the project requires), trace attached.
- [ ] Screenshots: desktop (1440), tablet (834), mobile (390) for primary route.
- [ ] Empty state, loading state, error state captured.
- [ ] Console clean (no errors, no unhandled promise rejections).
- [ ] axe-core / a11y scan passed at AA.
- [ ] Reduced-motion check verified for any animations.
- [ ] UI Reviewer report attached and approved.

## Backend (API/Service)

- [ ] Unit tests cover happy + error path + boundary.
- [ ] Integration / contract test against the live schema (or testcontainers equivalent).
- [ ] API trace captured (status codes, payloads, latency p50/p95).
- [ ] Exception paths return the documented error shape.
- [ ] Authorization negative cases (no token, wrong role, expired) tested.
- [ ] Idempotency / retry semantics covered where the contract demands them.

## Database

- [ ] Migration up + down tested locally.
- [ ] Pre/post row counts + sample row query captured.
- [ ] Long-running migrations rehearsed against a representative dataset size.
- [ ] Indexes `CONCURRENT` where supported.
- [ ] Backfill procedure (if data moves) is in `docs/evidence/<id>/db/`.
- [ ] Lock duration / outage estimate stated.

## Security (when applicable)

- [ ] Threat model section in `docs/evidence/<id>/threat-model.md`.
- [ ] Auth negative + positive tests run.
- [ ] Dependency audit (`npm audit` / `pip-audit` / `govulncheck` etc.) clean.
- [ ] Secrets scan clean (`gitleaks` / `trufflehog`).
- [ ] CSP / CORS / headers unchanged or intentionally updated with rationale.

## Infra / DevOps

- [ ] Deploy dry-run captured.
- [ ] Environment diff (vars, secrets, infra) captured.
- [ ] Feature flags / kill switches documented.

## Cross-Cutting

- [ ] No secrets / credentials in the diff.
- [ ] No `.env`, no build artifacts, no node_modules — `.gitignore` rules observed.
- [ ] Docs updated OR follow-up Issue filed for doc update.
- [ ] Changelog updated for user-facing change.
- [ ] `PROJECT_STATUS.md` reflects current Issue state.

