'use client';

import { Card, CardBody } from '@nextui-org/react';
import Link from 'next/link';
import Image from 'next/image';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <Link href="/" className="flex items-center gap-2">
            <Image
              src="/images/Logo-Text.png"
              alt="Librio"
              width={120}
              height={40}
              priority
            />
          </Link>
        </div>
      </nav>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <h1 className="text-4xl font-bold text-gray-900 mb-8">Privacy Policy</h1>

        <Card>
          <CardBody className="gap-6 p-8">
            <section>
              <h2 className="text-2xl font-bold mb-4">1. Introduction</h2>
              <p className="text-gray-600 mb-4">
                Librio ("we", "us", "our", or "Company") operates the Librio application and website. This page informs you of our policies regarding the collection, use, and disclosure of personal data when you use our Service and the choices you have associated with that data.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">2. Information Collection and Use</h2>
              <p className="text-gray-600 mb-4">
                We collect several different types of information for various purposes to provide and improve our Service to you.
              </p>
              <h3 className="text-lg font-bold mb-2">Types of Data Collected:</h3>
              <ul className="list-disc list-inside space-y-2 text-gray-600 mb-4">
                <li><strong>Personal Data:</strong> Email address, first name, last name, phone number, address, state, province, ZIP/postal code, city, cookies and usage data</li>
                <li><strong>Usage Data:</strong> Browser type, browser version, pages visited, time and date of visit, time spent on pages, device identifiers</li>
                <li><strong>Location Data:</strong> We may use GPS, Bluetooth, and other location technologies to determine your location</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">3. Use of Data</h2>
              <p className="text-gray-600 mb-4">Librio uses the collected data for various purposes:</p>
              <ul className="list-disc list-inside space-y-2 text-gray-600 mb-4">
                <li>To provide and maintain our Service</li>
                <li>To notify you about changes to our Service</li>
                <li>To allow you to participate in interactive features of our Service</li>
                <li>To provide customer support</li>
                <li>To gather analysis or valuable information so we can improve our Service</li>
                <li>To monitor the usage of our Service</li>
                <li>To detect, prevent and address technical and security issues</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">4. Security of Data</h2>
              <p className="text-gray-600 mb-4">
                The security of your data is important to us, but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your Personal Data, we cannot guarantee its absolute security.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">5. Changes to This Privacy Policy</h2>
              <p className="text-gray-600 mb-4">
                We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "effective date" at the top of this Privacy Policy.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">6. Contact Us</h2>
              <p className="text-gray-600 mb-4">
                If you have any questions about this Privacy Policy, please contact us at:
              </p>
              <p className="text-gray-600">
                Email: privacy@librio.com<br />
                Address: 123 Learning Street, Education City, EC 12345
              </p>
            </section>

            <div className="border-t pt-6 mt-6 text-sm text-gray-500">
              <p>Last updated: August 23, 2026</p>
            </div>
          </CardBody>
        </Card>

        <div className="mt-8 text-center">
          <Link href="/" className="text-librio-purple hover:underline">
            Back to home
          </Link>
        </div>
      </div>
    </div>
  );
}
