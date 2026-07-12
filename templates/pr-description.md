# PR Description

```markdown
## Related Issue
- Closes #

## Summary
<2–4 bullets describing what changed>

## Motivation
<why; cite Issue/ADR IDs>

## Changed Files
- key files (auto by GitHub)

## Architecture Impact
- New module? Cite ADR or commit to writing one.
- Schema change? Cite migration + rollback.
- Public API change? Cite `docs/api/...` and version note.

## Testing
- Unit: <% coverage delta>
- Integration / contract:
- E2E / browser evidence: <link to docs/evidence/<id>/>

## Evidence
- docs/evidence/<id>/change-summary.md
- docs/evidence/<id>/test-results/
- docs/evidence/<id>/screenshots/

## CI
- Workflow run: <github actions URL or run-id>
- Commit SHA: <full sha of the head of the PR branch>
- Required checks (each must be green): lint · unit · integration · build · security-scan
- Captured log: docs/evidence/<id>/ci-log.txt
- If any check is red: stay in workflows/04-ci-recovery.md — this PR is BLOCKED.

## Risk
- ...

## Rollback Plan
- ...

## Checklist
- [ ] Issue body has all required fields
- [ ] Implementation Plan exists
- [ ] Tests added/updated and green locally
- [ ] **CI is GREEN on the latest commit at the head of the PR branch** (see `## CI` above) — capture ci-log.txt
- [ ] Required reviewers approved (≥ Bug Hunter + Behavior Reviewer)
- [ ] Evidence pack complete (per change type)
- [ ] No Critical/High findings open
- [ ] Docs updated (or follow-up Issue filed)
- [ ] No secrets / credentials in diff
- [ ] Changelog entry added (if user-facing)
```

