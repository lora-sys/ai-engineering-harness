/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#000000',
        surface: '#0a0a0a',
        primary: '#22d3ee',
        accent: '#d946ef',
        highlight: '#fde047',
        ink: '#fafafa',
        muted: '#71717a',
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
        display: ['"Space Grotesk"', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        hero: ['clamp(4rem, 14vw, 14rem)', { lineHeight: '0.9', letterSpacing: '-0.04em' }],
        section: ['clamp(2.5rem, 6vw, 5rem)', { lineHeight: '1' }],
      },
      boxShadow: {
        neon: '0 0 30px rgba(34, 211, 238, 0.6), 0 0 60px rgba(217, 70, 239, 0.3)',
      },
    },
  },
  plugins: [],
}
