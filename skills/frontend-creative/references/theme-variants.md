# Theme Variants

Four starting themes from `creative-ui-design-spec.md` §4, with concrete Tailwind tokens + motion presets per theme. Pick one before starting `workflows/01-macro-design.md`.

## Theme A — Cyberpunk Immersive Dark

**Aesthetic**: black background, neon glow, future-tech, particle/WebGL.

**Tailwind tokens**:
- Background: `bg-black` or `bg-zinc-950`
- Primary: `bg-cyan-400` with `shadow-[0_0_30px_rgba(34,211,238,0.6)]`
- Accent: `bg-fuchsia-500`, `bg-yellow-300`
- Type: `font-mono` for body, `font-black tracking-tighter` for hero

**Motion**:
- Hero: GSAP timeline — particle field fades in → headline strokes → CTA glints
- Scroll: parallax depth via R3F (camera Z moves with scroll)
- Hover: magnetic buttons, neon trail cursor

**Reference brands**: Stripe Sessions, Linear Changelog, Vercel Edge.

## Theme B — Minimal Art Gallery

**Aesthetic**: generous whitespace, giant typography, magazine layout, art feel.

**Tailwind tokens**:
- Background: `bg-stone-50` (light) or `bg-stone-950` (dark variant)
- Primary: `bg-stone-900 text-stone-50` for high contrast
- Accent: `text-amber-600` (sparingly)
- Type: `font-serif` for body, `font-serif font-black text-[clamp(4rem,12vw,12rem)]` for hero

**Motion**:
- Hero: Framer Motion fade + slight Y translate on each line (stagger 0.1s)
- Scroll: GSAP ScrollTrigger pinning sections, text reveal on enter
- Cursor: subtle parallax (10px max) tied to cursor position

**Reference brands**: Apple AirPods Max page, Aesop, Studio Daïdai.

## Theme C — Retro Acid Y2K

**Aesthetic**: Y2K, high saturation, brutalist, experimental layout.

**Tailwind tokens**:
- Background: `bg-lime-300` or `bg-fuchsia-300` (loud)
- Primary: `bg-orange-500 text-black`
- Accent: checker pattern, gradient borders
- Type: `font-mono font-black uppercase tracking-widest`

**Motion**:
- Hero: GSAP marquee ticker, chromatic-aberration text
- Scroll: snap-scroll sections, brutalist shift on hover
- Cursor: trail with conic-gradient

**Reference brands**: Gumroad, Linear marketing pages, mid-90s-rave posters.

## Theme D — Future-Tech 3D Particle

**Aesthetic**: WebGL, shader, 3D scene, immersive experience.

**Tailwind tokens**:
- Background: deep gradient `bg-gradient-to-br from-slate-950 via-purple-950 to-slate-950`
- Primary: `text-cyan-200` with bloom
- Accent: shader-driven color blobs
- Type: `font-sans font-light tracking-tight` (thin modern)

**Motion**:
- Hero: R3F particle system (1000-3000 particles), shader-based field
- Scroll: camera dolly + scene rotation tied to scroll progress
- Cursor: influences particle attraction field

**Reference brands**: Apple Vision Pro page, r3f landing examples, Resend homepage.

## How to choose

If the user hasn't specified a theme, pick based on the brief:

| Brief signal | Theme |
| --- | --- |
| "tech / SaaS / developer tool" | A (Cyberpunk) or D (3D) |
| "luxury / lifestyle / brand" | B (Minimal Gallery) |
| "creative agency / portfolio / bold" | C (Retro Acid) |
| "Web3 / AI / experimental product" | D (3D) |

If the user picks "something I've never seen", suggest C or invent a new one.
