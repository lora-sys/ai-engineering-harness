# AI Creative UI Design Spec

The rulebook for generating Awwwards-grade creative web pages with AI. This is the spec the `frontend-creative` skill enforces. 17 sections, ordered from "why AI defaults to generic" to "the final prompt template".

## 一、Why AI Defaults to Generic Dashboards

Most AI-generated pages fall into:

* Dashboard card layouts
* Centered hero
* Standard SaaS pages
* Tailwind default component aesthetic

Why:

1. **Insufficient context constraint**
   * The AI doesn't know your aesthetic standard
   * No explicit visual target

2. **Prompts aren't specific enough**
   * "Make a beautiful website" → default templates
   * Need to describe composition, motion, space, atmosphere

3. **Lack of high-quality visual baselines**
   * No Awwwards, no art references, no Figma samples
   * The AI can't learn advanced design language

4. **Technical-architecture limits**
   * Plain component libraries restrict creativity
   * Missing animation, 3D, visual-system support

5. **Model capability limits**
   * Requires stronger creative models + multi-round refinement

## 二、High-Quality AI Creative Web Formula

```
Bold Creative UI =
High-Quality Visual References
+
Structured Design Prompt
+
Tech-Stack Constraints
+
Multi-Round Visual Review
+
Strong Generative Model
+
Open Architecture
```

Core goal:

> The AI doesn't just generate a page — it simulates an Awwwards-level web designer + frontend engineer.

## 三、AI Design Role Prompt

Cast the AI as:

> A top-tier creative web designer + frontend engineer

Capabilities:

* Awwwards-grade modern interactive web design
* Asymmetric layout
* Layered spatial composition
* Parallax scroll
* WebGL / 3D motion
* Bold typography
* Gradient-art palette
* Cursor interaction
* Scroll-driven narrative

## 四、Style Themes (pick one)

### 4.1 Cyberpunk Immersive Dark Homepage

- Black background
- Neon glow
- Future-tech aesthetic
- Particle / WebGL

### 4.2 Minimal Art Gallery Scroll Narrative

- Generous whitespace
- Giant typography
- Magazine layout
- High-end art feel

### 4.3 Retro Acid Design Portfolio

- Y2K
- High-saturation
- Brutalist
- Experimental layout

### 4.4 Future-Tech 3D Particle Homepage

- WebGL
- Shader
- 3D scene
- Immersive experience

## 五、Layout Rules

Forbidden:

❌ Generic SaaS Grid

```
Header
Hero
3 Cards
Features
Footer
```

Adopt:

✅ Non-traditional visual narrative

Includes:

- Asymmetric grid
- Off-center composition
- Multi-layer z-index
- Deep spatial composition
- Asymmetric containers
- Long-scroll storytelling
- Full-bleed visual regions

Goal:

> Design web pages like cinema, not arrange components.

## 六、Typography Rules

Core:

### Giant Titles as Visual Subject

Example:

```
BUILD
THE
FUTURE
```

Use:

- Oversized type
- Staggered alignment
- Variable fonts
- Type animation
- Text masking
- Dynamic gradient type

## 七、Motion Rules

### Motion Layering Principle

Don't:

❌ Animate the whole page wildly

Should:

```
Core region
↓
Heavy visual animation

Ordinary region
↓
Light animation
```

### Tech Choices

#### GSAP

For:

- Page core animations
- ScrollTrigger
- Complex timelines
- Parallax scroll

#### Framer Motion

For:

- React component animations
- Hover
- Page transitions
- Micro-interactions

#### React Three Fiber

For:

- 3D
- Particles
- Shaders
- WebGL backgrounds

Principle:

> GSAP for "big scenes", Framer Motion for "details".

## 八、Recommended Tech Stack

```
Next.js
+
React
+
TypeScript
+
Tailwind CSS
+
Framer Motion
+
GSAP
+
React Three Fiber
```

Optional:

```
Three.js
GLSL Shader
Web Audio API
Lenis Smooth Scroll
```

## 九、Performance Principles (Critical)

Creative ≠ Effect Soup

Must:

### 3D Optimization

- Lazy Loading
- Dynamic model loading
- Limit particle count
- Avoid main-thread blocking

### Animation Optimization

- GPU-accelerate
- transform-first
- Reduce layout reflows
- Control FPS

### Page Standard

Check:

- Lighthouse
- Mobile Performance
- Accessibility
- Safari compatibility

## 十、AI Multimodal Design Method (Strongest)

### Input:

Upload:

- 3-5 high-end web page screenshots
- Figma pages
- Art posters
- Awwwards cases

Then tell the AI:

> Learn the composition, spatial layers, color atmosphere, and interaction rhythm of these pages — don't copy them. Based on this visual language, create new original web pages.

## 十一、Load Design Spec File

Recommended:

```
creative-design-spec.md
```

As project-level rules.

Let the AI follow globally:

Includes:

- Motion rhythm
- Color system
- Typography rules
- Component rules
- Performance requirements
- Responsive rules

## 十二、AI Iteration Flow

### Round 1: Macro Design

Focus on:

- Page structure
- Atmosphere
- Composition
- Story line

Don't immediately tweak:

- padding
- icon
- small animations

### Round 2: Local Optimization

Example:

Don't:

> Rewrite the entire page

Should:

> Only modify the Hero region, add fluid gradient glow, keep other layouts unchanged.

### Round 3: Visual Regression

Each round:

Screenshot → Compare → Correct

Prevent:

AI drifting toward generic.

## 十三、Creative Review Prompt

Let the AI check:

```
Please act as an Awwwards judge.

Check:

1. Does it break traditional Dashboard layout?
2. Does it have visual narrative?
3. Does it have spatial layers?
4. Does it have an original visual language?
5. Does it meet futuristic/art web standards?
6. Is there a templating risk?
```

## 十四、Version Management

Each round:

```
v1 initial creative

↓

v2 layout optimization

↓

v3 motion enhancement

↓

v4 performance optimization

↓

final
```

Use Git to save.

Don't let the AI overwrite the whole project.

## 十五、Advanced Creative Directions

### 15.1 AI Programmatic Art Backgrounds

Tech:

- GLSL Shader
- React Three Fiber
- Noise Texture
- Fluid Simulation

Effects:

- Fluid background
- Particle universe
- Music-reactive visuals

### 15.2 Dynamic UI + Creative Pages

Architecture:

```
Fixed creative visual skeleton

+

A2UI JSON dynamic regions
```

Advantage:

- Page keeps high-end design
- AI can dynamically generate content

### 15.3 Sound-Interactive Web Pages

Tech:

```
Web Audio API

+

AI

+

Scroll Interaction
```

Example:

- Scroll changes music
- Cursor affects sound
- Page changes with rhythm

### 15.4 AI Auto-Generates Theme Variants

Let the AI output:

```
Theme A:
Cyberpunk Neon

Theme B:
Minimal Gallery

Theme C:
Retro Acid

Theme D:
Future 3D
```

Implementation:

One codebase, multiple visual themes.

## 十六、Prompt Keyword Library

### Layout

```
asymmetric layout
magazine layout
long-scroll narrative
full-bleed visual
layered depth
fragmented layout
break the grid
experimental typography
```

### Visual

```
Acid Design
Y2K
Brutalism
Neo Futurism
Cyberpunk
Glassmorphism
Noise Texture
Gradient Mesh
3D Element
Particle Background
```

### Interaction

```
Cursor Follow
Parallax Scroll
Magnetic Button
Text Reveal
Smooth Transition
Distortion Effect
Hover Morph
Immersive Scroll
Sound Interaction
```

## 十七、Final AI UI Generation Template

Core prompt:

```
You are an Awwwards-grade creative web designer and senior React engineer.

Do NOT generate a traditional Dashboard.

Design an experimental webpage with visual narrative capability.

Requirements:

- Asymmetric layout
- Multi-layer spatial structure
- Giant artistic typography
- Strong visual focal point
- Long-scroll experience
- GSAP for core animations
- Framer Motion for micro-interactions
- React Three Fiber for 3D visuals

Tech:
Next.js + React + TypeScript + Tailwind

References:
[upload screenshots]

Learn the visual language; don't copy.

Goal:
Create an original-art-style, performant, shippable modern interactive webpage.

Output:
1. Complete code
2. Design rationale
3. Motion explanation
4. Performance optimization plan
```

## 核心理念 One-Sentence

> **AI makes generic pages because you gave it functional requirements; AI makes high-end creative pages when you give it design language, visual baselines, tech boundaries, and sustained aesthetic feedback.**
