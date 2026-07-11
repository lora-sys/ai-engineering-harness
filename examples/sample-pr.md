# Sample — PR Description

## Related Issue
Closes #42

## Summary
- Adds GitHub OAuth login via `/auth/github` route.
- Adds `oauth_accounts` table with provider+provider_user_id unique.
- Email auto-link when GitHub email is verified and matches an existing user.
- Frontend button on the login screen.

## Motivation
Reduces friction for the dominant user segment and removes the "forgot password" funnel. Per PRD §3.2.

## Changed Files
- (filled in by GitHub on PR open)
- New: src/api/auth/oauth.ts; src/components/auth/GithubButton.tsx; db/migrations/20260710_oauth.sql
- Modified: src/api/auth/index.ts; src/services/users/index.ts; src/lib/session/cookies.ts; docs/api/auth.md

## Architecture Impact
- New module: `src/api/auth/oauth.ts` (provider abstraction allows Google/Apple later).
- New ADR: docs/decisions/0042-oauth-abstraction.md.
- Schema change: `oauth_accounts` (additive).

## Testing
- Unit: +12 (auth/link/state)
- Integration: +4 (callback + replay)
- E2E: +1 (Playwright login flow)

## Evidence
- docs/evidence/42/change-summary.md
- docs/evidence/42/test-results/playwright.json
- docs/evidence/42/screenshots/login.png; landing.png
- docs/evidence/42/db/pre-stats.md; post-stats.md
- docs/evidence/42/review-bug-hunter.md ✅
- docs/evidence/42/review-behavior-reviewer.md ✅
- docs/evidence/42/review-architecture-reviewer.md ✅
- docs/evidence/42/review-security-reviewer.md ✅
- docs/evidence/42/fix-tasks.md (Aggregator: ✅)

## Risk
Auth change — Human Approval obtained.

## Rollback Plan
Revert migration; remove routes; redeploy. ≤ 5 minutes.

## Checklist
- [x] Issue body complete
- [x] Plan present
- [x] Tests added/updated, locally green
- [x] CI green
- [x] Required reviewers approved
- [x] Evidence complete
- [x] No Critical/High open
- [x] Docs updated (auth.md + ADR)
- [x] No secrets
- [x] Changelog: "Add GitHub OAuth login"

