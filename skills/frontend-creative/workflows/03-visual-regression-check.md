# Workflow 03 — Visual Regression Check

Catch drift before ship. Compare the current state against the brief and against previous rounds.

## Trigger

- Round 2+ iteration is complete.
- Awwwards self-score is plateauing (not necessarily passing).

## Steps

1. **Run the Awwwards review checklist** (mandatory — see `templates/review-checklist.md`): 6 categories, 1-10 each. Total < 36 = fail; 36-47 = needs work; ≥ 48 = ship-able.
2. Run the **Phase 3 prompt** from `references/prompt-library.md`:
   > Compare the current state to the brief.
3. Walk each row of the brief and the `templates/review-checklist.md`.
4. List the top 3 issues, ordered by **impact on Awwwards criteria** (not by ease).
5. **Do NOT modify the code** in this round. Just review.
6. If issues are found: go back to `workflows/02-local-refinement.md` for one more round targeting the top issue.
7. If the page passes review with ≥ 48/60: proceed to ship.

## Drift detection

Read `iteration-log.md` over the last 3 rounds. Ask:
- Did the page get MORE generic each round?
- Did the type scale shrink?
- Did the asymmetry flatten?
- Did the motion scope expand to everything?

If 2+ "yes": the page is regressing. Stop iterating. Re-read §12.

## Output

- A review report (PASS / NEEDS-WORK / FAIL).
- If NEEDS-WORK: top 3 issues.
- If PASS: ready for ship.

## Hand-off

- PASS → `workflows/04-ship.md`.
- NEEDS-WORK → `workflows/02-local-refinement.md`.
- FAIL → restart from `workflows/01-macro-design.md` with a different theme.
