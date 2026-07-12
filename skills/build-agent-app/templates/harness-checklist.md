# Harness Spec — <agent name>

## State

- Long-term store: <name> / <schema> / <writer> / <reader>
- Session store: <what lives only for one run>

## Memory

- Short-term: <plan, last tool result>
- Long-term: <durable facts only — list which>
- Write policy: <only on stop / only on confirm / never>

## Eval

- Per-task check: <binary check / unit test / LLM-as-judge>
- Per-capability metric: <success rate, cost, latency p95>
- Sample rate: <how often the per-task eval runs in prod>

## Observability

- Log every run: <destination>
- Fields per run: inputs, outputs, tool calls, stop reason, tokens, errors
- Dashboard / search: <link or "stdout until we outgrow that">

## Failure handling

| Tool | Error type | Agent action |
| --- | --- | --- |
| ... | timeout | retry once, then escalate |
| ... | 4xx | retry with corrected input |
| ... | 5xx | switch to backup tool |

## Human approval gate

| Action class | Always require approval? | Mechanism |
| --- | --- | --- |
| Read-only tool | no | — |
| Local scratch write | no | — |
| External API call (write side-effect) | yes | "approve_<action>" tool that pauses the run |
| Spend money / production change | yes | "approve_<action>" tool that pauses the run |

## Cost target

- Token / USD per run ceiling: <number>
- Daily ceiling: <number>
- Action when exceeded: <kill-switch / degrade / notify>
