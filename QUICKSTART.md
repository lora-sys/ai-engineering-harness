# Quickstart — ai-engineering-harness

> **An engineering organization of AI agents, run by a Coordinator.** This is the *coordination* skill: it doesn't generate code, it spawns agents that do. It's the closed loop from Issue → Worktree → Plan → Implement → Self-test → CI → Adversarial Review → Evidence → Merge → Memory.

This skill is the **conductor, not the orchestra**. You give it a PRD, an Issue, or a request; it spawns the right agents and walks the closed loop until you have evidence-gated, reviewable, shippable code.

---

## 1 · When to use this skill

| You have… | Use this skill? |
| --- | --- |
| A PRD / spec and want to bootstrap a new project from it | **Yes** |
| An existing repo and want to add a feature / fix a bug | **Yes** |
| An engineering team that needs an evidence-gated process | **Yes** |
| A creative web UI to design | **No** — use `$frontend-creative` |
| An agent app to design | **No** — use `$build-agent-app` (which then hands off to this skill) |
| A one-off script or throwaway prototype | **No** — overhead |

---

## 2 · The 9 operating principles (read these first)

The harness runs on these. They're the first thing to consult when in doubt.

1. **Trust evidence, not vibes.** Local tests passing ≠ ready. Need full evidence pack + CI green + ≥ 2 reviewers ✅.
2. **Cold-start reviews.** Reviewer reads Issue + Plan + PR diff + Evidence, not the implementer's chat.
3. **Issues are the unit of work.** No Issue, no work. Issue has 11 fields (Context, Goal, Scope, Non-Goal, ...).
4. **Worktree isolation.** One Issue = one Owner = one Worktree = one branch.
5. **L0–L3 context control.** Default: don't load `docs/` whole. Load the minimum trusted context per task.
6. **Human approval gate.** Auth / schema / prod keys / paid APIs / release versions need human in the loop.
7. **Memory is project state, not chat.** Stable conclusions in `docs/` + `memory/`, not chat history.
8. **CI as a blocking gate.** Red CI blocks review, merge, Issue-close. The strongest gate.
9. **Local-first for overlapping changes.** *(v1.5.0+)* If a PR proposes code that already exists locally, comment with the local paths; don't merge. Operationalised in `workflows/09-pr-intake.md`.

---

## 3 · Pick the right workflow

The skill has 9+ workflows. Pick by what you're doing:

| You want to… | Start with |
| --- | --- |
| **Bootstrap a new project** from a PRD | `workflows/00-project-bootstrap.md` |
| **Deliver one feature / fix** through the full closed loop | `workflows/01-feature-delivery.md` |
| **Triage an external Issue / PR** (especially with overlap) | `workflows/09-pr-intake.md` |
| **Adversarial review** a PR (find bugs + behavior issues) | `workflows/03-adversarial-pr-review.md` |
| **Recover from a red CI** | `workflows/04-ci-recovery.md` |
| **Resolve a merge conflict** | `workflows/05-conflict-resolution.md` |
| **Update existing projects** to pick up new harness features | `scripts/register-existing.sh <root>` |
| **End a phase** (write memory + next steps) | `workflows/06-phase-summary.md` |
| **Release a version** | `scripts/release.sh <version>` |
| **Maintain memory across phases** | `workflows/08-memory-evolution.md` |

---

## 4 · End-to-end example: bootstrap a new project

You have a PRD at `~/my-projects/cool-app/prd.md`. You want a full evidence-gated build.

### Step 1 — Bootstrap

**You say to the LLM:**
```
$ai-engineering-harness. Bootstrap ~/my-projects/cool-app/ from prd.md.
Run workflows/00-project-bootstrap.md.
```

**The LLM does:**
- Creates `docs/`, `memory/`, `PROJECT_STATUS.md`, `AGENTS.md`, `CLAUDE.md`
- Creates `.github/ISSUE_TEMPLATE/` + `.github/PULL_REQUEST_TEMPLATE.md` (from the harness's templates)
- Sets up CI workflows (`.github/workflows/`)
- Writes the first 3 Issues (one per MVP feature) to the kanban
- Initializes `.harness-state.json` at `v<current-harness-version>`

**You verify:** `cd cool-app && cat PROJECT_STATUS.md && gh issue list`

### Step 2 — Pick an Issue and drive it

**You say to the LLM:**
```
$ai-engineering-harness. Pick the top Issue from PROJECT_STATUS.md
("todo" column, oldest first). Drive it through workflows/01-feature-delivery.md.
Use worktree discipline: git worktree add ../cool-app-issue-N -b feature/N-<slug> main.
```

**The LLM walks 11 phases** (see `01-feature-delivery.md`):
1. Inventory
2. Branch + Worktree
3. Bundle context (run `scripts/context-bundle.sh` once)
4. Self-test
5. Evidence Assembly + Compact Report
6. Open Draft PR
7. **CI gate** (BLOCK if red, run `04-ci-recovery.md` if so)
8. Adversarial Review (≥ 2 reviewers)
9. Self-review + decide (merge / comment / close — see `09-pr-intake.md`)
10. Merge
11. Memory write (run `06-phase-summary.md`)

### Step 3 — Take an external PR

**You say to the LLM:**
```
$ai-engineering-harness. Review PR #42 against workflows/09-pr-intake.md.
Run scripts/context-bundle.sh first. Check for local equivalence.
```

**The LLM does** the Local-first check (per Principle #9):
- If the PR's content already exists locally → comment with the local paths, ask author to align. Do NOT merge.
- If the PR adds net-new aligned work → adversarial review → merge.
- If the PR is out of scope → close with rationale, link the precedent.

---

## 5 · Managing existing projects (the upgrade flow)

The harness evolves — v1.0 added the closed loop, v1.4 added `sync-project.sh`, v1.7 added GHA + theme variants, v1.8 added `--auto` + `register-existing.sh`. **Projects you've already taken over with the skill need to be re-synced to pick up the new features.**

Three paths, all idempotent and non-destructive:

```bash
# 1. Update the harness install (the skill itself).
npx -y skills update lora-sys/ai-engineering-harness -g

# 2. Update a SINGLE project you already manage:
bash /path/to/ai-engineering-harness/scripts/sync-project.sh --project-dir ~/projects/my-app --auto

# 3. Update MANY projects at once (e.g. all your repos):
bash /path/to/ai-engineering-harness/scripts/register-existing.sh ~/repos
# Walks the tree, finds every AGENTS.md + docs/evidence/ project,
# and runs #2 on the ones without .harness-state.json. One-shot.
```

After syncing, verify:
```bash
bash /path/to/ai-engineering-harness/scripts/sync-project.sh --project-dir ~/projects/my-app --status
# Output: "Status: in sync"
```

**Non-destructive by design** — migrations never overwrite user content. See `D-016` in `memory/notes-2026-07-12.md`.

---

## 6 · The skill family

This is one of 3 skills in the same family, installable separately or together:

| Skill | Purpose | Use when |
| --- | --- | --- |
| **`$ai-engineering-harness`** | Engineering coordination (Issue → PR → Merge → Memory) | "Build a SaaS / product / library with evidence-gated process" |
| **`$build-agent-app`** | Agent app design (Agent + Harness contracts) | "Build an LLM agent / take over an agent / refactor a broken agent" |
| **`$frontend-creative`** | Awwwards-grade creative web UI | "Build a landing page / brand site / experimental product page" |

Install:
```bash
# All three (default)
bash install.sh --skill all

# Just one
bash install.sh --skill ai-engineering-harness
bash install.sh --skill build-agent-app
bash install.sh --skill frontend-creative
```

---

## 7 · Prompt templates (copy-paste)

### Bootstrap
```
$ai-engineering-harness. Bootstrap [path] from [path/to/prd.md].
Run workflows/00-project-bootstrap.md.
```

### Feature delivery
```
$ai-engineering-harness. Drive Issue #N through workflows/01-feature-delivery.md.
Use worktree discipline. Run scripts/context-bundle.sh in Phase 3.
```

### PR triage (with Local-first principle)
```
$ai-engineering-harness. Triage PR #N using workflows/09-pr-intake.md.
Check for local equivalence first. Run scripts/context-bundle.sh.
```

### Upgrade existing projects
```bash
# Per-project:
bash /path/to/ai-engineering-harness/scripts/sync-project.sh --project-dir <path> --auto
# Or all repos:
bash /path/to/ai-engineering-harness/scripts/register-existing.sh ~/repos
```

---

## 8 · Cheat sheet (do / don't)

### Always do
- ✅ **Every change starts as an Issue.** With 11 fields filled in.
- ✅ **Worktree per Issue.** `git worktree add ...` — never edit `main` directly.
- ✅ **CI green is the strongest gate.** Red CI = no merge, no review, no Issue close.
- ✅ **≥ 2 cold-start reviewers** per PR. Bug Hunter + Behavior Reviewer minimum.
- ✅ **Evidence pack per Issue.** `docs/evidence/<id>/` with change-summary + test-results + screenshots + review-report.
- ✅ **Compact report (v1.2.0+).** Run `scripts/compact-report.sh` after each Owner finishes.
- ✅ **Local-first (v1.5.0+).** If a PR overlaps with local code, comment with the local paths; don't merge.
- ✅ **Re-sync projects** after upgrading the harness (`scripts/register-existing.sh`).

### Never do
- ❌ **"Looks good, ship it"** without evidence + adversarial review + green CI.
- ❌ **Merge a red CI** — even if you manually verified locally. The CI gate is the rule.
- ❌ **Edit `main` directly.** Always via Worktree + PR.
- ❌ **Skip the Issue.** Even for "tiny" changes.
- ❌ **Silence critical findings** in adversarial review. Re-spawn the implementer; don't close.
- ❌ **Use this skill for creative UIs.** Use `$frontend-creative`.
- ❌ **Use this skill to design an agent app.** Use `$build-agent-app` first.

---

## 9 · Where to read more

- `SKILL.md` (the full reference) — operating principles, repository layout, agent roster, workflow list.
- `workflows/00-project-bootstrap.md` — full bootstrap workflow.
- `workflows/01-feature-delivery.md` — full 11-phase delivery loop.
- `workflows/09-pr-intake.md` — PR triage + Local-first principle.
- `workflows/03-adversarial-pr-review.md` — how to be a good reviewer.
- `workflows/04-ci-recovery.md` — what to do when CI is red.
- `workflows/06-phase-summary.md` — end-of-phase memory write.
- `references/cd-monitoring.md` — the CI gate pattern.
- `references/pr-intake-decision-matrix.md` — merge vs comment vs close rubric.
- `references/agent-spawning.md` — how the Coordinator spawns agents.
- `memory/notes-2026-07-12.md` — durable decisions (D-001 through D-016).
- `CONTRIBUTING.md` — how to propose changes back to the harness.

### Sibling skills
- **`$build-agent-app`** — design the agent app, then hand off here. `QUICKSTART.md` inside.
- **`$frontend-creative`** — Awwwards-grade creative web UI. `QUICKSTART.md` inside.

### One-sentence summary

> **The Coordinator spawns agents, walks the closed loop (Issue → PR → Evidence → Merge → Memory), and only ships what the evidence-gate says is shippable. You give it a PRD or an Issue; it does the rest.**
