import type { Metadata, Viewport } from 'next';
import { Fredoka } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';

const fredoka = Fredoka({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Librio - AI Study Companion',
  description: 'Master any subject with AI-powered explanations, flashcards, quizzes, and personalized study tools',
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/icons/logo.png', type: 'image/png' },
    ],
    apple: '/icons/logo.png',
  },
  manifest: '/manifest.json',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Librio',
  },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#3B82F6',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
        <link rel="icon" href="/icons/logo.png" type="image/png" />
        <link rel="apple-touch-icon" href="/icons/logo.png" />
      </head>
      <body className={fredoka.className}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
