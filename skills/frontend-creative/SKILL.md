---
name: frontend-creative
description: Awwwards-grade creative web UI (non-Dashboard). Triggers: landing page, portfolio, brand site, Awwwards, GSAP, Framer Motion, R3F. Stack: Next.js + TS + Tailwind + Framer Motion + GSAP + R3F. Hands off impl to $ai-engineering-harness. Install: bash install.sh --skill frontend-creative
---

# Frontend Creative UI

Awwwards-grade creative web UIs: landing pages, portfolios, brand sites. **NOT** for SaaS dashboards.

## Trigger

Keywords: landing page, portfolio, brand site, Awwwards, bold typography, GSAP, Framer Motion, R3F, experimental page, motion-rich.

Skip if: internal tools, dashboards, admin panels, backend, "clean / minimal / standard".

## Principles

1. **No Dashboard layout.** Asymmetric, full-bleed, narrative-driven composition.
2. **Type is the hero.** Large type as visual subject.
3. **Motion in layers.** Heavy on focal region; GSAP for scenes, Framer Motion for micro.
4. **Performance is creative constraint.** Lazy-load 3D, GPU transforms, Lighthouse 90+.
5. **Iterate 3 rounds.** Macro → local → regression. No drift to generic.
6. **Awwwards self-review** before ship (see `templates/review-checklist.md`).

## Stack (fixed)

| Layer | Tool |
|-------|------|
| Framework | Next.js (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Micro motion | Framer Motion |
| Scene motion | GSAP + ScrollTrigger |
| 3D / particles | React Three Fiber + drei |
| Deploy | Vercel |

## Anti-patterns

- Generic SaaS hero with centered headline + 3 cards.
- Lorem ipsum, placeholder copy, fake testimonials.
- Auto-playing hero video with sound.
- "Cool" 3D that's a generic particle sphere.
- Animations on every scroll (parallax fatigue).
- AI rewriting the whole page each round → drift.

## Hand-off

Design approved → hand off to `$ai-engineering-harness` for implementation:

> Design approved. Brief at `docs/design/<id>/brief.md`. Macro layout at `<repo>`. Hand off to `$ai-engineering-harness` for Phase 3 (Implement) through Phase 8 (Review). Use `frontend-stack` agent preset.

## Lifecycle

| Phase | Workflow | Output |
|-------|----------|--------|
| New project | `00-bootstrap.md` | Scaffold + creative stack + theme |
| Brief | `00-design-brief-collection.md` | Filled `templates/design-brief.md` |
| Round 1 | `01-macro-design.md` | Macro layout + theme |
| Round 2+ | `02-local-refinement.md` | Local iteration (Anti-drift check) |
| Review | `03-visual-regression-check.md` | Awwwards checklist |
| Ship | `04-ship.md` | Review-checklist gate |
| Resume | `05-takeover.md` | Inventory + baseline |
| Post-mortem | `06-post-mortem.md` | After-ship lessons |
| Restart | `07-redo.md` | Diagnose + archive + restart |

## Read on demand

- `references/creative-ui-design-spec.md` — 17-section rulebook (read first)
- `references/theme-{a,b,c,d}-*.md` — 4 theme variants
- `references/prompt-library.md` — per-phase prompts
- `templates/design-brief.md` — per-project brief
- `templates/review-checklist.md` — pre-ship gate
- `agents/creative-frontend.md` — agent persona
- `$dashboard` — sibling skill for visualizing project state. This skill does NOT do dashboards.
- `$build-agent-app` — sibling skill for designing agent apps.
