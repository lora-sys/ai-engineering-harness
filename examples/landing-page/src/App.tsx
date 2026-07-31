import { useEffect, useRef, useState } from 'react'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import facts from './facts.json'

gsap.registerPlugin(ScrollTrigger)

/** Single source of truth for motion gating. Checked in JS, not just CSS, so the
 *  canvas loop never starts rather than starting and being visually frozen. */
const reduceMotion = () =>
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

const REPO = 'https://github.com/lora-sys/ai-engineering-harness'
const INSTALL_CMD = 'npx -y skills add lora-sys/ai-engineering-harness -g --all --full-depth'

/* ---------------------------------------------------------------------------
   Blueprint field — drafting rules with a slow scan sweep.
   Replaces the previous particle constellation: a node graph reads as "neural
   network", which is not what this product is. Ruled paper reads as measurement.
   --------------------------------------------------------------------------- */
function BlueprintField() {
  const ref = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    if (reduceMotion()) return
    const canvas = ref.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    // Cap DPR at 2. On a 3x phone an uncapped backing store is 2.25x the pixels
    // for no visible gain, and it is the easiest way to lose the mobile budget.
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    let w = 0
    let h = 0
    let raf = 0
    let visible = true
    let t = 0

    const resize = () => {
      w = canvas.width = Math.floor(canvas.offsetWidth * dpr)
      h = canvas.height = Math.floor(canvas.offsetHeight * dpr)
    }
    resize()
    window.addEventListener('resize', resize)

    const tick = () => {
      raf = 0
      if (!visible) return
      t += 1
      ctx.clearRect(0, 0, w, h)

      const step = 32 * dpr
      const sweep = ((t * 0.55) % (canvas.offsetHeight + 320)) - 160

      ctx.lineWidth = 1
      for (let y = 0; y <= h; y += step) {
        const cssY = y / dpr
        // Distance from the sweep sets brightness: the line under the sweep is
        // legible, the rest is barely there.
        const d = Math.abs(cssY - sweep)
        const lit = d < 110 ? (1 - d / 110) ** 2 : 0
        ctx.strokeStyle = `rgba(126, 231, 135, ${(0.05 + lit * 0.5) * 0.5})`
        ctx.beginPath()
        ctx.moveTo(0, y + 0.5)
        ctx.lineTo(w, y + 0.5)
        ctx.stroke()
      }

      // A few static verticals, so it reads as a grid and not a scanline effect.
      ctx.strokeStyle = 'rgba(43, 57, 71, 0.32)'
      for (let x = 0; x <= w; x += step * 5) {
        ctx.beginPath()
        ctx.moveTo(x + 0.5, 0)
        ctx.lineTo(x + 0.5, h)
        ctx.stroke()
      }

      raf = requestAnimationFrame(tick)
    }

    // Pause when scrolled away: otherwise the loop burns battery painting a
    // surface nobody is looking at.
    const io = new IntersectionObserver(
      ([e]) => {
        visible = e.isIntersecting
        if (visible && !raf) raf = requestAnimationFrame(tick)
      },
      { threshold: 0 },
    )
    io.observe(canvas)
    raf = requestAnimationFrame(tick)

    return () => {
      if (raf) cancelAnimationFrame(raf)
      io.disconnect()
      window.removeEventListener('resize', resize)
    }
  }, [])

  return (
    <canvas
      ref={ref}
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 h-full w-full"
    />
  )
}

/* ---------------------------------------------------------------------------
   Gate panel — the merge conditions as an instrument readout. This is the
   product's actual argument, so it gets the hero rather than a feature list.
   --------------------------------------------------------------------------- */
const GATE_ROWS = [
  { k: 'ci', label: 'CI', value: 'green', note: 'mechanically observable' },
  { k: 'rev', label: 'REVIEWERS', value: '≥ 2 cold-start', note: 'no shared context' },
  { k: 'ev', label: 'EVIDENCE', value: 'complete', note: 'every AC has a PASS line' },
]

function GatePanel() {
  return (
    <div className="plate-ticks border border-rule bg-plate/70 backdrop-blur-[2px]">
      <div className="flex items-center justify-between border-b border-rule px-4 py-2.5">
        <span className="font-mono text-label uppercase text-graphite">merge gate</span>
        <span className="flex items-center gap-2 font-mono text-label uppercase text-signal">
          <span className="signal-dot inline-block h-1.5 w-1.5 rounded-full bg-signal" />
          armed
        </span>
      </div>
      <ul>
        {GATE_ROWS.map((r) => (
          <li
            key={r.k}
            className="gate-row flex items-baseline gap-3 border-b border-rule/70 px-4 py-3 transition-colors duration-200 last:border-b-0 hover:bg-plate2"
          >
            <span className="w-[5.5rem] shrink-0 font-mono text-label uppercase text-graphite">
              {r.label}
            </span>
            <span className="font-mono text-sm text-paper">{r.value}</span>
            <span className="ml-auto hidden font-mono text-[0.6875rem] text-graphite sm:block">
              {r.note}
            </span>
          </li>
        ))}
      </ul>
      <p className="border-t border-rule px-4 py-3 font-mono text-[0.6875rem] leading-relaxed text-graphite">
        All three, or the branch does not land.
        <span className="text-alert"> Red CI blocks review, merge and issue-close.</span>
      </p>
    </div>
  )
}

/* --------------------------------------------------------------------------- */

function Hero() {
  const root = useRef<HTMLElement>(null)

  useEffect(() => {
    if (reduceMotion()) return
    // Opt the hero into its clipped start state only now that JS is running and
    // is about to animate it out. Set before the timeline so there is no frame
    // where the full wordmark is visible and then snaps closed.
    document.documentElement.classList.add('js-motion')
    const ctx = gsap.context(() => {
      // These are on-mount (no scroll trigger), so `from()` is safe here: the
      // timeline always runs. The clip-path reveal is a `to` because the closed
      // state lives in CSS, which keeps the text visible if JS never loads.
      gsap
        .timeline({ defaults: { ease: 'power3.out' } })
        .to('.wordmark-line', { clipPath: 'inset(0 0 0% 0)', duration: 0.75, stagger: 0.1 })
        .from('.hero-sub', { y: 14, opacity: 0, duration: 0.5 }, '-=0.35')
        .from('.hero-panel', { y: 20, opacity: 0, duration: 0.55 }, '-=0.4')
        .from('.gate-row', { opacity: 0, x: -8, duration: 0.3, stagger: 0.06 }, '-=0.3')
        .from('.hero-meta', { opacity: 0, duration: 0.4 }, '-=0.2')
    }, root)
    return () => {
      ctx.revert()
      // Drop the clipped start state on unmount, so a hot reload or a remount
      // cannot leave the wordmark hidden with no timeline left to reveal it.
      document.documentElement.classList.remove('js-motion')
    }
  }, [])

  return (
    <header ref={root} className="relative min-h-[100svh] overflow-hidden border-b border-rule">
      <BlueprintField />
      <div className="blueprint-rules pointer-events-none absolute inset-0 opacity-40" />
      <div
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            'radial-gradient(120% 80% at 20% 30%, rgba(7,9,12,0.15) 0%, rgba(7,9,12,0.82) 55%, #07090c 100%)',
        }}
      />

      <div className="relative flex min-h-[100svh] flex-col px-gutter pb-10 pt-6">
        <div className="hero-meta flex items-center justify-between font-mono text-label uppercase text-graphite">
          <span className="flex items-center gap-2">
            <span className="inline-block h-2 w-2 border border-rule-lit" />
            ai-engineering-harness
          </span>
          <span className="tnum hidden sm:inline">v{facts.version}</span>
        </div>

        {/* Asymmetric: content on 7 of 12, readout on the right. Not centered. */}
        <div className="grid flex-1 grid-cols-12 items-center gap-y-12 pt-16 sm:pt-20">
          <div className="col-span-12 lg:col-span-7">
            <h1 className="font-display text-hero font-bold uppercase text-paper">
              {/* Hard break, never auto-wrapped: the previous build split this
                  mid-word into "AI ENGINEERIN / G / HARNESS". */}
              <span className="wordmark-line">AI&nbsp;Engineering</span>
              <span className="wordmark-line text-graphite">Harness</span>
            </h1>

            <p className="hero-sub mt-7 max-w-[46ch] font-mono text-sm leading-relaxed text-graphite sm:text-body">
              An engineering organisation of{' '}
              <span className="tnum text-paper">{facts.agents}</span> AI agents wired
              into one closed loop. It does not make your agents faster — it makes
              their output <span className="text-paper">checkable</span>.
            </p>

            <div className="hero-meta mt-9 flex flex-wrap items-center gap-x-6 gap-y-3 font-mono text-label uppercase">
              <a
                href="#install"
                className="border border-signal/45 px-5 py-3 text-signal transition-colors duration-200 hover:bg-signal/10"
              >
                Install ↓
              </a>
              <a
                href={REPO}
                target="_blank"
                rel="noreferrer"
                className="border border-rule px-5 py-3 text-paper transition-colors duration-200 hover:border-rule-lit"
              >
                Source →
              </a>
            </div>
          </div>

          <div className="hero-panel col-span-12 lg:col-span-5">
            <GatePanel />
          </div>
        </div>

        <div className="hero-meta mt-8 flex items-center gap-3 font-mono text-label uppercase text-graphite">
          <span className="h-px flex-1 bg-rule" />
          <span>scroll</span>
        </div>
      </div>
    </header>
  )
}

/* --------------------------------------------------------------------------- */

function Section({
  n,
  title,
  kicker,
  children,
  id,
}: {
  n: string
  title: string
  kicker?: string
  children: React.ReactNode
  id?: string
}) {
  return (
    <section id={id} className="relative border-b border-rule px-gutter py-20 sm:py-28">
      <span
        aria-hidden="true"
        className="gutter-num absolute left-1.5 top-20 hidden font-mono text-label text-graphite lg:block"
      >
        {n}
      </span>
      <div className="lg:pl-10">
        {kicker && <p className="mb-4 font-mono text-label uppercase text-graphite">{kicker}</p>}
        <h2 className="max-w-[24ch] font-display text-section font-bold uppercase text-paper">
          {title}
        </h2>
        <div className="mt-10">{children}</div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------------------------
   The gate — staggered rows, each indenting further right. Not three equal cards.
   --------------------------------------------------------------------------- */
const ARGUMENT = [
  {
    n: '01',
    h: 'Red CI blocks everything',
    p: 'Not a warning — a stop. A red pipeline blocks review, blocks merge and blocks closing the issue, because it is the only failure signal that is mechanically observable rather than argued about.',
    indent: 'lg:ml-0',
  },
  {
    n: '02',
    h: 'Two cold-start reviewers',
    p: "A Bug Hunter and a Behaviour Reviewer, both spawned without the implementer's context. Shared context is how a reviewer inherits the author's blind spot and approves it back to them.",
    indent: 'lg:ml-[8%]',
  },
  {
    n: '03',
    h: 'An evidence pack, or it did not happen',
    p: 'Every acceptance criterion carries a PASS line, a run id, a log path. "It works on my machine" is not a result; it is a claim with the evidence removed.',
    indent: 'lg:ml-[16%]',
  },
]

function TheGate() {
  const root = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (reduceMotion()) return
    const ctx = gsap.context(() => {
      // fromTo + immediateRender:false, not gsap.from(). `from()` writes
      // opacity:0 immediately and only restores it when the trigger fires, so
      // anything that stops the trigger firing -- a mid-page landing, a
      // ScrollTrigger.refresh() race, a print stylesheet -- leaves the section
      // permanently blank. Verified: a full-page capture showed both this
      // section and the inventory as empty voids. Content must never depend on
      // an animation running.
      gsap.fromTo(
        '.arg-row',
        { opacity: 0, y: 24 },
        {
          opacity: 1,
          y: 0,
          duration: 0.6,
          stagger: 0.12,
          ease: 'power3.out',
          immediateRender: false,
          scrollTrigger: { trigger: root.current, start: 'top 85%' },
        },
      )
    }, root)
    return () => ctx.revert()
  }, [])

  return (
    <div ref={root} className="space-y-5">
      {ARGUMENT.map((a) => (
        <article
          key={a.n}
          className={`arg-row plate-ticks max-w-[58ch] border border-rule bg-plate/50 p-6 transition-colors duration-300 hover:border-rule-lit sm:p-7 ${a.indent}`}
        >
          <div className="flex items-baseline gap-4">
            <span className="tnum font-mono text-label text-signal">{a.n}</span>
            <h3 className="font-display text-lg font-semibold text-paper sm:text-xl">{a.h}</h3>
          </div>
          <p className="mt-3 font-mono text-[0.8125rem] leading-relaxed text-graphite">{a.p}</p>
        </article>
      ))}
    </div>
  )
}

/* ---------------------------------------------------------------------------
   The loop — one continuous SVG stroke, drawn by scroll progress.
   The previous build drew 8 identical boxes that wrapped onto two rows with an
   arrow pointing at nothing. A loop that visibly fails to close is the worst
   possible diagram for this product, so this one is a single path that returns.
   --------------------------------------------------------------------------- */
const STAGES = ['ISSUE', 'WORKTREE', 'PLAN', 'BUILD', 'REVIEW', 'EVIDENCE', 'MERGE', 'MEMORY']
const LOOP_PATH = 'M 60 60 H 740 V 130 H 60 V 200 H 740'
// Vertical variant for narrow screens. A 800-wide viewBox scaled into a 335px
// column renders its 12px labels at 5px -- measured, not guessed -- which is
// illegible and violates the readability constraint. Small screens get a layout
// where the stroke runs top-to-bottom and labels sit at real size in HTML.
const LOOP_PATH_V = 'M 24 20 V 660'

function TheLoop() {
  const root = useRef<HTMLDivElement>(null)
  const pathRef = useRef<SVGPathElement>(null)
  const pathVRef = useRef<SVGPathElement>(null)
  const [active, setActive] = useState(0)

  useEffect(() => {
    // Both variants exist in the DOM (CSS decides which is visible), so drive
    // whichever paths are present rather than assuming one.
    const paths = [pathRef.current, pathVRef.current].filter(Boolean) as SVGPathElement[]
    if (!paths.length) return

    const lens = paths.map((p) => {
      const len = p.getTotalLength()
      p.style.strokeDasharray = `${len}`
      return len
    })

    if (reduceMotion()) {
      paths.forEach((p) => (p.style.strokeDashoffset = '0'))
      setActive(STAGES.length - 1)
      return
    }
    paths.forEach((p, i) => (p.style.strokeDashoffset = `${lens[i]}`))

    const ctx = gsap.context(() => {
      ScrollTrigger.create({
        trigger: root.current,
        start: 'top 75%',
        end: 'bottom 65%',
        scrub: true,
        onUpdate: (self) => {
          const p = self.progress
          paths.forEach((el, i) => {
            el.style.strokeDashoffset = `${lens[i] * (1 - p)}`
          })
          setActive(Math.min(STAGES.length - 1, Math.floor(p * STAGES.length)))
        },
      })
    }, root)
    return () => ctx.revert()
  }, [])

  return (
    <div ref={root}>
      {/* Desktop / tablet: serpentine, reading order follows the stroke. */}
      <svg
        viewBox="0 0 800 260"
        className="hidden w-full sm:block"
        role="img"
        aria-label={`The closed loop: ${STAGES.join(' then ')}, returning to the start.`}
      >
        <path d={LOOP_PATH} fill="none" stroke="#1b232c" strokeWidth="1.5" />
        <path
          ref={pathRef}
          d={LOOP_PATH}
          fill="none"
          stroke="#7ee787"
          strokeWidth="1.5"
          strokeLinecap="square"
        />
        {STAGES.map((s, i) => {
          const row = Math.floor(i / 4)
          const col = i % 4
          const x = row === 0 ? 60 + col * 226.7 : 740 - col * 226.7
          const y = row === 0 ? 60 : 200
          const on = i <= active
          return (
            <g key={s}>
              <rect
                x={x - 7}
                y={y - 7}
                width="14"
                height="14"
                fill="#07090c"
                stroke={on ? '#7ee787' : '#2b3947'}
                strokeWidth="1.5"
              />
              <text
                x={x}
                y={row === 0 ? y - 20 : y + 30}
                textAnchor="middle"
                fontFamily="'JetBrains Mono', monospace"
                fontSize="12"
                letterSpacing="1.6"
                fill={on ? '#e6edf3' : '#8b98a5'}
              >
                {s}
              </text>
            </g>
          )
        })}
      </svg>

      {/* Mobile: the stroke is an SVG rail, but the labels are real HTML text at
          real size, so nothing depends on viewBox scaling to stay legible. */}
      <div className="relative sm:hidden" aria-hidden="true">
        <svg
          viewBox="0 0 48 680"
          preserveAspectRatio="none"
          className="absolute left-0 top-0 h-full w-12"
        >
          <path d={LOOP_PATH_V} fill="none" stroke="#1b232c" strokeWidth="1.5" />
          <path
            ref={pathVRef}
            d={LOOP_PATH_V}
            fill="none"
            stroke="#7ee787"
            strokeWidth="1.5"
          />
        </svg>
        <ol className="relative space-y-0">
          {STAGES.map((s, i) => {
            const on = i <= active
            return (
              <li key={s} className="flex h-[5.25rem] items-center gap-4 pl-[0.9rem]">
                <span
                  className="h-3.5 w-3.5 shrink-0 border-[1.5px] bg-ink transition-colors duration-300"
                  style={{ borderColor: on ? '#7ee787' : '#2b3947' }}
                />
                <span
                  className="font-mono text-label uppercase transition-colors duration-300"
                  style={{ color: on ? '#e6edf3' : '#8b98a5' }}
                >
                  {s}
                </span>
                <span className="tnum ml-auto font-mono text-[0.625rem] text-graphite">
                  {String(i + 1).padStart(2, '0')}
                </span>
              </li>
            )
          })}
        </ol>
      </div>
      {/* The SVG above is aria-hidden on mobile because the <ol> already conveys
          the sequence to assistive tech; one description is better than two. */}
      <p className="sr-only sm:hidden">
        The closed loop: {STAGES.join(', then ')} — and back to the start.
      </p>

      <p className="mt-8 max-w-[62ch] font-mono text-[0.8125rem] leading-relaxed text-graphite">
        One path, always the same order, and it returns: what the loop learns lands in{' '}
        <span className="text-paper">memory/</span> so the next session starts from a
        conclusion instead of re-deriving it.
      </p>
    </div>
  )
}

/* ---------------------------------------------------------------------------
   Inventory — real counts, straight from facts.json.
   --------------------------------------------------------------------------- */
const INVENTORY: Array<{ k: keyof typeof facts; label: string; note: string }> = [
  { k: 'agents', label: 'agent roles', note: 'coordinator, plan, backend, qa, reviewers …' },
  { k: 'workflows', label: 'workflows', note: 'bootstrap → ship, plus CI recovery and PR intake' },
  { k: 'templates', label: 'templates', note: 'issue, plan, PR, review, evidence, ADR' },
  { k: 'checklists', label: 'checklists', note: 'acceptance gates' },
  { k: 'references', label: 'references', note: 'deep docs' },
  { k: 'detectors', label: 'scan detectors', note: 'secrets, error handling, drift, intent loss' },
  { k: 'targets', label: 'CLI agents', note: 'claude, codex, cursor, gemini, qwen …' },
  { k: 'batsFiles', label: 'test files', note: 'bats regression suite' },
]

function Inventory() {
  const root = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (reduceMotion()) return
    const ctx = gsap.context(() => {
      // fromTo, for the same reason as TheGate: content must not be hidden by
      // default state that only an animation can undo.
      gsap.fromTo(
        '.inv-row',
        { opacity: 0, y: 12 },
        {
          opacity: 1,
          y: 0,
          duration: 0.4,
          stagger: 0.05,
          ease: 'power2.out',
          immediateRender: false,
          scrollTrigger: { trigger: root.current, start: 'top 88%' },
        },
      )
    }, root)
    return () => ctx.revert()
  }, [])

  return (
    <div ref={root} className="border-t border-rule">
      {INVENTORY.map((r) => (
        <div
          key={r.k}
          className="inv-row grid grid-cols-[3.5rem_1fr] items-baseline gap-x-4 border-b border-rule py-4 transition-colors duration-200 hover:bg-plate/60 sm:grid-cols-[5rem_14rem_1fr] sm:gap-x-6"
        >
          <span className="tnum font-mono text-xl text-signal sm:text-2xl">{facts[r.k]}</span>
          <span className="font-mono text-label uppercase text-paper">{r.label}</span>
          <span className="col-span-2 font-mono text-[0.75rem] text-graphite sm:col-span-1">
            {r.note}
          </span>
        </div>
      ))}
      <p className="mt-6 max-w-[62ch] font-mono text-[0.75rem] leading-relaxed text-graphite">
        These figures are generated from the repository at build time by{' '}
        <span className="text-paper">scripts/site-facts.sh</span>, and the build fails
        if they drift. An earlier version of this page claimed 9 workflows and 14 CLI
        agents by hand; both were wrong.
      </p>
    </div>
  )
}

/* --------------------------------------------------------------------------- */

function Install() {
  const [copied, setCopied] = useState(false)

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(INSTALL_CMD)
      setCopied(true)
      setTimeout(() => setCopied(false), 1800)
    } catch {
      // Clipboard is blocked in some embedded/insecure contexts. Say nothing
      // false: leave the label alone so the user selects the text manually.
      setCopied(false)
    }
  }

  return (
    <div>
      <div className="plate-ticks border border-rule bg-plate">
        <div className="flex items-center justify-between border-b border-rule px-4 py-2.5">
          <span className="font-mono text-label uppercase text-graphite">one command</span>
          <button
            onClick={copy}
            className="font-mono text-label uppercase text-signal transition-opacity duration-200 hover:opacity-70"
            aria-label="Copy install command"
          >
            {copied ? '✓ copied' : 'copy'}
          </button>
        </div>
        {/* break-all so narrow screens wrap cleanly instead of collapsing into
            four ragged lines the way the previous build did at 390px. */}
        <code className="block break-all px-4 py-5 font-mono text-[0.8125rem] leading-relaxed text-paper sm:text-sm">
          <span className="select-none text-signal">$ </span>
          {INSTALL_CMD}
        </code>
      </div>

      <div className="mt-6 flex flex-wrap gap-x-8 gap-y-3 font-mono text-label uppercase text-graphite">
        <span>
          installs <span className="tnum text-paper">{facts.skills}</span> skills
        </span>
        <span>
          across <span className="tnum text-paper">{facts.targets}</span> CLI agents
        </span>
        <span>
          v<span className="tnum text-paper">{facts.version}</span> · MIT
        </span>
      </div>

      <p className="mt-8 max-w-[58ch] font-mono text-[0.8125rem] leading-relaxed text-graphite">
        Then, in the repo you want to take over:{' '}
        <span className="text-paper">
          “Use $ai-engineering-harness to take over this repo.”
        </span>{' '}
        It scans first and names what it found — category and worst location — before it
        asks you for anything.
      </p>
    </div>
  )
}

export default function App() {
  // Anchor smoothing lives here, not in CSS, so it can honour reduced-motion —
  // which `scroll-behavior: smooth` cannot — and not fight ScrollTrigger pinning.
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      const a = (e.target as HTMLElement)?.closest?.('a[href^="#"]')
      if (!a) return
      const href = a.getAttribute('href')
      if (!href || href === '#') return
      const el = document.getElementById(href.slice(1))
      if (!el) return
      e.preventDefault()
      el.scrollIntoView({ behavior: reduceMotion() ? 'auto' : 'smooth', block: 'start' })
    }
    document.addEventListener('click', onClick)
    return () => document.removeEventListener('click', onClick)
  }, [])

  return (
    <main className="min-h-screen bg-ink">
      <Hero />

      <Section n="01" kicker="the argument" title="Vibes ship. Evidence lands.">
        <p className="mb-10 max-w-[58ch] font-mono text-[0.8125rem] leading-relaxed text-graphite">
          AI writes code roughly ten times faster than you do. Without engineering
          discipline the defect density is unchanged — you have simply arrived at the
          same bugs sooner. Three conditions decide whether a branch lands:
        </p>
        <TheGate />
      </Section>

      <Section n="02" kicker="the mechanism" title="One loop, and it closes">
        <TheLoop />
      </Section>

      <Section n="03" kicker="what's inside" title="Countable, not adjectival">
        <Inventory />
      </Section>

      <Section n="04" kicker="install" title="Drops into your agent" id="install">
        <Install />
      </Section>

      <footer className="px-gutter py-12">
        <div className="flex flex-col gap-4 font-mono text-label uppercase text-graphite sm:flex-row sm:items-center sm:justify-between">
          <span>ai-engineering-harness · v{facts.version}</span>
          <span className="flex flex-wrap gap-x-6 gap-y-2">
            <a href={REPO} target="_blank" rel="noreferrer" className="transition-colors hover:text-paper">
              github
            </a>
            <a
              href={`${REPO}/blob/main/QUICKSTART.md`}
              target="_blank"
              rel="noreferrer"
              className="transition-colors hover:text-paper"
            >
              quickstart
            </a>
            <a
              href={`${REPO}/blob/main/docs/case-studies/README.md`}
              target="_blank"
              rel="noreferrer"
              className="transition-colors hover:text-paper"
            >
              case studies
            </a>
            <a
              href={`${REPO}/blob/main/LICENSE`}
              target="_blank"
              rel="noreferrer"
              className="transition-colors hover:text-paper"
            >
              mit
            </a>
          </span>
        </div>
        <p className="mt-6 font-mono text-[0.75rem] text-graphite">让每一行代码，都有证据。</p>
      </footer>
    </main>
  )
}
