# Design Brief — ai-engineering-harness landing page

## What
Single-page Awwwards-grade intro site for the ai-engineering-harness project. This is the project's *front door* — the first thing a developer sees when they hear about it.

## Audience
Software engineers, engineering leads, AI-curious devs. They've seen "AI agent" pitches before and are skeptical. They want to see: (a) what makes this different, (b) proof it works, (c) how to install in 1 command.

## Primary action
- **Install**: `npx -y skills add lora-sys/ai-engineering-harness -g`
- Secondary: read the GitHub repo

## Theme
**A — Cyberpunk Immersive Dark** (matches the existing project poster aesthetic).

## Stack (pragmatic)
- Vite + React 18 + TypeScript
- Tailwind CSS
- GSAP + ScrollTrigger (one hero timeline, one scroll-pin section)
- Plain HTML/canvas for the particle background (no React Three Fiber — keep it light, < 200 KB JS)

## Layout
- **Section 1 (Hero)**: Full-bleed. Massive headline "AI ENGINEERING HARNESS" (clamp 5rem → 18rem). Tagline: "让每一行代码,都有证据" (Let every line of code have evidence). Animated particle grid. Single CTA: "Install →" with the npx command.
- **Section 2 (Stats bar)**: 4 stat cells — 18 agents · 9 workflows · 1 closed loop · ≥ 2 reviewers. Tight type, monospace.
- **Section 3 (Closed loop)**: Visual diagram of ISSUE → WORKTREE → PLAN → BUILD → REVIEW → EVIDENCE → MERGE → MEMORY. Each stage as a node, animated draw-in on scroll.
- **Section 4 (Install)**: The one command. Big. Copy-able. Plus "Or read the docs" link.
- **Section 5 (Footer)**: GitHub URL, license, version.

## Motion plan
- Hero: GSAP timeline. Particle grid fades in (0.5s) → headline chars stagger-reveal (0.8s) → CTA glides up (0.4s).
- Scroll: ScrollTrigger pins the closed-loop section, draws the arrows.
- Micro: button hover (magnetic + glow).

## Performance budget
- Lighthouse mobile ≥ 90
- LCP < 2.5s
- No autoplay video
- Total JS < 200 KB

## Reference brands
- Stripe Sessions
- Vercel Edge
- Resend homepage
