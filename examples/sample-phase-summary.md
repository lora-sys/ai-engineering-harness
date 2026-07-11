# Sample — Phase Summary

# Phase 2 Summary — Auth MVP

## Goals & Exit Criteria
- Ship GitHub login, magic-link login, session refresh.
- Stabilize session store; no P0 bugs reported by 7-day soak.

## Shipped (PRs)
- #42 GitHub OAuth login — Evidence: docs/evidence/42/
- #50 Magic-link login — Evidence: docs/evidence/50/
- #55 Session refresh — Evidence: docs/evidence/55/

## Structural Changes
- New modules: `src/api/auth/oauth.ts`, `src/api/auth/magicLink.ts`, `src/lib/session/`.
- New schema: `oauth_accounts`, `magic_links` (additive).

## Reviewer Patterns
- Bug Hunter: race conditions on callback/link (resolved with advisory locks).
- Security Reviewer: redirect_uri allow-list became a reusable helper.

## Decisions
- ADR-0042: OAuth provider abstraction.
- ADR-0043: Magic-link token shape.

## Lessons
- Always capture post-merge evidence before declaring Done; one PR shipped without Evidence in this phase, caught in review.
- Use `agent-browser` consistently for OAuth UI snapshots (Playwright alone missed the redirect interim state).

## Open Follow-up Issues
- #63 Google OAuth — modeled on ADR-0042.
- #67 Rate-limit sign-in attempts.

## Next Phase
- Phase 3: on-boarding flows.
- Risks: invite tokens may collide with magic links; will revisit ADR-0043.

