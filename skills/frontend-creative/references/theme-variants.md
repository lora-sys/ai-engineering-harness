# Theme Variants — Index

Five starting themes. Each has its own file with concrete Tailwind config, motion
presets, and reference brands.

| Theme | File | Use when |
| --- | --- | --- |
| A — Cyberpunk Immersive Dark | [`theme-a-cyberpunk.md`](theme-a-cyberpunk.md) | Tech / SaaS / consumer AI |
| B — Minimal Art Gallery | [`theme-b-minimal-gallery.md`](theme-b-minimal-gallery.md) | Luxury / lifestyle / brand |
| C — Retro Acid Y2K | [`theme-c-retro-acid.md`](theme-c-retro-acid.md) | Creative agencies / portfolios / bold |
| D — Future-Tech 3D Particle | [`theme-d-future-3d.md`](theme-d-future-3d.md) | Web3 / experimental products |
| E — Engineering Blueprint | [`theme-e-engineering-blueprint.md`](theme-e-engineering-blueprint.md) | Developer tools / infra / CI / security / observability |

A and E are both dark and are the two most likely to be confused. Pick by what the
product claims:

- claims **possibility** ("look what this can do") → **A**
- claims **verifiability** ("you can check this") → **E**

A neon-gradient hero on a product whose pitch is trust argues against its own
pitch. That is why this repo's own site was rebuilt from A to E — see
`examples/landing-page/` for the shipped implementation, which is where every
value in theme E's file comes from.

If none fit, invent your own — copy theme-b's structure, swap tokens, document the
aesthetic.
