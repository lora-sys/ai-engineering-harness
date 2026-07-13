---
name: build-agent-app
description: >
  Design, take over, or refactor an agent app. Use when (a) the user has a
  PRD/idea and the answer is or could be an LLM-driven agent, (b) the user
  wants Codex to wire an existing agent app into a new harness / workflow /
  eval, or (c) the user hands over a "broken" agent app that needs diagnosis
  and a targeted rebuild. Acts as the Agent App Architect: writes the Agent
  Contract + Harness Contract, picks the entry workflow (new / takeover /
  refactor), then hands implementation off to $ai-engineering-harness. Pairs
  with that skill -- build-agent-app answers "should we even build an agent,
  and what should it look like"; ai-engineering-harness answers "how do we
  ship it as a working, evidence-gated piece of code."
---

# build-agent-app

The kernel: **agent = model + harness**. Designing an agent app is the act of specifying the model (Role + Goal + Tools + Output) and the harness (State + Memory + Eval + Observe + Failure path + Human approval). Most agent failures come from one of these ten contracts being under-specified.

This skill is the **architect step**. Implementation belongs to `$ai-engineering-harness`. Never write business code from this skill.

> **New to this skill? Read [`QUICKSTART.md`](QUICKSTART.md) first** — working tutorial with end-to-end examples for the 3 entry workflows (new / takeover / refactor), copy-paste prompt templates, and a do/don't cheat sheet.

## When to use

Use this skill if the user's request is **any of**:

- "Build me an agent that does X."
- "Convert this PRD into an agent app."
- "Take over this existing agent and make it fit our workflow."
- "This agent is broken — diagnose and refactor."
- "Wrap this script/tool in an agent loop."
- "I have a tool. Should I add an LLM in front, and if so which one?"

Do not use it for:

- Single-step scripts (just write the script).
- Pure LLM chat / RAG without tool use (just write a prompt).
- Code tasks in general — use `$ai-engineering-harness` directly.

## Operating principles

1. **Decision 0: is this even an agent?** Most "agent" requests are scripts. Demand a written answer before designing tools, prompts, or state. See `references/decision-0.md`.
2. **One agent, one goal.** An agent that "does search, writes code, books flights, and chats" is four products glued together. Split before scaling.
3. **Tools are the boundary.** If the agent can't *do* anything, it's a chatbot. Quality of the agent ≈ quality of the tool design.
4. **Workflow beats free-form planning** for repeated tasks. Use ReAct or Planner patterns, not "let the LLM figure it out."
5. **Memory is for future decisions**, not chat logs. If nothing will read this state next week, don't store it.
6. **High-risk actions require human approval.** Deploy, delete, send money, modify production. The harness enforces, the user ratifies.
7. **Every agent must be observable**: trace the decision, the tool calls, the failures. Don't ship a black box.
8. **Failure paths are part of the design.** Tool errors, permission errors, timeouts — plan retries, fallbacks, escalation.
9. **After this skill: implementation is `$ai-engineering-harness`'s job.** This skill writes contracts + entry workflow; aeh does code + tests + PR + adversarial review.

## Workflow selection

Pick exactly one:

- **`workflows/new-from-prd.md`** — user has a PRD / idea / script → design + spec + handoff.
- **`workflows/takeover-existing.md`** — user has an agent code we don't recognize → audit + integrate.
- **`workflows/refactor-broken.md`** — user reports symptoms (cost, wrong answers, latency) → diagnose + minimal rebuild.

If the user's request doesn't fit cleanly, run `references/decision-0.md` first; the workflow falls out of the answer.

## Agent Contract (always write this)

For every agent that comes out of this skill, fill `templates/agent-contract.md`:

- **Role** — who am I, in one sentence
- **Goal** — outcome the user can observe when I'm done
- **Constraints** — forbidden actions, format rules, response shape
- **Tools** — each with `name`, `description` (the description is the LLM's guide), input schema (strict), output schema
- **Output** — wire format for the final result

Don't write the contract *after* writing the code. Write it first; let the code follow.

## Harness Contract (always write this)

For the agent's runtime, fill `templates/harness-checklist.md` (or read `references/harness-checklist.md`):

- **State** — session vs long-term; what lives where
- **Memory** — short (conversation state, current plan) vs long (user prefs, facts); only what's future-useful
- **Eval** — how we measure success, and how that loops back to prompt/code changes
- **Observability** — tracing, logs, metrics
- **Failure** — retries, alt tools, escalations to user; never silent
- **Human approval** — which tool categories pause for "are you sure?"

## Hand-off to `$ai-engineering-harness`

After contracts exist, this skill emits a `docs/agent-spec/<name>.md` (compatible with `ai-engineering-harness`'s `docs/product/` style). That file is what `$ai-engineering-harness` consumes as the project's PRD.

Suggested hand-off prompt to the user:

```text
Use $ai-engineering-harness to bootstrap this repo from docs/agent-spec/<name>.md
```

If you're not in a real project yet, run `scripts/scaffold-agent-spec.sh <name>` to lay down the spec scaffold in any directory.

## Anti-patterns

- **Universal Agent** ("does search + code + bookings + chat"). Split it.
- **Tool-permission-everything** ("root + full db + R + W"). Least privilege.
- **Free-form long plans** without checkpoints — agent drifts.
- **Storing chat in memory** — never useful; bloats context.
- **Prompt over 200 tokens with no Constraint section** — LLM weight vs rule imbalance.
- **"I'll add eval later"** — set the eval hooks before the first prod run.
- **Implementing without first writing the Agent + Harness Contract** — the whole skill exists to prevent this.

## Quick start

```text
# New app from PRD
Use $build-agent-app to design a code-review agent from PRD.md

# Take over existing
Use $build-agent-app to integrate /path/to/agent-app into my project

# Refactor broken
Use $build-agent-app to diagnose why /path/to/agent is doing X wrong
```

For installation:

```bash
npx -y skills add lora-sys/build-agent-app -g --all
```

## Bundled resources

- `references/decision-0.md` — "is this an agent" checklist
- `references/harness-checklist.md` — State/Memory/Eval/Observe/Failure/Approval
- `templates/agent-contract.md` — Role/Goal/Constraints/Tools/Output
- `templates/harness-checklist.md` — copy-paste harness spec
- `workflows/new-from-prd.md` — entry: greenfield design → hand off
- `workflows/takeover-existing.md` — entry: reverse-engineer an existing agent → integrate
- `workflows/refactor-broken.md` — entry: symptom → diagnosis → minimal rebuild
- `scripts/scaffold-agent-spec.sh` — make a `docs/agent-spec/<name>.md` skeleton

Read on demand. Concise is a feature.
