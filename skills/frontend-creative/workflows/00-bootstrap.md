# Workflow 00 — Bootstrap (new project from scratch)

Use when the user wants to start a fresh frontend project with the creative stack. Distinct from `workflows/00-design-brief-collection.md` (which fills the brief) — bootstrap handles the *technical* setup so the design work has somewhere to live.

## Trigger

- "I want to start a new creative website for X"
- No existing project repo (or user wants a fresh repo)
- User has filled or is willing to fill `templates/design-brief.md`

## Steps

1. **Confirm brief** — if `templates/design-brief.md` isn't filled, send the user to `workflows/00-design-brief-collection.md` first. Don't bootstrap without a brief.
2. **Pick a theme** — read `references/theme-variants.md` (or the 4 per-theme files). The user picks, or default by brief signal:
   - "tech / SaaS / developer tool" → A (Cyberpunk)
   - "luxury / lifestyle / brand" → B (Minimal Gallery)
   - "creative agency / portfolio / bold" → C (Retro Acid)
   - "Web3 / AI / experimental" → D (Future 3D)
3. **Scaffold the project**:
   ```bash
   npx create-next-app@latest <project-name> --typescript --tailwind --app
   cd <project-name>
   ```
4. **Install the creative stack**:
   ```bash
   npm i framer-motion gsap @react-three/fiber @react-three/drei three
   npm i -D @types/three
   # Optional smooth scroll:
   npm i @studio-freight/lenis
   ```
5. **Apply the chosen theme's Tailwind config** — copy the theme's `tailwind.config.ts` block from `references/theme-{a,b,c,d}-*.md` into the project's `tailwind.config.ts`. Replace the default colors / fonts.
6. **Set up the design system files**:
   - Copy `templates/design-brief.md` → `<project>/docs/design/001-brief.md` (or your chosen issue id).
   - Create `<project>/iteration-log.md` (copy the table header from `templates/iteration-log.md`).
   - Copy `templates/review-checklist.md` → `<project>/docs/design/001-review.md`.
7. **Initial commit**:
   ```bash
   git add .
   git commit -m "chore(bootstrap): scaffold + creative stack + theme"
   ```
8. **Hand off** to `workflows/01-macro-design.md` (Round 1).

## Output

- A Next.js + TS + Tailwind + Framer Motion + GSAP + R3F project, on a chosen theme, ready for design work.
- `docs/design/001-brief.md`, `iteration-log.md`, `docs/design/001-review.md` initialized.

## Hand-off

`workflows/01-macro-design.md`. The project is ready for Round 1.
