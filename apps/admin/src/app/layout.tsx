import type { Metadata, Viewport } from 'next';
import { Fredoka } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';

const fredoka = Fredoka({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Librio - Admin & Public Portal',
  description: 'Librio Admin Dashboard and Public Portal',
  icons: {
    icon: '/icons/logo.png',
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
      <body className={fredoka.className}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
