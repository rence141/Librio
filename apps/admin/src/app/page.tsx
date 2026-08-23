'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button, Card, CardBody } from '@nextui-org/react';
import Image from 'next/image';
import { useAuthStore } from '@/stores/authStore';
import Link from 'next/link';

export default function Home() {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();

  useEffect(() => {
    // Redirect authenticated admins to dashboard
    if (isAuthenticated && user?.role === 'admin') {
      router.push('/admin/dashboard');
    }
  }, [isAuthenticated, user, router]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Navigation */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <Link href="/" className="flex items-center gap-3 hover:opacity-80 transition">
            <Image
              src="/icons/logo.png"
              alt="Librio Logo"
              width={40}
              height={40}
              priority
            />
            <Image
              src="/images/Logo-Text.png"
              alt="Librio"
              width={120}
              height={40}
              priority
              className="hidden sm:block"
            />
          </Link>
          <div className="flex gap-4">
            {isAuthenticated ? (
              <>
                <Button
                  as={Link}
                  href={user?.role === 'admin' ? '/admin/dashboard' : '/dashboard'}
                  color="primary"
                  variant="flat"
                >
                  Dashboard
                </Button>
                <Button
                  color="danger"
                  variant="flat"
                  onClick={() => useAuthStore.getState().logout()}
                >
                  Logout
                </Button>
              </>
            ) : (
              <>
                <Button as={Link} href="/login" variant="flat">
                  Login
                </Button>
                <Button as={Link} href="/signup" color="primary">
                  Sign Up
                </Button>
              </>
            )}
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center">
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            Welcome to Librio
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            Your comprehensive platform for learning, studying, and managing educational content with AI-powered features.
          </p>
          <div className="flex gap-4 justify-center">
            <Button
              as={Link}
              href="/download"
              size="lg"
              color="primary"
            >
              Download App
            </Button>
            <Button
              as={Link}
              href="/signup"
              size="lg"
              variant="bordered"
            >
              Get Started
            </Button>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="bg-white py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-bold text-center mb-12">Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <Card>
              <CardBody className="gap-4">
                <div className="text-4xl">📚</div>
                <h3 className="text-xl font-bold">Study Materials</h3>
                <p className="text-gray-600">
                  Access a vast library of study materials, flashcards, and educational content.
                </p>
              </CardBody>
            </Card>
            <Card>
              <CardBody className="gap-4">
                <div className="text-4xl">🤖</div>
                <h3 className="text-xl font-bold">AI-Powered</h3>
                <p className="text-gray-600">
                  Leverage AI to generate study guides, quizzes, and personalized learning paths.
                </p>
              </CardBody>
            </Card>
            <Card>
              <CardBody className="gap-4">
                <div className="text-4xl">📊</div>
                <h3 className="text-xl font-bold">Analytics</h3>
                <p className="text-gray-600">
                  Track your progress with detailed analytics and performance insights.
                </p>
              </CardBody>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-indigo-600 text-white py-20">
        <div className="max-w-4xl mx-auto text-center px-4">
          <h2 className="text-3xl font-bold mb-6">Ready to get started?</h2>
          <p className="text-lg mb-8">
            Join thousands of students using Librio to enhance their learning experience.
          </p>
          <Button
            as={Link}
            href="/signup"
            size="lg"
            className="bg-white text-indigo-600 font-bold"
          >
            Sign Up Now
          </Button>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-300 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
            <div>
              <h4 className="text-white font-bold mb-4">Librio</h4>
              <p className="text-sm">
                Your comprehensive learning platform powered by AI.
              </p>
            </div>
            <div>
              <h4 className="text-white font-bold mb-4">Product</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/download">Download</Link></li>
                <li><Link href="/features">Features</Link></li>
                <li><Link href="/pricing">Pricing</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-bold mb-4">Legal</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/privacy">Privacy Policy</Link></li>
                <li><Link href="/terms">Terms of Service</Link></li>
                <li><Link href="/contact">Contact</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-bold mb-4">Resources</h4>
              <ul className="space-y-2 text-sm">
                <li><Link href="/blog">Blog</Link></li>
                <li><Link href="/docs">Documentation</Link></li>
                <li><Link href="/support">Support</Link></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 pt-8 text-center text-sm">
            <p>&copy; 2026 Librio. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
