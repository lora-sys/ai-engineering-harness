# Workflow 00 — Design Brief Collection

Fill `templates/design-brief.md` with the user before any design work begins. The brief is the contract that the rest of the phases refer back to.

## Trigger

- User asks for a creative webpage.
- No design brief exists yet.

## Steps

1. Run the **Phase 0 prompt** from `references/prompt-library.md`:
   > You are about to design a creative webpage.
   > Ask me ONE question at a time to fill in the design brief.
2. Get answers for all 5 questions (what / audience / primary action / references / theme).
3. Optionally get constraints + out-of-scope + open questions.
4. Write `templates/design-brief.md` to `<project>/docs/design/<id>/brief.md` (substitute `<id>` with a slug).
5. Commit: `git commit -m "design: brief for <id>"`.

## Anti-patterns

- Don't accept "I don't know" for any of the 5 core questions — push back, suggest defaults from `references/theme-variants.md`.
- Don't accept fewer than 3 references — the AI can't design in a vacuum.
- Don't skip "Out of scope" — that section is what saves you from scope creep later.

## Output

- `docs/design/<id>/brief.md` — filled-in brief.
- One row in `iteration-log.md` (Round 0: brief).

## Hand-off

Move to `workflows/01-macro-design.md`.
