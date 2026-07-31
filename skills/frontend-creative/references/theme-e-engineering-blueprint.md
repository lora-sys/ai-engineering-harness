# Theme E — Engineering Blueprint / Instrumentation

Aesthetic: drafting rules, measured values, monospaced numerals, one semantic
accent. Best for: developer tools, infrastructure, CI/CD, security, observability,
anything whose pitch is *verifiability* rather than *possibility*.

This theme exists because themes A–D all argue "look what is possible". A product
whose claim is "you can check this" needs a visual language that argues the
opposite of a neon gradient. It is the theme shipped on this repo's own site
(`examples/landing-page/`), so every value below is copied from working code
rather than proposed.

## When to pick this over Theme A

Both are dark. They argue different things.

| | Theme A — Cyberpunk | Theme E — Blueprint |
|---|---|---|
| Argument | this is powerful / futuristic | this is measured / checkable |
| Accent | 3–4 neon hues, decorative | **one**, semantic only |
| Glow | ambient, everywhere | only on state indicators |
| Numerals | display font | monospace, tabular |
| Background | particles / constellation | drafting rules + slow scan |
| Fails when | the product's claim is trust | the product's claim is delight |

If you cannot say what a lit element's *state* is, this is not the theme.

## Tailwind config

```js
export default {
  theme: {
    extend: {
      colors: {
        ink:         '#07090c',   // page ground (near-black, faintly blue)
        plate:       '#0d1116',   // raised surface
        plate2:      '#11171d',   // second-level surface
        rule:        '#1b232c',   // drafting line, 1px
        'rule-lit':  '#2b3947',   // active drafting line
        signal:      '#7ee787',   // THE accent — pass / green CI
        alert:       '#ff7b72',   // fail state only
        paper:       '#e6edf3',   // primary text
        graphite:    '#8b98a5',   // secondary text
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', 'ui-monospace', 'SFMono-Regular', 'monospace'],
        display: ['"Space Grotesk"', 'system-ui', '-apple-system', 'sans-serif'],
      },
      fontSize: {
        // Sized against the COLUMN, not the viewport — see "Type sizing" below.
        hero: ['clamp(2.25rem, 5.4vw, 5.5rem)', { lineHeight: '0.95', letterSpacing: '-0.03em' }],
        section: ['clamp(1.75rem, 4vw, 3.25rem)', { lineHeight: '1.02', letterSpacing: '-0.02em' }],
        label: ['0.6875rem', { lineHeight: '1', letterSpacing: '0.16em' }],
        body: ['1.0625rem', { lineHeight: '1.65' }],
      },
      spacing: { gutter: 'clamp(1.25rem, 4vw, 5rem)' },
      transitionTimingFunction: { instrument: 'cubic-bezier(0.16, 1, 0.3, 1)' },
    },
  },
}
```

### Measured contrast

Computed in-page with the WCAG relative-luminance formula, not estimated:

| | on `ink` | on `plate` | on `plate2` |
|---|---:|---:|---:|
| `paper` | 16.87 | 16.03 | 15.27 |
| `signal` | 12.97 | 12.33 | 11.74 |
| `alert` | 7.91 | 7.51 | 7.15 |
| `graphite` | 6.77 | 6.43 | **6.13** |

Lowest pair 6.13:1 — every pairing clears AA (4.5:1); everything but the greys
clears AAA (7:1). The palette has this headroom on purpose: it survives being
handed to someone who then adds an opacity modifier. It does not survive much.
`text-graphite/60` on small numerals was a real Lighthouse a11y failure on the
shipped site — the token passes, the token at 60% does not.

## Type sizing: against the column, not the viewport

The single most expensive mistake in this theme, because the failure is
**invisible**.

The hero sits on 7 of 12 columns. A `vw`-based clamp sizes against the *viewport*,
so it overshoots by whatever the gutter and the other 5 columns take. At `8.5vw`
on a 1440px viewport the wordmark needed **835px inside a 764px column** — and
because the reveal animation uses `clip-path`, the overflow did not scroll, did
not wrap, and did not show. It rendered as `AI ENGINEERIN`, silently, for a whole
round of review.

`5.4vw` keeps the longest line inside the column from 320px to 2560px.

To measure it, `scrollWidth` is useless — the span is block-level, so it reports
the container width. Get the **inked** text width with a Range:

```js
const el = document.querySelector('.wordmark-line')
const r = document.createRange()
r.selectNodeContents(el)
const textWidth = r.getBoundingClientRect().width   // real ink
const colWidth = el.getBoundingClientRect().width   // available
// textWidth must be < colWidth at every breakpoint you claim to support
```

## Layout

A persistent 12-column drafting grid with a left gutter carrying section numerals
(`01 — 04`), set vertically. Sections are asymmetric by *indent*, not by card
count:

```
01  the argument      row 1  ml-0
                      row 2  ml-[8%]      ← each row steps further right
                      row 3  ml-[16%]
02  the mechanism     one continuous SVG stroke (see below)
03  what's inside     spec table, monospaced figures
04  install           one command, one copy target
```

Three staggered rows instead of three equal cards is the whole point: equal cards
assert everything matters equally. The indent asserts sequence.

## Motion presets

```tsx
// Reduced motion is a code path, not a CSS block. Checked before anything starts.
const reduceMotion = () =>
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

// Hero: on-mount, so from() is safe (the timeline always runs).
// The clip reveal is a `to` because the CLOSED state lives in CSS behind a
// JS-added class — if the bundle never loads, the wordmark is simply visible.
useEffect(() => {
  if (reduceMotion()) return
  document.documentElement.classList.add('js-motion')
  const ctx = gsap.context(() => {
    gsap.timeline({ defaults: { ease: 'power3.out' } })
      .to('.wordmark-line', { clipPath: 'inset(0 0 0% 0)', duration: 0.75, stagger: 0.1 })
      .from('.hero-sub', { y: 14, opacity: 0, duration: 0.5 }, '-=0.35')
      .from('.gate-row', { opacity: 0, x: -8, duration: 0.3, stagger: 0.06 }, '-=0.3')
  }, root)
  return () => { ctx.revert(); document.documentElement.classList.remove('js-motion') }
}, [])
```

```css
/* The closed state is opt-in, added by JS immediately before it animates out. */
.wordmark-line { display: block; }
html.js-motion .wordmark-line { clip-path: inset(0 0 100% 0); will-change: clip-path; }

@media (prefers-reduced-motion: reduce) {
  html.js-motion .wordmark-line { clip-path: none !important; }
}
```

### Scroll: scrub without pin

The loop diagram is one continuous SVG path whose `stroke-dashoffset` is driven by
scroll progress — `scrub: true` with **no `pin`**:

```tsx
ScrollTrigger.create({
  trigger: root.current,
  start: 'top 75%', end: 'bottom 65%',
  scrub: true,
  onUpdate: (self) => {
    const p = self.progress
    paths.forEach((el, i) => { el.style.strokeDashoffset = `${lens[i] * (1 - p)}` })
    setActive(Math.min(STAGES.length - 1, Math.floor(p * STAGES.length)))
  },
})
```

Scrub-without-pin is deliberate and is the honest reading of "no long pins, the
user's scroll stays theirs" (spec §7). The diagram draws as you pass it; leaving
mid-way is allowed and leaves a partially-drawn stroke, which is fine. A pin here
would hold the visitor hostage to a 500ms line animation.

Under reduced motion the offsets are set to `0` (fully drawn) and no
ScrollTrigger is created at all.

### Background: drafting field, not particles

Canvas rules plus one slow scan sweep. Three constraints that make it free:

- `devicePixelRatio` capped at 2 — retina above that buys nothing and costs fill rate
- paused off-screen via `IntersectionObserver`
- **never started** under reduced motion (not "started then stopped")

## SVG diagrams: check the effective font size

A diagram in an 800-wide `viewBox` scaled into a 335px mobile column renders its
`12px` labels at **5.03px**. That is not a style question, it is illegible — and
nothing in the code says `5px`, so it only appears if you compute
`fontSize × (renderedWidth / viewBoxWidth)`.

The fix is not a bigger font inside the viewBox (it wrecks the desktop diagram).
Ship a **separate narrow-screen variant** where the stroke runs top-to-bottom and
labels are real HTML at real size:

```tsx
{/* desktop: horizontal serpentine, labels inside SVG */}
<svg viewBox="0 0 800 260" className="hidden sm:block">
  <path d="M 60 60 H 740 V 130 H 60 V 200 H 740" />
</svg>
{/* mobile: vertical stroke, labels as 11px HTML beside it */}
<div className="sm:hidden"> … </div>
```

## Micro-interactions

- copy button: `'copy'` → `'✓ copied'`, reverting after 1800ms, and **reverting to
  `copy` on a rejected clipboard promise** — never a false success
- gate rows: 1px rule brightens (`rule` → `rule-lit`) on hover. No lift, no glow
- the one lit element is a state dot, and its glow is its job:

```css
.signal-dot {
  box-shadow: 0 0 0 1px rgba(126,231,135,0.35), 0 0 12px rgba(126,231,135,0.45);
}
```

- all numerals `font-variant-numeric: tabular-nums` — figures in a column must
  align, and a page making numeric claims should look like it counts
- no custom cursor. Nothing on the page is a canvas the visitor manipulates, so a
  bespoke cursor would be decoration wearing an interaction's clothes

## Numbers are derived, never typed

Non-negotiable for this theme, because the theme's entire argument is that the
product's claims are checkable. A build script reads the filesystem and writes
`facts.json`; the build fails on drift.

```bash
detectors="$(grep -cE '^[[:space:]]+// (10|[1-9])\. ' path/to/parser.js)"
targets="$(awk '/^TARGETS=\(/{f=1;next} f&&/^\)/{exit} f&&NF{c++} END{print c+0}' install.sh)"
```

Two things learned doing this:

- **Do not publish figures that change every commit.** Test counts were
  deliberately left off the page: a gate that fires during routine work gets
  disabled, and then it guards nothing.
- **Verify from the rendered DOM, not the bundle.** Grepping the minified JS for
  our version matched React's `version:"18.3.1"`. Vite had renamed our keys
  (`workflows:Vx`). The DOM is what the visitor reads, so the DOM is the check.

## Reference brands

- Linear — restraint, type scale
- Vercel Edge — instrument-readout hero
- Stripe Docs — drafting-grid discipline
- Oscilloscope / logic-analyser UI — the state-readout language

## Anti-patterns

- ❌ Adding a second accent. Two semantic colours means neither is semantic
- ❌ Glow on anything without a state. Then light stops meaning "state"
- ❌ A drafting grid nothing aligns to — that is the banned decorative grid (§5)
  wearing a blueprint costume
- ❌ Equal cards. The indent *is* the composition
- ❌ Proportional numerals in a figures table
- ❌ `text-<token>/60` on small text. The token passes contrast; the opacity does not
- ❌ Pinning the diagram section
