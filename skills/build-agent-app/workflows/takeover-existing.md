# Workflow — Take over an existing agent app

Trigger: user has an agent codebase they don't recognize (or doesn't match our harness conventions).

1. **Inventory** the agent: locate prompt / system messages, tool definitions, model config, state files, eval/observability code.
2. **Reverse-fill the Agent Contract** (`templates/agent-contract.md`) from the existing code. Compare to what the *user thinks* the contract is — gaps are your de-risk opportunities.
3. **Reverse-fill the Harness Spec**. Especially: where is state written? Is there an eval loop? Are high-risk actions gated?
4. **Diff against our design principles** (`SKILL.md` § Operating principles). For each gap, flag with severity (Critical / High / Medium / Low).
5. **Emit a `takeover-PR.md`** that lists: what we found, what's missing, what we'd change in priority order. Don't write code yet.
6. **Hand off** the takeover-PR to `$ai-engineering-harness` as a feature spec.
