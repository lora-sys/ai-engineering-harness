/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Engineering blueprint / instrumentation palette. One accent, not four.
        // `signal` and `alert` are semantic: they appear only on things that have
        // a pass/fail nature, so light always means state, never decoration.
        ink: '#07090c',
        plate: '#0d1116',
        plate2: '#11171d',
        rule: '#1b232c',
        'rule-lit': '#2b3947',
        signal: '#7ee787',
        alert: '#ff7b72',
        paper: '#e6edf3',
        graphite: '#8b98a5',
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', 'ui-monospace', 'SFMono-Regular', 'monospace'],
        display: ['"Space Grotesk"', 'system-ui', '-apple-system', 'sans-serif'],
      },
      fontSize: {
        // Sized against the COLUMN, not the viewport. The hero sits on 7 of 12
        // columns, so viewport-relative units overshoot: at 8.5vw on a 1440
        // viewport the wordmark needed 835px inside a 764px column and
        // `clip-path` silently cropped it to "AI ENGINEERIN". 5.4vw keeps
        // "AI ENGINEERING" — the longest line — inside the column at every width
        // between 320 and 2560. Verified by measuring scrollWidth vs clientWidth,
        // not by eye: the clip means overflow is invisible until you measure it.
        hero: ['clamp(2.25rem, 5.4vw, 5.5rem)', { lineHeight: '0.95', letterSpacing: '-0.03em' }],
        section: ['clamp(1.75rem, 4vw, 3.25rem)', { lineHeight: '1.02', letterSpacing: '-0.02em' }],
        label: ['0.6875rem', { lineHeight: '1', letterSpacing: '0.16em' }],
        body: ['1.0625rem', { lineHeight: '1.65' }],
      },
      spacing: {
        gutter: 'clamp(1.25rem, 4vw, 5rem)',
      },
      transitionTimingFunction: {
        instrument: 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
    },
  },
  plugins: [],
}
