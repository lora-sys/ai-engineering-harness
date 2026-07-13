# Theme C — Retro Acid Y2K

Aesthetic: Y2K, high-saturation, brutalist, experimental layout. Best for: creative agencies, music products, fashion, art collectives.

## Tailwind config

```js
export default {
  theme: {
    extend: {
      colors: {
        bg:        '#a3e635',     // lime-400
        surface:   '#fbbf24',     // amber-400
        ink:       '#000000',
        primary:   '#f97316',     // orange-500
        accent:    '#d946ef',     // fuchsia-500
        secondary: '#06b6d4',     // cyan-500
      },
      fontFamily: {
        mono: ['"Space Mono"', 'ui-monospace', 'monospace'],
        display: ['"Archivo Black"', '"Inter"', 'sans-serif'],
      },
      fontSize: {
        hero: ['clamp(4rem, 18vw, 20rem)', { lineHeight: '0.85', letterSpacing: '-0.06em' }],
      },
      backgroundImage: {
        'checker': 'repeating-conic-gradient(#000 0% 25%, #fde047 0% 50%) 0 0 / 40px 40px',
        'gradient-radical': 'conic-gradient(from 45deg, #f97316, #d946ef, #06b6d4, #a3e635, #f97316)',
      },
    },
  },
}
```

## Motion presets

```tsx
// GSAP marquee ticker
useGSAP(() => {
  gsap.to('.marquee-track', {
    xPercent: -50,
    duration: 20,
    repeat: -1,
    ease: 'none',
  })
}, [])

// Brutalist hover shift
<motion.a
  whileHover={{ x: -4, y: -4, boxShadow: '8px 8px 0 #000' }}
  transition={{ type: 'spring', stiffness: 400, damping: 20 }}
  className="border-4 border-black bg-amber-400 px-6 py-3"
>
  BUY NOW
</motion.a>
```

## Reference brands

- Gumroad — `https://gumroad.com`
- Linear marketing pages
- Mid-90s rave posters
- Brain Dead (streetwear) — `https://wearebraindead.com`

## Anti-patterns

- ❌ "AI does acid" clichés (chrome, drip, glitch)
- ❌ Trying to be retro AND serious — pick a lane
- ❌ High-saturation on text without background contrast
