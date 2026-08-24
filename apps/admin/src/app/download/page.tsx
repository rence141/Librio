'use client';

import Image from 'next/image';
import Link from 'next/link';
import { Apple, Play, Mail, Shield, Zap } from 'lucide-react';

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-gray-100 flex flex-col">
      {/* Navigation */}
      <nav className="bg-white shadow-sm sticky top-0 z-50">
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
            <Link href="/features" className="text-gray-600 hover:text-gray-900 font-medium">
              Features
            </Link>
            <Link href="/how-it-works" className="text-gray-600 hover:text-gray-900 font-medium">
              How It Works
            </Link>
            <Link href="/faq" className="text-gray-600 hover:text-gray-900 font-medium">
              FAQ
            </Link>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/login" className="text-gray-600 hover:text-gray-900 font-medium">
              Sign In
            </Link>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center px-6 py-32">
        <div className="max-w-6xl w-full flex items-center gap-20">
          {/* Left: Phone Mockup */}
          <div className="flex-1 flex justify-center">
            <div className="w-80 h-96 bg-gradient-to-br from-yellow-600 to-yellow-300 rounded-3xl shadow-2xl flex items-center justify-center">
              <div className="text-white text-center">
                <p className="text-sm">[Phone mockup image]</p>
              </div>
            </div>
          </div>

          {/* Right: Content */}
          <div className="flex-1">
            <h1 className="text-6xl font-bold mb-6 text-black">Get the App NOW</h1>
            
            <p className="text-2xl text-gray-700 mb-8 leading-relaxed font-semibold">
              Your AI study companion in your pocket.
            </p>
            
            <p className="text-lg text-gray-600 mb-10 leading-relaxed">
              Chat with Claude, study offline, generate flashcards. Get instant answers to any question, anytime, anywhere.
            </p>
            
            <div className="flex gap-4 flex-wrap">
              <a 
                href="https://apps.apple.com/" 
                className="px-8 py-3 bg-black text-white font-bold rounded-lg hover:bg-gray-800 transition flex items-center gap-2"
              >
                <Apple size={20} />
                Download on App Store
              </a>
              <a 
                href="https://play.google.com/" 
                className="px-8 py-3 bg-black text-white font-bold rounded-lg hover:bg-gray-800 transition flex items-center gap-2"
              >
                <Play size={20} />
                Get it on Google Play
              </a>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="font-bold mb-4">Product</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><Link href="/features" className="hover:text-white">Features</Link></li>
                <li><Link href="/how-it-works" className="hover:text-white">How It Works</Link></li>
                <li><Link href="/download" className="hover:text-white">Download</Link></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">Company</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><Link href="/about" className="hover:text-white">About</Link></li>
                <li><Link href="/blog" className="hover:text-white">Blog</Link></li>
                <li><Link href="/careers" className="hover:text-white">Careers</Link></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">Legal</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><Link href="/privacy" className="hover:text-white">Privacy Policy</Link></li>
                <li><Link href="/terms" className="hover:text-white">Terms of Service</Link></li>
                <li><Link href="/contact" className="hover:text-white">Contact</Link></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">Connect</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><a href="#" className="hover:text-white flex items-center gap-2"><Mail size={16} /> Email</a></li>
                <li><a href="#" className="hover:text-white">Twitter</a></li>
                <li><a href="#" className="hover:text-white">LinkedIn</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 flex items-center justify-between">
            <p className="text-sm text-gray-400">© 2026 Librio. All rights reserved.</p>
            <div className="flex items-center gap-6 text-sm text-gray-400">
              <a href="#" className="hover:text-white">Privacy</a>
              <a href="#" className="hover:text-white">Terms</a>
              <a href="#" className="hover:text-white">Cookies</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
