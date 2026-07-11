# Question: best way for a single-skill repo to land in skills.sh?

**tl;dr**: I shipped a single-skill repo (`lora-sys/ai-engineering-harness`) that follows the `npx skills add` convention, with `SKILL.md` + `meta.json` + topics + license. Is that enough to land in skills.sh, or should I file an Issue/discussion somewhere first?

## What I've verified

- `npx skills add lora-sys/ai-engineering-harness -g --all` works on a clean machine — installs to 60+ CLI agents.
- Skills auto-discovery picks up `SKILL.md` frontmatter.
- I added a `meta.json` with `{id, name, description, category, priority, tags, install, agents_supported, license, repository, entry}` matching the convention used in similar community skill repos.

## Three questions

1. **Crawler schedule** — Is skills.sh auto-crawl scheduled (e.g., on release-tag push via webhook), or is it a periodic cron? If periodic, what's the cadence?
2. **Schema conformance** — Is `meta.json` a recognized schema, or is `SKILL.md` frontmatter the only contract? I don't want to maintain a non-conforming sidecar file.
3. **Submission signal** — Is there a canonical signal (issue, PR, discussion, Discord channel) to nudge the indexer, or will the auto-crawl find it eventually?

## Why I'm asking

I want this skill to be in front of:
- Anyone running `npx skills find orchestration`
- Anyone searching "AI agent orchestration" or "evidence-gated" on the web

Happy to file a more specific Issue if there's a tracker for that.

## What's here

- Repo: https://github.com/lora-sys/ai-engineering-harness
- All 5 versions released (`v0.1.0` → `v0.1.5`)
- `SKILL.md` at root (243 lines, full YAML frontmatter)
- `meta.json` at root (1.1 KB, schema-compatible with community skills)
- README in English + Chinese, with explicit `--all` safety contract
