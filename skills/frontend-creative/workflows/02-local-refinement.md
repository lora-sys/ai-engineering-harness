# Workflow 02 — Local Refinement

Round 2+: improve **one region at a time**. Never rewrite the whole page.

## Trigger

- Macro design (Round 1) is approved.
- User wants more polish.

## Steps

1. Read `iteration-log.md` for what changed last round.
2. Run the **Phase 2 prompt** from `references/prompt-library.md`:
   > Pick ONE region. Optimize it. Keep other regions unchanged.
3. Implement the change in 1 commit.
4. Save `round-N.png`.
5. Update `iteration-log.md` with the round N row.
6. **Run the Anti-drift check** (mandatory — see `templates/iteration-log.md`):
   - Did the page get MORE generic or LESS generic this round?
   - Is the type scale still giant / asymmetric?
   - Is the motion layered?
7. If "more generic" twice in a row: STOP. Re-read `references/creative-ui-design-spec.md` §12.

## Anti-patterns

- Don't change more than one region per round.
- Don't accept "make it pop more" without specifying what "pop" means.
- Don't add libraries (e.g., "let me also add Three.js for the cursor") — extend what's there.

## Output

- 1 commit per round.
- Screenshot per round.
- Updated `iteration-log.md`.

## Hand-off

- Repeat this workflow until the Awwwards self-score plateaus at ≥ 48/60.
- Then move to `workflows/03-visual-regression-check.md`.
