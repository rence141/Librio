'use client';

import { Card, CardBody } from '@nextui-org/react';
import Link from 'next/link';

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold text-indigo-600">
            Librio
          </Link>
        </div>
      </nav>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <h1 className="text-4xl font-bold text-gray-900 mb-8">Terms of Service</h1>

        <Card>
          <CardBody className="gap-6 p-8">
            <section>
              <h2 className="text-2xl font-bold mb-4">1. Terms</h2>
              <p className="text-gray-600 mb-4">
                By accessing and using this website and application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">2. Use License</h2>
              <p className="text-gray-600 mb-4">
                Permission is granted to temporarily download one copy of the materials (information or software) on Librio's website for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
              </p>
              <ul className="list-disc list-inside space-y-2 text-gray-600 mb-4">
                <li>Modifying or copying the materials</li>
                <li>Using the materials for any commercial purpose or for any public display</li>
                <li>Attempting to decompile or reverse engineer any software contained on the website</li>
                <li>Removing any copyright or other proprietary notations from the materials</li>
                <li>Transferring the materials to another person or "mirroring" the materials on any other server</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">3. Disclaimer</h2>
              <p className="text-gray-600 mb-4">
                The materials on Librio's website are provided on an 'as is' basis. Librio makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">4. Limitations</h2>
              <p className="text-gray-600 mb-4">
                In no event shall Librio or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Librio's website, even if Librio or an authorized representative has been notified orally or in writing of the possibility of such damage.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">5. Accuracy of Materials</h2>
              <p className="text-gray-600 mb-4">
                The materials appearing on Librio's website could include technical, typographical, or photographic errors. Librio does not warrant that any of the materials on its website are accurate, complete, or current. Librio may make changes to the materials contained on its website at any time without notice.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">6. Links</h2>
              <p className="text-gray-600 mb-4">
                Librio has not reviewed all of the sites linked to its website and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by Librio of the site. Use of any such linked website is at the user's own risk.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">7. Modifications</h2>
              <p className="text-gray-600 mb-4">
                Librio may revise these terms of service for its website at any time without notice. By using this website, you are agreeing to be bound by the then current version of these terms of service.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">8. Governing Law</h2>
              <p className="text-gray-600 mb-4">
                These terms and conditions are governed by and construed in accordance with the laws of the jurisdiction in which Librio operates, and you irrevocably submit to the exclusive jurisdiction of the courts in that location.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">9. User Responsibilities</h2>
              <p className="text-gray-600 mb-4">
                Users are responsible for maintaining the confidentiality of their account information and password. Users agree to accept responsibility for all activities that occur under their account. Users must notify Librio immediately of any unauthorized use of their account.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold mb-4">10. Intellectual Property Rights</h2>
              <p className="text-gray-600 mb-4">
                All content, features, and functionality (including but not limited to all information, software, text, displays, images, video and audio) are owned by Librio, its licensors, or other providers of such material and are protected by United States and international copyright, trademark, and other intellectual property laws.
              </p>
            </section>

            <div className="border-t pt-6 mt-6 text-sm text-gray-500">
              <p>Last updated: August 23, 2026</p>
            </div>
          </CardBody>
        </Card>

        <div className="mt-8 text-center">
          <Link href="/" className="text-indigo-600 hover:underline">
            Back to home
          </Link>
        </div>
      </div>
    </div>
  );
}
