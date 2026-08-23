'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  Lightbulb,
  Layers,
  HelpCircle,
  FileText,
  FolderOpen,
  MessageSquare,
  WifiOff,
  Shield,
  Lock,
  Sparkles,
  ArrowRight,
  Check,
} from 'lucide-react';

export default function FeaturesPage() {
  const [activeTab, setActiveTab] = useState(0);

  const featureOverview = [
    {
      icon: Lightbulb,
      title: 'AI Tutor',
      description: 'Clear, student-friendly explanations for any topic.',
    },
    {
      icon: Layers,
      title: 'Smart Flashcards',
      description: 'Auto-generated review cards with spaced repetition.',
    },
    {
      icon: HelpCircle,
      title: 'AI Quizzes',
      description: 'Practice questions from your own materials.',
    },
    {
      icon: FileText,
      title: 'Smart Summaries',
      description: 'Condense long materials into key points.',
    },
    {
      icon: FolderOpen,
      title: 'Study Materials',
      description: 'Upload and organize notes, PDFs, and documents.',
    },
    {
      icon: MessageSquare,
      title: 'AI Chat',
      description: 'Ongoing conversation with context awareness.',
    },
  ];

  const detailedFeatures = [
    {
      icon: Lightbulb,
      title: 'AI Tutor',
      tagline: 'A tutor that never sleeps',
      description:
        'Ask questions about difficult topics and get clear, student-friendly explanations. Librio's AI Tutor adapts to your learning style and pace, providing context-aware answers to your specific questions.',
      benefits: [
        'Adapts to your learning style and pace',
        'Context-aware answers based on your materials',
        'Available 24/7 — no scheduling required',
      ],
      image: '/images/AI-Tutor.jpg',
      imageAlt: 'AI Tutor explaining a concept',
    },
    {
      icon: Layers,
      title: 'Smart Flashcards',
      tagline: 'Remember more with less effort',
      description:
        'Turn your study materials into flashcards instantly. Smart Flashcards use spaced repetition to surface the right cards at the right time, so you reinforce what matters before you forget it.',
      benefits: [
        'Auto-generated from your uploaded materials',
        'Spaced repetition optimizes review timing',
        'Review anywhere — even offline',
      ],
      image: '/images/Flashcard-img.jpg',
      imageAlt: 'Smart Flashcards review interface',
    },
    {
      icon: HelpCircle,
      title: 'AI Quizzes',
      tagline: 'Test what you know, find what you don't',
      description:
        'Practice with questions generated directly from your study materials. AI Quizzes identify gaps in your knowledge and help you focus your studying on the areas that need the most attention.',
      benefits: [
        'Questions sourced from your own materials',
        'Identifies knowledge gaps automatically',
        'Track progress over time',
      ],
      image: '/images/AI-Quizzes.jpg',
      imageAlt: 'AI Quizzes practice interface',
    },
  ];

  const tabFeatures = [
    {
      icon: FileText,
      title: 'Smart Summaries',
      description:
        'Turn long study materials into concise, digestible explanations. Smart Summaries extract the key points from your notes, textbooks, and documents so you can review them quickly.',
    },
    {
      icon: FolderOpen,
      title: 'Study Materials',
      description:
        'Upload and organize materials that Librio can work with. Support for notes, documents, PDFs, and more. Keep all your study content in one central, organized place.',
    },
    {
      icon: MessageSquare,
      title: 'AI Chat',
      description:
        'Have an ongoing conversation with your personal study companion. AI Chat remembers context from your previous interactions, making it feel like talking to a knowledgeable tutor who knows your learning journey.',
    },
  ];

  const useCases = [
    {
      title: 'Students',
      description: 'Break down complex topics, prepare for exams, and retain more with active recall.',
    },
    {
      title: 'Lifelong Learners',
      description: 'Explore new subjects at your own pace with a patient, knowledgeable companion.',
    },
    {
      title: 'Professionals',
      description: 'Stay sharp with quick summaries and practice — even during a commute.',
    },
  ];

  const trustItems = [
    {
      icon: WifiOff,
      title: 'Works Offline',
      description: 'The AI runs entirely on your device. Study on planes, trains, or anywhere without a connection.',
    },
    {
      icon: Lock,
      title: 'Private by Design',
      description: 'Your study materials stay on your device. No cloud uploads required for core features.',
    },
    {
      icon: Shield,
      title: 'Secure',
      description: 'Your data is encrypted and never shared with third parties.',
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
            <Link href="/features" className="text-sm font-medium text-librio-purple transition-colors">
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

      {/* 1. Hero Section */}
      <section className="pt-32 pb-20 px-6 md:px-12 overflow-hidden">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Left: Text */}
            <div className="text-center lg:text-left">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-librio-purple/10 mb-6">
                <Sparkles className="w-4 h-4 text-librio-purple" />
                <span className="text-sm font-medium text-librio-purple">AI-powered study companion</span>
              </div>
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-extrabold tracking-tight text-gray-900 mb-6 leading-[1.1]">
                Powerful tools that{' '}
                <span className="bg-librio-gradient bg-clip-text text-transparent">simplify your life</span>
              </h1>
              <p className="text-lg text-gray-600 mb-8 max-w-xl mx-auto lg:mx-0">
                Everything you need to master any subject — explanations, flashcards, quizzes, and summaries — all in one place. And it works offline.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                <Link
                  href="/download"
                  className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2 hover:scale-105 transform transition-all duration-200"
                >
                  Get the app
                  <ArrowRight className="w-5 h-5" />
                </Link>
                <Link
                  href="/how-it-works"
                  className="inline-flex items-center justify-center px-8 py-4 text-lg font-semibold rounded-full border border-gray-300 text-gray-700 hover:border-gray-900 hover:text-gray-900 transition-colors"
                >
                  See how it works
                </Link>
              </div>
            </div>
            {/* Right: Product preview */}
            <div className="relative">
              <div className="absolute inset-0 bg-librio-gradient opacity-10 blur-3xl rounded-full"></div>
              <div className="relative rounded-3xl overflow-hidden shadow-2xl border border-gray-200">
                <Image
                  src="/images/Hero-Image.jpg"
                  alt="Librio app interface"
                  width={800}
                  height={600}
                  className="w-full h-auto object-cover"
                  priority
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 2. Feature Overview Grid */}
      <section className="py-20 px-6 md:px-12 bg-[#F8FAFC]">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              One app. Everything you need.
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Six core tools designed to help you understand, practice, and remember.
            </p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {featureOverview.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <div
                  key={index}
                  className="bg-white rounded-2xl p-8 border border-gray-100 hover:shadow-lg hover:border-librio-purple/20 transition-all duration-300"
                >
                  <div className="w-12 h-12 rounded-xl bg-librio-purple/10 flex items-center justify-center mb-5 text-librio-purple">
                    <Icon className="w-6 h-6" />
                  </div>
                  <h3 className="text-lg font-bold text-gray-900 mb-2">{feature.title}</h3>
                  <p className="text-gray-600 text-sm leading-relaxed">{feature.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* 3. Detailed Feature Sections */}
      <section className="py-20 px-6 md:px-12">
        <div className="max-w-7xl mx-auto space-y-24">
          {detailedFeatures.map((feature, index) => {
            const Icon = feature.icon;
            const reversed = index % 2 === 1;
            return (
              <div
                key={index}
                className={`grid grid-cols-1 lg:grid-cols-2 gap-12 items-center ${
                  reversed ? 'lg:grid-flow-col-dense' : ''
                }`}
              >
                {/* Text */}
                <div className={reversed ? 'lg:col-start-2 lg:row-start-1' : ''}>
                  <div className="inline-flex items-center gap-2 mb-4">
                    <div className="w-10 h-10 rounded-lg bg-librio-gradient flex items-center justify-center text-white">
                      <Icon className="w-5 h-5" />
                    </div>
                    <span className="text-sm font-semibold text-librio-purple uppercase tracking-wide">
                      {feature.tagline}
                    </span>
                  </div>
                  <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                    {feature.title}
                  </h2>
                  <p className="text-lg text-gray-600 leading-relaxed mb-6">
                    {feature.description}
                  </p>
                  <ul className="space-y-3 mb-8">
                    {feature.benefits.map((benefit, bIndex) => (
                      <li key={bIndex} className="flex items-start gap-3">
                        <span className="flex-shrink-0 w-5 h-5 rounded-full bg-librio-purple/10 flex items-center justify-center mt-0.5">
                          <Check className="w-3 h-3 text-librio-purple" />
                        </span>
                        <span className="text-gray-700">{benefit}</span>
                      </li>
                    ))}
                  </ul>
                  <Link
                    href="/download"
                    className="inline-flex items-center gap-2 text-librio-purple font-semibold hover:gap-3 transition-all"
                  >
                    Try {feature.title}
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
                {/* Image */}
                <div className={reversed ? 'lg:col-start-1 lg:row-start-1' : ''}>
                  <div className="relative rounded-2xl overflow-hidden shadow-xl border border-gray-200">
                    <Image
                      src={feature.image}
                      alt={feature.imageAlt}
                      width={800}
                      height={600}
                      className="w-full h-auto object-cover"
                    />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* 4. Interactive Tabbed Section */}
      <section className="py-20 px-6 md:px-12 bg-[#F8FAFC]">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              More ways to learn
            </h2>
            <p className="text-lg text-gray-600">
              Explore the additional tools built into Librio.
            </p>
          </div>
          {/* Tabs */}
          <div className="flex flex-wrap justify-center gap-2 mb-10">
            {tabFeatures.map((tab, index) => {
              const Icon = tab.icon;
              return (
                <button
                  key={index}
                  onClick={() => setActiveTab(index)}
                  className={`inline-flex items-center gap-2 px-5 py-3 rounded-full text-sm font-semibold transition-all ${
                    activeTab === index
                      ? 'ai-button'
                      : 'bg-white text-gray-600 border border-gray-200 hover:border-librio-purple/30'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {tab.title}
                </button>
              );
            })}
          </div>
          {/* Tab Content */}
          <div className="bg-white rounded-3xl p-8 md:p-12 shadow-sm border border-gray-100">
            {tabFeatures.map((tab, index) => {
              const Icon = tab.icon;
              return activeTab === index ? (
                <div key={index} className="text-center max-w-2xl mx-auto">
                  <div className="w-16 h-16 rounded-2xl bg-librio-gradient flex items-center justify-center text-white mx-auto mb-6">
                    <Icon className="w-8 h-8" />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-4">{tab.title}</h3>
                  <p className="text-gray-600 leading-relaxed">{tab.description}</p>
                </div>
              ) : null;
            })}
          </div>
        </div>
      </section>

      {/* 5. Offline Intelligence Banner */}
      <section className="py-20 px-6 md:px-12">
        <div className="max-w-7xl mx-auto">
          <div className="rounded-3xl p-12 md:p-16 bg-librio-gradient text-white relative overflow-hidden">
            <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2"></div>
            <div className="absolute bottom-0 left-0 w-48 h-48 bg-white/5 rounded-full translate-y-1/2 -translate-x-1/2"></div>
            <div className="relative max-w-2xl">
              <div className="inline-flex items-center gap-2 mb-6">
                <WifiOff className="w-6 h-6" />
                <span className="text-sm font-semibold uppercase tracking-wide">Offline Intelligence</span>
              </div>
              <h2 className="text-3xl md:text-4xl font-bold mb-4 leading-tight">
                Study anywhere, anytime — no internet required
              </h2>
              <p className="text-white/90 text-lg leading-relaxed mb-8">
                Librio's AI runs entirely on your device. Ask questions, generate summaries, create flashcards, and take quizzes — all without a connection. Your study sessions work anywhere.
              </p>
              <Link
                href="/download"
                className="inline-flex items-center gap-2 px-8 py-4 bg-white text-librio-purple rounded-full font-bold hover:scale-105 transform transition-all duration-200"
              >
                Get the app
                <ArrowRight className="w-5 h-5" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* 6. Use Cases */}
      <section className="py-20 px-6 md:px-12 bg-[#F8FAFC]">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Built for how you learn
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Whether you're cramming for finals or picking up a new skill, Librio adapts to you.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {useCases.map((useCase, index) => (
              <div key={index} className="text-center">
                <div className="w-14 h-14 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-6 text-librio-purple">
                  <Sparkles className="w-7 h-7" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{useCase.title}</h3>
                <p className="text-gray-600 leading-relaxed">{useCase.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 7. Trust Section */}
      <section className="py-20 px-6 md:px-12">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
              Your data stays yours
            </h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Privacy and security built into everything we do.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {trustItems.map((item, index) => {
              const Icon = item.icon;
              return (
                <div key={index} className="text-center">
                  <div className="w-14 h-14 rounded-2xl bg-librio-purple/10 flex items-center justify-center mx-auto mb-6 text-librio-purple">
                    <Icon className="w-7 h-7" />
                  </div>
                  <h3 className="text-lg font-bold text-gray-900 mb-2">{item.title}</h3>
                  <p className="text-gray-600 text-sm leading-relaxed max-w-xs mx-auto">{item.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* 8. Final CTA */}
      <section className="py-24 px-6 md:px-12 bg-[#F8FAFC]">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-extrabold text-gray-900 mb-6 leading-tight">
            Ready to study smarter?
          </h2>
          <p className="text-lg text-gray-600 mb-10">
            Download Librio and start learning in seconds.
          </p>
          <Link
            href="/download"
            className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center gap-2 hover:scale-105 transform transition-all duration-200"
          >
            Get the app
            <ArrowRight className="w-5 h-5" />
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
              Â© 2026 Librio. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
