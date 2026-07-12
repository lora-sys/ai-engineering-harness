---
name: ai-engineering-harness
description: AI-native software engineering organization harness that turns a project from idea → PRD → MVP → polished product. Multi-agent (Coordinator + 17 specialists (Explore, Plan, Frontend, Backend, Database, QA, Bug Hunter, Behavior Reviewer, Architecture Reviewer, Security Reviewer, UI Reviewer, Conflict Resolver, Release, Context Assembly, Memory Curator, Review Aggregator, Scope)) operating on an Issue-driven, Worktree-isolated, PR-carried, Adversarial-reviewed, Evidence-Gated loop. Maintains CLAUDE.md/AGENTS.md/DESIGN.md/ENGINEERING.md/TESTING.md/CONTRIBUTING.md/PROJECT_STATUS.md plus docs/, memory/, sessions/, tasks/ with dynamic L0–L3 context control. Use when an engineering effort needs a persistent multi-agent organization that produces verifiable, reviewable, shippable software instead of one-shot coding.
---

# AI Autonomous Engineering Harness

This skill is a **software engineering organization**, not a coding prompt. It treats software delivery as a closed loop: vision → design → issue → branch → PR → adversarial review → evidence → merge → memory → next issue. Codex becomes the **Coordinator** and spawns scoped sub-agents for each step.

## 1. Operating Principles

1. **Human owns vision and boundaries.** AI owns implementation, review, and verification.
2. **Issues are the unit of work.** Every change starts as an Issue, ends as a merged PR with Evidence.
3. **Worktrees isolate agents.** No agent edits `main`/`master` directly. Each owner gets one Worktree.
4. **Adversarial review is non-negotiable.** 2–3 cold-start reviewers per PR. Default assumption: *the implementation has a problem — find it*.
5. **Evidence gates every transition.** Frontend screenshots + Playwright, backend tests + curl traces, DB migration + rollback, CI logs, Reviewer reports. No evidence → not Done.
6. **Memory is project state, not chat.** Stable conclusions live in `docs/`, `memory/`, sessions reportable, ephemeral reasoning left out of long-term storage.
7. **Documentation is the contract.** `CLAUDE.md`, `AGENTS.md`, `DESIGN.md`, `ENGINEERING.md`, `TESTING.md`, `CONTRIBUTING.md`, `PROJECT_STATUS.md` are referenced by every Issue/PR/Agent.

## 2. When to Use This Skill

Use this skill when **any** of the following is true:

- The user wants to start, take over, or rescue a non-trivial product (MVP, internal tool, SaaS, feature set).
- A repo has no operating system yet (no `docs/INDEX.md`, no issue template, no PR template, no ADR log, no evidence directory).
- Multiple agents/users/Worktrees will touch the same repo and need a shared contract.
- Quality has been slipping: PRs merge without review, no tests, no UI verification, no rollback plan.
- There is a need to bootstrap a new project from a PRD/MVP Spec into a working, verifiable product.

For one-off scripts, throwaway prototypes, or single-file edits, fall back to a regular coding skill — this harness is overhead for those.

## 3. Repository Layout the Skill Expects

When the harness is initialized on a project, the following structure is created and **continuously maintained**:

```
.
├── CLAUDE.md                  # Project source of truth for AI agents
├── AGENTS.md                  # Same content as CLAUDE.md (compat)
├── DESIGN.md                  # Brand, design system, UI/interaction rules
├── ENGINEERING.md             # Frontend / backend / DB / API / Git / review rules
├── TESTING.md                 # Test strategy & Evidence format
├── CONTRIBUTING.md            # How to propose changes (Issue-first)
├── PROJECT_STATUS.md          # Live board (Todo/Planning/Implementing/Review/Testing/Blocked/Done)
├── docs/
│   ├── INDEX.md               # Master index — agents read this first
│   ├── .index/                # Generated: manifest.json, relations.json, freshness.json
│   ├── product/               # PRD, MVP, feature specs, user stories, roadmap
│   ├── architecture/          # System, frontend, backend, DB, agent, security, deploy
│   ├── design/                # Brand, tokens, components, UI patterns, motion
│   ├── decisions/             # ADRs (one file per decision)
│   ├── evidence/<feature>/    # change-summary.md, test-results/, screenshots/, review-report.md
│   └── sessions/              # Per-session logs of multi-agent runs
├── memory/
│   ├── project-memory.md      # Stable product facts, scope, constraints
│   ├── frontend-memory.md     # Frontend lessons
│   ├── backend-memory.md      # Backend lessons
│   ├── reviewer-memory.md     # Reviewer lessons
│   ├── decisions.md           # Chronological cross-cutting decisions
│   ├── lessons.md             # Things we learned the hard way
│   └── architecture-memory.md # Approved architecture patterns
├── sessions/                  # Active multi-agent runs (file-system message bus)
├── tasks/                     # Agent task board (TaskList mirror, persisted)
├── skills/                    # Project-local skills discovered during work
├── .github/
│   ├── ISSUE_TEMPLATE/        # bug, feature, refactor, spike
│   └── PULL_REQUEST_TEMPLATE.md
└── .codex/                    # Hooks / Codex-specific config (optional)
```

## 4. The Closed Loop

Every functional change follows this sequence. See `workflows/` for the per-phase detail.

```
Idea
  → PRD/MVP Spec (docs/product/)
  → Roadmap (docs/product/roadmap.md)
  → Issue (GitHub/Linear/Local — one of the templates in templates/)
      ├── Context, Goal, Scope, Non-Goal, Related Docs
      ├── Implementation Plan (high level)
      ├── Acceptance Criteria (testable)
      ├── Evidence Requirements
      └── Reviewer Requirements
  → Agent claims Issue → branch (feature/#id-name) + worktree
  → Context Assembly (L0/L1/L2/L3 selection, see references/context-levels.md)
  → Implementation Plan (refs Issue)
  → Code (with focus, scope, tests)
  → Self-test (unit + integration)
  → Commit (type(scope): description, refs Issue)
  → Draft PR (template in templates/pr-description.md)
  → CI runs
  → Adversarial Review (see workflows/adversarial-pr-review.md)
      ├── Bug Hunter    — runtime bugs, exceptions, races, nulls, edges
      ├── Behavior Reviewer — expected vs actual behavior vs spec
      ├── Architecture Reviewer — coupling, boundaries, debt
      ├── [Security Reviewer] — if change touches auth/payments/PII/secrets
      └── [UI Reviewer] — if change touches UI/UX
  → Review Aggregator (review-aggregator agent) — dedupes, ranks, files Fix Tasks
  → Fix → re-test → re-review loop until no Critical/High remain
  → Evidence Gate (see checklists/evidence-gate.md)
  → Human Approval Gate (when required: schema/permission/release)
  → Merge → close Issue → phase summary → memory update → next Issue
```

The Coordinator **does not write business code**. It reads, plans, dispatches, verifies.

## 5. Agent Roster

Each agent is a tight-scope persona documented in `agents/`. Spawn them with explicit role, allowed files, input artifacts, output format, and acceptance criteria.

| Agent                  | Purpose                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------- |
| `coordinator`          | The you-of-this-skill. Reads docs, owns TaskList, orchestrates phases, never writes feature code. |
| `explore`              | Fast read-only codebase discovery (CodeGraph/rep/grep). Pure output: facts, no opinions. |
| `plan`                 | Synthesizes Implementation Plan from Issue + architecture + memory. No code yet.       |
| `frontend`             | Implements UI per design + plan. Owns components, styles, a11y, motion.               |
| `backend`              | Implements API/services per plan. Owns endpoints, business logic, integration tests.  |
| `database`             | Owns schema, migration, seed, rollback, data safety review.                            |
| `qa`                   | Executes tests, captures screenshots, runs agent-browser / Playwright, writes Evidence. |
| `bug-hunter`           | Cold-start reviewer for runtime bugs, nulls, races, exceptions, edge cases.           |
| `behavior-reviewer`    | Cold-start reviewer comparing expected vs actual behavior vs PRD/Issue.                |
| `architecture-reviewer`| Cold-start reviewer for coupling, boundaries, repeated logic, tech debt.              |
| `security-reviewer`    | Conditional: auth, PII, secrets, payments, supply chain, deps.                        |
| `ui-reviewer`          | Conditional: visual + interaction + a11y + motion + responsive + empty/error states.  |
| `conflict-resolver`    | When two agents/PRs/Worktrees want the same code, proposes a merge strategy.           |
| `release`              | Pre-release checklist (PRs, CI, migrations, version, changelog, evidence).             |
| `review-aggregator`    | Collects reviewer reports → ranked Fix Tasks → routes back to owners.                  |
| `context-assembly`     | Builds `context-manifest.md` for an Agent task from L0–L3 index.                      |
| `memory-curator`       | Promotes session findings into Source-of-Truth docs / ADRs / lessons.                 |

All agents are **scoped**: they may not modify files outside their allow-list, may not bypass review, may not merge.

## 6. Context Discipline

The harness's biggest job is keeping each agent **focused**. Default rule: **do not load everything**.

**L0 — Always-on rules** (`AGENTS.md` snapshot):
- Global forbidden actions, secrets policy, file allow-list, evidence requirement.

**L1 — Task-local context** (per Issue):
- Issue body, related PRD/section, module overview, in-scope ADR list, acceptance criteria.

**L2 — Related context on demand**:
- Adjacent modules, interface contracts, recent phase summaries, decider log.

**L3 — Deep context, only when explicitly needed**:
- Original design docs, full Evidence packs, old session logs.

`agents/context-assembly.md` produces a `context-manifest.md` listing the docs/IDs loaded, so reviewers can audit what each Agent saw.

See `references/context-levels.md` for the full spec.

## 7. Evidence Gate

No transition is "Done" without Evidence. The Coordinator checks the gate before advancing.

Minimum Evidence per change-type:

| Type         | Required Evidence                                                                          |
| ------------ | ------------------------------------------------------------------------------------------ |
| Frontend     | Screenshots (desktop + mobile), Playwright JSON, browser console clean, a11y check, UI Review |
| Backend      | Test results, API traces, exception coverage, security probe, perf baseline where relevant |
| Database     | Migration SQL, data-safety diff, rollback plan & dry run, seed impact                       |
| Infra/DevOps | CI green, deploy dry-run, environment diff, secret scan                                      |
| Cross-cut    | Reviewer reports (each reviewer), change-summary.md, verification.md                       |

Evidence goes to `docs/evidence/<feature-or-issue-id>/`. See `checklists/evidence-gate.md` and `templates/evidence-pack.md`.

## 8. Human Approval Gate

Use it (and pause the loop) when the next step includes any of:

- Schema or migration that loses/restructures data.
- Auth/permission model change.
- Anything touching production secrets or external paid APIs.
- Release / version bump.
- Decision that breaks an ADR.

The Coordinator writes a `Waiting for Approval` note in `PROJECT_STATUS.md` and uses `request_user_input` or stops until the human responds.

## 9. Memory & Skill Evolution

At the end of each phase:

- Promote stable conclusions to Source of Truth docs.
- Append time-bound lessons to `memory/lessons.md`.
- Convert repeated patterns into project-local skills under `skills/` or templates under `templates/`.
- Update `docs/.index/freshness.json` so the index reflects reality.

The system does not trust "completed" — it trusts **verifiable evidence + a remembered record**.

## 10. How Codex Uses This Skill

When invoked as `$ai-engineering-harness`:

1. The Coordinator role activates. Read the project root, find `CLAUDE.md` / `AGENTS.md` / `PROJECT_STATUS.md` / `docs/INDEX.md`. If they don't exist, run `workflows/00-project-bootstrap.md`.
2. Read the latest `memory/` + last `sessions/` entry to recover state if this is a resume.
3. If the user provides raw text (PRD, idea, bug), classify and route:
   - Bootstrapping a new project → bootstrap workflow.
   - Existing repo, no docs → bootstrap workflow.
   - Existing repo with docs → enter at the current Todo from `PROJECT_STATUS.md`.
4. Maintain `PROJECT_STATUS.md` continuously; never let it drift more than one Issue behind reality.
5. Use `agents/`, `workflows/`, `templates/`, `checklists/` as the contract — load them on demand, never pre-load all of them.

## 11. Bundled Resources — Read on Demand

- `agents/` — one file per agent persona with role, scope, allowed files, input/output format.
- `workflows/` — step-by-step procedures (bootstrap, feature delivery, review, CI recovery, conflict, release).
- `templates/` — Issue, Implementation Plan, PR, Review Report, Evidence Pack, Phase Summary, ADR, session files.
- `checklists/` — Evidence Gate, frontend/backend/database/security/PR-merge checklists.
- `references/` — context levels, document indexing, Worktree discipline, agent spawning patterns.
- `examples/` — worked samples of filled templates.
- `scripts/` — bash helpers (`new-session.sh`, `context-manifest.sh`, `evidence-pack.sh`).

**Do not read them all into context.** Use the workflow file to decide which to read.

## 12. Quick Start

```bash
# Bootstrap a brand-new project from a PRD
Use $ai-engineering-harness to bootstrap this repo from docs/prd.md

# Resume work on an existing project
Use $ai-engineering-harness. Read PROJECT_STATUS.md, continue the next Todo.

# Add a feature
Use $ai-engineering-harness to add a feature for ISSUE-42 (OAuth login with GitHub)

# Audit a stalled project
Use $ai-engineering-harness to audit open Issues, PRs, and CI; produce a recovery plan.
```

## 13. Anti-Patterns the Harness Refuses

- Writing code without an Issue.
- Editing `main`/`master` directly.
- Merging without two Reviewer reports + CI green + Evidence complete.
- Bulk-loading `docs/` into context for every agent.
- Skipping Evidence because "tests passed locally".
- Auto-resolving multi-agent conflicts.
- Treating chat history as project memory.
- One agent implementing + reviewing the same PR.
