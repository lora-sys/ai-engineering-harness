# Theme D — Future-Tech 3D Particle

Aesthetic: WebGL, shader, 3D scene, immersive experience. Best for: Web3, AI products, experimental launches.

## Tailwind config

```js
export default {
  theme: {
    extend: {
      colors: {
        bg:        '#020617',     // slate-950
        surface:   '#0f172a',     // slate-900
        primary:   '#67e8f9',     // cyan-300
        accent:    '#c084fc',     // purple-400
        ink:       '#f8fafc',     // slate-50
        muted:     '#64748b',     // slate-500
      },
      fontFamily: {
        sans: ['"Inter"', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        hero: ['clamp(4rem, 12vw, 12rem)', { lineHeight: '1', letterSpacing: '-0.03em', fontWeight: '300' }],
      },
      backgroundImage: {
        'gradient-deep': 'radial-gradient(ellipse at top, #1e1b4b 0%, #020617 70%)',
        'gradient-purple': 'linear-gradient(135deg, #7c3aed 0%, #06b6d4 100%)',
      },
    },
  },
}
```

## Motion presets (R3F + GSAP scroll)

```tsx
// Particle field (R3F)
import { Canvas, useFrame } from '@react-three/fiber'
import { Points, PointMaterial } from '@react-three/drei'
import { useRef } from 'react'
import * as THREE from 'three'

function ParticleField({ count = 2000 }) {
  const ref = useRef<THREE.Points>(null!)
  const positions = new Float32Array(count * 3)
  for (let i = 0; i < count; i++) {
    positions[i * 3] = (Math.random() - 0.5) * 10
    positions[i * 3 + 1] = (Math.random() - 0.5) * 10
    positions[i * 3 + 2] = (Math.random() - 0.5) * 10
  }
  useFrame((_, dt) => { ref.current.rotation.y += dt * 0.05 })
  return (
    <Points ref={ref} positions={positions} stride={3}>
      <PointMaterial transparent color="#67e8f9" size={0.02} sizeAttenuation />
    </Points>
  )
}

<Canvas camera={{ position: [0, 0, 5] }}>
  <ParticleField />
</Canvas>
```

```tsx
// Scroll-driven camera dolly
useGSAP(() => {
  gsap.to(camera.position, {
    z: 2,
    scrollTrigger: { trigger: '#hero', start: 'top top', end: 'bottom top', scrub: true },
  })
}, [])
```

## Reference brands

- Apple Vision Pro product page
- R3F landing examples — `https://r3f.app`
- Resend homepage
- Linear changelog hero (rotating gradient mesh)

## Performance budget

- Particle count: ≤ 3000 on desktop, ≤ 800 on mobile
- Lazy-load R3F only after first scroll past hero
- Disable on `prefers-reduced-motion: reduce`

## Anti-patterns

- ❌ Generic particle sphere that's been done 1000 times
- ❌ 3D scene that doesn't react to user input
- ❌ Heavy shader work on mobile
