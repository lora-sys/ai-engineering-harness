# Theme B — Minimal Art Gallery

Aesthetic: generous whitespace, giant typography, magazine layout, high-end art feel. Best for: luxury goods, lifestyle brands, agency portfolios.

## Tailwind config

```js
export default {
  theme: {
    extend: {
      colors: {
        bg:        '#fafaf9',     // stone-50
        surface:   '#f5f5f4',     // stone-100
        line:      '#e7e5e4',     // stone-200
        primary:   '#1c1917',     // stone-900
        accent:    '#d97706',     // amber-600 (sparingly)
        ink:       '#0c0a09',     // stone-950
        muted:     '#78716c',     // stone-500
      },
      fontFamily: {
        serif: ['"Cormorant Garamond"', '"Times New Roman"', 'serif'],
        sans: ['"Inter"', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        hero: ['clamp(5rem, 16vw, 18rem)', { lineHeight: '0.85', letterSpacing: '-0.05em' }],
        section: ['clamp(2rem, 5vw, 4rem)', { lineHeight: '1.05' }],
        caption: ['0.75rem', { lineHeight: '1.4', letterSpacing: '0.15em' }],
      },
    },
  },
}
```

## Motion presets

```tsx
// Hero: text reveal line by line
useGSAP(() => {
  gsap.from('.hero-line', {
    y: 60, opacity: 0,
    duration: 1, stagger: 0.12, ease: 'power3.out',
  })
}, [])

// Cursor parallax (subtle, 10px max)
useEffect(() => {
  const onMove = (e) => {
    const x = (e.clientX / window.innerWidth - 0.5) * 10
    const y = (e.clientY / window.innerHeight - 0.5) * 10
    document.documentElement.style.setProperty('--cx', `${x}px`)
    document.documentElement.style.setProperty('--cy', `${y}px`)
  }
  window.addEventListener('mousemove', onMove)
  return () => window.removeEventListener('mousemove', onMove)
}, [])
```

## Reference brands

- Apple AirPods Max product page
- Aesop — `https://aesop.com`
- Studio Daïdai — `https://studiodaidai.com`
- Loewe — seasonal campaign pages

## Anti-patterns

- ❌ Hard-edged Bauhaus minimalism (cold, soulless)
- ❌ Comic Sans-adjacent serifs
- ❌ Reveal-on-scroll on every paragraph (parallax fatigue)
