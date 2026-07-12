# Diagnosis — Daily-Digest Summarizer

> Output of `workflows/refactor-broken.md`.
> Once approved, hand off to `$ai-engineering-harness` as a fix branch.

## Step 1: Name the symptoms

Map each complaint to a single design violation. **No fix proposal yet** — name first.

| # | Symptom | Apparent cause | Real violation (operating principle) |
|---|---|---|---|
| 1 | "good morning" at 11pm | stale prompt | **Constraints not specified** — Agent Contract didn't say "match greeting to local time." |
| 2 | "Left out the emails I cared about" | bad prioritization | **Workflow beats free-form** — there's no prioritization step. The LLM picks items in arbitrary order; user preferences are unknown. |
| 3 | $1.20 for a 7-bullet digest | unclear cost control | **Cost target not enforced** — Harness Spec had no token-budget ceiling. |
| 4 | Private Slack channel shown to manager | exposed data | **Human approval gate missing** — public-influence actions (the digest is consumed by humans) need a class-of-effect check; "private channel" needs an explicit exclude list. |
| 5 | Length is wildly inconsistent (1–14 bullets) | no shape contract | **Verifiable output** — output shape should be JSON `{greeting: str, bullets: [<max=3>], links: [...]}` not free text. |
| 6 | Digest of "all emails ever" — missed a flight | context blow-up | **No state / window contract** — there's no defined "today" window. Email/Slack history fed in unbounded. |

## Step 2: Map to design principles

Symptoms cluster into three underlying principle violations:

- **Output contract missing** (5, 1) — shape, length cap, greeting rules not in spec.
- **Stop condition + window missing** (6, 2) — no time window defined; no priority rule.
- **Cost + privacy gates missing** (3, 4) — no budget ceiling, no class-of-effect filter.

## Step 3: Minimal fix — change as few contracts as possible

Constraint-driven: pick the **minimum** contracts that kill all six symptoms.

| Change | Fixes symptoms |
|---|---|
| **Output shape contract** — JSON `{greeting, bullets (≤3), links, source_count}`; greeting must match local time of the user's timezone (parametrize at invoke time) | #1, #5 |
| **Window contract** — input is `messages: [{ts, channel, sender, body}]` filtered to `ts >= start_of_today(USER_TZ) AND ts <= now()`; never feed full history | #6 |
| **Priority rule** — score each message by `(mentioned_user, in_recent_thread, has_action_keywords)`; sort desc; take top N (config, default N=3) | #2 |
| **Privacy filter (hard rule, in system prompt)** — exclude `channel.privacy == 'private'` unless `user_id in channel.members`. Audit on every run. | #4 |
| **Token budget** — model `gpt-4o-mini`; max output tokens 400; total budget per run ≤ $0.10; halt + alert if exceeded | #3 |

That's 5 contract changes. They map cleanly to the Agent Contract (output, inputs, constraints) and the Harness Spec (eval, observability, approval).

## Step 4: Eval hooks first (before fix)

Set these up **before** shipping the fix — otherwise we can't tell the fix works.

| Eval | Pass criteria |
|---|---|
| 50 historical digests, ranked "are the 3 bullets the 3 most important?" | precision@3 ≥ 0.7 vs hand-tagged |
| 30 historical digests, "does it leak a private channel?" | precision ≥ 0.95, recall ≥ 0.8 |
| 30 historical digests, "does the cost fit the budget?" | $/run ≤ $0.10 in ≥ 95% of cases |
| Greeting matches local time | 100% on sample of 10 across timezones |
| Output is well-formed JSON with ≤ 3 bullets | 100% parse success |
| Output length variance | p95/p50 ≤ 2 (instead of today's 14/1) |

## Step 5: Hand-off plan for `$ai-engineering-harness`

Branch name suggestion: `fix/daily-digest-contracts`.

Issue body should contain:
- The diagnosis table above.
- The 5 contract changes.
- The eval suite to set up first.
- A diff budget: don't change anything outside the 5 contract changes; that's a refactor-PR.

Go: `Use $ai-engineering-harness to take this issue from Planning to Done.`

## What's intentionally out of scope

- Re-platforming the agent (keeping it on gpt-4o-mini is fine).
- Personalization beyond the priority rule (e.g., "always include emails from my manager"). Add a follow-up Issue.
- Channel blacklist beyond `private`. Add a follow-up Issue.
