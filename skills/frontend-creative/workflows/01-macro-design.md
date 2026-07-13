# Workflow 01 — Macro Design

Round 1: produce the page's overall structure. **No micro-details yet.**

## Trigger

- `templates/design-brief.md` exists.
- User has confirmed the theme.

## Steps

1. Run the **Phase 1 prompt** from `references/prompt-library.md`.
2. Read `references/creative-ui-design-spec.md` §5 (layout), §6 (typography), §7 (motion).
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

## Output

- 3 commits in the project repo.
- `round-1.png` screenshot.
- Updated `iteration-log.md`.

## Hand-off

Move to `workflows/02-local-refinement.md` for one-region-at-a-time iteration.
