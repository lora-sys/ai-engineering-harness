---
name: frontend-creative
description: "Awwwards-grade creative web UI (non-Dashboard). Triggers: landing page, portfolio, brand site, Awwwards, GSAP, Framer Motion, R3F. Stack: Next.js + TS + Tailwind + Framer Motion + GSAP + R3F. Hands off impl to $ai-engineering-harness. Install: bash install.sh --skill frontend-creative"
---

# Frontend Creative UI

Awwwards-grade creative web UIs: landing pages, portfolios, brand sites. **NOT** for SaaS dashboards.

## Trigger

Keywords: landing page, portfolio, brand site, Awwwards, bold typography, GSAP, Framer Motion, R3F, experimental page, motion-rich.

Skip if: internal tools, dashboards, admin panels, backend, "clean / minimal / standard".

## Principles

1. **No Dashboard layout.** Asymmetric, full-bleed, narrative-driven composition.
2. **Type is the hero.** Large type as visual subject.
3. **Motion in layers.** Heavy on focal region; GSAP for scenes, Framer Motion for micro. Never both on one element.
4. **Performance is creative constraint.** Lazy-load 3D, GPU transforms, Lighthouse 90+.
5. **Iterate 3 rounds.** Macro → local → regression. No drift to generic.
6. **Awwwards self-review** before ship (see `templates/review-checklist.md`).
7. **Plan before code.** `workflows/01-macro-design.md` Step 0 — visual concept, wireframe, components, motion, tech, content, performance, a11y. Once code exists the design decisions are already made implicitly.
8. **Numbers get derived, never typed.** Any figure obtainable from the repo or an API is read at build time and the build fails on drift. Hand-typed counts go stale silently; this repo's own site claimed 9 workflows (10) and 14 CLI agents (40) on its front page for months.
9. **Reduced motion and keyboard are code paths.** Verified by emulating the query and tabbing the page — not by a CSS block.
10. **Content never depends on an animation running.** A bare `gsap.from()` on scroll-triggered content leaves the section blank if the trigger never fires.

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

### Banned clichés (hard reject — full table in spec §5)

Blue-purple gradient SaaS template · full-screen glassmorphism · rows of
identical rounded cards · bento grid · robot avatars · shield and padlock icons ·
floating AI chat bubble · decorative grid that nothing aligns to · excess neon or
universal glow · digital globe with arcs · blockchain hexagons and generic Web3
iconography · grey body text under 4.5:1 · any motion that costs readability or
performance.

Glow is allowed only when **semantic** — a state indicator whose job is to emit.
One accent used with meaning beats four used for decoration.

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
- `references/theme-{a,b,c,d,e}-*.md` — 5 theme variants (`theme-variants.md` indexes them)
- `../../examples/landing-page/` — theme E shipped end-to-end: derived facts, measured contrast, the working blueprint build
- `references/prompt-library.md` — per-phase prompts
- `templates/design-brief.md` — per-project brief
- `templates/review-checklist.md` — pre-ship gate
- `agents/creative-frontend.md` — agent persona
- `$dashboard` — sibling skill for visualizing project state. This skill does NOT do dashboards.
- `$build-agent-app` — sibling skill for designing agent apps.
