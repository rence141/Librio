'use client';

import { useEffect, useState } from 'react';
import {
  Card,
  CardBody,
  CardHeader,
  Button,
  Input,
  Select,
  SelectItem,
  Skeleton,
} from '@nextui-org/react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { apiClient } from '@/services/api';
import { AnalyticsData } from '@/types/admin';
import toast from 'react-hot-toast';

const COLORS = ['#3B82F6', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981'];

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        setLoading(true);
        const response = await apiClient.getAnalytics(startDate, endDate);
        setAnalytics(response.data.data);
      } catch (error) {
        toast.error('Failed to load analytics');
      } finally {
        setLoading(false);
      }
    };

    fetchAnalytics();
  }, [startDate, endDate]);

  if (loading) {
    return (
      <div className="p-8 space-y-6">
        <Skeleton className="h-32 rounded-lg" />
        <Skeleton className="h-96 rounded-lg" />
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
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        <p className="text-gray-600">Detailed insights and performance metrics</p>
      </div>

      {/* Date Range Filter */}
      <Card>
        <CardBody className="gap-4 p-6">
          <div className="flex gap-4 flex-wrap items-end">
            <Input
              type="date"
              label="Start Date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="w-full md:w-48"
            />
            <Input
              type="date"
              label="End Date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="w-full md:w-48"
            />
            <Button
              color="primary"
              onClick={() => {
                setStartDate('');
                setEndDate('');
              }}
            >
              Reset
            </Button>
          </div>
        </CardBody>
      </Card>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Total Users</p>
            <p className="text-3xl font-bold text-gray-900">
              {analytics.totalUsers.toLocaleString()}
            </p>
            <p className="text-xs text-blue-600">All registered users</p>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Active Users</p>
            <p className="text-3xl font-bold text-gray-900">
              {analytics.activeUsers.toLocaleString()}
            </p>
            <p className="text-xs text-green-600">
              {((analytics.activeUsers / analytics.totalUsers) * 100).toFixed(1)}% active
            </p>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Total Documents</p>
            <p className="text-3xl font-bold text-gray-900">
              {analytics.totalDocuments.toLocaleString()}
            </p>
            <p className="text-xs text-purple-600">Created by users</p>
          </CardBody>
        </Card>

        <Card>
          <CardBody className="gap-2 p-6">
            <p className="text-gray-600 text-sm">Total Sessions</p>
            <p className="text-3xl font-bold text-gray-900">
              {analytics.totalSessions.toLocaleString()}
            </p>
            <p className="text-xs text-orange-600">Study sessions</p>
          </CardBody>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* User Growth */}
        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">User Growth</h2>
            <p className="text-sm text-gray-600">New users over time</p>
          </CardHeader>
          <CardBody className="p-4">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={analytics.userGrowth}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="count"
                  stroke="#3B82F6"
                  strokeWidth={2}
                  dot={{ fill: '#3B82F6' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardBody>
        </Card>

        {/* Top Subjects */}
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

      {/* Event Distribution */}
      <Card>
        <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
          <h2 className="text-lg font-bold">Event Distribution</h2>
          <p className="text-sm text-gray-600">User activity breakdown</p>
        </CardHeader>
        <CardBody className="p-4">
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={Object.entries(analytics.eventDistribution).map(
                  ([name, value]) => ({
                    name,
                    value,
                  })
                )}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, value }) => `${name}: ${value}`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {Object.entries(analytics.eventDistribution).map((_, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </CardBody>
      </Card>

      {/* Additional Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">Session Duration</h2>
          </CardHeader>
          <CardBody className="p-6">
            <div className="space-y-4">
              <div>
                <p className="text-gray-600 text-sm mb-2">Average Duration</p>
                <p className="text-4xl font-bold text-gray-900">
                  {Math.round(analytics.averageSessionDuration / 60)} min
                </p>
              </div>
              <div className="bg-blue-50 p-4 rounded-lg">
                <p className="text-sm text-gray-600">Total Session Time</p>
                <p className="text-2xl font-bold text-blue-600">
                  {Math.round((analytics.totalSessions * analytics.averageSessionDuration) / 3600)} hrs
                </p>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader className="flex flex-col items-start px-4 py-4 border-b">
            <h2 className="text-lg font-bold">Engagement Metrics</h2>
          </CardHeader>
          <CardBody className="p-6">
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Docs per User</span>
                <span className="font-bold">
                  {(analytics.totalDocuments / analytics.totalUsers).toFixed(1)}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Sessions per User</span>
                <span className="font-bold">
                  {(analytics.totalSessions / analytics.totalUsers).toFixed(1)}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Active Rate</span>
                <span className="font-bold">
                  {((analytics.activeUsers / analytics.totalUsers) * 100).toFixed(1)}%
                </span>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Export Button */}
      <div className="flex justify-end">
        <Button color="primary" size="lg">
          📥 Export Report
        </Button>
      </div>
    </div>
  );
}
