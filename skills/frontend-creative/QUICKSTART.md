# Quickstart — Frontend Creative UI Skill

> **Awwwards-grade creative web UIs for AI agents.** Use it when "make a website" means "make something that doesn't look like a Tailwind starter."

This document is a working tutorial. Read it top-to-bottom once, then refer back to the [decision table](#pick-the-right-workflow) and the [prompt templates](#prompt-templates) as needed.

---

## 1 · What this skill does

Generates creative, Awwwards-grade web pages (landing pages, brand sites, product pages, portfolios, experimental pages) using a fixed stack:

| Layer | Tool |
| --- | --- |
| Framework | Next.js (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Micro motion | Framer Motion |
| Scene motion | GSAP + ScrollTrigger |
| 3D / particles | React Three Fiber + drei (theme D only) |
| Smooth scroll | Lenis (optional) |

**Use this skill for**: creative landing pages, brand sites, "I want a page that doesn't look like every other SaaS site", experimental interactions, Awwwards-grade product pages.

**Don't use this skill for**: internal tools, admin panels, dashboards, data-heavy tables, "clean and minimal" SaaS apps. For those, use plain frontend conventions — the skill will fight you.

---

## 2 · Pick the right workflow

The skill has **9 workflows** organized by lifecycle stage. Start with the one that matches your situation:

| You want to… | Start with | Then go to |
| --- | --- | --- |
| Start a **brand-new project** | `workflows/00-bootstrap.md` | → `00-design-brief-collection` → `01-macro-design` → `02-local-refinement` → `03-visual-regression-check` → `04-ship` |
| **Resume an existing design** that's OK but not great | `workflows/05-takeover.md` | → `01-macro-design` (as a target) → `02-local-refinement` |
| **Refactor / redo** a design that Awwwards-baseline < 24/60 or is described as "garbage / 狗屎" | `workflows/07-redo.md` | → `00-bootstrap` (with a *different* theme) → 01–04 |
| Run a **post-mortem** on a design that's already shipped | `workflows/06-post-mortem.md` | (terminal) |
| Just need a one-off macro design / local refinement / ship gate | `01` / `02` / `03` / `04` directly | (skip the lifecycle wrapper) |

**Always**: pick a theme first (`references/theme-{a,b,c,d}-*.md`). Default by brief signal:
- "tech / SaaS / developer tool" → A (Cyberpunk)
- "luxury / lifestyle / brand" → B (Minimal Gallery)
- "creative agency / portfolio / bold" → C (Retro Acid)
- "Web3 / AI / experimental" → D (Future 3D)

If you've been iterating the same direction and the design is drifting generic, **switch theme**. Same theme = same mistakes.

---

## 3 · End-to-end example: new project

You want a creative landing page for a fictional product "Nimbus AI" (an AI image generator). You've never worked with this skill before. Here's the entire flow.

### Step 1 — Bootstrap (one-shot)

**You say to the LLM:**
```
$frontend-creative. Run workflows/00-bootstrap.md. Project name: nimbus-ai.
Default theme: A (Cyberpunk Immersive Dark) — Nimbus is an AI dev tool.
```

**The LLM does:**
- `npx create-next-app@latest nimbus-ai --typescript --tailwind --app`
- Installs framer-motion, gsap, @react-three/fiber, @react-three/drei, three
- Applies Theme A's Tailwind config (cyan-400 + neon glow + Space Grotesk display)
- Creates `docs/design/001-brief.md`, `iteration-log.md`, `docs/design/001-review.md`
- `git commit -m "chore(bootstrap): scaffold + creative stack + theme"`

**You verify:** `cd nimbus-ai && pnpm dev` opens the empty scaffold.

### Step 2 — Fill the brief

**You say to the LLM:**
```
$frontend-creative. Run workflows/00-design-brief-collection.md.
Ask me one question at a time. Save the answers to docs/design/001-brief.md.
```

**The LLM asks** (5 questions from `references/prompt-library.md` Phase 0):
1. What is this page for? → "Nimbus AI landing page"
2. Who's the audience? → "AI engineers + indie hackers"
3. One action? → "Sign up for the waitlist"
4. References? → 3 URLs (Stripe Sessions, Resend homepage, Vercel Edge)
5. Theme? → A (Cyberpunk)

**You answer.** LLM writes `docs/design/001-brief.md` and commits it.

### Step 3 — Round 1: Macro design (3 commits)

**You say to the LLM:**
```
$frontend-creative. Run workflows/01-macro-design.md using
docs/design/001-brief.md. Output 3 commits: skeleton → layout → motion.
```

**The LLM produces:**
- **Commit 1 — Skeleton.** App-router structure. Region placeholders (Hero, Features, Pricing, FAQ, CTA, Footer). No styling.
- **Commit 2 — Layout.** Tailwind tokens. Type scale (clamp 4rem → 14rem hero, clamp 2.5rem → 5rem section). Colors per Theme A. Spacing rhythm.
- **Commit 3 — Motion.** GSAP timeline for Hero. ScrollTrigger for Features. Framer Motion for nav + hover.

**You verify:** `pnpm dev` shows the page with all 3 layers working. Take a screenshot. Update `iteration-log.md` with the round-1 row + Awwwards self-score.

### Step 4 — Round 2+: Local refinement (one region at a time)

**You say to the LLM:**
```
$frontend-creative. Run workflows/02-local-refinement.md, Round 2.
Optimize ONLY the Hero. Add fluid gradient glow background, chromatic-aberration
on the headline. Keep other regions unchanged. Update iteration-log.md
with the Awwwards self-score. Then run the anti-drift check.
```

**The LLM does:**
- Changes ≤ 1 region
- Commits
- Screenshots
- Updates `iteration-log.md`
- Asks the 5 anti-drift YES/NO questions

**If "more generic" or any rejection criterion fires twice in a row**: **STOP**. Re-read `references/creative-ui-design-spec.md` §12. Consider restarting from `01-macro-design` with a different theme.

### Step 5 — Round N: Visual regression (mandatory pre-ship)

**You say to the LLM:**
```
$frontend-creative. Run workflows/03-visual-regression-check.md.
Fill templates/review-checklist.md. 6 categories, 1-10 each. Total ≥ 48 to ship.
```

**The LLM fills the checklist** with: composition / type / color / motion / originality / performance. Lists the top 3 issues. Says PASS / NEEDS-WORK / FAIL.

- **< 36**: Reject. Restart with a different theme.
- **36–47**: Back to Step 4, one more round.
- **≥ 48**: Proceed to Step 6.

### Step 6 — Ship

**You say to the LLM:**
```
$frontend-creative. Run workflows/04-ship.md. Lighthouse mobile ≥ 90,
LCP < 2.5s. No autoplay. No lorem ipsum. Commit the final.
```

**The LLM does:** runs `pnpm build`, runs Lighthouse, fixes perf issues if any, commits `final`.

**Two paths after ship**:
- **Path A — design exploration only**: stop. Write `case-study.md` describing what worked / what didn't.
- **Path B — ship as product**: hand off to `$ai-engineering-harness` for Phase 3 (Implement) → Phase 8 (Review). The harness runs its normal evidence-gated loop.

---

## 4 · End-to-end example: take over an existing project

You have `~/projects/old-saas-site/` that looks like every other SaaS landing page. You want to make it Awwwards-grade.

```
$frontend-creative. Run workflows/05-takeover.md. Target: ~/projects/old-saas-site/.
Take screenshots at mobile/tablet/desktop. Run review-checklist.md as the baseline.
Then run 01-macro-design.md as a target (Theme B — Minimal Gallery).
Use the existing design's content (don't change the copy, change the visual language).
```

The LLM:
1. Inventories the existing project (commits, deps, layout).
2. Saves `before-takeover/round-0-{mobile,tablet,desktop}.png`.
3. Runs the Awwwards checklist — baseline score.
4. Generates a target design in a side-by-side comparison.
5. Hands off to Round 2 (local refinement) to bring the existing design toward the target.

---

## 5 · End-to-end example: redo a "狗屎" project

`~/projects/garbage-site/` was bootstrap'd at v1.0. Awwwards baseline is 14/60. The user hates it.

```
$frontend-creative. Run workflows/07-redo.md. Target: ~/projects/garbage-site/.
Diagnose the failure, archive the old version (git tag before-redo-1),
restart from 00-bootstrap with Theme C (Retro Acid — different from the original).
```

The LLM:
1. Diagnoses: "What was the original brief? What got shipped? Why the gap?"
2. Archives: `git tag before-redo-1` + creates `archive/before-redo-1` branch.
3. Writes a new brief as a *response* to the diagnosis.
4. Picks a different theme (C, not whatever the old one was).
5. Restart from `00-bootstrap.md` with the new theme.
6. Continues through 01 → 04.

**Key rule**: if you find yourself wanting to "fix" with one more round of iteration rather than restarting, you have a redo situation. **Redo, don't iterate**.

---

## 6 · Prompt templates (copy-paste)

For each phase, here's a single prompt you can give the LLM. Adapt the bracketed parts.

### Bootstrap
```
$frontend-creative. Run workflows/00-bootstrap.md.
- Project name: [name]
- Theme: [A | B | C | D | "pick based on the brief"]
- Stack: default (Next.js + TS + Tailwind + Framer Motion + GSAP + R3F)
```

### Design brief
```
$frontend-creative. Run workflows/00-design-brief-collection.md.
Ask me ONE question at a time. Save the answers to docs/design/001-brief.md.
```

### Macro design
```
$frontend-creative. Run workflows/01-macro-design.md using docs/design/001-brief.md.
Output 3 commits: skeleton → layout → motion. Don't add features the brief didn't ask for.
```

### Local refinement
```
$frontend-creative. Run workflows/02-local-refinement.md, Round [N].
Optimize ONLY [region name]. [Specific change]. Keep other regions unchanged.
Commit. Screenshot. Update iteration-log.md. Run the anti-drift check.
```

### Visual regression
```
$frontend-creative. Run workflows/03-visual-regression-check.md.
Fill templates/review-checklist.md. 6 categories × 1-10. Total < 36 = fail; ≥ 48 = ship-able.
```

### Ship
```
$frontend-creative. Run workflows/04-ship.md. Lighthouse mobile ≥ 90, LCP < 2.5s.
No autoplay video/audio. No lorem ipsum. Commit "final".
```

### Take over
```
$frontend-creative. Run workflows/05-takeover.md. Target: [path].
Screenshots at mobile/tablet/desktop. Review-checklist as baseline.
Then 01-macro-design as the target.
```

### Redo
```
$frontend-creative. Run workflows/07-redo.md. Target: [path].
Diagnose, archive (git tag before-redo-N), restart with a DIFFERENT theme.
```

### Post-mortem
```
$frontend-creative. Run workflows/06-post-mortem.md.
Gather analytics + user feedback, write docs/case-studies/<project>.md.
```

---

## 7 · Cheat sheet (do / don't)

### Always do
- ✅ **Three-round iteration** (macro → local → regression). Not 100 micro-edits.
- ✅ **One region per round** in Step 4. Never two.
- ✅ **Screenshot + iteration-log entry per round**. So you can diff between rounds.
- ✅ **Awwwards review-checklist** at Step 5. Total < 36 = don't ship.
- ✅ **Switch theme** if "more generic" fires twice. Same theme = same mistakes.
- ✅ **Git commit per round**. Don't let the LLM overwrite everything.
- ✅ **Use the 17-section spec** (`references/creative-ui-design-spec.md`). It's the rulebook.

### Never do
- ❌ Generic SaaS hero (centered headline + 3 feature cards).
- ❌ Lorem ipsum / fake testimonials / placeholder copy.
- ❌ Autoplay video or audio.
- ❌ Animations on every element (layer them: heavy on focal, light elsewhere).
- ❌ One round that changes 2+ regions.
- ❌ Letting the LLM rewrite the whole page each round.
- ❌ Trusting the LLM's "looks great to me" — only the Awwwards checklist counts.
- ❌ Using this skill for dashboards / admin / internal tools.

---

## 8 · Where to read more

- `references/creative-ui-design-spec.md` — the **17-section rulebook**. Read this before doing anything else.
- `references/theme-{a,b,c,d}-*.md` — 4 fully-fleshed theme variants (Tailwind config + motion presets + reference brands + anti-patterns).
- `references/prompt-library.md` — the prompts the LLM uses per phase.
- `templates/design-brief.md` — fill in per project.
- `templates/iteration-log.md` — track each round's screenshots + diffs.
- `templates/review-checklist.md` — Awwwards-style self-review before ship (mandatory pre-ship gate).
- `agents/creative-frontend.md` — the agent persona that drives this skill.

### Workflows
- `workflows/00-bootstrap.md` — new project from scratch
- `workflows/00-design-brief-collection.md` — fill the brief
- `workflows/01-macro-design.md` — Round 1 macro
- `workflows/02-local-refinement.md` — Round 2+ local iteration (anti-drift check mandatory)
- `workflows/03-visual-regression-check.md` — review (Awwwards checklist mandatory)
- `workflows/04-ship.md` — ship (review-checklist as pre-ship gate)
- `workflows/05-takeover.md` — resume an existing design
- `workflows/06-post-mortem.md` — 复盘 after ship
- `workflows/07-redo.md` — 狗屎 → restart

### One-sentence summary

> **Run the workflow that matches your situation, pick a theme, iterate in 3 rounds with the Awwwards checklist as the gate, and don't trust the LLM when it says "looks great to me."**
