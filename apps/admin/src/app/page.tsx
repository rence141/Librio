'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';

export default function LandingPage() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

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
  ];

  const benefits = [
    {
      icon: '💡',
      title: 'Understand',
      description: 'Break difficult topics into simple, understandable explanations.',
    },
    {
      icon: '✍️',
      title: 'Practice',
      description: 'Generate questions and quizzes from your study materials.',
    },
    {
      icon: '🧠',
      title: 'Remember',
      description: 'Use flashcards and review tools to reinforce what you\'ve learned.',
    },
    {
      icon: '📚',
      title: 'Organize',
      description: 'Keep your study materials and learning tools together.',
    },
  ];

  const features = [
    {
      icon: '🤖',
      title: 'AI Tutor',
      description: 'Ask questions and get clear, student-friendly explanations.',
      image: '/images/AI-Tutor.jpg',
    },
    {
      icon: '🎴',
      title: 'Smart Flashcards',
      description: 'Turn lessons and study materials into flashcards for review.',
      image: '/images/Flashcard-img.jpg',
    },
    {
      icon: '❓',
      title: 'AI Quizzes',
      description: 'Generate practice questions based on your learning materials.',
      image: '/images/AI-Quizzes.jpg',
    },
    {
      icon: '📄',
      title: 'Smart Summaries',
      description: 'Turn long study materials into concise explanations.',
    },
    {
      icon: '📁',
      title: 'Study Materials',
      description: 'Upload and organize materials that Librio can work with.',
    },
    {
      icon: '💬',
      title: 'AI Chat',
      description: 'Have an ongoing conversation with your personal study companion.',
    },
  ];

  const steps = [
    {
      number: '01',
      title: 'Add Your Material',
      description: 'Upload your notes, documents, or study content.',
    },
    {
      number: '02',
      title: 'Learn With Librio',
      description: 'Ask questions, generate explanations, summaries, flashcards, and quizzes.',
    },
    {
      number: '03',
      title: 'Review & Remember',
      description: 'Practice what you\'ve learned and reinforce your knowledge.',
    },
  ];

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white border-b border-gray-100">
        <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
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
            <a href="#features" className="text-gray-600 hover:text-gray-900 transition">
              Features
            </a>
            <a href="#how-it-works" className="text-gray-600 hover:text-gray-900 transition">
              How It Works
            </a>
            <a href="#faq" className="text-gray-600 hover:text-gray-900 transition">
              FAQ
            </a>
            <Link href="/login" className="text-gray-600 hover:text-gray-900 transition">
              Log In
            </Link>
            <Link
              href="/signup"
              className="ai-button ai-button-sm"
            >
              Get Started
            </Link>
          </div>
          <div className="md:hidden">
            <Link
              href="/signup"
              className="ai-button ai-button-sm"
            >
              Get Started
            </Link>
          </div>
        </nav>
      </header>

      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 md:py-32">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-8">
            <div>
              <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
                Your AI Study Companion.
              </h1>
              <p className="text-xl text-gray-600 leading-relaxed">
                Learn smarter with AI-powered explanations, flashcards, quizzes, summaries, and personalized study tools — all in one place.
              </p>
            </div>
            <div className="flex gap-4 flex-wrap">
              <Link
                href="/signup"
                className="ai-button ai-button-lg"
              >
                ✨ Get Started Free
              </Link>
              <a
                href="#how-it-works"
                className="ai-button-outline ai-button-lg"
              >
                See How It Works
              </a>
            </div>
            <p className="text-sm text-gray-500">
              No credit card required. Start learning in seconds.
            </p>
          </div>
          <div className="relative h-96 rounded-2xl overflow-hidden">
            <Image
              src="/images/Hero-Image.jpg"
              alt="Librio App Interface"
              fill
              className="object-cover"
              priority
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent"></div>
            <div className="absolute inset-0 bg-librio-gradient opacity-10"></div>
          </div>
        </div>
      </section>

      {/* Benefits Section */}
      <section className="bg-gray-50 py-20 md:py-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
              Everything you need to study smarter.
            </h2>
            <p className="text-xl text-gray-600">
              Librio transforms how you learn by combining AI intelligence with proven study techniques.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {benefits.map((benefit, index) => (
              <div key={index} className="bg-white rounded-xl p-8 border border-gray-200 hover:border-gray-300 transition">
                <div className="text-4xl mb-4">{benefit.icon}</div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{benefit.title}</h3>
                <p className="text-gray-600">{benefit.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 md:py-32">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Powerful features for every learner.
          </h2>
          <p className="text-xl text-gray-600">
            Everything you need to master any subject.
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <div key={index} className="ai-feature group">
              {feature.image && (
                <div className="relative h-48 mb-4 rounded-lg overflow-hidden">
                  <Image
                    src={feature.image}
                    alt={feature.title}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                </div>
              )}
              <div className="ai-feature-header">
                <div className="text-3xl">{feature.icon}</div>
                <h3 className="ai-feature-title">{feature.title}</h3>
              </div>
              <p className="text-gray-700">{feature.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="bg-gray-50 py-20 md:py-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
              From study material to understanding.
            </h2>
            <p className="text-xl text-gray-600">
              Three simple steps to smarter learning.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {steps.map((step, index) => (
              <div key={index} className="relative">
                {index < steps.length - 1 && (
                  <div className="hidden md:block absolute top-20 left-full w-8 h-0.5 bg-gradient-to-r from-librio-purple to-librio-cyan"></div>
                )}
                <div className="bg-white rounded-xl p-8 border border-gray-200">
                  <div className="text-4xl font-bold bg-librio-gradient bg-clip-text text-transparent mb-4">
                    {step.number}
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-3">{step.title}</h3>
                  <p className="text-gray-600">{step.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Differentiation */}
      <section className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-20 md:py-32">
        <div className="text-center">
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            AI that helps you learn, not just gives you answers.
          </h2>
          <p className="text-xl text-gray-600 mb-8 leading-relaxed">
            Librio is designed around how students actually learn. Rather than just answering questions, Librio guides you through understanding, practice, and active recall — the proven methods that build lasting knowledge.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-12">
            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
              <div className="text-3xl mb-3">🎯</div>
              <h3 className="font-bold text-gray-900 mb-2">Personalized Learning</h3>
              <p className="text-sm text-gray-600">Adapts to your pace and learning style.</p>
            </div>
            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
              <div className="text-3xl mb-3">📊</div>
              <h3 className="font-bold text-gray-900 mb-2">Track Progress</h3>
              <p className="text-sm text-gray-600">See what you've learned and what to focus on.</p>
            </div>
            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
              <div className="text-3xl mb-3">🔄</div>
              <h3 className="font-bold text-gray-900 mb-2">Active Recall</h3>
              <p className="text-sm text-gray-600">Practice retrieval to strengthen memory.</p>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="bg-gray-50 py-20 md:py-32">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
              Frequently asked questions.
            </h2>
            <p className="text-xl text-gray-600">
              Everything you need to know about Librio.
            </p>
          </div>
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
                {openFaq === index && (
                  <div className="px-6 py-4 bg-gray-50 border-t border-gray-200">
                    <p className="text-gray-700">{item.answer}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="bg-gradient-to-br from-gray-50 to-gray-100 py-20 md:py-32">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="absolute inset-0 bg-librio-gradient opacity-5 blur-3xl rounded-full"></div>
          <div className="relative">
            <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
              Study smarter with Librio.
            </h2>
            <p className="text-xl text-gray-600 mb-8">
              Your AI-powered study companion is ready to help.
            </p>
            <Link
              href="/signup"
              className="ai-button ai-button-lg inline-block"
            >
              ✨ Get Started Free
            </Link>
            <p className="text-sm text-gray-500 mt-6">
              No credit card required. Start learning in seconds.
            </p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
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
