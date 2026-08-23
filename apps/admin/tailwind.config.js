/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    './node_modules/@nextui-org/theme/dist/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3B82F6',
        secondary: '#8B5CF6',
        success: '#10B981',
        warning: '#F59E0B',
        danger: '#EF4444',
        librio: {
          purple: '#9B5DE5',
          blue: '#6F9BEF',
          cyan: '#22D3E6',
        },
      },
      fontFamily: {
        sans: ['Fredoka', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        'librio-gradient': 'linear-gradient(90deg, #9B5DE5 0%, #6F9BEF 50%, #22D3E6 100%)',
        'librio-gradient-vertical': 'linear-gradient(180deg, #9B5DE5 0%, #6F9BEF 50%, #22D3E6 100%)',
      },
      boxShadow: {
        'librio-glow': '0 0 20px rgba(155, 93, 229, 0.3), 0 0 40px rgba(111, 155, 239, 0.2), 0 0 60px rgba(34, 211, 230, 0.1)',
        'librio-glow-strong': '0 0 30px rgba(155, 93, 229, 0.5), 0 0 60px rgba(111, 155, 239, 0.3), 0 0 90px rgba(34, 211, 230, 0.2)',
      },
    },
  },
  darkMode: 'class',
  plugins: [require('@nextui-org/react')],
};
