# Decision 0 — Verdict

PRD: PR Review Agent for an internal monorepo.

| Check | Pass | Note |
|---|---|---|
| 1 Goal-named (not just a tool call) | ✅ | "Give every PR a consistent first-pass review" — outcome is observable. |
| 2 Choice required (not just execution) | ✅ | Picking which comments matter and what severity they are is a real judgment task. |
| 3 Verifiable output | ✅ | Comments + severity counts + status — a human reviewer's diff can be diffed against. |
| 4 Stop condition | ✅ | Run ends when all configured checks have produced a verdict. Hard cap = 5 min. |
| 5 Bounded single-mistake risk | ✅ | Only **comments** + status. No merge, no push, no DB write. Worst case = noisy false-positive comment. |

**Verdict: Build an agent.** (5/5 checks pass.)

## What kind of agent

| Pattern | Fit | Why |
|---|---|---|
| Simple LLM → tool → output | weak | the LLM has to choose which of 6+ check categories to run. |
| ReAct (think → act → observe → repeat) | **strong** | natural loop: pick a check, run it, observe output, decide if finding, repeat. |
| Planner / Multi-Agent | overkill | single goal, single domain, no parallel branches. |

**ReAct with explicit stop condition + severity scoring**.

## Tool surface (preliminary)

- `get_pr_diff` — fetch git format-patch for a PR.
- `get_changed_files` — list of touched paths.
- `run_check_secrets` — regex + entropy scan for API keys / passwords.
- `run_check_tests` — confirm tests run for changed paths (heuristic on names).
- `run_check_lint` — for each path, run the relevant linter.
- `run_check_deps` — diff package.json / requirements / go.mod and flag new entries.
- `post_review` — write the review back to GitHub.

## Next step

Run the skill's workflow `workflows/new-from-prd.md`:

1. Write Agent Contract (`templates/agent-contract.md`).
2. Write Harness Spec (`templates/harness-checklist.md`).
3. `scripts/scaffold-agent-spec.sh code-review-agent` → emits `docs/agent-spec/code-review-agent.md`.
4. Hand off to `$ai-engineering-harness`.
