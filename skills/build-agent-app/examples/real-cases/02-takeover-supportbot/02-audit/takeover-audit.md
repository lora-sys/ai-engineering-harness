# Takeover Audit — SupportBot

> Output of `workflows/takeover-existing.md`.
> Use this to seed `Issue` → `Plan` for `$ai-engineering-harness`.

## Step 1: Inventory (what's there)

| File | Purpose | Status |
|---|---|---|
| `prompt.txt` | System prompt | exists — vague, no constraints, no tool-routing guidance |
| `config.json` | Model config | temperature 0.7 + 500-token cap → encourages verbosity and hallucination |
| `tools_list.md` | Tool list | single tool, `search_docs`, no schema |
| `README.md` | Single line: "quick hack" |  |

What's **missing**:

- No state store, no session memory, no per-user history.
- No observability — no logs, no traces, no metrics.
- No eval — no golden queries, no precision/recall tracking.
- No failure escalation path (just "tell user to email support").
- No version control for the prompt (no git history).
- No input/output schema — LLM gives free-form strings, no machine-readability.
- No tests at all.

## Step 2: Reverse-filled Agent Contract

### Role
"Friendly" customer-support helper. (Inferred — only "be friendly" is in the prompt.)

### Goal
Answer user questions about AcmeCorp using the help docs.

### Non-goals
Not specified.

### Inputs
Free-form user messages, no schema.

### Outputs
Free-form text replies. (No schema → no way to detect drift.)

### Tools

| Tool | Status | Issue |
|---|---|---|
| `search_docs(query)` | declared | description says nothing about return shape; could return anything |

## Step 3: Reverse-filled Harness Spec

| Spec | Status |
|---|---|
| State | none |
| Memory | none |
| Eval | none |
| Observability | none |
| Failure handling | "tell user to email support" — weakest possible |
| Human approval | none — everything is one LLM call away from a public reply |

## Step 4: Gaps vs Design Principles

| Principle | Gap | Severity |
|---|---|---|
| 1. One agent, one goal | Goal is okay ("answer support questions"), but prompt is too vague | Medium |
| 2. Tools are the boundary | only one tool, return shape unknown | Medium |
| 3. Workflow beats free-form | whole loop is one giant ReAct step — LLM picks everything | High |
| 4. Memory is for future decisions | no memory at all | High |
| 5. Stop condition | none — runs until the LLM decides to stop emitting | High |
| 6. Cost target | $0.50 is implicit by 500-token cap; no per-session tracking | Medium |
| 7. Observability mandatory | **none** | **Critical** |
| 8. Failure handling | degrades to "email support" | High |
| 9. Human approval gate | **none — public replies go out unmoderated** | **Critical** |
| 10. Verifiable output | no eval → no way to verify the claims in the symptom log are real | High |

## Step 5: Symptom → diagnosis (from symptoms.md)

| Symptom | Probable root cause |
|---|---|
| "Different answer for same question" | temperature 0.7 + no eval → answers drift run-to-run. Add seed=42 for reproducible answers; record response hashes to detect drift. |
| "Invented a refund policy" | LLM hallucination on missing docs. Tool's prompt doesn't bind to doc content; need `search_docs` to return `[{id, snippet}]` and force LLM to cite `id`s, plus add an eval that catches non-cited claims. |
| "We have no idea which questions it gets asked" | no observability. Add per-request log with `{ts, user_id, prompt_hash, response_hash, tool_calls, latency}`. |

## Step 6: Takeover plan (priority order)

1. **Critical (do first, blocks safe production use)**
   - Add observability: structured log per request, idempotent.
   - Add human-approval gate **before** `post_reply`. Until then, route to a queue for human review.
2. **High**
   - Bound the prompt: tool return shape `{docs: [{id, snippet, score}]}` and force LLM to cite `id`s.
   - Define non-goals in the prompt explicitly: "do not answer pricing / legal questions, escalate."
   - Add seed (reproducible) + a 50-row golden-set eval + CI gate.
3. **Medium**
   - Cost ceiling: enforce by token-budget diff per request.
4. **Out of scope for the takeover PR**
   - Multi-agent routing (tier 0 bot → tier 1 human) — that's a refactor-PR.

## Step 7: Hand off to `$ai-engineering-harness`

The takeover spec above is what aeh needs. Suggested Issue title:

> Take over legacy SupportBot: add observability + human approval gate

Suggested Issue body: link to `takeover-audit.md` + `references/harness-checklist.md`.

Skill output lands in `docs/product/takeover-supportbot.md`. Then:

```text
Use $ai-engineering-harness to bootstrap this repo from docs/product/takeover-supportbot.md
```
