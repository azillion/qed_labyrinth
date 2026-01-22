/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        grimoire: {
          950: '#0c0a09',
          900: '#1c1917',
          800: '#292524',
          700: '#44403c',
          600: '#57534e',
        },
        amber: {
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          900: '#78350f',
        }
      },
      fontFamily: {
        serif: ['Cinzel', 'Georgia', 'serif'],
      },
    },
  },
  plugins: [],
}
