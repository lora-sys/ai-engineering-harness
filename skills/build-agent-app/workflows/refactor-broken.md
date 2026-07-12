# Workflow — Refactor a broken agent app

Trigger: user has an existing agent that misbehaves (wrong answers, runaway cost, latency spikes, escalations to user that shouldn't happen).

1. **Symptom-first diagnosis** — don't propose a fix until the symptom is named:
   - Wrong answers → eval loop miss?
   - Runaway cost → no stop condition / tool call explosion?
   - Latency → too many LLM calls per run?
   - Inappropriate escalations → human approval gate mis-set?
   - Hallucinated tools → tool description underspecified?
2. **Trace one failing run** through observability logs. Find the single decision that went wrong.
3. **Map to design principle** (`SKILL.md` § Operating principles 1–8). Each symptom maps to 1–2 principles.
4. **Propose minimal fix** — change exactly one or two contracts/tools/prompts; resist scope creep.
5. **Set up eval hooks first** to measure the fix before deploying. If you can't measure, you're guessing.
6. **Hand off** to `$ai-engineering-harness` as a fix branch. Keep the diff small.
