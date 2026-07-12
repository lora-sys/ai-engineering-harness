# Harness Checklist (every agent needs all of these)

## State

- Session / short-term (current plan, conversation) — bounded; reset by a stop condition.
- Long-term (user prefs, durable facts) — only what's still useful next week.

If long-term state exists, name what schema it has, who reads it, who writes it. Don't store unstructured JSON.

## Memory

Two-tier:

- **Short-term**: ephemeral conversation / plan state. Lives in agent's own context window or session store. Dies with the session.
- **Long-term**: persistent facts the agent must remember across sessions. Name every field; set a dedupe / decay policy; never write the chat log.

Storage choice:

- Structured (preferences, schema) → DB or typed store.
- Embeddings / fuzzy recall → vector store.
- "Maybe useful later" → don't store.

## Evaluation

Two loops:

1. **Per-task**: did the agent emit the expected output given this input? A binary check, an LLM-as-judge, a unit test on the final output shape. Run on every prod invocation, sample.
2. **Per-capability**: how is this agent doing at *its job* over time? Track success rate, retry rate, top error reasons. Loop back to prompt / tool changes.

If eval hooks aren't set up before the agent goes to prod, you can't tell a regression from a bad input. Set them up **first**.

## Observability

Mandatory fields per agent run:

- Inputs (redacted if sensitive)
- Final output
- Tool call list (in order, with latency)
- Stop reason
- Total tokens & cost
- Error info (if any)

Surface them: log to a durable store on every run, queryable. If you can't reproduce a run from logs, you can't debug it.

## Failure handling

For every tool:

- What does it return on error? (Documented.)
- What does the agent do with that error? (Retry? Switch tool? Ask the user?)

For the agent's overall run:

- A single tool error is not a run failure. Retry once, then pick an alternate tool, then escalate to the user.
- A repeated tool error *is* a run failure. Persist the error info to long-term memory as "this tool keeps failing for this input shape" *only if* the pattern recurs.

## Human approval

At minimum, require explicit user approval before any tool that:

- Mutates state outside the agent's own scratch space (DB writes, file changes in shared dirs, API calls to paid services)
- Sends something visible to a third party (email, message, public PR)
- Spends real money or real time (deploys, long-running jobs)

The approval gate is in the agent's loop, not at design-time. It's a tool call the LLM makes when it wants to do a high-risk action.
