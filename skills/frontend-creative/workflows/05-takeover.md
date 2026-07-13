# Workflow 05 — Takeover (resume an existing design)

Use when the user has an existing design (their own or a previous attempt) and wants to continue improving it. Distinct from `07-redo.md` (which is "blow it up and start over") — takeover assumes the current design is salvageable.

## Trigger

- "I have this design — help me take it to Awwwards level"
- "Here's my current site — let's iterate on it"
- User has an existing project with some design already in place

## Steps

1. **Inventory the current state**:
   ```bash
   # Project layout
   ls -la src/app
   # Recent commits
   git log --oneline -20
   # Current dependencies
   cat package.json | python3 -c "import json,sys; d=json.load(sys.stdin); print('deps:', list(d.get('dependencies',{}).keys()))"
   ```
2. **Capture the current design**:
   - Take screenshots of every page (or every viewport state) at 3 sizes (mobile / tablet / desktop).
   - Save to `<project>/.design-screenshots/before-takeover/`.
3. **Read existing docs** — if the project has `docs/design/`, read the brief and prior iteration logs. Otherwise write a fresh `docs/design/001-brief.md` based on the user's verbal description.
4. **Pick a theme** (A/B/C/D). This is the *new* design language the user wants, not necessarily what the existing design uses. If the existing design is already in-theme, skip this step.
5. **Awwwards baseline score** — run `templates/review-checklist.md` on the current state. Record the total. This is the "before" score.
6. **Identify the gap** — what 1-3 specific things would lift the score by ≥ 12 points? Examples:
   - Type scale too small → fix the hero type.
   - Layout too symmetric → make 1 section asymmetric.
   - Motion flat → add a GSAP timeline to the hero.
7. **Run `workflows/01-macro-design.md` Round 1** with the *new* brief as input. This produces a *target* design.
8. **Run `workflows/02-local-refinement.md` Round 2+** to bring the existing design toward the target.

## Output

- A `before/` screenshot folder documenting the takeover starting point.
- A `brief.md` capturing the new design intent.
- A `review-checklist.md` with a "before" score.

## Hand-off

- Continue with `workflows/02-local-refinement.md` to bring the design to Awwwards level.
- If Round 1 reveals the design is too far gone, switch to `workflows/07-redo.md`.

## Anti-patterns

- ❌ Don't take over without a written brief. Even a 2-line brief is better than no brief.
- ❌ Don't promise to "preserve everything" — takeover is about reaching the target, not about being non-destructive.
- ❌ Don't skip the baseline score. You need a number to measure progress against.
