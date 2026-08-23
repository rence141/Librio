export interface UserStats {
  id: string;
  email: string;
  fullName: string;
  subscriptionTier: string;
  createdAt: string;
  lastActive?: string;
  documentsCount: number;
  sessionsCount: number;
  storageUsedMb: number;
  status: 'active' | 'suspended' | 'deleted';
}

export interface Material {
  id: string;
  title: string;
  subject: string;
  topic?: string;
  createdBy: string;
  isPublic: boolean;
  isFeatured: boolean;
  downloadCount: number;
  rating?: number;
  status: 'pending' | 'approved' | 'rejected';
  createdAt: string;
}

export interface AnalyticsData {
  totalUsers: number;
  activeUsers: number;
  totalDocuments: number;
  totalSessions: number;
  averageSessionDuration: number;
  topSubjects: Array<{ subject: string; count: number }>;
  userGrowth: Array<{ date: string; count: number }>;
  eventDistribution: Record<string, number>;
}

export interface SystemHealth {
  databaseStatus: 'healthy' | 'degraded' | 'down';
  apiStatus: 'healthy' | 'degraded' | 'down';
  syncQueueSize: number;
  failedSyncs: number;
  cacheHitRate: number;
  averageLatency: number;
  timestamp: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
