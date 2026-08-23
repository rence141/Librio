'use client';

import Image from 'next/image';
import Link from 'next/link';

export default function FeaturesPage() {
  const primaryFeatures = [
    {
      title: 'AI Tutor',
      image: '/images/AI-Tutor.jpg',
      longDescription: 'Get clear explanations for difficult topics and learn at your own pace with a tutor that never sleeps. Librio\'s AI Tutor adapts to your learning style and provides context-aware answers to your specific questions.',
    },
    {
      title: 'Smart Flashcards',
      image: '/images/Flashcard-img.jpg',
      longDescription: 'Turn your study materials into flashcards instantly and reinforce what you\'ve learned efficiently. Smart Flashcards use spaced repetition to help you remember more of what matters.',
    },
    {
      title: 'AI Quizzes',
      image: '/images/AI-Quizzes.jpg',
      longDescription: 'Practice with questions generated directly from your study materials or exams. AI Quizzes identify gaps in your knowledge and help you focus on what matters most.',
    },
  ];

  const secondaryFeatures = [
    {
      title: 'Smart Summaries',
      description: 'Turn long study materials into concise, digestible explanations. Smart Summaries extract the key points from your notes, textbooks, and documents so you can review them quickly.',
    },
    {
      title: 'Study Materials',
      description: 'Upload and organize materials that Librio can work with. Support for notes, documents, PDFs, and more. Keep all your study content in one central, organized place.',
    },
    {
      title: 'AI Chat',
      description: 'Have an ongoing conversation with your personal study companion. AI Chat remembers context from your previous interactions, making it feel like talking to a knowledgeable tutor who knows your learning journey.',
    },
  ];

  return (
    <div className="min-h-screen bg-[#F8FAFC]">
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

      {/* Main Content */}
      <main className="flex-grow w-full max-w-7xl mx-auto px-6 md:px-12 pt-24 pb-24">
        {/* Hero */}
        <section className="text-center max-w-3xl mx-auto mb-20">
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-6 leading-tight">
            Powerful tools that<br />simplify your life
          </h1>
          <p className="text-lg text-gray-600">
            Everything you need to master any subject, all in one place.
          </p>
        </section>

        {/* Feature Sections - each with full image + text */}
        <section className="space-y-12 mb-16">
          {/* AI Tutor */}
          <article className="bg-white rounded-3xl overflow-hidden shadow-sm">
            <div className="w-full">
              <Image
                src={primaryFeatures[0].image}
                alt={primaryFeatures[0].title}
                width={1200}
                height={800}
                className="w-full h-auto object-cover"
              />
            </div>
            <div className="p-8">
              <h2 className="text-2xl font-bold mb-3">{primaryFeatures[0].title}</h2>
              <p className="text-gray-600 text-sm leading-relaxed">{primaryFeatures[0].longDescription}</p>
            </div>
          </article>

          {/* Smart Flashcards */}
          <article className="bg-white rounded-3xl overflow-hidden shadow-sm">
            <div className="w-full">
              <Image
                src={primaryFeatures[1].image}
                alt={primaryFeatures[1].title}
                width={1200}
                height={800}
                className="w-full h-auto object-cover"
              />
            </div>
            <div className="p-8">
              <h2 className="text-2xl font-bold mb-3">{primaryFeatures[1].title}</h2>
              <p className="text-gray-600 text-sm leading-relaxed">{primaryFeatures[1].longDescription}</p>
            </div>
          </article>

          {/* AI Quizzes */}
          <article className="bg-white rounded-3xl overflow-hidden shadow-sm">
            <div className="w-full">
              <Image
                src={primaryFeatures[2].image}
                alt={primaryFeatures[2].title}
                width={1200}
                height={800}
                className="w-full h-auto object-cover"
              />
            </div>
            <div className="p-8">
              <h2 className="text-2xl font-bold mb-3">{primaryFeatures[2].title}</h2>
              <p className="text-gray-600 text-sm leading-relaxed">{primaryFeatures[2].longDescription}</p>
            </div>
          </article>

          {/* Offline Intelligence */}
          <article className="rounded-3xl p-8 bg-librio-gradient text-white">
            <h2 className="text-xl font-bold mb-3">Offline Intelligence</h2>
            <p className="text-white/90 text-sm leading-relaxed">
              Once your materials are uploaded, Librio&apos;s AI goes to work — entirely on your device. Ask questions about difficult topics, generate concise summaries, create flashcards for review, and take AI-generated quizzes to test your knowledge. No internet required: the AI runs locally, so your study sessions work anywhere, even offline.
            </p>
          </article>
        </section>

        {/* Secondary Features Grid */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-24">
          {secondaryFeatures.map((feature, index) => (
            <article key={index} className="bg-white rounded-3xl p-8 shadow-sm">
              <h2 className="text-xl font-bold mb-3">{feature.title}</h2>
              <p className="text-gray-600 text-sm leading-relaxed">{feature.description}</p>
            </article>
          ))}
        </section>

        {/* Bottom CTA */}
        <section className="text-center pb-12">
          <h2 className="text-4xl font-extrabold text-gray-900 mb-8">Ready to study smarter?</h2>
          <Link
            href="/download"
            className="ai-button ai-button-lg rounded-full inline-flex items-center justify-center hover:scale-105 transform transition-all duration-200"
          >
            Get the app
          </Link>
        </section>
      </main>

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
              © 2026 Librio. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
