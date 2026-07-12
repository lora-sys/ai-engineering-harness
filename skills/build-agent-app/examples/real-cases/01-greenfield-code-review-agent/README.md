# Case 1 — Greenfield PR Review Agent

This case shows the **`new-from-prd` workflow** end-to-end on a real-shaped PRD.

## The PRD

A 6-point Product Requirements Doc for an internal-monorepo PR-review agent. Look at it through the lens of:
- "Goal-named, not tool call-only."
- "Choice required, not just execution."
- "Verifiable output."
- "Stop condition."
- "Bounded single-mistake risk."

Five checks all pass. **Verdict: build an agent.** The Decision-0 file spells out which pattern fits (ReAct) and why.

## What this case demonstrates

| Pattern | Where it shows up |
| --- | --- |
| Decision-0 with 5-dim table | `02-decision-0/decision-0.md` |
| Per-tool contract with `name`, `description`, input/output, error-response | `03-agent-contract/agent-contract.md` |
| Harness spec with Stop, Memory, Eval, Failure, Human-approval | `04-harness-spec/harness-spec.md` |
| Hand-off scaffold (the eeh-ready spec) | `05-spec-output/code-review-agent.md` |

## How to read it

1. Start with `01-input/PRD.md` — that's what the user would hand the skill.
2. Read `02-decision-0/` next. If verdict says "build an agent", continue.
3. Compare `03-agent-contract/` against `templates/agent-contract.md` — every section in the template should appear, filled.
4. Same comparison for the harness.
5. The scaffolded spec at `05-spec-output/code-review-agent.md` is what you'd hand to `$ai-engineering-harness`:

   ```text
   Use $ai-engineering-harness to bootstrap this repo from docs/agent-spec/code-review-agent.md
   ```

## Re-running the case

If you want to re-derive the outputs (e.g., the contract drifted):

```bash
# Tell any Codex session to act as the skill:
# "Use $build-agent-app. The PRD is at examples/real-cases/01-greenfield-code-review-agent/01-input/PRD.md."
```

The output should land somewhere under `./output/` of wherever you ran it from.
