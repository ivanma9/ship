/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Linear-inspired neutral palette
        // All colors meet WCAG 2.1 AA contrast requirements (4.5:1 minimum)
        background: '#0d0d0d',
        foreground: '#f5f5f5',
        muted: '#8a8a8a', // Changed from #737373 (4.09:1) to #8a8a8a (5.1:1 contrast)
        border: '#262626',
        accent: '#005ea2', // Logo blue — use as bg with white text (6.72:1 on white); NOT as text on dark bg
        'accent-hover': '#0071bc', // Lighter blue for hover — use as bg with white text
        'accent-text': '#1a85d9', // Accessible blue for text on dark bg (5.0:1 on #0d0d0d, WCAG AA)
      },
      fontFamily: {
        sans: [
          'Inter',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
      },
    },
  },
  plugins: [],
};
