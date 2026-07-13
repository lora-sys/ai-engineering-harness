# Workflow 04 — Ship

Final checks + hand-off to `$ai-engineering-harness` (if the design needs to become a shipped product).

## Trigger

- Visual regression passed (`workflows/03-visual-regression-check.md`).
- Awwwards self-score ≥ 48/60.

## Steps

1. Run the **Phase 4 prompt** from `references/prompt-library.md`.
2. **Run `templates/review-checklist.md` end-to-end** (mandatory pre-ship gate). Final score recorded.
3. Verify performance:
   - Lighthouse mobile ≥ 90 (Performance, A11y, Best Practices, SEO)
   - LCP < 2.5s on mid-range mobile
   - No autoplay video / audio
   - No layout thrash (transforms only)
4. Verify Awwwards criteria (the checklist).
5. **Commit `final`** with screenshot, design brief, iteration log, review checklist all bundled.

## Hand-off (two paths)

**Path A — design exploration only** (user wanted a design, not a product):
- Stop here. The design is the deliverable.
- Optionally: write a `case-study.md` describing the process, the failures, what worked.

**Path B — ship as product**:
- Hand off to `$ai-engineering-harness`:
  > Design approved. Brief at `docs/design/<id>/brief.md`. Macro at `<repo>`. Hand off to `$ai-engineering-harness` for Phase 3 (Implement) through Phase 8 (Review).
- The harness will run its normal evidence-gated loop with the creative-stack agent preset.

## Anti-patterns

- Don't ship with lorem ipsum or fake testimonials.
- Don't ship below Lighthouse 90.
- Don't ship without an Awwwards self-score ≥ 48/60.

## Output

- A `final` commit.
- Either a `case-study.md` (path A) or a hand-off message to `$ai-engineering-harness` (path B).
