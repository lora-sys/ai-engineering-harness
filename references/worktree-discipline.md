# Worktree Discipline

Every implementer works in their own Worktree. The Coordinator never edits a feature branch from outside the assigned Worktree.

## Setup

```bash
git worktree add ../<project>-issue-<id> -b feature/<id>-<slug> main
cd ../<project>-issue-<id>
```

## Rules

- One Issue = one Owner = one Worktree = one branch.
- Branch naming: `feature/#<id>-<slug>`, `fix/#<id>-<slug>`, `refactor/#<id>-<slug>`, `chore/#<id>-<slug>`.
- Never `git checkout main` to commit a feature — owner stays on their branch.
- Push to remote so CI can run; the Worktree is just a local check-out.
- Multiple parallel Owners are fine **only if their allow-lists don't overlap**. If they touch the same file → Conflict Resolver before merge.

## Forbidden

- Direct commits to `main` / `master` by anyone except the merge button (Coordinator or Release Agent acting on an approved PR).
- Mixing two Issues into one branch.
- Force-push to a branch other than the one you own.

## Cleanup

After merge:

```bash
git worktree remove ../<project>-issue-<id>
git branch -d feature/<id>-<slug>
```

## When Things Bloat

If a branch exceeds ~600 changed lines or 4 modules, the Coordinator splits into follow-up Issues. Long-lived branches are a smell.

