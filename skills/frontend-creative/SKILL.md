---
name: frontend-creative
description: Awwwards-grade creative web UI design + frontend engineering for AI agents. Generates non-Dashboard, asymmetric, motion-rich websites (Next.js + React + TS + Tailwind + Framer Motion + GSAP + React Three Fiber). Use when the user wants a creative landing page, design portfolio, or experimental product page — not a standard SaaS dashboard. Adjacent to $build-agent-app and $ai-engineering-harness: hand off implementation to the harness after the design brief is approved.
---

# Frontend Creative UI

A skill for generating **Awwwards-grade creative web UIs** — landing pages, design portfolios, experimental product pages, brand sites. **NOT** for standard SaaS dashboards (use the regular frontend conventions for those).

The default LLM behavior on "build me a website" is to produce a Tailwind-default, center-aligned, 3-card hero. This skill counter-programs that.

## When to use

Trigger this skill when the user asks for:
- "A creative landing page for X"
- "Make my product page stand out — like the Apple product pages"
- "I want a portfolio site with motion / 3D / parallax"
- "Generate a one-page brand site with bold typography"
- "Build me an experimental / Awwwards-style page"

Do **not** trigger this skill for:
- Internal tools, dashboards, admin panels (use plain frontend conventions)
- Backend, CLI, data-heavy pages
- Anything where the user explicitly asks for "clean / minimal / standard"

## Quick start

1. Read [`references/creative-ui-design-spec.md`](references/creative-ui-design-spec.md) — the 17-section spec. This is the rulebook.
2. **What are you doing?** (pick the right starting workflow):
   - **New project from scratch** → `workflows/00-bootstrap.md` (scaffold the project) → `00-design-brief-collection.md` → `01-macro-design.md` → ...
   - **Resume an existing design** → `workflows/05-takeover.md` (inventory + baseline score) → `01-macro-design.md` → ...
   - **Existing design is unsalvageable (狗屎)** → `workflows/07-redo.md` (diagnose + archive old + restart)
   - **Design already shipped, time to learn from it** → `workflows/06-post-mortem.md`
3. **Always**: pick a **style theme** (section §4): Cyberpunk / Minimal Gallery / Retro Acid / Future 3D / or invent one.
4. **Always**: fill in `templates/design-brief.md`.
5. **For design work**: `01-macro-design.md` → `02-local-refinement.md` (Anti-drift check mandatory) → `03-visual-regression-check.md` (Awwwards checklist mandatory) → `04-ship.md` (review-checklist gate).

## Operating principles

These are non-negotiable. Internalize them; they override generic frontend conventions.

1. **No Dashboard layout.** No "Header → Hero → 3 Cards → Features → Footer". Use asymmetric, full-bleed, narrative-driven composition. (Spec §5.)
2. **Type is the hero.** Treat large type as visual subject, not body decoration. (Spec §6.)
3. **Motion in layers, not everywhere.** Heavy motion on the focal region; light elsewhere. GSAP for big scenes; Framer Motion for micro. (Spec §7.)
4. **Performance is creative constraint, not afterthought.** Lazy-load 3D, GPU-accelerate transforms, hit Lighthouse 90+ mobile. (Spec §9.)
5. **Iterate in 3 rounds, not 100 micro-edits.** Round 1 macro. Round 2 local. Round 3 regression. Don't let AI drift toward generic. (Spec §12.)
6. **Awwwards-style self-review before ship.** Run the checklist in `templates/review-checklist.md`. (Spec §13.)
7. **Version every visual iteration.** Each round saves its own screenshot + diff. Don't let AI overwrite everything. (Spec §14.)

## Tech stack (fixed — don't substitute)

| Layer | Tool |
| --- | --- |
| Framework | Next.js (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Micro motion | Framer Motion |
| Scene motion | GSAP + ScrollTrigger |
| 3D / particles | React Three Fiber + drei |
| Smooth scroll | Lenis (optional) |
| Deploy | Vercel (recommended) |

Don't propose alternatives in your prompt; this stack is chosen for interoperability. If the user wants different tools, they can override explicitly.

## Anti-patterns

- ❌ Generic SaaS hero with centered headline + 3 feature cards.
- ❌ Lorem ipsum, placeholder copy, fake testimonials.
- ❌ Auto-playing hero video with sound.
- ❌ "Cool" 3D scene that's actually a generic particle sphere.
- ❌ Animations that fire on every scroll (parallax fatigue).
- ❌ Letting the AI rewrite the whole page each round (drift toward generic).

## Hand-off

When the design brief + 3 macro rounds are approved, hand off implementation to `$ai-engineering-harness`:

> Design approved. Brief at `docs/design/<id>/brief.md`. Macro layout at `<repo>`. Hand off to `$ai-engineering-harness` for Phase 3 (Implement) through Phase 8 (Review). Use `frontend-stack` agent preset if available.

## See also

- `references/creative-ui-design-spec.md` — full 17-section rulebook (READ THIS FIRST).
- `references/theme-{a,b,c,d}-*.md` — 4 fully-fleshed theme variants (Tailwind config + motion presets + reference brands).
- `references/prompt-library.md` — reusable prompts for each phase.
- `templates/design-brief.md` — fill in per project.
- `templates/iteration-log.md` — track each round's screenshots + diffs.
- `templates/review-checklist.md` — Awwwards-style self-review before ship (mandatory pre-ship gate).
- **Lifecycle workflows:**
  - `workflows/00-bootstrap.md` — new project from scratch (scaffold + creative stack + theme)
  - `workflows/00-design-brief-collection.md` — fill the brief
  - `workflows/01-macro-design.md` — Round 1 macro
  - `workflows/02-local-refinement.md` — Round 2+ local iteration (Anti-drift check mandatory)
  - `workflows/03-visual-regression-check.md` — review (Awwwards checklist mandatory)
  - `workflows/04-ship.md` — ship (review-checklist as pre-ship gate)
  - `workflows/05-takeover.md` — resume an existing design
  - `workflows/06-post-mortem.md` — 复盘 (after ship)
  - `workflows/07-redo.md` — 狗屎 → restart
- `agents/creative-frontend.md` — the agent persona that drives this skill.
