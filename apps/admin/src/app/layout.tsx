import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Providers } from './providers';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Librio - Admin & Public Portal',
  description: 'Librio Admin Dashboard and Public Portal',
  viewport: 'width=device-width, initial-scale=1',
  icons: {
    icon: '/images/favicon.svg',
    apple: '/images/logo.svg',
  },
  manifest: '/manifest.json',
  themeColor: '#3B82F6',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Librio',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
