'use client';

import { useEffect, useState } from 'react';
import { Card, CardBody, CardHeader, Button, Skeleton } from '@nextui-org/react';
import { apiClient } from '@/services/api';
import { SystemHealth } from '@/types/admin';
import toast from 'react-hot-toast';

export default function SystemPage() {
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const [loading, setLoading] = useState(true);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchHealth = async () => {
    try {
      const response = await apiClient.getSystemHealth();
      setHealth(response.data.data);
    } catch (error) {
      toast.error('Failed to load system health');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealth();
  }, []);

  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(fetchHealth, 5000);
    return () => clearInterval(interval);
  }, [autoRefresh]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
        return 'bg-green-100 text-green-800';
      case 'degraded':
        return 'bg-yellow-100 text-yellow-800';
      case 'down':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return '✓';
      case 'degraded':
        return '⚠';
      case 'down':
        return '✕';
      default:
        return '?';
    }
  };

  if (loading) {
    return (
      <div className="p-8 space-y-6">
        <Skeleton className="h-32 rounded-lg" />
        <Skeleton className="h-96 rounded-lg" />
      </div>
    );
  }

  if (!health) {
    return (
      <div className="p-8">
        <Card>
          <CardBody>
            <p className="text-center text-gray-500">Failed to load system health</p>
          </CardBody>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-8">
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">System Monitoring</h1>
          <p className="text-gray-600">Real-time system health and performance metrics</p>
        </div>
        <div className="flex gap-2">
          <Button
            isIconOnly
            onClick={fetchHealth}
            className="bg-blue-600 text-white"
          >
            🔄
          </Button>
          <Button
            isIconOnly
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={autoRefresh ? 'bg-green-600 text-white' : 'bg-gray-600 text-white'}
          >
            {autoRefresh ? '▶' : '⏸'}
          </Button>
        </div>
      </div>

      {/* System Status Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Database Status */}
        <Card>
          <CardBody className="gap-4 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-600 text-sm">Database Status</p>
                <p className="text-2xl font-bold text-gray-900 mt-2">
                  {health.databaseStatus.charAt(0).toUpperCase() +
                    health.databaseStatus.slice(1)}
                </p>
              </div>
              <div
                className={`w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold ${getStatusColor(
                  health.databaseStatus
                )}`}
              >
                {getStatusIcon(health.databaseStatus)}
              </div>
            </div>
          </CardBody>
        </Card>

        {/* API Status */}
        <Card>
          <CardBody className="gap-4 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-600 text-sm">API Status</p>
                <p className="text-2xl font-bold text-gray-900 mt-2">
                  {health.apiStatus.charAt(0).toUpperCase() +
                    health.apiStatus.slice(1)}
                </p>
              </div>
              <div
                className={`w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold ${getStatusColor(
                  health.apiStatus
                )}`}
              >
                {getStatusIcon(health.apiStatus)}
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Cache Status */}
        <Card>
          <CardBody className="gap-4 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-600 text-sm">Cache Hit Rate</p>
                <p className="text-2xl font-bold text-gray-900 mt-2">
                  {(health.cacheHitRate * 100).toFixed(1)}%
                </p>
              </div>
              <div className="w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold bg-blue-100 text-blue-800">
                💾
              </div>
            </div>
          </CardBody>
        </Card>
      </div>

      {/* Performance Metrics */}
      <Card>
        <CardHeader className="flex flex-col items-start px-6 py-4 border-b">
          <h2 className="text-lg font-bold">Performance Metrics</h2>
          <p className="text-sm text-gray-600">Real-time performance data</p>
        </CardHeader>
        <CardBody className="gap-6 p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Average Latency */}
            <div>
              <div className="flex justify-between items-center mb-2">
                <p className="text-gray-600 font-medium">Average Latency</p>
                <p className="text-2xl font-bold text-gray-900">
                  {health.averageLatency.toFixed(0)}ms
                </p>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-blue-600 h-2 rounded-full"
                  style={{
                    width: `${Math.min((health.averageLatency / 1000) * 100, 100)}%`,
                  }}
                ></div>
              </div>
              <p className="text-xs text-gray-500 mt-1">Target: &lt;100ms</p>
            </div>

            {/* Cache Hit Rate */}
            <div>
              <div className="flex justify-between items-center mb-2">
                <p className="text-gray-600 font-medium">Cache Hit Rate</p>
                <p className="text-2xl font-bold text-gray-900">
                  {(health.cacheHitRate * 100).toFixed(1)}%
                </p>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-green-600 h-2 rounded-full"
                  style={{
                    width: `${health.cacheHitRate * 100}%`,
                  }}
                ></div>
              </div>
              <p className="text-xs text-gray-500 mt-1">Target: &gt;80%</p>
            </div>
          </div>
        </CardBody>
      </Card>

      {/* Queue Status */}
      <Card>
        <CardHeader className="flex flex-col items-start px-6 py-4 border-b">
          <h2 className="text-lg font-bold">Sync Queue Status</h2>
          <p className="text-sm text-gray-600">Background job processing</p>
        </CardHeader>
        <CardBody className="gap-6 p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Queue Size */}
            <div className="bg-blue-50 p-6 rounded-lg">
              <p className="text-gray-600 text-sm mb-2">Pending Jobs</p>
              <p className="text-4xl font-bold text-blue-600">
                {health.syncQueueSize}
              </p>
              <p className="text-xs text-gray-500 mt-2">
                {health.syncQueueSize === 0
                  ? 'Queue is empty'
                  : 'Processing...'}
              </p>
            </div>

            {/* Failed Syncs */}
            <div
              className={`p-6 rounded-lg ${
                health.failedSyncs > 0
                  ? 'bg-red-50'
                  : 'bg-green-50'
              }`}
            >
              <p className="text-gray-600 text-sm mb-2">Failed Syncs</p>
              <p
                className={`text-4xl font-bold ${
                  health.failedSyncs > 0
                    ? 'text-red-600'
                    : 'text-green-600'
                }`}
              >
                {health.failedSyncs}
              </p>
              <p className="text-xs text-gray-500 mt-2">
                {health.failedSyncs === 0
                  ? 'No failures'
                  : 'Requires attention'}
              </p>
            </div>
          </div>
        </CardBody>
      </Card>

      {/* System Information */}
      <Card>
        <CardHeader className="flex flex-col items-start px-6 py-4 border-b">
          <h2 className="text-lg font-bold">System Information</h2>
        </CardHeader>
        <CardBody className="gap-4 p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex justify-between">
              <span className="text-gray-600">Last Updated</span>
              <span className="font-semibold">
                {new Date(health.timestamp).toLocaleTimeString()}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Uptime Status</span>
              <span className="font-semibold text-green-600">Running</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Environment</span>
              <span className="font-semibold">Production</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">API Version</span>
              <span className="font-semibold">v1.0.0</span>
            </div>
          </div>
        </CardBody>
      </Card>

      {/* Alerts */}
      {(health.databaseStatus === 'down' ||
        health.apiStatus === 'down' ||
        health.failedSyncs > 10) && (
        <Card className="border-2 border-red-500">
          <CardHeader className="flex flex-col items-start px-6 py-4 border-b bg-red-50">
            <h2 className="text-lg font-bold text-red-800">⚠️ Active Alerts</h2>
          </CardHeader>
          <CardBody className="gap-3 p-6">
            {health.databaseStatus === 'down' && (
              <p className="text-red-700">
                🔴 Database is down. Immediate action required.
              </p>
            )}
            {health.apiStatus === 'down' && (
              <p className="text-red-700">
                🔴 API is down. Users may experience service interruption.
              </p>
            )}
            {health.failedSyncs > 10 && (
              <p className="text-red-700">
                🟡 High number of failed syncs ({health.failedSyncs}). Check logs.
              </p>
            )}
          </CardBody>
        </Card>
      )}
    </div>
  );
}
