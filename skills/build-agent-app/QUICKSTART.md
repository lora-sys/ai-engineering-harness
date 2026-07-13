# Quickstart — build-agent-app

> **Design the agent app, then hand off to `$ai-engineering-harness` for implementation.** This skill is the architect step. It writes the **Agent Contract** and the **Harness Contract**, picks the entry workflow, and hands off. It never writes business code.

The kernel: **agent = model + harness**. Designing an agent app means specifying:

- **Model**: Role + Goal + Tools + Output
- **Harness**: State + Memory + Eval + Observe + Failure path + Human approval

Most agent failures come from one of these contracts being under-specified.

---

## 1 · When to use this skill

| You have… | Use this skill? | Why |
| --- | --- | --- |
| A PRD / idea where the answer is (or could be) an LLM-driven agent | **Yes** | This is the core use case. |
| An existing agent app you want to take over | **Yes** | `takeover-existing.md` workflow. |
| A "broken" agent app that needs diagnosis + targeted rebuild | **Yes** | `refactor-broken.md` workflow. |
| A regular SaaS / web app / internal tool | No | Use plain frontend / backend skills. |
| A PR / issue for an existing agent app | No | That's `$ai-engineering-harness` territory. |

---

## 2 · Pick the right workflow

| You want to… | Start with |
| --- | --- |
| Design a **new** agent app from a PRD / idea | `workflows/new-from-prd.md` |
| **Take over** an existing agent app | `workflows/takeover-existing.md` |
| **Refactor** a broken agent app | `workflows/refactor-broken.md` |

All three end the same way: hand off to `$ai-engineering-harness` for Phase 3 (Implement) → Phase 8 (Review).

---

## 3 · End-to-end example: new agent app

You have a PRD for "SupportPilot" — an LLM agent that triages customer support tickets and either answers or escalates. You want to design it.

### Step 1 — Write the Agent Contract

**You say to the LLM:**
```
$build-agent-app. Run workflows/new-from-prd.md.
Project: ~/code/supportpilot/. PRD: docs/product/prd.md.
Produce the Agent Contract: Role, Goal, Tools, Output.
```

**The LLM produces** (`docs/agent/agent-contract.md`):
```markdown
# Agent Contract — SupportPilot

## Role
Tier-1 support triage agent. Answers or escalates.

## Goal
Given a customer support ticket, produce one of:
- A direct answer (for FAQs / known issues)
- An escalation packet (for billing / account / bugs)
- A clarification question (for ambiguous tickets)

## Tools
- `kb.search(query)` — query the knowledge base
- `ticket.read(id)` — fetch full ticket + history
- `escalate.create(ticket_id, packet)` — open escalation

## Output
A structured JSON object: {decision: "answer"|"escalate"|"clarify", payload: ...}

## Boundaries
NEVER: refund money, close accounts, send emails to customers, modify code.
```

### Step 2 — Write the Harness Contract

**You say to the LLM:**
```
$build-agent-app. Run workflows/new-from-prd.md step 2.
Produce the Harness Contract: State, Memory, Eval, Observe, Failure, Human approval.
```

**The LLM produces** (`docs/agent/harness-contract.md`):
```markdown
# Harness Contract — SupportPilot

## State
Ticket queue (from `escalate.create`), in-flight clarifications, last-action timestamp.

## Memory
- Short-term: per-ticket scratchpad (cleared on close)
- Long-term: per-customer escalation history (read-only past escalations)

## Eval
- 5% of tickets go through a side-by-side review (LLM answer vs. human answer)
- Threshold: ≥ 95% agreement before auto-promote
- Below: roll back to "always escalate"

## Observe
Log: ticket_id, decision, latency_ms, tools_called, eval_score.

## Failure
- Tool error → retry once, then escalate
- ≥ 2 consecutive timeouts → page on-call
- Eval < 0.95 for a day → page on-call + roll back to "always escalate"

## Human approval
Required before: any escalation > $50 refund, any account closure, any public statement.
```

### Step 3 — Hand off

**You say to the LLM:**
```
$build-agent-app. Run workflows/new-from-prd.md step 3.
Hand off to $ai-engineering-harness. Issue brief: "Build SupportPilot
per docs/agent/agent-contract.md + docs/agent/harness-contract.md.
File the first 3 implementation Issues."
```

**The LLM does** the hand-off: emits a `Hand-off packet` (compact summary) that the harness skill reads as its first input.

---

## 4 · End-to-end example: take over

You have `~/code/old-agent/` that's been running for 6 months but nobody knows what it does. You want to understand and document it.

```
$build-agent-app. Run workflows/takeover-existing.md. Target: ~/code/old-agent/.
Read the code. Infer the Agent Contract + Harness Contract. Document the gaps.
```

The LLM:
- Reads the source
- Reverse-engineers the contracts
- Documents: "The Role is X but the code does Y — drift detected"
- Lists gaps: "No Memory, no Failure path, no Eval"
- Hands off to refactor-broken.md with a "fix this first" list

---

## 5 · End-to-end example: refactor a broken agent

`~/code/flaky-agent/` was deployed, customers complain, eval is dropping.

```
$build-agent-app. Run workflows/refactor-broken.md. Target: ~/code/flaky-agent/.
Diagnose: what's the failure mode? Fix the Harness Contract first (eval / observe / failure),
then the Agent Contract. Don't change the model — change the contract.
```

The LLM:
- Reads the eval logs
- Identifies: "Model is fine. Harness is broken — no retry, no tool error handling, eval is sampled at 1% not 5%."
- Rewrites the Harness Contract
- Hands off to `$ai-engineering-harness` for implementation

---

## 6 · Prompt templates (copy-paste)

### New from PRD
```
$build-agent-app. Run workflows/new-from-prd.md.
Project: [path]. PRD: [path/to/prd.md].
Produce the Agent Contract first, then the Harness Contract, then hand off.
```

### Take over
```
$build-agent-app. Run workflows/takeover-existing.md.
Target: [path]. Read the code. Infer the contracts. Document the gaps.
```

### Refactor
```
$build-agent-app. Run workflows/refactor-broken.md.
Target: [path]. Diagnose the failure. Fix the Harness Contract first.
```

---

## 7 · Cheat sheet

### Always do
- ✅ **Write the Agent Contract first.** Role + Goal + Tools + Output + Boundaries.
- ✅ **Then write the Harness Contract.** State + Memory + Eval + Observe + Failure + Human approval.
- ✅ **Be explicit about what the agent NEVER does** (Boundaries section). The harness enforces this, not the model.
- ✅ **Specify the Failure path** before specifying the Happy path. What happens when tools fail? When the model hallucinates? When eval drops?
- ✅ **Hand off to `$ai-engineering-harness`** for implementation. This skill doesn't write code.

### Never do
- ❌ **Write business code from this skill.** That's the harness's job.
- ❌ **Pick a model (GPT-4 vs Claude vs ...) before writing the contracts.** The contract should be model-agnostic; model selection comes later.
- ❌ **Skip the Boundaries section** because "the model won't do that." It will.
- ❌ **Skip the Failure path** because "we'll add it later." You won't. Write it now.
- ❌ **Confuse this skill with `$frontend-creative`.** That one is for creative UIs, not agent apps.

---

## 8 · Where to read more

- `references/decision-0.md` — the agent-app decision framework: is this even an agent, or should it be a regular app?
- `references/harness-checklist.md` — exhaustive list of harness concerns; the workflow walks through each.
- `templates/agent-contract.md` — fill-in template for the Agent Contract.
- `templates/harness-checklist.md` — fill-in template for the Harness Contract.
- `workflows/new-from-prd.md` — full workflow: PRD → Agent + Harness Contracts → hand-off.
- `workflows/takeover-existing.md` — full workflow: existing code → contracts → gaps.
- `workflows/refactor-broken.md` — full workflow: diagnosis → fix the harness first → hand off.
- `agents/` — agent personas for this skill.
- `scripts/scaffold-agent-spec.sh` — generate the agent-spec directory structure.

### Related skills
- **`$ai-engineering-harness`** — receives the hand-off, runs the engineering loop.
- **`$frontend-creative`** — sibling for creative UI design. *Different scope* — don't use it here.

### One-sentence summary

> **Write the Agent Contract and the Harness Contract, then hand off to `$ai-engineering-harness` for implementation. Never write business code from this skill.**
