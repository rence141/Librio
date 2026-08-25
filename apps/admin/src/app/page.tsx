'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { Lightbulb, CheckCircle, Settings, Folder } from 'lucide-react';

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
      icon: Lightbulb,
      title: 'Understand',
      description: 'Break difficult topics into simple, understandable explanations.',
    },
    {
      icon: CheckCircle,
      title: 'Practice',
      description: 'Generate questions and quizzes from your study materials.',
    },
    {
      icon: Settings,
      title: 'Remember',
      description: 'Use flashcards and review tools to reinforce what you\'ve learned.',
    },
    {
      icon: Folder,
      title: 'Organize',
      description: 'Keep your study materials and learning tools together.',
    },
  ];

  const features = [
    {
      icon: '→',
      title: 'AI Tutor',
      description: 'Ask questions and get clear, student-friendly explanations.',
      image: '/images/AI-Tutor.jpg',
    },
    {
      icon: '→',
      title: 'Smart Flashcards',
      description: 'Turn lessons and study materials into flashcards for review.',
      image: '/images/Flashcard-img.jpg',
    },
    {
      icon: '→',
      title: 'AI Quizzes',
      description: 'Generate practice questions based on your learning materials.',
      image: '/images/AI-Quizzes.jpg',
    },
    {
      icon: '→',
      title: 'Smart Summaries',
      description: 'Turn long study materials into concise explanations.',
    },
    {
      icon: '→',
      title: 'Study Materials',
      description: 'Upload and organize materials that Librio can work with.',
    },
    {
      icon: '→',
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
      <header className="fixed top-0 inset-x-0 bg-white/80 backdrop-blur-md z-50 border-b border-gray-100">
        <div className="flex justify-between items-center h-14 sm:h-16 px-3 sm:px-4">
            {/* Logo */}
            <Link href="/" className="flex-shrink-0 flex items-center gap-2 cursor-pointer">
              <Image
                src="/images/Logo-Text.png"
                alt="Librio"
                width={100}
                height={32}
                priority
                className="w-24 sm:w-32 h-auto"
              />
            </Link>
            {/* Desktop Navigation */}
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
            {/* CTA - pinned to right edge */}
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
            {/* Mobile CTA */}
            <div className="md:hidden">
              <Link href="/download" className="ai-button ai-button-sm rounded-full text-xs sm:text-sm px-3 sm:px-4 py-2">
                Get the app
              </Link>
            </div>
          </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden min-h-screen flex items-center justify-center pt-16 sm:pt-20" style={{backgroundImage: 'url(/images/Hero-Image.jpg)', backgroundSize: 'cover', backgroundPosition: 'center'}}>
        <div className="absolute inset-0 bg-black/40 z-0"></div>
        <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center py-12 sm:py-20">
          <h1 className="text-3xl sm:text-4xl lg:text-6xl font-extrabold text-white tracking-tight leading-tight mb-4 sm:mb-6">
            Your AI Study <br className="hidden sm:block" /> Companion
          </h1>
          <p className="mt-2 sm:mt-4 max-w-2xl mx-auto text-base sm:text-lg lg:text-xl text-gray-100 font-medium mb-6 sm:mb-10">
            Master any subject with personalized explanations, smart practice, and effortless organization. Learn smarter, not harder.
          </p>
          <Link
            href="/download"
            className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center hover:scale-105 transform transition-all duration-200 text-sm sm:text-base"
          >
            Get Started
          </Link>
        </div>
      </section>

      {/* Benefits Section */}
      <section className="py-12 sm:py-20 bg-librio-purple/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10 sm:mb-16">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-gray-900">Everything you need to study smarter</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
            {benefits.map((benefit, index) => {
              const IconComponent = benefit.icon;
              return (
                <div key={index} className="bg-white rounded-2xl p-8 shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] hover:shadow-[0_8px_30px_-4px_rgba(0,0,0,0.1)] transition-shadow border border-gray-100">
                  <div className="w-12 h-12 rounded-xl bg-librio-purple/10 flex items-center justify-center mb-6 text-librio-purple">
                    <IconComponent size={24} />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-3">{benefit.title}</h3>
                  <p className="text-gray-600 text-sm leading-relaxed">{benefit.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Features Section - Asymmetric Bento Grid */}
      <section id="features" className="py-12 sm:py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12 sm:mb-20">
            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-gray-900">Powerful tools that simplify your life</h2>
          </div>

          {/* Desktop/Tablet: Asymmetric CSS Grid */}
          <div className="hidden lg:block" style={{display: 'grid', gridTemplateColumns: '2fr 1fr', gridTemplateRows: '1fr 1fr', gap: '20px'}}>
            {/* Left: Large AI Tutor Card (column 1, spans both rows) */}
            <div className="group rounded-3xl overflow-hidden bg-gray-900 text-white shadow-2xl relative" style={{gridColumn: '1', gridRow: '1 / 3', minHeight: '800px'}}>
              {/* Background Image - fills entire card */}
              <div className="absolute inset-0 overflow-hidden">
                {features[0].image && (
                  <Image
                    src={features[0].image}
                    alt={features[0].title}
                    fill
                    className="object-cover opacity-100 group-hover:opacity-100 transition-opacity duration-300"
                    style={{objectPosition: 'center'}}
                  />
                )}
              </div>
              
              {/* Gradient overlay for text readability */}
              <div className="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/40 to-transparent pointer-events-none"></div>
              
              {/* Content - independent layer, never cropped */}
              <div className="relative z-10 h-full flex flex-col justify-end p-10">
                <div className="max-w-xs">
                  <h3 className="text-4xl font-bold mb-4 flex items-center gap-3">
                    {features[0].title}
                    <span className="text-2xl bg-librio-gradient bg-clip-text text-transparent">✦</span>
                  </h3>
                  <p className="text-gray-100 leading-relaxed text-lg mb-6">{features[0].description}</p>
                  <Link href="/download" className="inline-flex items-center text-white hover:text-librio-cyan transition-colors font-semibold">
                    Learn more <span className="ml-2">→</span>
                  </Link>
                </div>
              </div>
            </div>

            {/* Top Right: Smart Flashcards (column 2, row 1) */}
            <div className="group rounded-3xl overflow-hidden bg-gray-900 text-white shadow-2xl relative" style={{gridColumn: '2', gridRow: '1'}}>
              {/* Background Image - fills entire card */}
              <div className="absolute inset-0 overflow-hidden">
                {features[2].image && (
                  <Image
                    src={features[2].image}
                    alt={features[2].title}
                    fill
                    className="object-cover opacity-100 group-hover:opacity-100 transition-opacity duration-300"
                    style={{objectPosition: 'center'}}
                  />
                )}
              </div>
              
              {/* Gradient overlay for text readability */}
              <div className="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/60 to-transparent pointer-events-none"></div>
              
              {/* Content - independent layer, never cropped */}
              <div className="relative z-10 h-full flex flex-col justify-end p-6">
                <div className="max-w-xs">
                  <h3 className="text-2xl font-bold mb-2">{features[2].title}</h3>
                  <p className="text-gray-200 leading-relaxed text-sm mb-4">{features[2].description}</p>
                  <Link href="/download" className="inline-flex items-center text-white hover:text-librio-cyan transition-colors text-sm font-semibold">
                    Learn more <span className="ml-2">→</span>
                  </Link>
                </div>
              </div>
            </div>

            {/* Bottom Right: AI Quizzes (column 2, row 2) */}
            <div className="group rounded-3xl overflow-hidden bg-gray-900 text-white shadow-2xl relative" style={{gridColumn: '2', gridRow: '2'}}>
              {/* Background Image - fills entire card */}
              <div className="absolute inset-0 overflow-hidden">
                {features[1].image && (
                  <Image
                    src={features[1].image}
                    alt={features[1].title}
                    fill
                    className="object-cover opacity-100 group-hover:opacity-100 transition-opacity duration-300"
                    style={{objectPosition: 'center'}}
                  />
                )}
              </div>
              
              {/* Gradient overlay for text readability */}
              <div className="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/60 to-transparent pointer-events-none"></div>
              
              {/* Content - independent layer, never cropped */}
              <div className="relative z-10 h-full flex flex-col justify-end p-6">
                <div className="max-w-xs">
                  <h3 className="text-2xl font-bold mb-2">{features[1].title}</h3>
                  <p className="text-gray-200 leading-relaxed text-sm mb-4">{features[1].description}</p>
                  <Link href="/download" className="inline-flex items-center text-white hover:text-librio-cyan transition-colors text-sm font-semibold">
                    Learn more <span className="ml-2">→</span>
                  </Link>
                </div>
              </div>
            </div>
          </div>

          {/* Mobile: Stacked Layout */}
          <div className="lg:hidden space-y-3">
            {features.slice(0, 3).map((feature, index) => (
              <div key={index} className="group rounded-2xl overflow-hidden bg-gray-900 text-white shadow-lg relative h-56 sm:h-64">
                {/* Background Image - fills entire card */}
                <div className="absolute inset-0 overflow-hidden">
                  {feature.image && (
                    <Image
                      src={feature.image}
                      alt={feature.title}
                      fill
                      className="object-cover opacity-100 group-hover:opacity-100 transition-opacity duration-300"
                      style={{objectPosition: 'center'}}
                    />
                  )}
                </div>
                
                {/* Gradient overlay for text readability */}
                <div className="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/60 to-transparent pointer-events-none"></div>
                
                {/* Content - independent layer, never cropped */}
                <div className="relative z-10 h-full flex flex-col justify-end p-3 sm:p-5">
                  <div className="w-full">
                    <h3 className="text-lg sm:text-xl font-bold mb-1 sm:mb-2 flex items-center gap-2">
                      {feature.title}
                      {index === 0 && <span className="text-base bg-librio-gradient bg-clip-text text-transparent">✦</span>}
                    </h3>
                    <p className="text-gray-200 leading-tight text-xs sm:text-sm mb-2">{feature.description}</p>
                    <Link href="/download" className="inline-flex items-center text-white hover:text-librio-cyan transition-colors text-xs font-semibold">
                      Learn more <span className="ml-1">→</span>
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
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
          <h2 className="text-4xl md:text-5xl font-bold bg-librio-gradient bg-clip-text text-transparent mb-6">
            AI that helps you learn, not just gives you answers.
          </h2>
          <p className="text-xl text-gray-600 mb-8 leading-relaxed">
            Librio is designed around how students actually learn. Rather than just answering questions, Librio guides you through understanding, practice, and active recall — the proven methods that build lasting knowledge.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-12">
            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
              <h3 className="font-bold text-gray-900 mb-2">Personalized Learning</h3>
              <p className="text-sm text-gray-600">Adapts to your pace and learning style.</p>
            </div>
            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
              <h3 className="font-bold text-gray-900 mb-2">Track Progress</h3>
              <p className="text-sm text-gray-600">See what you've learned and what to focus on.</p>
            </div>
            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
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
              href="/download"
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
      <footer className="bg-gray-900 pt-16 pb-8 border-t border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-8 mb-12">
            <div className="col-span-2 lg:col-span-1">
              <div className="flex items-center gap-2 mb-6">
                <Image
                  src="/images/Logo-Text.png"
                  alt="Librio"
                  width={100}
                  height={32}
                />
              </div>
              <p className="text-gray-400 text-sm">Your intelligent companion for smarter, faster learning.</p>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Product Links</h4>
              <ul className="space-y-3">
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">Chat</a></li>
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">Materials</a></li>
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">Flashcards</a></li>
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">Quizzes</a></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Company</h4>
              <ul className="space-y-3">
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">About</a></li>
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">Contact Us</a></li>
                <li><a className="text-gray-400 hover:text-white transition-colors text-sm" href="#">Careers</a></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Legal</h4>
              <ul className="space-y-3">
                <li><Link className="text-gray-400 hover:text-white transition-colors text-sm" href="/privacy">Privacy Policy</Link></li>
                <li><Link className="text-gray-400 hover:text-white transition-colors text-sm" href="/terms">Terms of Service</Link></li>
              </ul>
            </div>
          </div>
          <div className="pt-8 border-t border-gray-800 flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm text-gray-500">© 2026 Librio. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
