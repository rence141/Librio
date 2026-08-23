'use client';

import { useEffect, useState } from 'react';
import { Card, CardBody, CardHeader, Divider, Skeleton } from '@nextui-org/react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { apiClient } from '@/services/api';
import { AnalyticsData } from '@/types/admin';
import toast from 'react-hot-toast';

export default function AdminDashboard() {
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        const response = await apiClient.getAnalytics();
        setAnalytics(response.data.data);
      } catch (error) {
        toast.error('Failed to load analytics');
      } finally {
        setLoading(false);
      }
    };

    fetchAnalytics();
  }, []);

  if (loading) {
    return (
      <div className="p-8 space-y-6">
        <Skeleton className="h-32 rounded-lg" />
        <Skeleton className="h-96 rounded-lg" />
      </div>
    );
  }

  if (!analytics) {
    return (
      <div className="p-8">
        <Card>
          <CardBody>
            <p className="text-center text-gray-500">Failed to load analytics</p>
          </CardBody>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-8">
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600">Welcome back! Here's your system overview.</p>
        </div>
        <div className="ai-badge">
          AI Insights Available
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Total Users</p>
            <p className="text-3xl font-bold text-gray-900">{analytics.totalUsers.toLocaleString()}</p>
            <p className="text-xs text-green-600">+12% from last month</p>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Active Users</p>
            <p className="text-3xl font-bold text-gray-900">{analytics.activeUsers.toLocaleString()}</p>
            <p className="text-xs text-blue-600">Currently active</p>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Total Documents</p>
            <p className="text-3xl font-bold text-gray-900">{analytics.totalDocuments.toLocaleString()}</p>
            <p className="text-xs text-purple-600">+8% from last month</p>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Total Sessions</p>
            <p className="text-3xl font-bold text-gray-900">{analytics.totalSessions.toLocaleString()}</p>
            <p className="text-xs text-orange-600">+15% from last month</p>
          </CardBody>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* User Growth Chart */}
        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">User Growth</h2>
            <p className="text-sm text-gray-600">Last 30 days</p>
          </CardHeader>
          <CardBody className="p-4">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={analytics.userGrowth}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="count" stroke="#3B82F6" />
              </LineChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* Top Subjects Chart */}
        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">Top Subjects</h2>
            <p className="text-sm text-gray-600">By document count</p>
          </CardHeader>
          <CardBody className="p-4">
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={analytics.topSubjects}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="subject" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="count" fill="#8B5CF6" />
              </BarChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">Average Session Duration</h2>
          </CardHeader>
          <CardBody className="p-6">
            <p className="text-4xl font-bold text-gray-900">
              {Math.round(analytics.averageSessionDuration / 60)} min
            </p>
            <p className="text-sm text-gray-600 mt-2">
              Average time spent per session
            </p>
          </CardBody>
        </Card>

        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">System Status</h2>
          </CardHeader>
          <CardBody className="p-6">
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">API Status</span>
                <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                  Healthy
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Database</span>
                <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                  Healthy
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Cache</span>
                <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                  Healthy
                </span>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* AI Features Section */}
      <div className="ai-feature">
        <div className="ai-feature-header">
          <div className="ai-feature-icon">✨</div>
          <h2 className="ai-feature-title text-lg">AI-Powered Insights</h2>
        </div>
        <p className="text-gray-700 mb-4">
          Get AI-generated insights and recommendations for your platform. Our advanced analytics engine analyzes user behavior patterns and provides actionable insights.
        </p>
        <div className="flex gap-3 flex-wrap">
          <button className="ai-button ai-button-sm">
            Generate AI Report
          </button>
          <button className="ai-button-outline ai-button-sm">
            View Recommendations
          </button>
        </div>
      </div>
    </div>
  );
}
