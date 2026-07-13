# Workflow — Project Bootstrap

Use when the Coordinator is dropped into a project that lacks the harness layout, OR when a new project is started from an idea/PRD.

## Trigger

- No `docs/INDEX.md`, no `PROJECT_STATUS.md`, no `.github/ISSUE_TEMPLATE/`, no `memory/`.
- OR: user provides a PRD/MVP Spec and asks to start.

## Steps

### Step 1 — Inventory (read-only)

Use `explore` agent to capture:

- Repo languages, frameworks, package managers, CI/CD present.
- Existing `docs/` (if any), existing ADRs, existing CONTRIBUTING / CODE_OF_CONDUCT.
- Existing tests and tooling.
- Open Issues / PRs (if remote visible).

Save to `sessions/<id>/inventory.md`.

### Step 2 — Vision Interview

The Coordinator asks the human (use `request_user_input` when available, otherwise a focused plain-text prompt):

- **Top user outcome** of v1 — one sentence.
- **Hard non-goals** — what v1 must NOT do.
- **Constraint landscape** — regulatory, perf budget, locale, devices, dependency policy.
- **Definition of Done for MVP** — list (5–10 items).

Persist the answers in `docs/product/vision.md`.

### Step 3 — PRD / MVP / Roadmap

Create, in `docs/product/`:

- `prd.md` — product requirements (sections: Goals, Non-Goals, Users, Use Cases, Success Metrics, Constraints).
- `mvp.md` — narrow MVP cut of PRD with explicit acceptance criteria.
- `roadmap.md` — phases with concrete deliverables and exit criteria.
- `feature-specs/<feature>.md` — one file per MVP feature with user story, ACs, Non-Goals.
- `user-stories.md` — backlog of user-story-shaped features.

### Step 4 — Architecture Baseline

Create, in `docs/architecture/`:

- `system.md` — components, boundaries, data flow.
- `frontend.md`, `backend.md`, `database.md`, `agent.md`, `security.md`, `deploy.md` — each with current state.
- `glossary.md` — shared terms.

### Step 5 — Design Baseline

Create, in `docs/design/`:

- `brand.md` — voice, tone, character.
- `tokens.md` — color, type, spacing, radius, motion.
- `components.md` — catalog with statuses (WIP / Approved / Deprecated).
- `motion.md` — easing, durations, reduced-motion defaults.
- `ui-patterns.md` — common screens (loading/empty/error/auth/forms).
- Capture Figma / image URLs in `docs/design/references.md`.

### Step 6 — Engineering / Testing / Contributing

Create at repo root:

- `CLAUDE.md` / `AGENTS.md` (same content; pick the one the platform loads).
- `ENGINEERING.md` — frontend/backend/api/db/git/review rules.
- `TESTING.md` — strategy + Evidence format.
- `CONTRIBUTING.md` — Issue-first process, branch naming, PR rules.
- `PROJECT_STATUS.md` — initial board.
- `.editorconfig`, `.gitignore` updates (env, secrets, deps, build, logs, .playwright-cache, worktrees metadata).

### Step 7 — Templates and CI

Create:

- `.github/ISSUE_TEMPLATE/{bug,feature,refactor,spike}.md` — copy from `templates/issue-*.md`.
- `.github/PULL_REQUEST_TEMPLATE.md` — copy from `templates/pr-description.md`.
- `.codex/hooks.json` if hooks are used (e.g., index refresh on doc change).
- CI workflows: `lint.yml`, `test.yml`, `build.yml`, `docs-index.yml` (samples in `examples/ci/`).

### Step 8 — Index Initial population

- Generate `docs/INDEX.md`.
- Generate `docs/.index/manifest.json`, `relations.json`, `freshness.json` (initial seeds; future hooks maintain).
- Link everything to memory files, GitHub templates, and workflows.

### Step 9 — Memory seed

- `memory/project-memory.md` — stable product facts (write from the PRD).
- `memory/architecture-memory.md` — current architecture decisions (cite ADRs as they land).
- `memory/decisions.md` — empty, ready for use.

### Step 10 — Resume Token

- Create `sessions/current-session.md` pointing at `sessions/<id>/`.
- Coordinator stands ready to receive the first Issue.

## Step 11 — Optional: SessionStart hook for `.claude/SESSION.md`

The harness ships a read-only SessionStart hook that auto-injects `.claude/SESSION.md` as session context on every new Claude Code session. Installing it is **host-level** (modifies `~/.claude/settings.json` or `.claude/settings.json`), so bootstrap does **not** install it by default. To opt in:

```bash
bash scripts/install-session-hook.sh --target global
# or
bash scripts/install-session-hook.sh --target project
```

See `references/session-start-hook.md` for the protocol, security notes, and uninstall steps.

## Acceptance Criteria for Bootstrap Done

- Every file in §3 of `SKILL.md` exists and is non-stub.
- `docs/INDEX.md` lists every doc and ADR.
- Issue + PR templates render in the UI.
- CI runs `lint` and `test` (even if minimal).
- `PROJECT_STATUS.md` has "Phase 0 / Bootstrap — Done".
- Coordinator emits a single human-readable summary of what was created and which docs to read first.

