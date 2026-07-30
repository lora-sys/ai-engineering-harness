---
name: ai-engineering-harness
description: Multi-agent engineering org harness. Issue → Worktree → Plan → Implement → Adversarial Review → Evidence → Merge → Memory loop. 18 agent personas, 9 workflows, evidence-gated, cold-start review, L0–L3 context control. Use prompts: bootstrap / resume / drive / audit.
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
8. **CI/CD is a blocking gate, not a checkpoint.** When a PR opens and after every push, the loop does NOT advance to (and certainly not past) review until CI is green. The Owner watches CI after every push; Coordinator confirms green before Phase 8. If CI is red, the feature is BLOCKED — stay in `workflows/04-ci-recovery.md` until green, no matter how many review approvals are queued. See `references/cd-monitoring.md`. This is the strongest gate in the harness, stronger than adversarial review, because a red CI is the only failure that is mechanical and observable.
9. **Local-first for overlapping changes.** When a PR proposes code that already exists in the project tree (main or any worktree), do NOT merge the PR as-is. Surface the local equivalent, comment on the PR with the local paths, and ask the author to align with the local version or propose something genuinely additive. The local version stays as-is. Operationalised by `workflows/09-pr-intake.md` and `agents/conflict-resolver.md`; criteria in `references/pr-intake-decision-matrix.md`.

## 2. When to Use This Skill

> **New to this skill? Read [`QUICKSTART.md`](QUICKSTART.md) first** — working tutorial covering the 9 workflows, the 9 operating principles, end-to-end examples, copy-paste prompt templates, and the upgrade flow for existing projects.

- The user wants to start, take over, or rescue a non-trivial product (MVP, internal tool, SaaS, feature set).
- A repo has no operating system yet (no `docs/INDEX.md`, no issue template, no PR template, no ADR log, no evidence directory).
- Multiple agents/users/Worktrees will touch the same repo and need a shared contract.
- Quality has been slipping: PRs merge without review, no tests, no UI verification, no rollback plan.
- There is a need to bootstrap a new project from a PRD/MVP Spec into a working, verifiable product.

For one-off scripts, throwaway prototypes, or single-file edits, fall back to a regular coding skill — this harness is overhead for those.

### Sibling skills — route by keyword

| Keyword | → Use | Skip if user says |
|---------|-------|-------------------|
| "agent", "LLM", "chatbot", "tool-use", "wire up" | **`$build-agent-app`** | "standard SaaS", "ship a feature" |
| "landing page", "portfolio", "brand site", "Awwwards", "GSAP", "Framer Motion", "R3F", "bold typography" | **`$frontend-creative`** | "dashboard", "admin panel", "standard UI" |
| "show dashboard", "project health", "evidence completeness", "kanban", "chaos score", "quick scan", "vibe signs" | **`$dashboard`** (auto-starts on `workflows/` execution — see §10 step 1) | — |

**Routing rule:** match the user's keywords → invoke the sibling skill directly. The sibling handles its own lifecycle; this skill resumes when the sibling hands off.

**Dashboard auto-start:** When working in a project directory, the Coordinator auto-runs `bash scripts/dashboard.sh` (from project root) before entering workflow phases and after completing them. This keeps the dashboard live at `:4321` reflecting current state. Skip if `.dashboard/` does not exist (dashboard not yet bootstrapped for this project).

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
  → CI runs  **(BLOCK: do not advance while red — see `workflows/04-ci-recovery.md` and `references/cd-monitoring.md`)**
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

17 agent personas, one per file in `agents/`. Spawn with explicit role, allowed files, input artifacts, output format, and acceptance criteria. Each agent is **scoped**: no modification outside allow-list, no bypassing review, no merging.

| Agent | Purpose |
|-------|---------|
| `coordinator` | Reads docs, owns TaskList, orchestrates phases, never writes feature code. |
| `explore` | Read-only codebase discovery. Output: facts, no opinions. |
| `plan` | Synthesizes Implementation Plan from Issue + architecture + memory. No code. |
| `frontend` | Implements UI per design + plan. Components, styles, a11y, motion. |
| `backend` | Implements API/services per plan. Endpoints, business logic, integration tests. |
| `database` | Schema, migration, seed, rollback, data safety review. |
| `qa` | Executes tests, captures screenshots, writes Evidence. |
| `bug-hunter` | Cold-start reviewer: runtime bugs, nulls, races, edges. |
| `behavior-reviewer` | Cold-start reviewer: expected vs actual vs spec. |
| `architecture-reviewer` | Cold-start reviewer: coupling, boundaries, debt. |
| `security-reviewer` | Conditional: auth, PII, secrets, payments, deps, infra. |
| `ui-reviewer` | Conditional: visual, interaction, a11y, motion, responsive. |
| `conflict-resolver` | Proposes merge strategy when two agents want the same code. |
| `release` | Pre-release checklist (PRs, CI, migrations, version, changelog). |
| `review-aggregator` | Collects reviewer reports → ranked Fix Tasks → routes back. |
| `context-assembly` | Builds `context-manifest.md` for an Agent task. |
| `memory-curator` | Promotes session findings into Source-of-Truth docs / ADRs. |

## 6. Context Discipline (L0–L3)

The harness's biggest job is keeping each agent **focused**. Default rule: **do not load everything**.

```
L0 — Always-on     SKILL.md, AGENTS.md, PROJECT_STATUS.md — loaded once, rarely re-read
L1 — Task-local    Issue body, relevant ADRs, acceptance criteria — per task
L2 — On demand     Adjacent modules, interface contracts, recent summaries — when referenced
L3 — Explicit only Full Evidence packs, old session logs, original PRD — never by default
```

`context-assembly` agent produces a `context-manifest.md` for every task. See `references/context-levels.md` for the choosing table.

## 7. Evidence Gate

No transition is "Done" without Evidence. Per-change requirements: `checklists/evidence-gate.md`. Quick reference:

| Type | Required |
|------|----------|
| Frontend | Screenshots + Playwright, console clean, a11y, UI Review |
| Backend | Test results, API traces, exception coverage, security probe |
| Database | Migration SQL, rollback, data-safety diff, seed impact |
| Infra/DevOps | **CI green (mandatory)** + deploy dry-run, env diff, secret scan |
| Cross-cut | Reviewer reports, change-summary.md, verification.md |

Evidence → `docs/evidence/<issue-id>/`.

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

1. The Coordinator role activates. Read the project root, find `CLAUDE.md` / `AGENTS.md` / `PROJECT_STATUS.md` / `docs/INDEX.md`. If they don't exist, run `workflows/00-project-bootstrap.md`. **Auto-start dashboard**: if `.dashboard/` exists (from `$dashboard`), run `bash scripts/dashboard.sh` (or `bash scripts/dashboard.sh <project-dir>`) so it's live at `:4321` before proceeding.
2. Read the latest `memory/` + last `sessions/` entry to recover state if this is a resume.
3. If the user provides raw text (PRD, idea, bug), classify and route:
   - Bootstrapping a new project → bootstrap workflow.
   - Existing repo, no docs → bootstrap workflow.
   - Existing repo with docs → enter at the current Todo from `PROJECT_STATUS.md`.
   - User mentions "agent", "LLM", "chatbot", "tool-use" → **`$build-agent-app`** first.
   - User mentions "landing page", "portfolio", "brand site", "Awwwards", "GSAP", "Framer Motion", "R3F" → **`$frontend-creative`** first.
   - User mentions "dashboard", "project health", "evidence", "kanban", "chaos score", "quick scan", "vibe signs" → **`$dashboard`** (also auto-started above).
4. Maintain `PROJECT_STATUS.md` continuously; never let it drift more than one Issue behind reality.
5. Use `agents/`, `workflows/`, `templates/`, `checklists/` as the contract — load them on demand, never pre-load all of them.

## 11. Bundled Resources — Read on Demand

**L0 (always loaded once at session start):**
- `SKILL.md` — this file
- `AGENTS.md` / `CLAUDE.md` — project contract

**On demand (load only when referenced by a workflow):**
- `agents/` — one file per persona (load the one you spawn)
- `workflows/` — step-by-step procedures
- `templates/` — Issue, Plan, PR, Review, Evidence, ADR, session files
- `checklists/` — Evidence Gate, frontend/backend/database/security/PR-merge
- `references/` — context levels, CI/CD monitoring, Worktree discipline, agent spawning, PR intake, context-bundle, compact-report
- `scripts/` — bash helpers (context-bundle, compact-report, validate-meta, run-tests, sync-project, release)
- `examples/` — filled template samples

**Never pre-load.** Read the workflow first; it tells you which resources to load per phase.

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
- **Red CI = blocked.** Calling an Issue "Done" while CI is red. Stay in `workflows/04-ci-recovery.md`.
- **Merging a PR that duplicates local code.** Comment with local paths, don't merge. Local version stays as-is. See Principle #9.
