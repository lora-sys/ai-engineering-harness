# Decision 0: Is this an agent?

Walk through these checks in order. If a check fails, **don't build an agent** — write a different artifact instead.

## 1. The request names a goal, not a tool call.

- ✅ "Summarize these PDFs and tell me what's relevant to my thesis."
- ❌ "Call the PDF parser and print the result."

Goal + outcome → agent. Tool call → script.

## 2. The work needs choosing, not executing.

If you can write a procedural script that does the same thing in deterministic order, **do that instead**. Agents earn their cost when:

- The tool/order is not knowable up-front (LLM picks at runtime).
- Inputs are noisy / varied (LLM parses them).
- Errors require interpretation (LLM triages).

## 3. There's a way to verify the output.

Successful agents deliver:

- A claim that can be checked (right answer / wrong answer)
- A diff that can be reviewed
- An action that has a measurable side effect

If you can't verify any of those, the agent is producing decorative output and you'd be better off shipping a form.

## 4. The loop has a stop condition.

"How long until I pay for an episode?" must be answerable.

- ReAct: "until the model emits Final Answer or hits a tool-call budget."
- Planner: "until the task list is empty or budget N is exhausted."
- Workflow: fixed machine — until the last step.

No stop → runaway risk → don't build an agent.

## 5. Risk of single mistep is bounded.

If one wrong tool call wipes the database, transfers money, or sends a public message, the agent needs a human-in-the-loop checkpoint **before** that action. If every action is high-stakes, an agent is the wrong tool. Re-think the surface area before adding one.

## Pass / Fail summary

| Check | If fail |
| --- | --- |
| 1 Goal-named | Re-cast as a script. |
| 2 Choice required | Re-cast as a script or workflow rule. |
| 3 Verifiable output | Ship a form, not an agent. |
| 4 Stop condition | Don't ship. |
| 5 Bounded risk | Split into a tool-gated workflow with human approvals. |

If all five pass: **yes, build an agent**. Move to writing the Agent Contract.
