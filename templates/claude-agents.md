# CLAUDE.md / AGENTS.md

The single source of truth that every Agent reads first. Keep it short and reference docs by ID.

```markdown
# Project: <Name>

## Vision
<one paragraph; cite docs/product/vision.md>

## Architecture (one-line summary)
<...> — full: docs/architecture/system.md

## Tech Stack
- Frontend: ...
- Backend: ...
- DB: ...
- Infra: ...

## Non-Negotiables
- Issue-first. PR carries the change. Evidence proves Done.
- No edits to main/master. Worktree per Issue.
- Adversarial Review (≥ Bug Hunter + Behavior Reviewer) before merge.
- Frontend: agent-browser / Playwright verification required.
- Backend: tests + contract + exception coverage required.
- Database: migration + rollback required.
- Auth/schema/release changes → Human Approval Gate.
- Memory lives in `docs/` and `memory/`, not chat.

## File Allow-List (Coordinators may write)
- PROJECT_STATUS.md, docs/INDEX.md, docs/.index/, memory/, sessions/, tasks/, skills/

## Forbidden
- ...

## Workflow
See ai-engineering-harness skill: workflows/01-feature-delivery.md is the default loop.

## Index of Stable Docs
- PRD: docs/product/prd.md
- MVP: docs/product/mvp.md
- Roadmap: docs/product/roadmap.md
- Architecture: docs/architecture/
- Design: docs/design/
- Memory: memory/
- Decisions: docs/decisions/

## First-Read Order for New Agents
1. This file
2. docs/INDEX.md
3. PROJECT_STATUS.md
4. memory/project-memory.md
5. The specific ADR(s) and module doc relevant to your task
```

