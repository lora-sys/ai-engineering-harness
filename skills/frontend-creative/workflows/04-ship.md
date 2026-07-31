# Workflow 04 — Ship

Final checks + hand-off to `$ai-engineering-harness` (if the design needs to become a shipped product).

## Trigger

- Visual regression passed (`workflows/03-visual-regression-check.md`).
- Awwwards self-score ≥ 56/70.

## Steps

1. Run the **Phase 4 prompt** from `references/prompt-library.md`.
2. **Run `templates/review-checklist.md` end-to-end** (mandatory pre-ship gate). Final score recorded.
3. Verify performance — each of these is a **measurement to run**, not a box to
   tick from memory:
   - Lighthouse mobile ≥ 90 (Performance, A11y, Best Practices, SEO). Record the
     four numbers. If any audit fails, fix it or state plainly why it is waived.
   - LCP < 2.5s, CLS < 0.1 — from a real trace, not an estimate.
   - JS gzipped within the brief's budget. `gzip -c dist/assets/*.js | wc -c`.
   - No autoplay video / audio.
   - No layout thrash (transforms only).
4. Verify interaction and a11y by exercising them:
   - Emulate `prefers-reduced-motion: reduce`, reload, and assert every entrance
     is at its final state and no canvas/RAF loop is running.
   - Tab through the whole page. Every interactive element reachable, focus
     visible, no trap.
   - Compute contrast for every text pair with the WCAG formula. Lowest pair
     ≥ 4.5:1. **Compute it in the page** — palette values look fine and measure
     badly more often than not.
   - Screenshot at 320 / 390 / 768 / 1440 / 1920 and confirm no horizontal scroll
     and no clipped text. Text hidden by `clip-path` or `overflow` does not show
     up in a screenshot — measure the text run against its container.
5. Verify content sources: every figure listed in brief §8 is either derived at
   build time or explicitly justified as static. A build that can ship a stale
   number will eventually ship one.
6. Verify the **deployed** page, and verify it is *this* build. Two separate
   checks, because either alone passes while the other fails:

   a. **Provenance** — the deployment that is live was produced by this commit.
      Get the deploy run's head SHA and match it against the merge commit, and
      confirm a site-build job actually ran on the PR:

      ```bash
      gh run list --branch main --workflow deploy-<site>.yml \
        --json headSha,conclusion,createdAt --limit 1
      git rev-parse HEAD          # must equal headSha above
      gh pr checks <n>            # a build job must appear, not just lint/test
      ```

      Without this, a stale deployment satisfies every content check below —
      it is serving the *previous* build, which was also correct. Four green
      checks mean nothing if no job touched the site's paths: that is how this
      repo's own rebuild reached `main` with 1,070 unbuilt lines.

   b. **Content** — read the figures from the **rendered DOM**, not the bundle.
      A minifier renames your keys, so grepping the shipped JS is unreliable —
      on this repo's own site that grep matched React's `version:"18.3.1"`
      instead of the project's. The DOM is what the visitor reads.

   Belt-and-braces if the site can afford it: emit the build SHA into the page
   (a `<meta>` or footer) so provenance is checkable from the DOM alone, in one
   step, by anyone.
7. **Commit `final`** with screenshot, design brief, iteration log, review checklist all bundled.

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
- Don't ship without an Awwwards self-score ≥ 56/70.
- Don't report a number you did not measure this round. "Lighthouse 95" from two
  rounds ago is not evidence; it is a memory.
- Don't let CI be the first thing that builds the site. If deployment is
  automated on merge, the build must also run on the PR — otherwise the four
  green checks say nothing about the page.

## Output

- A `final` commit.
- Either a `case-study.md` (path A) or a hand-off message to `$ai-engineering-harness` (path B).
