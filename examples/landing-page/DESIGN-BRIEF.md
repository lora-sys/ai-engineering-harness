# Design Brief — ai-engineering-harness landing page

## What
Single-page product site for ai-engineering-harness. This is the project's *front
door* — the first thing a developer sees when they hear about it.

## Audience
Software engineers, engineering leads, AI-curious devs. They have seen "AI agent"
pitches before and are skeptical. They want (a) what makes this different,
(b) proof it works, (c) how to install in one command.

## Primary action
- **Install**: `npx -y skills add lora-sys/ai-engineering-harness -g --all --full-depth`
- Secondary: read the GitHub repo

## Theme
**Theme E — Engineering blueprint / instrumentation**
(`skills/frontend-creative/references/theme-e-engineering-blueprint.md`).
Replaces the previous Theme A (Cyberpunk Immersive Dark). This build is the
theme's reference implementation, so the theme file is derived from this code
rather than the other way round.

### Why the change
The product's whole claim is *evidence over vibes*: code reaches `main` only when
CI is green, ≥2 cold-start reviewers approve, and the evidence pack is complete.
A neon-gradient hero argues the opposite — it says "trust the vibe". The previous
build had a 4-colour gradient wordmark, `shadow-neon` double glow on the CTA, and
a particle-constellation background: attractive, but it reads as an AI toy, not as
instrumentation a lead engineer would put in front of their team.

Blueprint/instrumentation language matches the artefact. Precise rules, measured
values, thin drafting lines, monospaced numerals. Glow is *reserved for state* —
a CI signal is allowed to emit light because emitting light is its job. Nothing
else does.

### Palette

| Token | Value | Role |
|---|---|---|
| `ink` | `#07090c` | page ground (near-black, faintly blue) |
| `plate` | `#0d1116` | raised surface |
| `plate2` | `#11171d` | second-level surface |
| `rule` | `#1b232c` | drafting line, 1px |
| `rule-lit` | `#2b3947` | active drafting line |
| `signal` | `#7ee787` | the single accent — pass / green CI |
| `alert` | `#ff7b72` | fail state only |
| `paper` | `#e6edf3` | primary text |
| `graphite` | `#8b98a5` | secondary text |

One accent, not four. `signal` and `alert` are *semantic* — they only appear on
things that have a pass/fail nature. Blue-purple gradients, full-screen glass,
neon washes: banned, per brief.

Contrast computed in-page with the WCAG luminance formula, not estimated. On
`ink`: `paper` 16.87, `signal` 12.97, `alert` 7.91, `graphite` 6.77. On `plate`:
16.03 / 12.33 / 7.51 / 6.43. On `plate2`: 15.27 / 11.74 / 7.15 / **6.13**.
Lowest pair is 6.13:1, so every text pairing clears AA (4.5:1) and all but the
greys clear AAA (7:1).

The headroom is deliberate but finite: `text-graphite/60` on the mobile step
numerals was a real Lighthouse a11y failure. The token passes; the token at 60%
does not.

## Type
- Display / UI: **Space Grotesk** — geometric, slightly technical.
- Data, labels, code, all numerals: **JetBrains Mono**, `tabular-nums`. Every
  number on the page is monospaced, because the page is making numeric claims.
- Hero: `clamp(2.25rem, 5.4vw, 5.5rem)`, `letter-spacing: -0.03em`.

  **5.4vw, sized against the column — not the viewport.** The hero sits on 7 of
  12 columns. At `8.5vw` on a 1440 viewport the wordmark needed 835px inside a
  764px column, and because the reveal uses `clip-path` the overflow did not
  wrap or scroll — it rendered as `AI ENGINEERIN`. Measured with a `Range`
  (`scrollWidth` reports the container, so it passes a clipped wordmark).
  Headroom verified: 17px spare at 320, 785px at 2560.

  The two wordmark lines are separate `<span class="wordmark-line">` elements, so
  they are broken structurally and never auto-wrap. There is no `<br>`.

## Layout (asymmetric, not centered-stack)

Every section sits on a shared 12-column drafting grid with a persistent left
gutter carrying section numerals (`01 — 04`, set vertically), like a spec sheet.

1. **Hero** — full-bleed, content on columns 1–7 (deliberately off-centre).
   Wordmark set as two separate `.wordmark-line` spans, so the break is
   structural and can never auto-wrap. Right side: a "gate panel" — the actual
   merge conditions, rendered as an instrument readout. Background: blueprint
   rule grid on canvas plus a slow scan sweep. No particles, no constellation.
2. **`01` the argument** — three conditions with real values, in a staggered
   3-row layout where each row indents further right (`ml-0` / `ml-[8%]` /
   `ml-[16%]`). Not three equal cards: equal cards assert everything matters
   equally, the indent asserts sequence.
3. **`02` the mechanism** — `ISSUE → WORKTREE → PLAN → BUILD → REVIEW → EVIDENCE
   → MERGE → MEMORY` as a *single continuous* SVG stroke
   (`M 60 60 H 740 V 130 H 60 V 200 H 740`), `stroke-dashoffset` scrubbed by
   scroll progress. The previous build rendered this as 8 identical boxes that
   wrapped onto two rows with a dangling arrow pointing at nothing; a loop that
   visibly does not close is the worst possible diagram for this product.

   Narrow screens get a **separate vertical variant** with labels as 11px HTML.
   The 800-wide viewBox scaled into a 335px column renders its 12px labels at
   5.03px — measured, not guessed.
4. **`03` what's inside** — the real inventory, as a spec table with monospaced
   figures. Numbers come from `scripts/site-facts.sh`, not from prose.
5. **`04` install** — the single command, one large copy target. Then footer.

## Motion plan
- Hero: GSAP timeline, on-mount — wordmark lines clip-reveal (0.75s, stagger 0.1;
  2 lines not 20 chars, so it cannot look like confetti) → sub → panel → gate
  rows tick in (stagger 0.06) → meta. `from()` is safe here because an on-mount
  timeline always runs; the clip-reveal is a `to` whose closed state lives in CSS
  behind a JS-added `.js-motion` class, so a failed bundle leaves the wordmark
  visible instead of clipped to nothing.
- Scroll: one `ScrollTrigger` on the loop section, `scrub: true` and
  **deliberately not pinned** — it drives `stroke-dashoffset` and node activation
  as you pass. A pin would hold the visitor hostage to a line animation, which
  spec §7 bans. Section numerals are static; there is no count-up.
- Micro: copy button `copy` → `✓ copied` (1800ms), reverting to `copy` on a
  rejected clipboard promise so it cannot report false success. Gate rows
  brighten one rule on hover. No magnetic buttons, no element-wide glow, and no
  custom cursor — nothing here is a canvas the visitor manipulates.
- `prefers-reduced-motion: reduce` → checked in JS via `matchMedia` before any
  timeline is built. Entrances collapse to final state, the loop stroke is set
  fully drawn, no ScrollTrigger is created, and the canvas never starts.

## Performance budget
- Lighthouse mobile ≥ 90 — shipped at 100 / 100 / 100 / 100
- LCP < 2.5s
- JS < 200 KB gzipped — shipped at **94.6 KB** (`gzip -c dist/assets/*.js | wc -c`
  = 96,846 bytes)
- No autoplay video, no web font FOIT (fonts `display: swap` + `preconnect`)
- Canvas: `devicePixelRatio` capped at 2, paused when off-screen via
  `IntersectionObserver`, and never started at all under reduced motion.

## Truth constraint (project-specific)

Every number on this page must be derivable from the repo at the commit that
builds it. The previous build shipped **9 workflows** (10), **14 CLI agents**
(40), and footer **V1.8.6** (`VERSION` says 0.2.2) — the same drift class the
READMEs were just fixed for, except on the public front door.

`scripts/site-facts.sh` reads the filesystem and writes `src/facts.json`; the
build fails if it is stale. A site whose own numbers are wrong cannot argue for
evidence-gated engineering.

Two rules that came out of building it:

- **Figures that change every commit stay off the page.** Test counts were
  deliberately not published: a gate that fires during routine work gets
  disabled, and a disabled gate guards nothing.
- **Verify from the rendered DOM, not the shipped bundle.** Vite minified our
  keys (`batsFiles:Kx`), and grepping the live JS for a version matched React's
  `version:"18.3.1"` instead of ours. The DOM is what the visitor reads.

## Reference brands
- Linear — restraint, type scale
- Vercel Edge — instrument readout hero
- Stripe Docs — drafting-grid discipline
- Oscilloscope / logic-analyser UI — the state readout language
