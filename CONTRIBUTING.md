# Contributing to ai-engineering-harness

This skill is a tool that orchestrates 18 other agents. The same rigor should apply to its own contributions: claims live or die on what was actually tested, not what should work in theory.

## Working principles

### 1. **Test the actual path before declaring it works or doesn't work**

> Promoted to durable memory as decision **D-008** after one too many "this dir is read-only" claims based on probing a different path.

When testing whether something is writable, executable, or reachable, **probe the path you intend to operate on** — not a parent, not a sibling, not a previous state.

Run the real action you intend to take and observe the exit code:

```bash
# Wrong: probe a related path and assume the result
touch ~/.codex/skills/.test-write   # fails, but is it the path you care about?
ls -la ~/.codex/skills/              # shows "RO" — assumed

# Right: probe the path you'll operate on
mkdir -p ~/.codex/skills/mything     # does THIS work?
ln -sfn ~/.codex/skills/mything → /home/lora/foo
install.sh --target codex            # did THIS succeed?
```

For any claim like "X doesn't work" or "Y is read-only", include the test you ran. Don't cite a single failed probe as definitive.

### 1.5 **Treat CI status as part of "the actual path"**

> Promoted from D-008 ("test the actual path") because the failure mode is identical and recurring.

CI status is observed, not inferred. When you claim "CI is green" or "CI is red" in a PR description, an evidence pack, a memory entry, or a chat reply, you must have looked at the actual CI run on the actual commit at the head of the branch — not the commit from 30 minutes ago, not "it was green when I last checked", not "I trust the local run".

```bash
# Wrong: infer from a stale state
# (last seen green 30 minutes ago → assume still green)
# (local tests passed → CI will pass)
# (the PR template's CI checkbox is already ticked → ship it)

# Right: probe the actual run
gh pr checks <PR>                  # see real status per check
gh run view <run-id> --log-failed  # read the actual failing log
# then write the result into docs/evidence/<id>/ci-log.txt
```

For any claim that involves a remote system (CI, deploy, registry, package publish), include the **run-id / sha / timestamp** you observed. If you can't produce one, you don't have the claim.

### 2. **Every claim in README is a promise — verify before merging**

This README + `SKILL.md` + `meta.json` form the user-facing contract. Numbers, names, "supports", "tested on" — all promises.

Before a PR merges, audit and verify:

| Claim type | Verify with |
| --- | --- |
| "X personas" | `ls agents/ \| wc -l` |
| "Y workflows" | `ls workflows/ \| wc -l` |
| "compatible with Z agents" | `install.sh --list` |
| "tested on env X" | your run log / commit history |
| "as of v… " | `git log --oneline` |

If a claim is approximate (e.g., "60+ CLI agents" really means "40 in `install.sh` + 60+ in the npx ecosystem"), say so precisely. Better: split into two metrics with annotations.

### 3. **Doc-only changes still bump patch version**

Decisions like description wording, install command flags, scope clarifications — these are the API surface for routing. An Agent decides whether to invoke this skill based on its `description`, exactly the way a developer decides whether to call a function by its docstring.

Bump patch (e.g., `v0.1.x → v0.1.x+1`) for any change that affects:
- Trigger conditions (the YAML `description`)
- Routing (which CLI Agent can use it)
- Install behavior (one-line command, side effects)
- Evidence / context budget (what files need to load)

See `memory/notes-2026-07-11.md`, decision D-006.

### 4. **Adversarial reviews before merging**

Issue → Branch → Worktree → Draft PR → ≥2 cold-start reviewers (Bug Hunter + Behavior Reviewer). Mirror this on the repo itself: any non-trivial change to a workflow or skill template should be reviewed by a second pair of eyes before merge. Even if you are the only maintainer, leave the PR open for a day or run through it as if you were a fresh reviewer.

### 5. **Memory compounds; docs stay close to the line**

Stable lessons go into `memory/notes-<date>.md` with Status · Context · Decision · Why · Consequence · **Revisit when**. Don't enshrine single-incident trivia, but don't lose patterns that will mislead future agents either. ADRs live in `docs/decisions/`. Day-to-day chatter stays in chat / comments.

## Pull request process

1. **Open an issue first** for non-trivial changes. Use the templates in `.github/ISSUE_TEMPLATE/`.
2. **Branch off `main`**: `feature/#<id>-<slug>` or `fix/#<id>-<slug>`.
3. **Worktree discipline**: one PR = one Worktree = one Issue (template in `templates/implementation-plan.md`).
4. **`scripts/validate-meta.sh --strict`** must pass before commit (catches schema drift).
5. **`scripts/changelog-auto.sh --append`** to preview the changelog entry your commits will produce; commit `CHANGELOG.md` separately if anything is off.
6. **PR description uses `templates/pr-description.md`** with the relevant sections.
7. **Adversarial review** if the change touches a workflow, an Agent role, the L0–L3 context model, or any architecture-bearing contract.
8. **Human Approval Gate** for: schema-breaking changes to `meta.json`, auth/permission model changes, release/version bumps, anything touching paid APIs.

## Commit message convention

```
type(scope): description          (≤ 50 chars)

Refs #<issue-id>

Body explaining WHY. The diff already shows WHAT.
```

Allowed types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`. Type determines the Keep-a-Changelog section in `scripts/changelog-auto.sh`.

## Releasing

```bash
# 1. After merging to main
git tag -a vX.Y.Z -m "vX.Y.Z — one-line summary"
git push origin vX.Y.Z

# 2. Release notes
gh release create vX.Y.Z \
  --title "vX.Y.Z — short title" \
  --notes-file /tmp/vXYZ-notes.md \
  --target main

# 3. Update your local install
npx -y skills update lora-sys/ai-engineering-harness -g
```

## What we don't accept

- **Untested compatibility claims** — If you add a new agent target to `install.sh`, verify with `install.sh --target <agent>`.
- **Claim-without-evidence** in skills / harness internals. The harness itself runs on evidence gates; the repo shouldn't be an exception.
- **Single-incident memory entries** — `memory/<role>-memory.md` is for patterns.
- **Auto-merge in CI**. Force-push to someone else's branch. Anything that takes the human out of the loop on a risk-bearing change.

## When in doubt

- Run `install.sh --help` and `bash scripts/validate-meta.sh` before opening a PR.
- Read `memory/notes-2026-07-11.md` to see what prior maintainers already learned.
- Re-read section 1 of this file. **Test the actual path.**

— lora-sys
