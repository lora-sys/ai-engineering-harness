# Frontend Acceptance Checklist

Owner signs every relevant box before opening PR.

## Code Quality

- [ ] Component is small, single-purpose, no prop drilling beyond one level without context.
- [ ] No hardcoded colors / sizes — uses tokens (CSS variables / Tailwind theme / styled system).
- [ ] Imports are clean (no unused, no circular).
- [ ] Lint, formatter, types pass.

## State & Data

- [ ] Loading state shown for async work.
- [ ] Empty state has copy + a primary action.
- [ ] Error state is recoverable (retry / contact / fallback).
- [ ] Optimistic updates are paired with rollback on failure.

## Accessibility

- [ ] Keyboard reachable; visible focus.
- [ ] Color contrast meets AA.
- [ ] Form fields have labels; errors are announced (`aria-live`).
- [ ] `lang` attribute on `<html>`.
- [ ] `alt` on meaningful images; `alt=""` on decorative.
- [ ] Touch targets ≥ 44×44 px (mobile).

## Performance

- [ ] Largest Contentful Paint < 2.5 s on a throttled Fast 3G trace for primary route.
- [ ] Total JS payload budget respected (project-defined).
- [ ] Images optimized; `srcset`, lazy where appropriate.

## Motion

- [ ] Durations < 400 ms for transitions.
- [ ] Reduced-motion fallback present.

## Visual

- [ ] Verified at 320 / 768 / 1280 / 1920 px widths.
- [ ] No overflow / no horizontal scroll.
- [ ] Typography hierarchy respected.

