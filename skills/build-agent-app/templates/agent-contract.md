# Agent Contract — <name>

Status: draft | in-review | accepted

## Role

One sentence. Who am I, what kind of work I do.

## Goal

The outcome the user can observe when I'm done. Measurable if possible ("3-sentence summary", "weekly digest", "PR opened with X check").

## Non-goals

What I will not do. Important for narrowing the LLM's choice space.

## Inputs

```yaml
shape: { ... }
example: ...
```

## Outputs

```yaml
shape: { ... }
example: ...
```

## Tools

### `tool_name`

- **Description**: <what the LLM reads to decide when to call it>
- **Inputs**: <schema>
- **Outputs**: <schema>
- **Errors**: <error types + how the agent should respond>

(Add one block per tool. LLM reads the description first; make it tell the LLM when NOT to use the tool.)

## Constraints

- Time / token budget per invocation
- Forbidden actions (what the system prompt MUST forbid)
- Required format rules on every output

## Stop condition

How I know when I'm done. (ReAct: emit `final_answer` or hit budget. Planner: empty task list. Workflow: last step.)
