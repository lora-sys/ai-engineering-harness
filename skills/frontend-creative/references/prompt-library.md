# Prompt Library

Reusable prompts for the `frontend-creative` workflows. These are templates — copy and adapt per project.

## Phase 0 — Design brief

```
You are about to design a creative webpage.

Ask me ONE question at a time to fill in:
1. What's the product / brand / portfolio?
2. Who's the audience?
3. What's the ONE action you want the visitor to take?
4. What references do you have? (URLs, screenshots, Figma)
5. Any constraints? (browser support, hosting, deadline)
```

After 5 answers, write `templates/design-brief.md` for me.

## Phase 1 — Macro design

```
You are an Awwwards-grade designer.

Theme: <pick from theme-variants.md>
Brief: <paste the filled design-brief.md>

Generate the MACRO layout only. Do NOT add micro-details yet:
- Page regions (full-bleed hero, scroll-narrative sections, footer)
- Type scale (giant title, body, caption)
- Color palette
- Spacing rhythm

Output:
1. ASCII wireframe (regions only, not components)
2. Type scale + spacing tokens
3. Color palette in Tailwind
4. Motion plan (which regions animate how)

3 commits: skeleton → layout → motion
```

## Phase 2 — Local refinement

```
Pick ONE region from the macro layout. Optimize it.

For example: "Hero only. Add fluid gradient glow background. Keep other regions unchanged."

Output: just the changed files + a 1-sentence rationale for the change.
```

## Phase 3 — Visual regression

```
Compare the current state to the brief.

Screenshot:
[paste current screenshot]

Brief:
[paste design-brief.md]

For each AC row, say PASS / FAIL / PARTIAL.
List the top 3 issues, ordered by impact on the Awwwards criteria.
Do NOT modify the code yet — just review.
```

## Phase 4 — Ship

```
Run Lighthouse mobile on /. Report scores.

Then verify:
- [ ] All animations GPU-accelerated (no layout thrash)
- [ ] No autoplay video/audio
- [ ] No lorem ipsum / fake testimonials
- [ ] Accessible (Lighthouse a11y ≥ 90)
- [ ] LCP < 2.5s on mid-range mobile

Fix anything that fails, then ship.
```

## Multimodal learning prompt (use in Phase 1 if user provides references)

```
I'm attaching 3-5 high-end web page screenshots.

For each:
- Note the composition (asymmetric grid, full-bleed, etc.)
- Note the spatial layering (z-index, depth, parallax)
- Note the color atmosphere (palette, gradients, contrast)
- Note the interaction rhythm (scroll triggers, hover effects)

Then:
- DO NOT reproduce any of them
- Combine the visual languages into a new original composition
- Pick a theme from references/theme-variants.md that fits the brief
```

## Awwwards review prompt (run before ship)

```
Act as an Awwwards judge.

Score this page 1-10 on:
1. Breaking the Dashboard layout
2. Visual narrative
3. Spatial layering
4. Original visual language
5. Future-tech / art-web standards
6. Templating risk (lower is better)

For each: 1-line justification + 1 concrete fix.
Reject if total < 36/60.
```
