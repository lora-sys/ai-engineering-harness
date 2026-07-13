# Theme A — Cyberpunk Immersive Dark

Aesthetic: black background, neon glow, future-tech, particle/WebGL. Best for: developer tools, AI products, Web3.

## Tailwind config (extend theme)

```js
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        bg:        '#000000',
        surface:   '#0a0a0a',
        line:      '#1a1a1a',
        primary:   '#22d3ee',     // cyan-400
        accent:    '#d946ef',     // fuchsia-500
        highlight: '#fde047',     // yellow-300
        ink:       '#fafafa',
        muted:     '#71717a',     // zinc-500
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
        display: ['"Space Grotesk"', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        hero: ['clamp(4rem, 14vw, 14rem)', { lineHeight: '0.9', letterSpacing: '-0.04em' }],
        section: ['clamp(2.5rem, 6vw, 5rem)', { lineHeight: '1' }],
        body: ['1.0625rem', { lineHeight: '1.6' }],
      },
      boxShadow: {
        neon: '0 0 30px rgba(34, 211, 238, 0.6), 0 0 60px rgba(217, 70, 239, 0.3)',
      },
      animation: {
        'glow-pulse': 'glow-pulse 2.5s ease-in-out infinite',
        'marquee': 'marquee 30s linear infinite',
        'noise': 'noise 0.5s steps(4) infinite',
      },
    },
  },
}
```

## Motion presets (GSAP + Framer Motion)

```tsx
// Hero headline — glitch + reveal
useGSAP(() => {
  gsap.from('.hero-char', {
    y: 100, opacity: 0, filter: 'blur(10px)',
    duration: 1.2, stagger: 0.05, ease: 'power4.out',
  })
  gsap.to('.hero-glitch', {
    textShadow: '0 0 10px #22d3ee, 0 0 20px #d946ef',
    duration: 0.1, repeat: 5, yoyo: true,
  })
}, [])

// Magnetic CTA — Framer Motion
<motion.button
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.98 }}
  onMouseMove={(e) => {
    const r = e.currentTarget.getBoundingClientRect()
    const x = (e.clientX - r.left - r.width / 2) * 0.3
    const y = (e.clientY - r.top - r.height / 2) * 0.3
    e.currentTarget.style.transform = `translate(${x}px, ${y}px)`
  }}
  className="shadow-neon border border-primary/40 px-8 py-4"
>
  Get Early Access
</motion.button>
```

## Reference brands

- Stripe Sessions — `https://stripe.com/sessions`
- Linear Changelog — `https://linear.app/changelog`
- Vercel Edge — the network-status hero
- Resend homepage — `https://resend.com`

## Anti-patterns

- ❌ Rainbow gradients with no semantic intent
- ❌ Generic "Web3" tropes (apes, lasers) unless brand-specific
- ❌ Glitch effect on every text — only on the focal hero
