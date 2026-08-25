'use client';

import Image from 'next/image';
import Link from 'next/link';
import { Apple, Play } from 'lucide-react';

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-stone-200 flex flex-col">
      {/* Navigation */}
      <nav className="bg-stone-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <Image
              src="/images/Logo-Text.png"
              alt="Librio"
              width={120}
              height={40}
              priority
            />
          </Link>
          <div className="hidden md:flex items-center gap-8">
            <Link href="/features" className="text-gray-700 hover:text-black font-medium">
              Features
            </Link>
            <Link href="/how-it-works" className="text-gray-700 hover:text-black font-medium">
              How It Works
            </Link>
            <Link href="/faq" className="text-gray-700 hover:text-black font-medium">
              FAQ
            </Link>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center px-4 sm:px-6 py-12 sm:py-20">
        <div className="max-w-6xl w-full flex flex-col md:flex-row items-center gap-8 md:gap-16">
          {/* Left: Gradient Box with Phone */}
          <div className="flex-1 flex justify-center w-full md:w-auto">
            <div className="relative w-64 h-80 sm:w-80 sm:h-96 rounded-3xl overflow-hidden shadow-2xl bg-gradient-to-br from-purple-600 via-purple-400 to-cyan-300 flex items-center justify-center">
              <Image
                src="/images/Phone-librio.png"
                alt="Librio App"
                fill
                priority
                className="object-cover"
              />
            </div>
          </div>

          {/* Right: Content */}
          <div className="flex-1 w-full text-center md:text-left">
            <h1 className="text-4xl sm:text-5xl md:text-7xl font-black mb-4 sm:mb-8 text-black leading-tight">Get The App</h1>
            
            <p className="text-lg sm:text-xl md:text-2xl font-bold text-black mb-4 sm:mb-6 leading-relaxed">
              Ready to transform your study experience?
            </p>
            
            <p className="text-base sm:text-lg text-gray-800 mb-8 sm:mb-12 leading-relaxed font-medium">
              Chat with Claude, study offline, and generate flashcards instantly. Get answers to any question, anytime, anywhere. Set up in seconds and start learning smarter today.
            </p>
            
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center md:justify-start">
              <a 
                href="https://apps.apple.com/" 
                className="px-6 sm:px-8 py-3 sm:py-4 bg-black text-white font-bold rounded-xl hover:bg-gray-900 transition flex items-center justify-center sm:justify-start gap-2 text-base sm:text-lg"
              >
                <Apple size={20} className="sm:w-6 sm:h-6" />
                App Store
              </a>
              <a 
                href="https://play.google.com/" 
                className="px-6 sm:px-8 py-3 sm:py-4 bg-black text-white font-bold rounded-xl hover:bg-gray-900 transition flex items-center justify-center sm:justify-start gap-2 text-base sm:text-lg"
              >
                <Play size={20} className="sm:w-6 sm:h-6" />
                Google Play
              </a>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
