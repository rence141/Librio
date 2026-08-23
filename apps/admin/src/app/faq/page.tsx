'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';

export default function FAQPage() {
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const faqItems = [
    {
      question: 'What is Librio?',
      answer: 'Librio is an AI-powered study companion designed to help students learn more effectively. It transforms your study materials into interactive learning experiences with AI-generated explanations, flashcards, quizzes, and personalized study tools.',
    },
    {
      question: 'Is Librio free?',
      answer: 'Yes! Librio offers a free tier with core features. We also offer premium plans with advanced capabilities for students who want more personalized learning experiences.',
    },
    {
      question: 'Can I upload my study materials?',
      answer: 'Absolutely. You can upload notes, documents, PDFs, and other study materials. Librio will analyze them and help you create flashcards, summaries, quizzes, and more.',
    },
    {
      question: 'Can Librio generate flashcards and quizzes?',
      answer: 'Yes. Librio uses AI to automatically generate flashcards and practice questions from your study materials, saving you time and helping you practice actively.',
    },
    {
      question: 'Does Librio work on mobile?',
      answer: 'Yes, Librio is available on iOS and Android, so you can study anywhere, anytime. Your materials and progress sync across all devices.',
    },
    {
      question: 'Is my study data private?',
      answer: 'Your privacy is important to us. All your study materials and learning data are encrypted and secure. We never share your data with third parties.',
    },
    {
      question: 'How does the AI Tutor work?',
      answer: 'The AI Tutor uses advanced language models to provide clear, student-friendly explanations for any topic. It adapts to your learning style and pace, and provides context-aware answers to your specific questions.',
    },
    {
      question: 'What are Smart Flashcards?',
      answer: 'Smart Flashcards are AI-generated review cards created from your study materials. They use spaced repetition to help you remember information more effectively over time.',
    },
    {
      question: 'How do AI Quizzes help me learn?',
      answer: 'AI Quizzes generate practice questions directly from your study materials. They help you identify gaps in your knowledge and focus your studying on areas that need the most attention.',
    },
    {
      question: 'Can I use Librio offline?',
      answer: 'Librio offers offline capabilities for core features. You can review flashcards and previously generated content without an internet connection. Your progress syncs when you reconnect.',
    },
  ];

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
            <Link href="/faq" className="text-sm font-medium text-librio-purple transition-colors">
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
      <section className="pt-32 pb-16 bg-librio-purple/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-6">
            Frequently asked questions.
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Everything you need to know about Librio.
          </p>
        </div>
      </section>

      {/* FAQ List */}
      <section className="py-20">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="space-y-4">
            {faqItems.map((item, index) => (
              <div key={index} className="border border-gray-200 rounded-lg overflow-hidden bg-white">
                <button
                  onClick={() => setOpenFaq(openFaq === index ? null : index)}
                  className="w-full px-6 py-4 flex justify-between items-center hover:bg-gray-50 transition"
                >
                  <span className="font-semibold text-gray-900 text-left">{item.question}</span>
                  <svg
                    className={`w-5 h-5 text-gray-600 transition-transform flex-shrink-0 ${
                      openFaq === index ? 'rotate-180' : ''
                    }`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                  </svg>
                </button>
                <div className={`overflow-hidden transition-all duration-300 ${openFaq === index ? 'max-h-96' : 'max-h-0'}`}>
                  <div className="px-6 py-4 bg-gray-50 border-t border-gray-200">
                    <p className="text-gray-700">{item.answer}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-librio-purple/5">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl font-bold text-gray-900 mb-6">
            Still have questions?
          </h2>
          <p className="text-gray-600 mb-8">
            Get the app and start learning with Librio today.
          </p>
          <Link
            href="/download"
            className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center hover:scale-105 transform transition-all duration-200"
          >
            Get the app
          </Link>
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
              <Link href="/privacy" className="hover:text-gray-900 transition">
                Privacy Policy
              </Link>
              <Link href="/terms" className="hover:text-gray-900 transition">
                Terms of Service
              </Link>
              <a href="mailto:support@librio.com" className="hover:text-gray-900 transition">
                Contact
              </a>
            </div>
            <p className="text-sm text-gray-500">
              © 2026 Librio. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
