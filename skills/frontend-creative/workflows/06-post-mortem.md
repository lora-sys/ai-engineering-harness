# Workflow 06 — Post-Mortem (复盘)

Run after a design ships. Different from `workflows/04-ship.md` (which is the pre-ship gate). Post-mortem is *after* the project is live and ideally after some user-feedback cycle.

## Trigger

- A design has shipped (≥ 1 week ago).
- User has feedback (analytics, user comments, A/B test results).
- Team wants to extract lessons for the next project.

## Steps

1. **Gather signals**:
   - Analytics: bounce rate, time on page, scroll depth, CTA click rate.
   - User feedback: comments, support tickets, social mentions.
   - Internal team feedback: "what would I do differently next time?"
2. **Compare to the brief**:
   - For each AC row in `docs/design/<id>/brief.md`, mark: HIT / PARTIAL / MISS.
   - For each row in `templates/review-checklist.md`, did the Awwwards score hold up in production?
3. **Identify the top 3 things to remember for next time**:
   - One thing that worked and should be repeated.
   - One thing that didn't work and should be avoided.
   - One thing that was missing and should be added (process / tool / role).
4. **Write a case-study.md**:
   ```markdown
   # Case Study — <project name>

   ## What was built
   <one-paragraph summary>

   ## Awwwards score (final)
   ## over 60

   ## Top 3 lessons
   1. ...
   2. ...
   3. ...

   ## Anti-patterns observed
   - ...

   ## For next project
   - ...
   ```
5. **Append to the case-study library** — `docs/case-studies/<project>.md`.

## Output

- `docs/case-studies/<project>.md` — case study with top 3 lessons.
- The project's iteration log gets a final "shipped + reviewed" entry.

## Hand-off

- Lessons go to:
  - `memory/notes.md` (project-scoped, if the project has memory/)
  - The user's general creative process (if there is one)
  - This skill's `references/prompt-library.md` if a new prompt pattern emerged
