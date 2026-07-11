# Submission: Add `lora-sys/ai-engineering-harness` to the skills.sh index

## What this skill does

`ai-engineering-harness` is a multi-agent **software-engineering organization harness** for any CLI coding agent that follows the `npx skills`-compatible skill convention. It encodes an Issue → Worktree → Plan → Implement → Adversarial Review → Evidence → Merge → Memory closed loop.

Bundle:

- **18 agent personas** (Coordinator, Frontend, Backend, Database, QA, Bug Hunter, Behavior Reviewer, Architecture Reviewer, Security Reviewer, UI Reviewer, Conflict Resolver, Release, Context Assembly, Memory Curator, …)
- **9 closed-loop workflows** (project bootstrap, feature delivery, adversarial PR review, conflict resolution, …)
- **16 templates** (Issue bug/feature/refactor/spike, Implementation Plan, PR, Review Report, Evidence Pack, Phase Summary, ADR, …)
- **6 acceptance checklists** (Evidence Gate, Frontend, Backend, Database, Security, PR Merge)
- **Install script** for 38 CLI coding agents + bilingual README (English + Chinese)
- **MIT license**

## One-line install

```bash
npx -y skills add lora-sys/ai-engineering-harness -g --all
```

## What I've done to make indexing trivial

- ✅ `SKILL.md` at the repo root with full YAML frontmatter (`name`, `description` ~ 200 chars describing the loop).
- ✅ `meta.json` at the repo root with `{id, name, description, category, priority, tags, install, agents_supported, license, repository, entry}` schema.
- ✅ Repo description begins with the use-it phrase: "AI-native software engineering organization harness. Use 4 prompts: bootstrap / resume / drive / audit."
- ✅ 10 GitHub topics including `skills`, `multi-agent`, `code-review`, `evidence`, `ai-engineering`.
- ✅ `LICENSE: MIT`.
- ✅ Releases v0.1.0 → v0.1.5 already tagged.
- ✅ Architecture diagram (`assets/architecture.svg`) + 1200×630 social card (`assets/social-preview.png`).
- ✅ 60+ CLI agents tested via `npx skills add` (AiderDesk, Claude Code, Cursor, Gemini, Grok, OpenCode, …).

## What I'd like

1. **Confirmation that the skills.sh crawler has or will pick this up.** If you've already crawled it, is there a way to force a re-index (e.g., a webhook on release, or a `@skills-bot` trigger phrase)?
2. **Confirmation that `meta.json` is a recognized schema**, or guidance toward whatever the canonical schema is so we can align (we'd rather conform than be a special case).
3. **Optional: link to it in the README of `vercel-labs/skills` if there's a "Community / Third-party skills" section.**
4. **Optional: a featured badge in skills.sh search results**, or whatever highlight exists for skills that have evidence of multi-agent coverage + AGPL/MIT license + ≥60 agent compatibility.

## Why this skill is worth indexing

It's the only general-purpose multi-agent engineering harness I know of that's:

- **Issue-first**, not prompt-first. (Issue is the contract; "Code" is the artifact.)
- **Evidence-gated**, not "vibes-gated". Every change requires `docs/evidence/<id>/` before merge.
- **Cold-start adversarial by default**. Reviewers don't see the implementer's chat; they only read diff + evidence.
- **Memory-evolving** across sessions.

For products that need a real engineering organization (not just "fix this bug"), this might be the trigger prompt that puts a serious CI in front of the AI.

## Links

- Repo: https://github.com/lora-sys/ai-engineering-harness
- Meta: https://github.com/lora-sys/ai-engineering-harness/blob/main/meta.json
- Latest release: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.5
- Architecture diagram: https://github.com/lora-sys/ai-engineering-harness/blob/main/assets/architecture.svg

## Reproduction (please run)

```bash
gh repo view lora-sys/ai-engineering-harness
npx -y skills find ai-engineering-harness --owner lora-sys
gh api repos/lora-sys/ai-engineering-harness/contents/meta.json | jq
```

Happy to adjust anything to align with the indexing contract. If there's a channel you'd prefer me to file this in (Discord / Discussion / Discord channel #skills), please point me there.

— lora-sys
