# Iteration Log

One row per round. Screenshots saved alongside as `round-N.png` in the design workdir.

| Round | Date | What changed | Screenshot | Awwwards self-score (1-10) | Issues to fix in next round |
| --- | --- | --- | --- | --- | --- |
| 1 | | macro layout: regions + type + palette | round-1.png | | |
| 2 | | local: Hero only — fluid gradient glow | round-2.png | | |
| 3 | | local: Scroll-narrative section pinned | round-3.png | | |
| ... | | | | | |

## Anti-drift check (mandatory after every round)

After each round, answer YES / NO to each:

- Did the page get MORE generic or LESS generic this round?
- Is the type scale still giant (≥ clamp(4rem, 12vw, 12rem))?
- Is the layout still asymmetric (no centered 3-card sections)?
- Is the motion still layered (heavy on focal, light elsewhere — not 100% motion)?
- Is the Awwwards self-score (from `review-checklist.md`) holding or improving?

**Reject round if**: more generic, OR type scale shrunk, OR asymmetry flattened, OR motion scope expanded to everything.

**Hard rule**: if "more generic" or any single rejection criterion fires **twice in a row**, stop iterating. Re-read `references/creative-ui-design-spec.md` §12 (Iteration Flow). Consider restarting from `workflows/01-macro-design.md` with a different theme.
