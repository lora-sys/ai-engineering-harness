# Sample — Issue (filled)

## Context
Customers have asked for a way to log in with their GitHub account instead of forcing them to create a new password. This unblocks adoption for users already in the GitHub ecosystem and reduces support load for forgotten passwords. Reference: docs/product/prd.md §3.2 (auth story 2).

## Goal
Allow users to sign in / sign up with GitHub OAuth.

## Scope
- `src/api/auth/` — OAuth handlers
- `src/services/users/` — link-by-email logic
- `src/components/auth/GithubButton.tsx`
- `db/migrations/<ts>_add_oauth_provider.sql`
- `docs/api/auth.md`

## Non-Goal
- Other OAuth providers (Google, Apple) — separate Issues.
- Enterprise SSO (SAML) — out of MVP.

## Related Docs
- docs/product/prd.md §3.2
- docs/architecture/security.md
- ADR-0007 (session management)

## Implementation Plan
docs/evidence/42/implementation-plan.md (will be written by `plan` agent)

## Acceptance Criteria
- [ ] User can click "Continue with GitHub", is redirected to GitHub, returns logged in.
- [ ] User with matching email is auto-linked; new user is registered.
- [ ] Sessions use existing session store (no duplication).
- [ ] Logout from web removes the OAuth session cookie.
- [ ] Security: state param, PKCE, redirect_uri allow-list enforced.

## Evidence Requirements
- [ ] API tests covering success, denial, mismatched-email, replay.
- [ ] Playwright e2e: happy path + denial path + screenshot of auth UI.
- [ ] Migration + rollback rehearsed.
- [ ] Security Reviewer report.

## Reviewer Requirements
- [x] bug-hunter
- [x] behavior-reviewer
- [x] architecture-reviewer
- [x] security-reviewer
- [ ] ui-reviewer (minor button — Coord judgment call)

## Owner
@<frontend-owner> @<backend-owner> @<database-owner>

## Estimate
medium

## Risk Notes
Touches auth → Human Approval required.

