# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-11

### Added
- Initial release
- 18 agent personas (Coordinator, Explore, Plan, Frontend, Backend, Database, QA, Bug Hunter, Behavior Reviewer, Architecture Reviewer, Security Reviewer, UI Reviewer, Conflict Resolver, Release, Review Aggregator, Context Assembly, Memory Curator, Scope reference)
- 9 closed-loop workflows (project bootstrap, feature delivery, issue lifecycle, adversarial PR review, CI recovery, conflict resolution, phase summary, release prep, memory evolution)
- 16 templates (Issue types for bug/feature/refactor/spike, Implementation Plan, PR description, Review Report, Evidence Pack index, Phase Summary, Context Manifest, ADR, Project Status, CLAUDE/AGENTS, memory file, session files)
- 6 acceptance checklists (Evidence Gate, PR Merge, Frontend, Backend, Database, Security)
- 6 reference docs (context levels L0-L3, document indexing, worktree discipline, agent spawning, evidence formats, shell tooling)
- 6 filled examples (Issue, Implementation Plan, PR, Review Report, Evidence Pack, Phase Summary)
- 5 helper scripts (new-session, new-evidence, new-worktree, refresh-index, changelog)
- `install.sh` installer targeting 38 CLI coding agents (Claude Code, Codex, Cursor, Gemini, Qwen, Grok, OpenCode, Hermes, Aider Desk, Continue, Roo, etc.)
- Bilingual README (English + Chinese)
- MIT license

### Install

```bash
npx -y skills add lora-sys/ai-engineering-harness -g --all
```

[0.1.0]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.0
