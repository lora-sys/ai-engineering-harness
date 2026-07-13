# Workflow — PR Intake (Local-first Triage)

Use when the Coordinator receives an external Issue or Pull Request on a harness-managed project. Distinct from `workflows/03-adversarial-pr-review.md` which covers PR **quality** (finding bugs); this workflow covers PR **intake** (deciding whether to merge at all, and how to handle overlap with local code).

Operates on Principle #9 — **Local-first for overlapping changes.**

## Trigger

- An Issue or PR is filed on the project's repo by someone other than the active Owner / Coordinator.
- A team member asks "should we merge this?"
- An old PR is being revisited after a long dormancy.

## Steps

### Step 1 — Triage against project context

Read the Issue/PR body. Cross-reference:
- `PROJECT_STATUS.md` — is this in the active phase? deferred? explicitly out of scope?
- `docs/decisions/*.md` — has this direction been decided against before?
- `memory/<role>-memory.md` — has any agent noted concerns about this area?
- The PR's branch: `git log main..pr-branch --oneline` to see what it's trying to land.

If the project has discussed this direction before and rejected it, surface the precedent in the response. Do NOT silently re-litigate.

### Step 2 — Local equivalence check (Local-first principle)

Run before any merge consideration:

```bash
# Search the local tree for related code / docs
git log --all --oneline | grep -iE "<feature-keyword>"
grep -rE "<feature-keyword>" docs/ --include="*.md" -l
grep -rE "<feature-keyword>" workflows/ agents/ scripts/ references/
```

If a local equivalent exists (same feature implemented differently, or a stub left for the PR to extend), the workflow's answer is **comment, don't merge**. See `references/pr-intake-decision-matrix.md` for the rubric.

The comment template is in `agents/conflict-resolver.md` ("Local-first for overlapping changes" section).

### Step 3 — Sequence

Multiple open PRs should be processed oldest-first, not by priority:

```bash
gh pr list --state open --json number,title,createdAt --limit 50 \
  | jq 'sort_by(.createdAt)'
```

Process them one at a time. Reason: parallel processing creates merge conflicts and context-switching cost; sequential processing lets the project absorb each change cleanly.

### Step 4 — Self-review

The Coordinator reads the PR diff against the project's history. The check is **not** "is this code correct" (that's `bug-hunter` / `behavior-reviewer`). It's:

- Does this add value to the project given current PROJECT_STATUS.md scope?
- Does this conflict with a closed Issue / ADR / memory note?
- Does this break any documented decision?
- Is the Implementation Plan attached (or implicit) consistent with the rest of the project?
- Does it respect the Local-first principle from Step 2?

### Step 5 — Decide

Three outcomes, mapped from `references/pr-intake-decision-matrix.md`:

| Decision | Trigger | Action |
| --- | --- | --- |
| **Merge** | PR passes Step 4, no local equivalent, CI green, adversarial review clean | `gh pr merge --squash` |
| **Comment + iterate** | PR has potential but needs changes | Comment with concrete asks, set label `needs-changes`, do NOT close |
| **Close with rationale** | Out of scope, duplicates local, or conflicts with closed decision | Comment explaining why, link precedent |

### Step 6 — Hand-off

After the decision:
- If merge: hand to `workflows/06-phase-summary.md` to update memory + PROJECT_STATUS.md.
- If comment + iterate: PR stays open. Coordinator monitors for new commits. Re-runs Step 4 on each push.
- If close: mark the linked Issue as closed (if applicable) with the same rationale.

## Anti-patterns

- **Don't process PRs in parallel.** Sequential processing is the whole point.
- **Don't skip the local-equivalence check.** That's the Local-first principle. Without it, the project accumulates parallel implementations.
- **Don't merge on "looks fine, no critical bugs."** The Coordinator reviews against project history, not just code quality.
- **Don't close a PR with a vague "doesn't fit."** Link the precedent: a closed Issue, an ADR, a memory note.

## See also

- `workflows/03-adversarial-pr-review.md` — feeds into Step 4 with bug + behavior findings.
- `agents/conflict-resolver.md` — owns the Local-first comment template.
- `references/pr-intake-decision-matrix.md` — the merge/comment/close rubric.
- `SKILL.md` §1 Principle #9 — the principle this workflow operationalizes.
