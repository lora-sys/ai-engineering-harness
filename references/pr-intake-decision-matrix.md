# PR Intake Decision Matrix

The merge-vs-comment-vs-close rubric for `workflows/09-pr-intake.md` Step 5.

## How to use

For each incoming PR (or external Issue that asks for a change), walk this matrix top-to-bottom. The first row that matches wins. If no row matches, default to **comment-and-iterate**.

## Matrix

| # | Condition | Decision | Action |
| --- | --- | --- | --- |
| 1 | PR adds net-new functionality aligned with current PROJECT_STATUS.md scope, has Implementation Plan or equivalent, passes adversarial review, CI green, **no local equivalent** | **merge** | `gh pr merge --squash` |
| 2 | PR is small (< 100 lines), trivially correct (typo fix, comment fix, dep bump), passes CI, adversarial review clean | **fast-track merge** | `gh pr merge --squash --admin` (skip adversarial for trivial patches) |
| 3 | PR has Critical/High review findings | **comment + iterate** | Comment listing findings, set label `needs-changes`, do NOT close |
| 4 | PR has Medium/Low review findings only | **comment + iterate** (or merge if trivial + fixes inline) | Comment, ask author to address before merge |
| 5 | **Local equivalent exists** for what the PR is adding (per `agents/conflict-resolver.md` Local-first section) | **comment + suggest alignment** | Comment with local file paths and the rationale; do NOT merge; do NOT close (let author decide) |
| 6 | PR conflicts with a **closed** Issue / ADR / memory note that rejected this direction | **close with rationale** | Comment linking the precedent; mark `wontfix` with cross-reference |
| 7 | PR touches area explicitly marked out-of-scope in PROJECT_STATUS.md or DESIGN.md | **close with rationale** | Comment with the scope doc reference |
| 8 | PR is large (> 500 lines) with no Implementation Plan attached and no discussion preceding it | **comment + ask for plan** | Comment asking author to file an Issue with a Plan first; close the PR with reference to the new Issue |
| 9 | PR CI is red | **BLOCK** | Per v1.0.2 CI-as-blocking-gate: do NOT merge. Comment "CI red — see 04-ci-recovery.md". |
| 10 | PR is from a first-time contributor with no context on the project's principles | **comment + welcome** | Comment explaining the project briefly, link to CONTRIBUTING.md, ask questions; do NOT close on first pass |
| 11 | PR is a duplicate of an already-open PR (same intent, two competing implementations) | **close the worse one** | Identify the better implementation by completeness + alignment with project conventions; close the other with rationale |
| 12 | PR fixes a critical security issue or data-loss bug | **hotfix merge** | `gh pr merge --squash` immediately, follow up with full review in a follow-up Issue |

## Default behaviour

When in doubt: **comment-and-iterate** is the safest default. The Coordinator should err on the side of asking questions rather than closing PRs, because closing discourages future contributions.

The exception is **row 5** (Local-first): when a local equivalent exists, the comment is firm (do NOT close, do NOT merge, ask the author to align). That's the project-protective side of Principle #9.

## Anti-patterns (don't do these)

- **Don't merge without checking local equivalence.** The Step 2 grep is non-optional.
- **Don't close a PR with "doesn't fit our roadmap"** without linking to the specific decision that established that roadmap.
- **Don't merge with red CI** — even if you manually verified locally. The CI gate is the harness's strongest rule.
- **Don't fast-track** (row 2) a PR that's actually a larger change with a typo-fix-shaped diff.
