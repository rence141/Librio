'use client';

import Image from 'next/image';
import Link from 'next/link';

export default function FeaturesPage() {
  const features = [
    {
      title: 'AI Tutor',
      description: 'Ask questions and get clear, student-friendly explanations.',
      image: '/images/AI-Tutor.jpg',
      longDescription: 'Get clear explanations for difficult topics and learn at your own pace with a tutor that never sleeps. Librio\'s AI Tutor adapts to your learning style and provides context-aware answers to your specific questions.',
    },
    {
      title: 'Smart Flashcards',
      description: 'Turn lessons and study materials into flashcards for review.',
      image: '/images/Flashcard-img.jpg',
      longDescription: 'Turn your study materials into flashcards instantly and reinforce what you\'ve learned efficiently. Smart Flashcards use spaced repetition to help you remember more of what you study.',
    },
    {
      title: 'AI Quizzes',
      description: 'Generate practice questions based on your learning materials.',
      image: '/images/AI-Quizzes.jpg',
      longDescription: 'Practice with questions generated directly from your study materials to prepare for exams. AI Quizzes identify gaps in your knowledge and help you focus on what matters most.',
    },
    {
      title: 'Smart Summaries',
      description: 'Turn long study materials into concise explanations.',
      longDescription: 'Turn long study materials into concise, digestible explanations. Smart Summaries extract the key points from your notes, textbooks, and documents so you can review them quickly.',
    },
    {
      title: 'Study Materials',
      description: 'Upload and organize materials that Librio can work with.',
      longDescription: 'Upload and organize materials that Librio can work with. Support for notes, documents, PDFs, and more. Keep all your study content in one central, organized place.',
    },
    {
      title: 'AI Chat',
      description: 'Have an ongoing conversation with your personal study companion.',
      longDescription: 'Have an ongoing conversation with your personal study companion. AI Chat remembers context from your previous interactions, making it feel like talking to a knowledgeable tutor who knows your learning journey.',
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

      {/* Hero */}
      <section className="pt-32 pb-16 bg-librio-purple/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-6">
            Powerful tools that simplify your life
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Everything you need to master any subject, all in one place.
          </p>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
            {features.map((feature, index) => (
              <div key={index} className="flex flex-col gap-6">
                {feature.image && (
                  <div className="relative h-64 rounded-2xl overflow-hidden shadow-lg">
                    <Image
                      src={feature.image}
                      alt={feature.title}
                      fill
                      className="object-cover"
                    />
                  </div>
                )}
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 mb-3">{feature.title}</h2>
                  <p className="text-gray-600 leading-relaxed mb-2">{feature.description}</p>
                  <p className="text-gray-500 leading-relaxed text-sm">{feature.longDescription}</p>
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
            Ready to study smarter?
          </h2>
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
