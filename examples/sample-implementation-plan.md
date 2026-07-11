# Sample — Implementation Plan (filled)

## Issue
- ID: 42
- Title: GitHub OAuth login
- Owner: @<backend-owner>
- Class: A (architecture — auth)

## Goal Recap
Allow users to log in with GitHub; auto-link by verified email; enforce PKCE/state.

## Architectural Decisions
- ADR-0007 applied as-is for session/token storage.
- New ADR-0042: OAuth provider abstraction (justified — needed for future Google/Apple).

## Change Surface

### Files
- Create: src/api/auth/oauth.ts
- Create: src/components/auth/GithubButton.tsx
- Modify: src/api/auth/index.ts (route map)
- Modify: src/services/users/index.ts (link by email)
- Modify: src/lib/session/cookies.ts (OAuth cookie path)
- Create: db/migrations/20260710120000_add_oauth_provider.sql

### Public Interfaces
- `GET /auth/github` — start, returns 302.
- `GET /auth/github/callback` — finishes, returns 302 to app.
- Errors: 400 invalid_state, 401 user_denied, 500 provider_error.

### Schema / Migration
- New table `oauth_accounts(id, user_id, provider, provider_user_id, created_at)`.
- Index `idx_oauth_provider_user(provider, provider_user_id)` UNIQUE.
- Backfill: none.
- Row-count impact: ~current user count on first login.

## Sequencing
1. Migration + repository.
2. OAuth abstraction + GitHub adapter.
3. Routes + handlers + tests.
4. Frontend button + Playwright.
5. Aggregator review.

## Tests
### Unit
- state/PKCE generation.
- email linking rules.

### Integration
- /auth/github/callback happy path (200 → 302).
- Token exchange mocked at provider boundary.

### E2E / Browser
- e2e/github-login.spec.ts: clicks button, mocks GitHub, asserts logged-in shell.

### Manual
- Live test against sandbox GitHub OAuth app.

## Evidence Plan
- Screenshots: login page (with GitHub button), post-login landing.
- API trace: full callback flow.
- DB: pre/post row counts on `oauth_accounts`.
- Security probes: replay, mismatched-state, redirect_uri tampering.

## Risk
- Auth change. Reversible only via the migration's down + clearing cookies.

## Rollback
- Revert migration, remove routes, redeploy.

## Out of Scope
Reaffirmed: no Google/Apple, no SAML.

## Reviewer Requirements
bug-hunter, behavior-reviewer, architecture-reviewer, security-reviewer, ui-reviewer (judgment).

## Acceptance Criteria → Tests
| AC | Test |
|----|------|
| Happy path GitHub login | e2e/github-login.spec.ts |
| Auto-link by verified email | unit/autoLink.test.ts |
| Logout clears session | integration/logout.test.ts |
| State / PKCE / redirect_uri | unit/security.test.ts + security review |

