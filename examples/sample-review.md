# Sample — Reviewer Report (bug-hunter)

## Reviewer
bug-hunter

## Inputs Reviewed
- Issue #42
- docs/evidence/42/implementation-plan.md
- PR #42 (commit abc123)
- docs/evidence/42/test-results/*

## Findings
| # | Severity | File:Line | Category | Description | Repro / Evidence | Suggested Fix |
|---|----------|-----------|----------|-------------|------------------|---------------|
| 1 | Medium   | src/api/auth/oauth.ts:88 | race | Concurrent callback + logout can leave DB row orphaned | unit/replay.test.ts flake, trace shows interleaving | Wrap link-or-create in advisory lock or `INSERT ... ON CONFLICT DO NOTHING` |
| 2 | Low      | src/components/auth/GithubButton.tsx:24 | a11y | Button lacks aria-busy during redirect | manual | Add aria-busy="true" on click |

## Hunting Checklist
- [x] Null/undefined paths
- [x] Exception swallowing (none observed)
- [x] Off-by-one (none)
- [x] Race / ordering — finding 1 above
- [x] Boundary inputs (state, nonce)
- [x] Resource cleanup (cookies cleared)
- [x] Error mapping (codes consistent)

## Status
⚠️ Non-blocking (no Critical/High). Owner should fix M/L in follow-up #43 or this PR.

## Notes for Implementer
Finding 1 is a real but rare race. Fix is small. Recommend same PR; if not, file Issue #43.

