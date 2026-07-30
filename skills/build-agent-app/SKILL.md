---
name: build-agent-app
description: Design/take over/refactor an agent app (LLM + tools + state). Triggers: build an agent, wire up LLM tool, chatbot, agent is broken, agent app. Writes Agent + Harness Contract, hands off to $ai-engineering-harness. Workflows: new / takeover / refactor. Install: bash install.sh --skill build-agent-app
---

# build-agent-app

Kernel: **agent = model + harness**. This is the **architect step**. Implementation belongs to `$ai-engineering-harness`.

## Trigger

Keywords: build an agent, convert PRD to agent, take over existing agent, agent is broken, diagnose agent, wrap script in agent loop, wire up LLM tool, chatbot, agent app.

Skip if: single-step script, pure LLM chat without tools, general code task (use `$ai-engineering-harness`).

## Operating principles

1. **Decision 0: is this even an agent?** Demand a written answer before designing tools/prompts/state.
2. **One agent, one goal.** "Search + code + bookings + chat" = 4 products. Split before scaling.
3. **Tools are the boundary.** If the agent can't do anything, it's a chatbot.
4. **Workflow beats free-form planning.** ReAct or Planner patterns, not "let the LLM figure it out."
5. **Memory is for future decisions**, not chat logs.
6. **High-risk actions require human approval.** Deploy, delete, send money.
7. **Every agent must be observable.** Trace decisions, tool calls, failures.
8. **Failure paths are part of the design.** Plan retries, fallbacks, escalation.
9. **This skill writes contracts + entry workflow; `$ai-engineering-harness` does code + tests + PR + review.**

## Workflow selection

Pick one:
- **`workflows/new-from-prd.md`** — PRD/idea → design + spec + handoff
- **`workflows/takeover-existing.md`** — existing agent → audit + integrate
- **`workflows/refactor-broken.md`** — symptoms → diagnose + rebuild

Run `references/decision-0.md` first if unclear.

## Contracts (always write)

**Agent Contract** (`templates/agent-contract.md`):
- Role, Goal, Constraints, Tools (name + description + input/output schema), Output format

**Harness Contract** (`references/harness-checklist.md`):
- State, Memory (short vs long), Eval, Observability, Failure paths, Human approval

Write contracts BEFORE writing code. Let code follow.

## Hand-off

After contracts exist, emit `docs/agent-spec/<name>.md` (compatible with `$ai-engineering-harness`'s `docs/product/` style). Then:

> Use $ai-engineering-harness to bootstrap this repo from docs/agent-spec/<name>.md

## Anti-patterns

- Universal Agent ("does search + code + bookings + chat") — split it.
- Tool-permission-everything — least privilege.
- Free-form plans without checkpoints — agent drifts.
- Storing chat in memory — bloats context, never useful.
- Prompt over 200 tokens with no Constraints section.
- "I'll add eval later" — set eval hooks before first prod run.
- Implementing before writing the contracts.

## Quick start

```
# New app from PRD
Use $build-agent-app to design a code-review agent from PRD.md

# Take over existing
Use $build-agent-app to integrate /path/to/agent-app into my project

# Refactor broken
Use $build-agent-app to diagnose why /path/to/agent is doing X wrong
```

## Read on demand

- `references/decision-0.md` — "is this an agent" checklist
- `references/harness-checklist.md` — State/Memory/Eval/Observe/Failure/Approval
- `templates/agent-contract.md` — Role/Goal/Constraints/Tools/Output
- `templates/harness-checklist.md` — copy-paste harness spec
- `scripts/scaffold-agent-spec.sh` — scaffold `docs/agent-spec/<name>.md`
- `$dashboard` — sibling skill for visualizing harness project state
- `$ai-engineering-harness` — sibling for implementation (code + tests + PR + review)
