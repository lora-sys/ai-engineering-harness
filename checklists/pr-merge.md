# PR Merge Checklist

The Coordinator's last gate before merging. Failed → no merge.

- [ ] Implementation Plan exists at `docs/evidence/<id>/implementation-plan.md`.
- [ ] Branch is the agreed feature/<id>-name.
- [ ] Diff scope matches Issue Scope (no drive-by changes).
- [ ] Tests added/updated; CI green.
- [ ] Adversarial Review: Bug Hunter ✅ and Behavior Reviewer ✅.
- [ ] Architecture Reviewer ✅ (when required).
- [ ] Security Reviewer ✅ (when required).
- [ ] UI Reviewer ✅ (when required).
- [ ] Aggregator reports ✅ Approved (no Critical/High open).
- [ ] Evidence Gate per `checklists/evidence-gate.md` for the change type.
- [ ] Human Approval obtained when required (schema / auth / release / paid).
- [ ] Changelog / release notes entry made (when user-facing).
- [ ] `PROJECT_STATUS.md` updated to indicate merge.
- [ ] Issue will auto-close (or comment with `Closes #`).
- [ ] Post-merge plan: phase summary update, memory write, worktree cleanup.

