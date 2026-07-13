# Workflow 07 — Redo (回炉改造)

The "狗屎" workflow. Run when the existing design is too far gone to take over incrementally. Different from `workflows/05-takeover.md` (which is incremental improvement) — redo blows up the design and starts from a clean slate.

## Trigger

- Awwwards baseline score < 24/60 (multiple categories = 0).
- The user describes the design as "狗屎" / "garbage" / "I hate it" / "it doesn't work".
- The brief has fundamentally changed (different audience, different product, different message).

## Steps

1. **Admit the redo** — write it down. The anti-drift check has failed twice in a row; the current direction is degrading. Refusing to admit this leads to incremental tweaks on a broken foundation.
2. **Diagnose the failure** — fill `templates/post-mortem.md` (a quick one, not the full post-mortem workflow):
   - What was the original brief?
   - What got shipped instead?
   - Why the gap?
   - What constraint / decision led to the wrong direction?
3. **Write a new brief** — overwrite `docs/design/<id>/brief.md` with the corrected intent. The new brief should be a *response* to the diagnosis, not just a tweak of the old one.
4. **Pick a different theme** — if the previous attempt was Theme A, try B or C. Same theme = same mistakes.
5. **Restart from `workflows/00-bootstrap.md`** with the new brief. (Or, if the project is already scaffolded, jump to `01-macro-design.md`.)
6. **Keep the old version accessible**:
   ```bash
   git tag before-redo-<n>
   git checkout -b archive/before-redo-<n>
   ```
   The old version isn't deleted; it's archived. The new design lives on `main`.
7. **Run `02-local-refinement.md` Round 2+** with the new theme + new brief.

## Output

- A new design (replaces the old).
- An archived branch (`archive/before-redo-<n>`) with the old version.
- A short `post-mortem.md` explaining what went wrong.

## Hand-off

- New design continues through `02-local-refinement.md` → `03-visual-regression-check.md` → `04-ship.md`.
- After the new design ships, run `06-post-mortem.md` to compare new vs old.

## Anti-patterns

- ❌ Don't "fix" by adding more rounds. Two failed anti-drift checks = redo, not round 7.
- ❌ Don't reuse the old theme. The new theme should be the explicit answer to "what the old theme got wrong".
- ❌ Don't keep iterating the new design before reaching Awwwards ≥ 48/60. If Round 1 of the redo gets 30, Round 2 of the redo should NOT be more iteration — it should be a *second* redo.
