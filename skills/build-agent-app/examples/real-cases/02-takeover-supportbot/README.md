# Case 2 — Takeover of a Legacy SupportBot

This case shows the **`takeover-existing` workflow** end-to-end. The point isn't to teach the skill — it's to give a maintainer a **before/after** they can compare against their own legacy agent.

## The Setup

A 5-file mock legacy agent in `01-existing-agent/`:

- `README.md` — single line: "quick hack from 2025-Q3"
- `prompt.txt` — vague system prompt, no constraints, no tool-routing
- `config.json` — gpt-4o-mini, `temperature: 0.7`, `max_tokens: 500`
- `tools_list.md` — one tool: `search_docs(query)`
- `symptoms.md` — three user complaints logged in #complaints

That's it. No state, no logs, no metrics, no eval.

## What the audit produces

`02-audit/takeover-audit.md` walks through:

1. **Inventory** — what exists, what's missing, with severity.
2. **Reverse-filled Agent Contract** — what we *infer* about role, goal, non-goals, inputs/outputs, the one tool.
3. **Reverse-filled Harness Spec** — what's likely missing in state/memory/eval/observe/failure/approval.
4. **Gap-to-principles table** — every gap mapped to one of the 10 design principles in `SKILL.md`, with severity.
5. **Symptom → diagnosis** — each user complaint → root cause → fix.
6. **Takeover plan** — Critical / High / Medium / Low backlog.
7. **Hand-off prompt** for `$ai-engineering-harness`.

## Why it's worth keeping

The pattern "reverse-fill → gap-to-principles → takeover plan" is the actual reusable artifact, not the specific SupportBot. Use this case as a template for any agent you find that:
- doesn't have a per-tool schema
- doesn't have observable runs
- ships public replies without a human-approval gate
- hasn't been told the model its role, its goal, or what tools it has

## Re-running

```text
Use $build-agent-app to integrate examples/real-cases/02-takeover-supportbot/01-existing-agent/.
```
