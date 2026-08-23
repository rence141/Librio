'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { Smartphone, Globe, Monitor, Apple, WifiOff, Sparkles, ArrowRight, Check } from 'lucide-react';

export default function DownloadPage() {
  const [activeTab, setActiveTab] = useState<'mobile' | 'web' | 'desktop'>('mobile');

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="fixed top-0 inset-x-0 bg-white/80 backdrop-blur-md z-50 border-b border-gray-100">
        <div className="flex justify-between items-center h-16">
          <Link href="/" className="flex-shrink-0 flex items-center gap-2 cursor-pointer pl-4">
            <Image
              src="/images/Logo-Text.png"
              alt="Librio"
              width={120}
              height={40}
              priority
            />
          </Link>
          <nav className="hidden md:flex items-center gap-8">
            <Link href="/features" className="text-sm font-medium text-gray-600 hover:text-librio-purple transition-colors">
              Features
            </Link>
            <Link href="/how-it-works" className="text-sm font-medium text-gray-600 hover:text-librio-purple transition-colors">
              How It Works
            </Link>
            <Link href="/faq" className="text-sm font-medium text-gray-600 hover:text-librio-purple transition-colors">
              FAQ
            </Link>
          </nav>
          <div className="hidden md:flex items-stretch h-16">
            <Link href="/download" className="ai-button inline-flex items-center justify-center px-6 h-full text-sm font-extrabold rounded-none gap-2">
              <span>Get the app</span>
              <svg className="w-6 h-6" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" viewBox="0 0 24 24">
                <rect height="7" width="7" x="3" y="3"></rect>
                <rect height="7" width="7" x="14" y="3"></rect>
                <rect height="7" width="7" x="14" y="14"></rect>
                <rect height="7" width="7" x="3" y="14"></rect>
              </svg>
            </Link>
          </div>
          <div className="md:hidden pr-4">
            <Link href="/download" className="ai-button ai-button-sm rounded-full">
              Get the app
            </Link>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section className="pt-32 pb-16 px-6 md:px-12">
        <div className="max-w-3xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-librio-purple/10 mb-6">
            <Sparkles className="w-4 h-4 text-librio-purple" />
            <span className="text-sm font-medium text-librio-purple">Get started in seconds</span>
          </div>
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-6 leading-tight">
            Download <span className="bg-librio-gradient bg-clip-text text-transparent">Librio</span>
          </h1>
          <p className="text-lg text-gray-600 mb-8">
            Available on iOS, Android, and the web. Study smarter anywhere, anytime - even offline.
          </p>
        </div>
      </section>

      {/* Platform Tabs */}
      <section className="px-6 md:px-12 pb-20">
        <div className="max-w-5xl mx-auto">
          {/* Tab Selector */}
          <div className="flex flex-wrap justify-center gap-2 mb-12">
            <button
              onClick={() => setActiveTab('mobile')}
              className={`inline-flex items-center gap-2 px-6 py-3 rounded-full text-sm font-semibold transition-all ${
                activeTab === 'mobile'
                  ? 'ai-button'
                  : 'bg-white text-gray-600 border border-gray-200 hover:border-librio-purple/30'
              }`}
            >
              <Smartphone className="w-4 h-4" />
              Mobile
            </button>
            <button
              onClick={() => setActiveTab('web')}
              className={`inline-flex items-center gap-2 px-6 py-3 rounded-full text-sm font-semibold transition-all ${
                activeTab === 'web'
                  ? 'ai-button'
                  : 'bg-white text-gray-600 border border-gray-200 hover:border-librio-purple/30'
              }`}
            >
              <Globe className="w-4 h-4" />
              Web
            </button>
            <button
              onClick={() => setActiveTab('desktop')}
              className={`inline-flex items-center gap-2 px-6 py-3 rounded-full text-sm font-semibold transition-all ${
                activeTab === 'desktop'
                  ? 'ai-button'
                  : 'bg-white text-gray-600 border border-gray-200 hover:border-librio-purple/30'
              }`}
            >
              <Monitor className="w-4 h-4" />
              Desktop
            </button>
          </div>

          {/* Mobile Tab */}
          {activeTab === 'mobile' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* iOS */}
              <div className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm hover:shadow-lg transition-shadow">
                <div className="w-14 h-14 rounded-2xl bg-gray-900 flex items-center justify-center mb-6">
                  <Apple className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">iOS</h3>
                <p className="text-gray-600 mb-6">
                  Download Librio from the App Store and start learning on your iPhone or iPad.
                </p>
                <a
                  href="https://apps.apple.com/app/librio"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2 w-full"
                >
                  Download on App Store
                  <ArrowRight className="w-5 h-5" />
                </a>
                <p className="text-sm text-gray-500 mt-4">Requires iOS 14.0 or later</p>
              </div>

              {/* Android */}
              <div className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm hover:shadow-lg transition-shadow">
                <div className="w-14 h-14 rounded-2xl bg-[#3DDC84] flex items-center justify-center mb-6">
                  <svg className="w-7 h-7 text-white" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.6 9.48l1.84-3.18c.16-.31.04-.69-.27-.85-.29-.15-.65-.06-.83.22l-1.88 3.24c-2.86-1.21-6.08-1.21-8.94 0L5.65 5.67c-.18-.28-.54-.37-.83-.22-.31.16-.43.54-.27.85L6.4 9.48C3.3 11.25 1.28 14.44 1 18h22c-.28-3.56-2.3-6.75-5.4-8.52zM7 15.25c-.69 0-1.25-.56-1.25-1.25s.56-1.25 1.25-1.25 1.25.56 1.25 1.25-.56 1.25-1.25 1.25zm10 0c-.69 0-1.25-.56-1.25-1.25s.56-1.25 1.25-1.25 1.25.56 1.25 1.25-.56 1.25-1.25 1.25z"/>
                  </svg>
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Android</h3>
                <p className="text-gray-600 mb-6">
                  Get Librio from Google Play and start learning on your Android device.
                </p>
                <a
                  href="https://play.google.com/store/apps/details?id=com.librio"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2 w-full"
                >
                  Get on Google Play
                  <ArrowRight className="w-5 h-5" />
                </a>
                <p className="text-sm text-gray-500 mt-4">Requires Android 8.0 or later</p>
              </div>
            </div>
          )}

          {/* Web Tab */}
          {activeTab === 'web' && (
            <div className="bg-white rounded-3xl p-8 md:p-12 border border-gray-100 shadow-sm text-center max-w-2xl mx-auto">
              <div className="w-16 h-16 rounded-2xl bg-librio-gradient flex items-center justify-center mx-auto mb-6">
                <Globe className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-2xl font-bold text-gray-900 mb-3">Access Librio Online</h3>
              <p className="text-gray-600 mb-8 max-w-md mx-auto">
                Use Librio directly in your web browser - no installation required. Works on Chrome, Firefox, Safari, and Edge.
              </p>
              <Link
                href="/login"
                className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2"
              >
                Open Web Version
                <ArrowRight className="w-5 h-5" />
              </Link>
            </div>
          )}

          {/* Desktop Tab */}
          {activeTab === 'desktop' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Windows */}
              <div className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm hover:shadow-lg transition-shadow">
                <div className="w-14 h-14 rounded-2xl bg-[#0078D4] flex items-center justify-center mb-6">
                  <svg className="w-7 h-7 text-white" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.9-1.801"/>
                  </svg>
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Windows</h3>
                <p className="text-gray-600 mb-6">
                  Download Librio for Windows and study from your desktop or laptop.
                </p>
                <a
                  href="/downloads/librio-windows.exe"
                  className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2 w-full"
                >
                  Download for Windows
                  <ArrowRight className="w-5 h-5" />
                </a>
                <p className="text-sm text-gray-500 mt-4">Windows 10 or later</p>
              </div>

              {/* macOS */}
              <div className="bg-white rounded-3xl p-8 border border-gray-100 shadow-sm hover:shadow-lg transition-shadow">
                <div className="w-14 h-14 rounded-2xl bg-gray-900 flex items-center justify-center mb-6">
                  <Apple className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">macOS</h3>
                <p className="text-gray-600 mb-6">
                  Download Librio for macOS and study from your Mac.
                </p>
                <a
                  href="/downloads/librio-macos.dmg"
                  className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2 w-full"
                >
                  Download for macOS
                  <ArrowRight className="w-5 h-5" />
                </a>
                <p className="text-sm text-gray-500 mt-4">macOS 10.14 or later</p>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Why Download */}
      <section className="py-20 px-6 md:px-12 bg-[#F8FAFC]">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Why download Librio?
            </h2>
            <p className="text-lg text-gray-600">
              Everything you need to learn smarter, right in your pocket.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-14 h-14 rounded-2xl bg-librio-purple/10 flex items-center justify-center mx-auto mb-6 text-librio-purple">
                <WifiOff className="w-7 h-7" />
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">Works Offline</h3>
              <p className="text-gray-600 text-sm leading-relaxed">Study anywhere - no internet connection required.</p>
            </div>
            <div className="text-center">
              <div className="w-14 h-14 rounded-2xl bg-librio-purple/10 flex items-center justify-center mx-auto mb-6 text-librio-purple">
                <Sparkles className="w-7 h-7" />
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">AI-Powered</h3>
              <p className="text-gray-600 text-sm leading-relaxed">Tutor, flashcards, quizzes, and summaries powered by on-device AI.</p>
            </div>
            <div className="text-center">
              <div className="w-14 h-14 rounded-2xl bg-librio-purple/10 flex items-center justify-center mx-auto mb-6 text-librio-purple">
                <Check className="w-7 h-7" />
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">Free to Start</h3>
              <p className="text-gray-600 text-sm leading-relaxed">Core features are free. Premium plans available for advanced tools.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 pt-16 pb-8 border-t border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-8">
            <Link href="/" className="flex items-center gap-2">
              <Image
                src="/images/Logo-Text.png"
                alt="Librio"
                width={100}
                height={32}
              />
            </Link>
            <div className="flex gap-8 text-sm text-gray-600">
              <Link href="/privacy" className="hover:text-white transition">
                Privacy Policy
              </Link>
              <Link href="/terms" className="hover:text-white transition">
                Terms of Service
              </Link>
              <a href="mailto:support@librio.com" className="hover:text-white transition">
                Contact
              </a>
            </div>
            <p className="text-sm text-gray-500">
              &copy; 2026 Librio. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
