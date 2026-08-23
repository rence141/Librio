'use client';

import { Button, Card, CardBody, Tabs, Tab } from '@nextui-org/react';
import Link from 'next/link';

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <Link href="/" className="text-2xl font-bold text-indigo-600">
            Librio
          </Link>
          <div className="flex gap-4">
            <Button as={Link} href="/login" variant="flat">
              Login
            </Button>
            <Button as={Link} href="/signup" color="primary">
              Sign Up
            </Button>
          </div>
        </div>
      </nav>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">Download Librio</h1>
          <p className="text-xl text-gray-600">
            Get Librio on your device and start learning today
          </p>
        </div>

        <Tabs aria-label="Download options" className="flex justify-center mb-12">
          <Tab key="mobile" title="Mobile Apps">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 py-8">
              <Card>
                <CardBody className="gap-4 p-8">
                  <div className="text-5xl">🍎</div>
                  <h3 className="text-2xl font-bold">iOS</h3>
                  <p className="text-gray-600">
                    Download Librio from the Apple App Store
                  </p>
                  <Button
                    as="a"
                    href="https://apps.apple.com/app/librio"
                    color="primary"
                    size="lg"
                    target="_blank"
                  >
                    Download on App Store
                  </Button>
                  <p className="text-sm text-gray-500">
                    Requires iOS 14.0 or later
                  </p>
                </CardBody>
              </Card>

              <Card>
                <CardBody className="gap-4 p-8">
                  <div className="text-5xl">🤖</div>
                  <h3 className="text-2xl font-bold">Android</h3>
                  <p className="text-gray-600">
                    Download Librio from Google Play Store
                  </p>
                  <Button
                    as="a"
                    href="https://play.google.com/store/apps/details?id=com.librio"
                    color="primary"
                    size="lg"
                    target="_blank"
                  >
                    Get on Google Play
                  </Button>
                  <p className="text-sm text-gray-500">
                    Requires Android 8.0 or later
                  </p>
                </CardBody>
              </Card>
            </div>
          </Tab>

          <Tab key="web" title="Web Version">
            <div className="py-8">
              <Card>
                <CardBody className="gap-4 p-8">
                  <h3 className="text-2xl font-bold">Access Librio Online</h3>
                  <p className="text-gray-600 mb-4">
                    Use Librio directly in your web browser without installation
                  </p>
                  <Button
                    as={Link}
                    href="/login"
                    color="primary"
                    size="lg"
                  >
                    Open Web Version
                  </Button>
                  <p className="text-sm text-gray-500 mt-4">
                    Works on all modern browsers: Chrome, Firefox, Safari, Edge
                  </p>
                </CardBody>
              </Card>
            </div>
          </Tab>

          <Tab key="desktop" title="Desktop">
            <div className="py-8">
              <Card>
                <CardBody className="gap-4 p-8">
                  <h3 className="text-2xl font-bold">Desktop Applications</h3>
                  <p className="text-gray-600 mb-4">
                    Download Librio for Windows and macOS
                  </p>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Button
                      as="a"
                      href="/downloads/librio-windows.exe"
                      color="primary"
                      size="lg"
                    >
                      Download for Windows
                    </Button>
                    <Button
                      as="a"
                      href="/downloads/librio-macos.dmg"
                      color="primary"
                      size="lg"
                    >
                      Download for macOS
                    </Button>
                  </div>
                  <p className="text-sm text-gray-500 mt-4">
                    Windows 10+ and macOS 10.14+
                  </p>
                </CardBody>
              </Card>
            </div>
          </Tab>
        </Tabs>

        {/* System Requirements */}
        <Card className="mt-12">
          <CardBody className="gap-4 p-8">
            <h2 className="text-2xl font-bold">System Requirements</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div>
                <h3 className="font-bold mb-2">Minimum Requirements</h3>
                <ul className="space-y-2 text-gray-600">
                  <li>• 100 MB free storage space</li>
                  <li>• Internet connection</li>
                  <li>• Modern web browser</li>
                </ul>
              </div>
              <div>
                <h3 className="font-bold mb-2">Recommended</h3>
                <ul className="space-y-2 text-gray-600">
                  <li>• 500 MB free storage space</li>
                  <li>• High-speed internet</li>
                  <li>• Latest browser version</li>
                </ul>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
