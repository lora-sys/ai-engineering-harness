# Context bundle

_Generated 2026-07-13T10:05:54+08:00 by scripts/context-bundle.sh_
_Repo: git@github.com:lora-sys/ai-engineering-harness.git_
_HEAD: 765ecd0_

## Repo identity

- **origin**: `git@github.com:lora-sys/ai-engineering-harness.git`
- **branch**: `main`
- **HEAD**: `765ecd0`
- **tag**: `v1.2.0`
- **working tree**: clean

## Recent commits (last 20)

765ecd0 feat(scripts): context-bundle.sh + compact-report.sh (v1.2.0)
5a65b7a feat(hooks): SessionStart hook auto-reads .claude/SESSION.md (v1.1.0)
680f669 chore(release): v1.0.10 — post-release docs roll-up
3f64fe4 docs(memory): D-013 — meta.json must match the tag being cut
85fdb66 docs(changelog): retrospective notes for v1.0.8 and v1.0.9
61430ae fix(release): meta.json = 1.0.9 for v1.0.9 release
40b704d fix(release): meta.json bump to 1.0.7 for v1.0.8
dcf55c4 fix(release): meta.json back-fill to v1.0.6 (v1.0.7)
7741369 fix(release): meta.json version back-fill to v1.0.5 (v1.0.6)
9f38aa0 fix(validator): use checked-out tag for drift check (v1.0.5)
df7f7fb fix(tooling): bump meta.json to v1.0.3 + script cd-location hardening (v1.0.4)
8dbf599 feat(tooling): add three pre-commit guards (v1.0.3)
ed92c8a feat(ci): promote CI/CD to a blocking gate (v1.0.2)
95e2ff4 docs(build-agent-app): add examples/real-cases handbook
ce9e69b feat(skill-family): v1.0.0 — add build-agent-app sibling + multi-skill install
9907061 docs: add CONTRIBUTING.md + fix 3 README assumptions
653e461 docs: correct codex install assumption (tested actually works)
c327f2d fix(install): ship fat-install mode + troubleshooting docs
6de1074 feat(tools): validate-meta.sh + changelog-auto.sh + vercel outreach
4090154 docs: populate CHANGELOG for v0.1.1 through v0.1.4

## Working-tree changes

(clean)

## Top-level layout

  drwxr-xr-x 1 lora lora   364 Jul 13 09:19 .
  drwx------ 1 lora lora  5894 Jul 13 10:04 ..
  drwxr-xr-x 1 lora lora   150 Jul 13 09:46 .git
  -rw-r--r-- 1 lora lora   416 Jul 11 10:23 .gitignore
  drwxr-xr-x 1 lora lora   166 Jul 11 11:57 .outreach
  -rw-r--r-- 1 lora lora 29304 Jul 13 09:44 CHANGELOG.md
  -rw-r--r-- 1 lora lora  7157 Jul 12 17:35 CONTRIBUTING.md
  -rw-r--r-- 1 lora lora  1065 Jul 11 10:23 LICENSE
  -rw-r--r-- 1 lora lora 37871 Jul 12 17:10 README.md
  -rw-r--r-- 1 lora lora 16240 Jul 13 09:42 SKILL.md
  -rw-r--r-- 1 lora lora     6 Jul 11 10:55 VERSION
  drwxr-xr-x 1 lora lora   528 Jul 11 09:58 agents
  drwxr-xr-x 1 lora lora    68 Jul 11 11:23 assets
  drwxr-xr-x 1 lora lora   220 Jul 11 09:56 checklists
  drwxr-xr-x 1 lora lora   226 Jul 11 09:57 examples
  drwxr-xr-x 1 lora lora    64 Jul 13 09:19 hooks
  -rwxr-xr-x 1 lora lora 11312 Jul 12 16:08 install.sh
  drwxr-xr-x 1 lora lora    76 Jul 12 17:09 memory
  -rw-r--r-- 1 lora lora  1264 Jul 13 09:44 meta.json
  drwxr-xr-x 1 lora lora   364 Jul 13 09:40 references
  drwxr-xr-x 1 lora lora   360 Jul 13 09:38 scripts
  drwxr-xr-x 1 lora lora    30 Jul 12 16:01 skills
  drwxr-xr-x 1 lora lora   484 Jul 12 17:33 templates
  drwxr-xr-x 1 lora lora   388 Jul 11 09:55 workflows

### Harness subdirs

  - `workflows/` — 9 entries
  - `agents/` — 19 entries
  - `scripts/` — 11 entries
  - `references/` — 10 entries
  - `templates/` — 16 entries
  - `checklists/` — 6 entries
  - `memory/` — 2 entries

## Open issues & PRs

### Open PRs

(none)

### Open issues

[error: gh issue list failed]

## Key harness files

  - `CONTRIBUTING.md` (137 lines, 7157 bytes)
  - `CHANGELOG.md` (426 lines, 29304 bytes)
  - `SKILL.md` (246 lines, 16240 bytes)

## Memory notes (most recent 3 files)


### memory/notes-2026-07-12.md

```
# 2026-07-12 · CI/CD is a blocking gate (not a checkpoint)

> One decision (D-011) from the v1.0.2 hardening pass on `ai-engineering-harness` on 2026-07-12.
> Format follows the convention from `notes-2026-07-11.md`: Status · Context · Decision · Why · Consequence · When to revisit.

## D-011 · CI/CD is a blocking gate, not a step

- **Status**: durable
- **Context**: During an audit of the harness, I traced how a Phase-7 "CI" was described across `SKILL.md`, `workflows/01-feature-delivery.md`, `agents/coordinator.md`, `agents/qa.md`, `templates/pr-description.md`, and `checklists/evidence-gate.md`. The pattern was: *"CI runs → reviewers → merge"*. Two failure modes were obvious:
  1. Nothing told the Owner Agent to keep watching CI **after** the first run. A push happened, CI started, and the loop drifted to Phase 8 because no one was assigned to polling.
  2. Nothing told the Coordinator to BLOCK while red. A red CI was treated as a status, not a stop sign. Reviews could queue up, "Approved" labels could land, even merges could be requested, all while CI was failing — because no rule in the harness said "wait until green".
  This is the exact inversion of how a red CI should behave: it is the **only** failure in the harness that is mechanical, observable, and unambiguous. Adversarial review is subjective; CI is binary. So CI must be the strongest gate.
- **Decision**: In v1.0.2 the harness promotes CI from "a step" to "a blocking gate":
  - `SKILL.md` §1 adds Principle #8 — *"CI/CD is a blocking gate, not a checkpoint."*
  - `workflows/01-feature-delivery.md` Phase 7 is renamed `(BLOCKING GATE — do not advance while red)` and spells out: Owner watches CI from first commit; Coordinator blocks review/merge/Done/Close until green; the rescue loop is `workflows/04-ci-recovery.md`; same-class second failure files a `ci`-tagged Issue + a `memory/lessons.md` line.
  - `agents/coordinator.md` adds an explicit rule: *"Red CI = blocked phase. Do NOT advance to adversarial review, do NOT close the Issue, do NOT merge while CI is red."*
  - `agents/qa.md` gets a CI/CD-watching role: poll every ~60–120 s, restart on every push, capture the failing log + class on first red, file a `ci` Issue + lessons entry on second red of the same class, never let Phase 8 start while red.
  - `references/cd-monitoring.md` is a new pattern doc describing the polling cadence, classification of failure classes, the "at most one re-run before real-defect triage" rule for flakes, and the hand-back to Owner.
  - `templates/pr-description.md` adds a `CI` section right before `## Risk` so the PR body has to enumerate the actual checks and the actual run-ids, not just tick a box.
  - `checklists/evidence-gate.md` adds: *"CI is GREEN on the latest commit at the head of the PR branch"* + *"No 'partial CI as green'. All configured checks must pass — lint, tests, build, security scan."* + a required `docs/evidence/<id>/ci-log.txt`.
  - `CONTRIBUTING.md` adds §1.5 — *"Treat CI status as part of 'the actual path'"*, extending D-008 (test the actual path) to remote-system claims. A claim of "CI green" without a run-id is not a claim.
  - `meta.json` version bumps to `1.0.2` (patch bump per D-006: routing/trigger surface changed).
- **Why**:
  - A red CI is the **only** mechanical signal in the closed loop. Subjective reviewer disagreement can be debated; a red CI cannot.
  - The Owner Agent was implicitly trusted to watch CI. That's a workload distribution error — the agent that pushes isn't always the agent that's available 5 minutes later when CI fails. CI watching must be **owned**, not assumed.
  - The harness has anti-patterns for "merge without review", "merge without tests", "merge without evidence". It needed an anti-pattern for **"advance while CI is red"**. SKILL.md §13 now carries that anti-pattern twice (with slightly different framings, so it survives rewording).
  - Without this rule, the harness is operationally fragile in the way that hurts users most: PRs get "approved" but never merge, and the work appears to be moving while nothing ships.
- **Consequence**:
  - The harness now has one strong mechanical gate (CI) and one strong social gate (≥2 adversarial reviewers). Anything that bypasses either is an anti-pattern.
  - Every Phase 7 has a polling owner (`qa`) and a rescue loop (`workflows/04-ci-recovery.md`). If a feature is "stuck in Phase 7", that's expected behavior when CI is red; it's only a bug if CI is **green** and the Coordinator still hasn't advanced.
  - Future agents reading `SKILL.md` will see CI mentioned three times in the Operating Principles region alone (loop diagram, Principle #8, anti-pattern), making it hard to deprioritize.
- **Revisit when**:
  - A future CI provider changes the polling surface (e.g. webhook-only, no REST) and `references/cd-monitoring.md` needs a rewrite.
  - The harness grows a "release-candidate" branch flow where CI on `main` matters more than CI on the PR branch — D-011 will need to specify which branch's CI is the gate.
  - An agent starts marking Issues Done while CI is red despite the rule — that's a sign the rule needs to be moved into a tool-level guard (e.g. a status-check that the merge button refuses to enable), not just prose.

## D-012 · Tooling hardening: catch regressions before they ship

- **Status**: durable
- **Context**: During the v1.0.2 release I hit two distinct process bugs that the harness's tooling did NOT catch:
  1. The previous maintainer pass claimed to add `## CI` to `templates/pr-description.md`. `git diff` later showed the edit never landed. Result: a "done" PR was missing a section that the harness now required. Anyone reading the PR saw the description, ticked the box, and moved on.
  2. I myself ran `scripts/changelog.sh` (a low-level generator) by mistake while a hand-edited v1.0.2 entry was on disk. The script silently overwrote the entire `CHANGELOG.md` with `[Unreleased]`. Required a `git checkout` to recover.
  These are exactly the kind of "looks done but isn't" failures the harness is supposed to prevent.
- **Decision**: Add three small, opinionated tooling guards and document them as pre-commit gates:
  - **`scripts/check-templates.sh`** (NEW) — asserts required headings exist at start-of-line in `templates/*.md`. Uses awk so regex meta-chars in headings like `## Shipped (PRs)` don't break it. Catches phantom edits like the v1.0.2 `## CI` regression. Runs in <50 ms.
  - **`scripts/changelog.sh`** — adds an overwrite guard. If `CHANGELOG.md` already has a versioned `## [X.Y.Z]` entry, the script REFUSES to run (exit 2). Only `--force` bypasses, and only intentionally. Same accident cannot happen twice.
  - **`scripts/validate-meta.sh`** — three new checks:
    1. `version` field is now REQUIRED in `meta.json`. Format-validated against semver `X.Y.Z[-prerelease]`.
    2. Drift check: meta.json's `version` is compared to the latest `v*.*.*` git tag. Mismatch → warning.
    3. **D-006 enforcement**: if `description` changed between two adjacent versioned tags AND only patch bumped, warn that the description is part of the routing surface and should bump minor per D-006.
- **Why**:
  - The harness's whole pitch is "evidence-gated, adversarial-reviewed, evidence-first". Its own release process had no equivalent guards. That's a credibility gap.
  - These three checks together close the three highest-frequency regressions: (a) claimed-but-undone template edits, (b) accidental clobber of hand-edited changelogs, (c) drift between declared version and reality.
  - Each check is small (<100 lines), fast (<1 s), and runs in any environment with `bash` + `python3` + `git`. No new dependencies.
- **Consequence**:
  - `CONTRIBUTING.md` PR-process step 4 now references both `validate-meta.sh --strict` AND `check-templates.sh --strict`. Both must be clean before commit.
  - A future maintainer who adds a new required template heading only needs to append one line to `TEMPLATE_ASSERTIONS` in `check-templates.sh`.
  - A future maintainer who intentionally regenerates the changelog from scratch has to pass `--force` — that word in the shell history is the audit trail.
- **Revisit when**:
  - A future maintainer adds new required meta.json fields beyond `version` — extend the REQUIRED list and write the corresponding check.
```

### memory/notes-2026-07-11.md

```
# 2026-07-11 · Build notes

> Four key decisions from building and publishing `ai-engineering-harness` on 2026-07-11.
> Each entry follows: Status · Context · Decision · Why · Consequence · When to revisit.

## D-001 · Single-skill repo (not multi-skill)
- **Status**: durable
- **Context**: AI Skills CLI by Vercel Labs accepts both layouts — `repo/SKILL.md` (single-skill) or `repo/skills/<name>/SKILL.md` (multi-skill). I had 15 SKILL.md files in `git-copilot/skills/` locally that could have been merged.
- **Decision**: Keep this repo single-skill; do **not** merge `git-copilot/skills/*` into this repo. Stash siblings behind a feature gate (`docs/decisions/`) instead.
- **Why**:
  - A repo name like `ai-engineering-harness` reads as one tool, not a bundle. Multi-skill signal would dilute the brand.
  - Each skill in `git-copilot` has its own audience and update cadence; bundling would force version lockstep.
  - `npx skills add <owner>/<repo>` works either way — discoverability isn't lost.
- **Consequence**: `--all` on this repo currently installs only the harness. Fine for now (one skill). Revisit if a tightly-coupled sister skill emerges.
- **Revisit when**: Someone asks "can I install web-design-audit from the same place" — that's the signal to bundle.

## D-002 · `npx skills` unified `~/.agents/skills/` model
- **Status**: durable
- **Context**: Vercel's `skills` CLI puts all CLI agent skills behind one canonical `~/.agents/skills/` then symlinks 55+ agent dirs to it. Some agents get a real copy (cursor, gemini, grok); the rest are symlinks.
- **Decision**: Prefer the `--all` install with `npx skills add` over my custom `install.sh --all`. The custom installer remains as a fallback for cases where `npx skills` is not available.
- **Why**:
  - One canonical update path — `npx skills update lora-sys/ai-engineering-harness -g` re-deploys to 72 agents at once via symlinks.
  - The CLI knows each agent's quirks (some need real copies, some only symlinks) so it makes better per-agent decisions than my flat `cp -r`.
  - Less drift long-term.
- **Consequence**: My `install.sh --all` becomes the **fat-installer** (full content everywhere), while `npx skills add` is the **thin-installer** (only SKILL.md at canonical). For projects that need bundled resources (workflows/, scripts/), the fat installer is required.
- **Revisit when**: A new agent ships that doesn't publish a per-agent path — `npx skills` will catch up first.

## D-003 · `npx skills add --all` is safe (with one caveat)
- **Status**: durable
- **Context**: User asked whether `--all` would install everything blindly. It's a valid concern — a "drop everything on the user" install is a footgun.
- **Decision**: `--all` is safe **for this repo**, because the repo currently has **one skill**. As the repo grows, this decision must be revisited at each new skill add.
- **Why**:
  - Today, `--all` ≡ install `ai-engineering-harness` to all agents.
  - The risk surface is bounded: each skill is a folder under the repo root; nothing under that folder runs code at install time (only `SKILL.md` is read by the agent).
  - Anyone wanting a stricter install can use `npx skills add ... -s <name> -a <agents>`.
- **Caveat spelled out in README**:
  - "If you add a sister skill later, `--all` will install it too. Use `-s <name>` to limit."
- **Revisit when**: A new skill folder is added to this repo — bump D-003 status to `tentative`, document the new state.

## D-004 · Architecture diagram as SVG (not bitmap)
- **Status**: durable
- **Context**: README needed a hero diagram showing the closed loop, 18 personas, evidence gate, memory ring. Imagegen skill defaulted to built-in bitmap generation (not available in this Codex flavor) and would need `OPENAI_API_KEY` for fallback.
- **Decision**: Hand-write the diagram in SVG (1440×820), render to PNG only when an OG card needs it.
- **Why**:
  - SVG is text-searchable, scales without blur, stays under 15 KB, and is diffable in PR reviews.
  - PNG is required only at social-card gateways (Twitter 1200×630, Slack unfurl, GitHub social preview). We can render-on-demand with `rsvg-convert` / `magick`.
  - Imagegen's own docs say: "diagrams / wireframes / icons ... better produced directly in SVG, HTML/CSS, or canvas". The skill itself recommends this path.
- **Consequence**:
  - `assets/architecture.svg` is the source of truth; `social-preview.png` is a derived asset.
  - If the diagram ever needs a visual treatment (gradients, photo embed), fall back to imagegen with explicit CLI request.
- **Revisit when**: A new loop stage appears (e.g. Release-Gate, Compliance-Review) — re-render.

## D-005 · Discovery is `npx skills find` not "submit form"
- **Status**: tentative
- **Context**: Skills.sh index is auto-crawled from GitHub. There's no manual submit form to call.
- **Decision**: Optimize the repo for the crawl (topics, description, license, SKILL.md frontmatter, install command in README) instead of trying to "submit".
- **Why**: The crawl reads everything already; the highest-leverage work is making those fields clean.
- **Consequence**: README ends with a `## Discoverability` section explaining the auto-crawl and giving users the `npx skills find` command to self-verify.
- **Revisit when**: Vercel ships a manual submit endpoint.

```

## Harness roster

### Workflows

  - `00-project-bootstrap.md` — Workflow — Project Bootstrap
  - `01-feature-delivery.md` — Workflow — Feature Delivery
  - `02-issue-lifecycle.md` — Workflow — Issue Lifecycle
  - `03-adversarial-pr-review.md` — Workflow — Adversarial PR Review
  - `04-ci-recovery.md` — Workflow — CI Recovery
  - `05-conflict-resolution.md` — Workflow — Conflict Resolution
  - `06-phase-summary.md` — Workflow — Phase Summary
  - `07-release-prep.md` — Workflow — Release Prep
  - `08-memory-evolution.md` — Workflow — Memory Evolution

### Agents

  - `architecture-reviewer`
  - `backend`
  - `behavior-reviewer`
  - `bug-hunter`
  - `conflict-resolver`
  - `context-assembly` — Builds the minimal trusted context for an Agent task. This is the **L0–L3 manifest builder**.
  - `coordinator`
  - `database`
  - `explore`
  - `frontend`
  - `memory-curator`
  - `plan`
  - `qa` — Executes the test + verification plan, captures Evidence.
  - `release`
  - `review-aggregator`
  - `scope`
  - `security-reviewer`
  - `ui-reviewer`

### Templates

  - `adr.md`
  - `claude-agents.md`
  - `context-manifest.md`
  - `evidence-pack.md`
  - `implementation-plan.md`
  - `issue-bug.md`
  - `issue-feature.md`
  - `issue-refactor.md`
  - `issue-spike.md`
  - `issue.md`
  - `memory-file.md`
  - `phase-summary.md`
  - `pr-description.md`
  - `project-status.md`
  - `review-report.md`
  - `session-files.md`

