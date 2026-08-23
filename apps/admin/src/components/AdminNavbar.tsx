'use client';

import { useRouter } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { Button, Dropdown, DropdownTrigger, DropdownMenu, DropdownItem } from '@nextui-org/react';
import { useAuthStore } from '@/stores/authStore';
import toast from 'react-hot-toast';

export default function AdminNavbar() {
  const router = useRouter();
  const { user, logout } = useAuthStore();

  const handleLogout = async () => {
    try {
      await logout();
      toast.success('Logged out successfully');
      router.push('/login');
    } catch (error) {
      toast.error('Logout failed');
    }
  };

  return (
    <nav className="bg-white border-b border-gray-200 px-8 py-4 flex justify-between items-center">
      <Link href="/admin/dashboard" className="flex items-center gap-2 hover:opacity-80 transition">
        <Image
          src="/icons/logo.png"
          alt="Librio Logo"
          width={32}
          height={32}
        />
        <h2 className="text-xl font-semibold text-gray-900">Admin Panel</h2>
      </Link>

      <div className="flex items-center gap-4">
        {/* Search */}
        <div className="hidden md:flex items-center gap-2 bg-gray-100 rounded-lg px-4 py-2">
          <span>🔍</span>
          <input
            type="text"
            placeholder="Search..."
            className="bg-transparent outline-none text-sm w-48"
          />
        </div>

        {/* AI Feature Badge */}
        <div className="ai-badge hidden sm:flex">
          AI Powered
        </div>

        {/* Notifications */}
        <button className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition">
          <span className="text-xl">🔔</span>
          <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        {/* User Menu */}
        <Dropdown>
          <DropdownTrigger>
            <button className="flex items-center gap-2 p-2 hover:bg-gray-100 rounded-lg transition">
              <div className="w-8 h-8 bg-indigo-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
                {user?.fullName.charAt(0).toUpperCase()}
              </div>
              <div className="hidden md:flex flex-col items-start">
                <p className="text-sm font-medium text-gray-900">{user?.fullName}</p>
                <p className="text-xs text-gray-500">{user?.email}</p>
              </div>
            </button>
          </DropdownTrigger>
          <DropdownMenu aria-label="User menu">
            <DropdownItem key="profile" textValue="Profile">
              Profile Settings
            </DropdownItem>
            <DropdownItem key="settings" textValue="Settings">
              Account Settings
            </DropdownItem>
            <DropdownItem key="help" textValue="Help">
              Help & Support
            </DropdownItem>
            <DropdownItem
              key="logout"
              textValue="Logout"
              color="danger"
              onClick={handleLogout}
            >
              Logout
            </DropdownItem>
          </DropdownMenu>
        </Dropdown>
      </div>
    </nav>
  );
}
