# Awwwards-Style Review Checklist

Run before `workflows/04-ship.md`. Score 1-10 each. Reject if total < 36.

## Composition (10)

- [ ] Asymmetric grid (not centered)
- [ ] At least one full-bleed region
- [ ] Clear focal point with visual hierarchy
- [ ] No "Header → Hero → 3 Cards → Features → Footer" pattern

## Type (10)

- [ ] Giant title (clamp 4-12rem) used as visual subject
- [ ] Variable / display font, not system default
- [ ] At least one experimental layout (staggered, masked, vertical)

## Color (10)

- [ ] Cohesive palette, not random Tailwind colors
- [ ] At least one gradient / texture / noise
- [ ] Sufficient contrast for a11y

## Motion (10)

- [ ] Heavy animation on the focal region
- [ ] Light animation elsewhere
- [ ] ScrollTrigger or equivalent — not just on-mount
- [ ] GSAP for scenes + Framer Motion for micro (or equivalent split)

## Originality (10)

- [ ] Doesn't look like a Tailwind starter
- [ ] Has a unique visual language (could be picked out of a lineup)
- [ ] "I've never seen this layout before" — true for at least one section

## Performance (10)

- [ ] Lighthouse mobile ≥ 90
- [ ] LCP < 2.5s
- [ ] No autoplay video/audio
- [ ] No layout thrash (transforms only)

## Total

Sum of all six categories.

- **< 36**: REJECT. Re-think the design.
- **36–47**: NEEDS WORK. Back to `workflows/02-local-refinement.md` for one more round.
- **≥ 48**: SHIP-ABLE. Proceed to `workflows/04-ship.md`.

## Reject criteria (any one fails → back to refinement)

- Total < 36
- Any individual category = 0
- The page is recognizably "Tailwind default"
- Lorem ipsum or fake testimonials remain

## Reject criteria

Reject (don't ship) if:
- Total < 36
- Any individual category = 0
- The page is recognizably "Tailwind default"
- Lorem ipsum or fake testimonials remain
