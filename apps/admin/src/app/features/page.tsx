'use client';

import Image from 'next/image';
import Link from 'next/link';

export default function FeaturesPage() {
  const primaryFeatures = [
    {
      title: 'AI Tutor',
      subtitle: 'Ask questions and get clear, student-friendly explanations.',
      image: '/images/AI-Tutor.jpg',
      longDescription: 'Get clear explanations for difficult topics and learn at your own pace with a tutor that never sleeps. Librio\'s AI Tutor adapts to your learning style and provides context-aware answers to your specific questions.',
      imageHeight: 'h-72 md:h-96',
    },
    {
      title: 'Smart Flashcards',
      subtitle: 'Turn lessons and study materials into flashcards for review.',
      image: '/images/Flashcard-img.jpg',
      longDescription: 'Turn your study materials into flashcards instantly and reinforce what you\'ve learned efficiently. Smart Flashcards use spaced repetition to help you remember more of what matters.',
      imageHeight: 'h-48',
    },
    {
      title: 'AI Quizzes',
      subtitle: 'Generate practice questions based on your learning materials.',
      image: '/images/AI-Quizzes.jpg',
      longDescription: 'Practice with questions generated directly from your study materials or exams. AI Quizzes identify gaps in your knowledge and help you focus on what matters most.',
      imageHeight: 'h-48',
    },
  ];

  const secondaryFeatures = [
    {
      title: 'Smart Summaries',
      subtitle: 'Turn long study materials into concise explanations.',
      longDescription: 'Turn long study materials into concise, digestible explanations. Smart Summaries extract the key points from your notes, textbooks, and documents so you can review them quickly.',
    },
    {
      title: 'Study Materials',
      subtitle: 'Upload and organize materials that Librio can work with.',
      longDescription: 'Upload and organize materials that Librio can work with. Support for notes, documents, PDFs, and more. Keep all your study content in one central, organized place.',
    },
    {
      title: 'AI Chat',
      subtitle: 'Have an ongoing conversation with your personal study companion.',
      longDescription: 'Have an ongoing conversation with your personal study companion. AI Chat remembers context from your previous interactions, making it feel like talking to a knowledgeable tutor who knows your learning journey.',
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

        {/* Feature Grid - AI Tutor large left, others stacked right */}
        <section className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8 md:auto-rows-fr">
          {/* AI Tutor - Large Card */}
          <article className="bg-white rounded-3xl overflow-hidden shadow-sm flex flex-col">
            <div className={`relative w-full ${primaryFeatures[0].imageHeight}`}>
              <Image
                src={primaryFeatures[0].image}
                alt={primaryFeatures[0].title}
                fill
                className="object-cover"
              />
            </div>
            <div className="p-8 flex-grow">
              <h2 className="text-2xl font-bold mb-4">{primaryFeatures[0].title}</h2>
              <h3 className="text-lg font-semibold mb-3 leading-snug">{primaryFeatures[0].subtitle}</h3>
              <p className="text-gray-600 text-sm leading-relaxed">{primaryFeatures[0].longDescription}</p>
            </div>
          </article>

          {/* Right column: Smart Flashcards + AI Quizzes + Offline Intelligence */}
          <div className="flex flex-col gap-6">
            {/* Smart Flashcards */}
            <article className="bg-white rounded-3xl overflow-hidden shadow-sm flex flex-col flex-1">
              <div className="relative w-full h-48">
                <Image
                  src={primaryFeatures[1].image}
                  alt={primaryFeatures[1].title}
                  fill
                  className="object-cover"
                />
              </div>
              <div className="p-8">
                <h2 className="text-2xl font-bold mb-3">{primaryFeatures[1].title}</h2>
                <h3 className="text-base font-semibold mb-2">{primaryFeatures[1].subtitle}</h3>
                <p className="text-gray-600 text-sm leading-relaxed">{primaryFeatures[1].longDescription}</p>
              </div>
            </article>

            {/* AI Quizzes */}
            <article className="bg-white rounded-3xl overflow-hidden shadow-sm flex flex-col flex-1">
              <div className="relative w-full h-48">
                <Image
                  src={primaryFeatures[2].image}
                  alt={primaryFeatures[2].title}
                  fill
                  className="object-cover"
                />
              </div>
              <div className="p-8">
                <h2 className="text-2xl font-bold mb-3">{primaryFeatures[2].title}</h2>
                <p className="text-gray-600 text-sm leading-relaxed">{primaryFeatures[2].longDescription}</p>
              </div>
            </article>

            {/* Offline Intelligence */}
            <article className="rounded-3xl p-8 bg-librio-gradient text-white flex-1">
              <h2 className="text-xl font-bold mb-3">Offline Intelligence</h2>
              <h3 className="text-sm font-semibold mb-2">Study anywhere, anytime, without an internet connection.</h3>
              <p className="text-white/90 text-sm leading-relaxed">
                Once your materials are uploaded, Librio&apos;s AI goes to work — entirely on your device. Ask questions about difficult topics, generate concise summaries, create flashcards for review, and take AI-generated quizzes to test your knowledge. No internet required: the AI runs locally, so your study sessions work anywhere, even offline.
              </p>
            </article>
          </div>
        </section>

        {/* Secondary Features Grid */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-24">
          {secondaryFeatures.map((feature, index) => (
            <article key={index} className="bg-white rounded-3xl p-8 shadow-sm">
              <h2 className="text-xl font-bold mb-3">{feature.title}</h2>
              <h3 className="text-sm font-semibold mb-2">{feature.subtitle}</h3>
              <p className="text-gray-600 text-sm leading-relaxed">{feature.longDescription}</p>
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
