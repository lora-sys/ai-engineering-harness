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
**Engineering blueprint / instrumentation.** Replaces the previous Theme A
(Cyberpunk Immersive Dark).

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
| `rule` | `#1b232c` | drafting line, 1px |
| `rule-lit` | `#2b3947` | active drafting line |
| `signal` | `#7ee787` | the single accent — pass / green CI |
| `alert` | `#ff7b72` | fail state only |
| `paper` | `#e6edf3` | primary text |
| `graphite` | `#8b98a5` | secondary text (AA on `ink`) |

One accent, not four. `signal` and `alert` are *semantic* — they only appear on
things that have a pass/fail nature. Blue-purple gradients, full-screen glass,
neon washes: banned, per brief.

Contrast computed in-page with the WCAG luminance formula, not estimated:
`paper` on `ink` = 16.87:1, `signal` on `ink` = 12.97:1, `alert` on `ink` =
7.91:1, `graphite` on `ink` = 6.77:1, `graphite` on `plate` = 6.43:1. Lowest pair
is 6.43:1, so every text pairing clears AA (4.5:1) and all but the two greys
clear AAA (7:1).

### Type
- Display / UI: **Space Grotesk** — geometric, slightly technical.
- Data, labels, code, all numerals: **JetBrains Mono**. Every number on the page
  is monospaced, because the page is making numeric claims.
- Hero: `clamp(2.75rem, 8.5vw, 9rem)`, `letter-spacing: -0.035em`.
  8.5vw not 14vw — the previous build broke `AI ENGINEERING` mid-word into
  `AI ENGINEERIN / G / HARNESS` on desktop. Verified at 390 / 768 / 1440 / 1920.

## Layout (asymmetric, not centered-stack)

Every section sits on a shared 12-column drafting grid with a persistent left
gutter carrying section numerals (`01 — 05`), like a spec sheet.

1. **Hero** — full-bleed, content on columns 1–8 (deliberately off-centre).
   Wordmark set as two hard-broken lines with an explicit `<br>`, never
   auto-wrapped. Right side: a live "gate panel" — the actual merge conditions,
   rendered as an instrument readout. Background: blueprint rule grid drawn on
   canvas, parallaxed, plus a slow scan sweep. No particles, no constellation.
2. **The gate** — the argument. Three conditions with real values, in a
   staggered 3-row layout where each row indents further right. Not three equal
   cards.
3. **The loop** — `ISSUE → WORKTREE → PLAN → BUILD → REVIEW → EVIDENCE → MERGE →
   MEMORY` as a *single continuous path* drawn with an SVG stroke, pinned on
   scroll, `stroke-dashoffset` animated by scroll progress. The previous build
   rendered this as 8 identical boxes that wrapped onto two rows with a dangling
   arrow pointing at nothing; a loop that visibly does not close is the worst
   possible diagram for this product.
4. **What's inside** — the real inventory, as a spec table with monospaced
   figures. Numbers come from `scripts/site-facts.sh`, not from prose.
5. **Install** — the single command, one large copy target. Then footer.

## Motion plan
- Hero: GSAP timeline — rule grid draws in (0.6s) → wordmark lines clip-reveal
  (0.7s, 2 lines not 20 chars, so it cannot look like confetti) → gate panel rows
  tick in (stagger 0.06).
- Scroll: one `ScrollTrigger` pin on the loop section, driving the path
  `stroke-dashoffset` and node activation. Section numerals count up.
- Micro: copy button state change; gate rows respond to hover with a 1px rule
  brighten. No magnetic buttons, no element-wide glow.
- `prefers-reduced-motion: reduce` → all of the above collapse to final state,
  canvas animation stops. Implemented, not just declared.

## Performance budget
- Lighthouse mobile ≥ 90
- LCP < 2.5s
- JS < 200 KB gzipped
- No autoplay video, no web font FOIT (fonts `display: swap`, subset latin)
- Canvas: `devicePixelRatio` capped at 2, paused when off-screen via
  `IntersectionObserver`, and never rendered at all under reduced-motion.

## Truth constraint (project-specific)

Every number on this page must be derivable from the repo at the commit that
builds it. The previous build shipped **9 workflows** (10), **14 CLI agents**
(40), and footer **V1.8.6** (`VERSION` says 0.2.2) — the same drift class the
READMEs were just fixed for, except on the public front door.

`scripts/site-facts.sh` reads the filesystem and writes `src/facts.json`; the
build fails if it is stale. A site whose own numbers are wrong cannot argue for
evidence-gated engineering.

## Reference brands
- Linear — restraint, type scale
- Vercel Edge — instrument readout hero
- Stripe Docs — drafting-grid discipline
- Oscilloscope / logic-analyser UI — the state readout language
