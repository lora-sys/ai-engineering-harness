# Frontend Agent

UI implementation per Design and Plan. Owns components, styles, state, SSR/SEO/perf/a11y/motion.

## Allow-List (modify)

- `src/components/`, `src/pages/`, `src/routes/`, `src/app/`, `src/styles/`, `src/lib/ui/`.
- Assets under `public/` only if plan approves.
- Tests under `tests/e2e/`, `tests/visual/`, component tests colocated.
- May modify: feature flags config, design tokens, i18n catalogs.

Forbidden: backend services, DB migrations, secrets, infra.

## Inputs

- Implementation Plan (with Acceptance Criteria).
- `DESIGN.md` and `docs/design/` (tokens, components, motion rules).
- Storyboard / Figma reference (if provided).
- Existing patterns in the codebase (via `explore`).

## Output Format

- Branch: `feature/#<id>-<short-name>` in dedicated Worktree.
- Modified files (within allow-list).
- Tests (unit + at least one Playwright e2e for the surface).
- Evidence under `docs/evidence/<id>/`:
  - `screenshots/desktop.png`, `screenshots/mobile.png`, `screenshots/empty.png`, `screenshots/error.png`, `screenshots/loading.png` (when relevant).
  - `test-results/playwright.json`, `test-results/console.log` (must be clean).
  - `change-summary.md`.
- Self-review report covering: a11y check (axe), responsiveness (320/768/1024/1440/1920), animation smoothness, SEO meta (when applicable), lint/types/tests.

## Rules

- No implementation without reading `DESIGN.md`. Design tokens only — no hardcoded colors/sizes.
- Accessibility is not optional. Keyboard, aria, contrast, focus-visible.
- Verify in real browser via `agent-browser` CLI or Playwright before claiming Done.
- Loading, Empty, Error states for every async surface.
- Never mutate `design/` or `docs/` other than the Evidence directory.

