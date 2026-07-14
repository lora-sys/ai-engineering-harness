import { useEffect, useRef, useState } from 'react'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

// Particle background — canvas, no R3F
function ParticleField() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    let raf = 0
    let w = (canvas.width = canvas.offsetWidth * window.devicePixelRatio)
    let h = (canvas.height = canvas.offsetHeight * window.devicePixelRatio)
    const onResize = () => {
      w = canvas.width = canvas.offsetWidth * window.devicePixelRatio
      h = canvas.height = canvas.offsetHeight * window.devicePixelRatio
    }
    window.addEventListener('resize', onResize)
    const N = 80
    const pts = Array.from({ length: N }, () => ({
      x: Math.random() * w,
      y: Math.random() * h,
      vx: (Math.random() - 0.5) * 0.3 * window.devicePixelRatio,
      vy: (Math.random() - 0.5) * 0.3 * window.devicePixelRatio,
      r: (Math.random() * 1.4 + 0.6) * window.devicePixelRatio,
    }))
    const tick = () => {
      ctx.clearRect(0, 0, w, h)
      // nodes
      ctx.fillStyle = 'rgba(34, 211, 238, 0.7)'
      for (const p of pts) {
        p.x += p.vx; p.y += p.vy
        if (p.x < 0 || p.x > w) p.vx *= -1
        if (p.y < 0 || p.y > h) p.vy *= -1
        ctx.beginPath()
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
        ctx.fill()
      }
      // connections
      ctx.strokeStyle = 'rgba(217, 70, 239, 0.18)'
      ctx.lineWidth = 0.6
      for (let i = 0; i < N; i++) {
        for (let j = i + 1; j < N; j++) {
          const dx = pts[i].x - pts[j].x
          const dy = pts[i].y - pts[j].y
          const d2 = dx * dx + dy * dy
          if (d2 < 160 * 160 * window.devicePixelRatio * window.devicePixelRatio) {
            ctx.beginPath()
            ctx.moveTo(pts[i].x, pts[i].y)
            ctx.lineTo(pts[j].x, pts[j].y)
            ctx.stroke()
          }
        }
      }
      raf = requestAnimationFrame(tick)
    }
    tick()
    return () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('resize', onResize)
    }
  }, [])
  return <canvas ref={canvasRef} className="absolute inset-0 w-full h-full" />
}

const STAGES = ['ISSUE', 'WORKTREE', 'PLAN', 'BUILD', 'REVIEW', 'EVIDENCE', 'MERGE', 'MEMORY'] as const

export default function App() {
  const heroRef = useRef<HTMLDivElement>(null)
  const loopRef = useRef<HTMLDivElement>(null)
  const [copied, setCopied] = useState(false)
  const installCmd = 'npx -y skills add lora-sys/ai-engineering-harness -g'

  // Hero intro animation
  useEffect(() => {
    const hero = heroRef.current
    if (!hero) return
    const tl = gsap.timeline({ defaults: { ease: 'power4.out' } })
    tl.from(hero.querySelectorAll('.hero-char'), {
      y: 120, opacity: 0, filter: 'blur(12px)',
      duration: 1.1, stagger: 0.045,
    })
    tl.from(hero.querySelector('.hero-tag'), { y: 30, opacity: 0, duration: 0.7 }, '-=0.5')
    tl.from(hero.querySelector('.hero-cta'), { y: 30, opacity: 0, duration: 0.5 }, '-=0.3')
    tl.from(hero.querySelector('.hero-stats'), { y: 20, opacity: 0, duration: 0.6 }, '-=0.2')
    return () => { tl.kill() }
  }, [])

  // Closed-loop scroll animation
  useEffect(() => {
    const loop = loopRef.current
    if (!loop) return
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        scrollTrigger: { trigger: loop, start: 'top center', end: 'bottom center', scrub: 1 },
      })
      tl.fromTo(
        loop.querySelectorAll('.loop-node'),
        { opacity: 0.15, scale: 0.85 },
        { opacity: 1, scale: 1, stagger: 0.15, ease: 'power2.out' },
        0
      )
      tl.fromTo(
        loop.querySelectorAll('.loop-arrow'),
        { strokeDasharray: 200, strokeDashoffset: 200 },
        { strokeDashoffset: 0, stagger: 0.15, ease: 'none' },
        0
      )
    }, loop)
    return () => ctx.revert()
  }, [])

  const copy = async () => {
    await navigator.clipboard.writeText(installCmd)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <main className="relative bg-bg text-ink overflow-x-hidden">
      {/* ───── NAV (sticky) ───── */}
      <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 py-3 bg-bg/70 backdrop-blur-md border-b border-primary/20">
        <a href="#top" className="flex items-center gap-2 font-display font-black text-sm uppercase tracking-tighter">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-primary">
            <circle cx="12" cy="12" r="9" />
            <circle cx="12" cy="12" r="3" className="text-accent" fill="currentColor" />
          </svg>
          <span className="gradient-text">AEH</span>
          <span className="hidden md:inline text-muted text-[10px] uppercase tracking-[0.3em]">ai-engineering-harness</span>
        </a>
        <div className="flex items-center gap-1 md:gap-4 text-[10px] md:text-xs uppercase tracking-[0.2em]">
          <a href="#loop" className="px-2 py-1 md:px-3 md:py-1.5 text-muted hover:text-primary transition-colors">Loop</a>
          <a href="#install" className="px-2 py-1 md:px-3 md:py-1.5 text-muted hover:text-primary transition-colors">Install</a>
          <a href="https://github.com/lora-sys/ai-engineering-harness/blob/main/QUICKSTART.md" target="_blank" rel="noreferrer" className="px-2 py-1 md:px-3 md:py-1.5 text-muted hover:text-primary transition-colors hidden sm:inline">Docs</a>
          <a
            href="https://github.com/lora-sys/ai-engineering-harness"
            target="_blank" rel="noreferrer"
            className="ml-2 px-3 py-1.5 md:px-4 md:py-2 border border-primary/50 text-primary font-mono font-bold hover:bg-primary hover:text-bg transition-all hover:shadow-neon flex items-center gap-2"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 .3a12 12 0 0 0-3.8 23.4c.6.1.8-.3.8-.6v-2.2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1-.7.1-.7.1-.7 1.2 0 1.9 1.2 1.9 1.2 1 1.7 1.4 2 1.6.1-.8.4-1.4.4-2.6 0 0 0-2.2 1.2 0 0 1 0-1.2 0-2.4-1.2-3.7 3.6-3.1 1.7-1 3.7-1 5.5 0 1.6.8 1 2.1.8 1.4-.8 1.2-2 2.2-2.4-.6 0-1.2-.2-2 .9.2-.3 1.4-.9 1.4-2.7 0-4.7-1.4-6.4-3.1 0-.8.3-1.7.3-3.5 0-2.3 1.5-4.3 1.5-7.7 0-.4 0-1-.1-1.4 0-3.6 2.2-7 6.4-7 1.8 0 3.4.6 4.6 1.3 1.2-.5 2.8-1.8 4.4-2.8-.1 0-.2 0-.3.1 0-1.9-.6-3 0-3.1 0-2.4 0-2.4 2.4 0 5.3 0 2.4 0 1.8 0 1.2-.1 1-.7 2-2.5 5.4-1.4 9.2 0 7.7 2.7 10.4 8 6.6-.2 12.2-1 12.9-1.4 0-1.2 0-2.3-.4-3.4.6-1.7.4-.4 1-.6.4-1.1 0-.7-.4-1.4-.7-2-.7-1.2-2.6-1.7-4.3-.2 0-1.5.1-1.9 1.2-1.4.7-.4 1.6-1.3 2.4-1.6 0-1-.1-1.3 0-1.8 0-2 0-1.4-.3-2.7-.7-4-1.4-1.7-3.6-1.5-3.4.4-1.4 2.6-.3 1.5 0 3-.3 1.6-1 2.7-1.5 1.3-1.6 1.7-1.7 0-3.3 0-4.3 0-4.3-1.4 0-2.7 0-3.6 0-2.7-.3-1.4-.6-3-.7-3.6-2-7.1 0-1.5 0-3.3-3.6-3.3 3.6-3.6 3.6-3.6 5 0 4.5 0 4.6-1.5 0-3.4 0-3.4-1.4 0-1.5 0-1.5-1-.1-2.7-1.7-3.4-1.7-3.5-1.7-1.6 0-2.3 0-2.3 0-1.5 0-1.5.1-.9.6-2.1 1.4-3.2 0-3.6 0-3.6-1.2 0-2.3-.1-2.5 0-2.4 0-1.4-1.5-3.4-1.7-3.5-1.7-1.5 0-2 0-2 0-1.7 0-1.7.3-.6 1.1-1.5 1.3-2.3 0-1.3 0-2.6-.8-1.5-.4-1.4-1.1-1.5z"/></svg>
            <span>GitHub →</span>
          </a>
        </div>
      </nav>
      {/* ───── HERO ───── */}
      <section id="top" ref={heroRef} className="relative min-h-screen flex flex-col items-center justify-center noise-bg overflow-hidden">
        <ParticleField />
        {/* Top label */}
        <div className="absolute top-6 left-6 right-6 z-10 flex justify-between items-center text-[10px] uppercase tracking-[0.3em] text-muted">
          <span>v1.8.6 · ai-engineering-harness</span>
          <span className="hidden md:block">让每一行代码,都有证据</span>
        </div>
        {/* Hero text */}
        <div className="relative z-10 text-center px-6">
          <h1 className="font-display font-black uppercase tracking-tighter leading-[0.85] text-hero">
            <div className="block">
              {'AI ENGINEERING'.split('').map((c, i) => (
                <span key={i} className="hero-char inline-block gradient-text">{c === ' ' ? '\u00A0' : c}</span>
              ))}
            </div>
            <div className="block mt-1">
              {'HARNESS'.split('').map((c, i) => (
                <span key={i} className="hero-char inline-block text-ink">{c === ' ' ? '\u00A0' : c}</span>
              ))}
            </div>
          </h1>
          <p className="hero-tag mt-10 text-lg md:text-2xl text-muted max-w-2xl mx-auto">
            A software-engineering organization of AI agents. Let every line of code have evidence.
          </p>
          <button
            onClick={copy}
            className="hero-cta group relative inline-flex items-center gap-3 mt-10 px-8 py-4 border border-primary/50 text-ink font-display font-bold text-lg tracking-wider uppercase bg-surface/50 backdrop-blur-sm hover:bg-surface hover:border-primary transition-all hover:shadow-neon"
          >
            <span className="text-primary">$</span>
            <span className="text-xs md:text-sm font-mono">{installCmd}</span>
            <span className="text-xs text-muted ml-2 group-hover:text-primary transition-colors">
              {copied ? '✓ copied' : 'click to copy'}
            </span>
          </button>
          <div className="hero-stats mt-16 flex flex-wrap justify-center gap-x-10 gap-y-3 text-[11px] uppercase tracking-[0.3em] text-muted">
            <span><b className="text-primary">18</b> agents</span>
            <span><b className="text-accent">9</b> workflows</span>
            <span><b className="text-highlight">1</b> closed loop</span>
            <span><b className="text-primary">≥2</b> cold-start reviewers</span>
          </div>
        </div>
        {/* Scroll hint */}
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 text-[10px] uppercase tracking-[0.3em] text-muted animate-pulse">
          scroll ↓
        </div>
      </section>

      {/* ───── CLOSED LOOP ───── */}
      <section id="loop" ref={loopRef} className="relative py-32 md:py-48 px-6 grid-bg">
        <div className="max-w-5xl mx-auto text-center mb-16">
          <h2 className="font-display font-black uppercase tracking-tighter text-section gradient-text">
            The closed loop
          </h2>
          <p className="mt-4 text-muted text-sm md:text-base">
            Every change goes through the same path. Code reaches <code className="text-primary">main</code> only when CI is green, ≥ 2 reviewers approve, and the Evidence pack is complete.
          </p>
        </div>
        <div className="max-w-5xl mx-auto flex flex-wrap items-center justify-center gap-3 md:gap-4">
          {STAGES.map((stage, i) => (
            <div key={stage} className="flex items-center gap-3 md:gap-4">
              <div className="loop-node group relative px-4 py-3 border border-primary/30 bg-surface/60 backdrop-blur-sm hover:border-primary hover:shadow-neon transition-all">
                <div className="text-[9px] uppercase tracking-[0.3em] text-muted mb-0.5">
                  0{i + 1}
                </div>
                <div className="font-display font-bold text-sm md:text-base tracking-wider text-ink">
                  {stage}
                </div>
              </div>
              {i < STAGES.length - 1 && (
                <svg className="loop-arrow w-8 h-8 md:w-10 md:h-10 text-accent shrink-0" viewBox="0 0 40 40" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M5 20 L33 20" />
                  <path d="M28 14 L33 20 L28 26" />
                </svg>
              )}
              {i === STAGES.length - 1 && (
                <svg className="loop-arrow w-8 h-8 md:w-10 md:h-10 text-highlight shrink-0" viewBox="0 0 40 40" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M33 20 L13 10" />
                  <path d="M16 7 L13 10 L17 12" />
                </svg>
              )}
            </div>
          ))}
        </div>
        <p className="max-w-2xl mx-auto mt-12 text-center text-xs uppercase tracking-[0.3em] text-muted">
          ↻  closed loop. evidence-gated. memory-compounds.
        </p>
      </section>

      {/* ───── MARQUEE ───── */}
      <section className="relative border-y border-primary/20 py-6 overflow-hidden">
        <div className="marquee-track text-[11px] uppercase tracking-[0.3em] text-muted">
          {Array.from({ length: 2 }).map((_, dup) => (
            <span key={dup} className="flex shrink-0">
              {['ISSUE-DRIVEN', '★', 'WORKTREE-ISOLATED', '★', 'PR-CARRIED', '★',
                'ADVERSARIAL-REVIEWED', '★', 'EVIDENCE-GATED', '★',
                'CI-AS-BLOCKING-GATE', '★', 'LOCAL-FIRST', '★',
                'MEMORY-COMPOUNDS', '★'].map((s, i) => (
                <span key={i} className={s === '★' ? 'mx-8 text-primary' : 'mx-8'}>{s}</span>
              ))}
            </span>
          ))}
        </div>
      </section>

      {/* ───── INSTALL ───── */}
      <section id="install" className="relative py-32 md:py-48 px-6 noise-bg">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="font-display font-black uppercase tracking-tighter text-section text-ink">
            Install in <span className="gradient-text">1 command</span>
          </h2>
          <p className="mt-4 text-muted text-sm md:text-base max-w-xl mx-auto">
            18 agents · 9 workflows · 1 closed loop. Drops into any of 14 supported CLI agents (Codex, Claude Code, Cursor, Gemini, Qwen, ...).
          </p>
          <button
            onClick={copy}
            className="group relative inline-flex items-center gap-3 mt-10 px-8 py-5 border border-primary/50 text-ink font-mono text-sm md:text-base bg-surface/50 backdrop-blur-sm hover:bg-surface hover:border-primary transition-all hover:shadow-neon"
          >
            <span className="text-primary">$</span>
            <span>{installCmd}</span>
            <span className="text-xs text-muted ml-2 group-hover:text-primary transition-colors">
              {copied ? '✓ copied' : 'click to copy'}
            </span>
          </button>
          <div className="mt-12 flex justify-center gap-6 text-[10px] uppercase tracking-[0.3em] text-muted">
            <a href="https://github.com/lora-sys/ai-engineering-harness" target="_blank" rel="noreferrer" className="hover:text-primary transition-colors">
              → GitHub
            </a>
            <span>·</span>
            <a href="https://github.com/lora-sys/ai-engineering-harness/blob/main/QUICKSTART.md" target="_blank" rel="noreferrer" className="hover:text-primary transition-colors">
              → Quickstart
            </a>
            <span>·</span>
            <span>MIT</span>
          </div>
        </div>
      </section>

      {/* ───── FOOTER ───── */}
      <footer className="relative border-t border-primary/10 py-8 px-6">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-2 text-[10px] uppercase tracking-[0.3em] text-muted">
          <span>ai-engineering-harness · v1.8.6</span>
          <span>让每一行代码,都有证据</span>
        </div>
      </footer>
    </main>
  )
}
