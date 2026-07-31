# Workflow 01 — Macro Design

Round 1: produce the page's overall structure. **No micro-details yet.**

## Trigger

- `templates/design-brief.md` exists.
- User has confirmed the theme.

## Step 0 — Declare the plan before writing any code

Write these eight items to `docs/design/<id>/macro-plan.md` and show them to the
user **before** the first commit. They take a few minutes and they are the only
thing standing between a brief and a generic page — once code exists, the design
decisions have already been made implicitly and nobody revisits them.

1. **Unified visual concept** — one paragraph. What the page *is* in physical
   terms (an instrument panel, a printed spec, a film title sequence). If this
   sentence would fit any other product, it is not a concept yet.
2. **Wireframe structure** — section order with the composition of each: which
   columns, what is off-centre, what is full-bleed. Text is fine; ASCII is fine.
3. **Core component list** — the named pieces you will build, and for each, why it
   is not a card.
4. **Motion plan** — per region: which system (GSAP or Framer Motion, never both
   on one element), what triggers it, what it reveals. Include the
   reduced-motion collapse for each.
5. **Technical strategy** — stack, what renders on the server, what is lazy, where
   the 3D/canvas boundary is, how state is held.
6. **Content strategy** — where every number and string comes from. Real values
   only. If a figure is derivable from the repo or an API, derive it; hand-typed
   numbers go stale silently and are the most common way a shipped page starts
   lying.
7. **Performance plan** — the budget in numbers (JS KB gzipped, LCP, CLS) and the
   specific mechanism for each: what is capped, what is deferred, what pauses
   off-screen.
8. **Accessibility plan** — measured contrast for every text pair, keyboard path
   through every interactive element, focus visibility, and what assistive tech
   receives for each non-text element.

Items 6, 7 and 8 are commitments that later workflows check. Do not write a
number here you have not measured or cannot derive.

## Steps

1. Run the **Phase 1 prompt** from `references/prompt-library.md`.
2. Read `references/creative-ui-design-spec.md` §5 (layout + banned clichés),
   §6 (typography), §7 (motion + interaction requirements).
3. Output the macro design as 3 commits:
   - **Commit 1: Skeleton.** Next.js app router setup. Region placeholders (no styling).
   - **Commit 2: Layout.** Apply Tailwind tokens (colors, type scale, spacing). No motion.
   - **Commit 3: Motion.** GSAP timeline + ScrollTrigger. Framer Motion on micro. R3F if theme D.
4. Save a screenshot of the result as `round-1.png`.
5. Update `iteration-log.md` with the round 1 row + Awwwards self-score.

## Anti-patterns

- Don't add features the brief didn't ask for.
- Don't optimize for Lighthouse yet (that's phase 04).
- Don't write 200 lines of GSAP for one region — the rule is **layered motion**, not max-motion.
- Don't start coding before Step 0 is written and seen. Skipping it is how a page
  ends up looking like every other page: the defaults win by default.

## Output

- 3 commits in the project repo.
- `round-1.png` screenshot.
- Updated `iteration-log.md`.

## Hand-off

Move to `workflows/02-local-refinement.md` for one-region-at-a-time iteration.
