# Workflow — Release Prep

When the project decides to cut a release (MVP freeze, version bump).

## Trigger

- `PROJECT_STATUS.md` indicates MVP / release criteria met, or human requests a release.

## Steps

1. Spawn `release` agent.
2. `release` produces `docs/releases/<version>/release-readiness.md`.
3. Coordinator walks `checklists/pr-merge.md` on the most recent N PRs.
4. Migration safety:
   - All migrations since last release have rollback rehearsed in staging.
   - Feature flags / kill switches documented.
5. Changelog auto-generated from merged PRs (`scripts/changelog.sh`).
6. Version bump in package manifests.
7. Tag + release notes.
8. If anything is missing → block; communicate via `Waiting for Approval`.

## Human Approval Gate

Release always crosses the Human Approval Gate.

