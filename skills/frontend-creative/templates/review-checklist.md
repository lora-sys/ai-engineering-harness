# Awwwards-Style Review Checklist

Run before `workflows/04-ship.md`. Seven categories, score 1-10 each (max 70).
Reject if total < 42, or if any single category scores 0.

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
- [ ] Sufficient contrast for a11y — computed, and computed on the **rendered**
      colour. A token that passes at full strength can fail at
      `text-<token>/60`; the opacity modifier is what ships

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

## Interaction & a11y (10)

Scored like the rest, because a page that only works for a mouse-using, motion-
tolerant desktop visitor is not finished.

- [ ] `prefers-reduced-motion` collapses every entrance to its final state, AND JS
      checks `matchMedia` so canvas/WebGL loops never start — verified by
      emulating the query, not by reading the CSS
- [ ] No content is hidden behind an animation that might not run (no bare
      `gsap.from()` on scroll-triggered content; `fromTo` +
      `immediateRender: false`)
- [ ] Full keyboard path through every interactive element, with visible focus
- [ ] No element driven by two animation systems at once
- [ ] Custom cursor (if any) passes all six rules in spec §7
- [ ] Copy buttons change state on success and do not report false success when
      the clipboard API is blocked
- [ ] Every CTA has a real destination, and they are distinguishable in analytics
      /logs (no two unlabelled "learn more" links)
- [ ] Giant type measured against its column with a `Range`, at every claimed
      breakpoint — `scrollWidth` reports the container and will pass a clipped
      wordmark
- [ ] Any scaled SVG's effective label size ≥ 11px on the narrowest supported
      screen (`fontSize × renderedWidth / viewBoxWidth`)

## Verdict questions

Answer these in words, not checkboxes. If any answer is uncomfortable, the score
is wrong.

- Does it look like a standard SaaS template?
- Is there an excess of cards?
- Is any animation meaningless — would removing it lose nothing?
- Is mobile fully usable, or merely present?
- Does the hero deliver both visual impact and a clear product claim?
- Does the product demo look like real software rather than an abstract
  illustration?
- Does it avoid robots, shields, padlocks and Web3 hexagons?
- Could it be mistaken for a traditional security vendor, or a personal
  portfolio?
- Does the motion improve comprehension, or only decorate?

## Total

Sum of all seven categories (max 70).

- **< 42**: REJECT. Re-think the design.
- **42–55**: NEEDS WORK. Back to `workflows/02-local-refinement.md` for one more round.
- **≥ 56**: SHIP-ABLE. Proceed to `workflows/04-ship.md`.

## Reject criteria (any one fails → back to refinement)

- Total < 42
- Any individual category = 0
- The page is recognizably "Tailwind default"
- Lorem ipsum, fake testimonials, or hand-typed numbers that should be derived
- Any banned cliché from spec §5 is present
- A measured contrast pair below 4.5:1
