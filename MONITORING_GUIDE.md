# Monitoring & Observability Guide - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: Phase 4 - Observability & Monitoring

---

## Table of Contents

1. [Overview](#overview)
2. [Error Tracking (Sentry)](#error-tracking-sentry)
3. [Analytics (Firebase)](#analytics-firebase)
4. [Performance Monitoring](#performance-monitoring)
5. [Logging & Log Aggregation](#logging--log-aggregation)
6. [Health Checks & Metrics](#health-checks--metrics)
7. [Dashboards & Alerts](#dashboards--alerts)
8. [Best Practices](#best-practices)

---

## Overview

Librio implements comprehensive monitoring across all components:

| Component | Tool | Purpose | Status |
|-----------|------|---------|--------|
| Error Tracking | Sentry | Capture and track errors | ✅ Ready |
| Analytics | Firebase | Track user behavior | ✅ Ready |
| Performance | Custom Metrics | Monitor response times | ✅ Ready |
| Logging | Pino + ELK | Centralized logging | ✅ Ready |
| Health Checks | Custom | System health monitoring | ✅ Ready |

---

## Error Tracking (Sentry)

### Backend Setup

**Installation**:
```bash
cd services/api
npm install @sentry/node
```

**Configuration**:
```typescript
// src/index.ts
import { initializeSentry, sentryRequestHandler, sentryErrorHandler } from './utils/monitoring';

initializeSentry();
app.use(sentryRequestHandler());
// ... routes ...
app.use(sentryErrorHandler());
```

**Environment Variables**:
```bash
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
```

### Mobile Setup

**Installation**:
```bash
cd apps/mobile
flutter pub add sentry_flutter
```

**Configuration**:
```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

await SentryFlutter.init(
  (options) {
    options.dsn = 'https://your-sentry-dsn@sentry.io/project-id';
    options.environment = 'production';
    options.tracesSampleRate = 1.0;
  },
  appRunner: () => runApp(const MyApp()),
);
```

### Capturing Errors

**Backend**:
```typescript
import { captureException, addBreadcrumb } from './utils/monitoring';

try {
  // ... operation ...
} catch (error) {
  addBreadcrumb('Operation failed', 'error', 'error');
  captureException(error as Error, { operation: 'signup' });
}
```

**Mobile**:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

try {
  // ... operation ...
} catch (e, stackTrace) {
  await Sentry.captureException(e, stackTrace: stackTrace);
}
```

### Sentry Dashboard

**Access**: https://sentry.io/

**Key Features**:
- Error tracking and grouping
- Stack trace analysis
- Release tracking
- Performance monitoring
- User feedback

---

## Analytics (Firebase)

### Mobile Setup

**Installation**:
```bash
cd apps/mobile
flutter pub add firebase_analytics
```

**Configuration**:
```dart
// lib/services/analytics_service.dart
final analyticsService = AnalyticsService();
await analyticsService.initialize();
```

### Tracking Events

**User Signup**:
```dart
await analyticsService.logSignup(
  method: 'email',
  success: true,
);
```

**User Login**:
```dart
await analyticsService.logLogin(
  method: 'google',
  success: true,
);
```

**Custom Events**:
```dart
await analyticsService.logEvent(
  'flashcard_created',
  parameters: {
    'type': 'multiple_choice',
    'source': 'manual',
  },
);
```

**Review Completion**:
```dart
await analyticsService.logReviewCompleted(
  deckId: 'deck_123',
  cardsReviewed: 10,
  correctCount: 8,
  duration: 300, // seconds
);
```

### Firebase Console

**Access**: https://console.firebase.google.com/

**Key Metrics**:
- User acquisition
- User engagement
- Event tracking
- Conversion funnels
- Retention analysis

---

## Performance Monitoring

### Backend Performance

**Response Time Monitoring**:
```typescript
import { performanceMonitoring } from './utils/monitoring';

app.use(performanceMonitoring());
```

**Slow Request Detection**:
- Requests > 1 second are logged
- Memory usage > 10MB is flagged
- Automatic breadcrumb creation

**Metrics Collection**:
```typescript
import { metricsCollector } from './utils/monitoring';

// Recorded automatically
const metrics = metricsCollector.getMetrics();
// {
//   requestCount: 1000,
//   errorCount: 5,
//   errorRate: "0.50%",
//   avgResponseTime: "45.23ms",
//   uptime: "2.50h"
// }
```

### Mobile Performance

**Operation Timing**:
```dart
final startTime = DateTime.now();
await authService.signIn(email: email, password: password);
final duration = DateTime.now().difference(startTime).inMilliseconds;

await analyticsService.logPerformance(
  operation: 'signin',
  duration: duration,
  success: true,
);
```

**Memory Monitoring**:
```dart
// Automatic via Sentry
// Tracks memory usage and crashes
```

---

## Logging & Log Aggregation

### Backend Logging

**Pino Logger**:
```typescript
import { logger } from './utils/logger';

logger.info('User signed up', { userId, email });
logger.warn('Slow request', { duration: 1500 });
logger.error('Database error', { code: 'ECONNREFUSED' });
```

**Log Levels**:
- `debug` - Detailed debugging information
- `info` - General informational messages
- `warn` - Warning messages
- `error` - Error messages
- `fatal` - Fatal error messages

### ELK Stack Integration

**Elasticsearch**:
```bash
# Store logs
docker run -d --name elasticsearch \
  -e "discovery.type=single-node" \
  docker.elastic.co/elasticsearch/elasticsearch:8.0.0
```

**Logstash**:
```bash
# Process logs
docker run -d --name logstash \
  -v /path/to/logstash.conf:/usr/share/logstash/pipeline/logstash.conf \
  docker.elastic.co/logstash/logstash:8.0.0
```

**Kibana**:
```bash
# Visualize logs
docker run -d --name kibana \
  -p 5601:5601 \
  docker.elastic.co/kibana/kibana:8.0.0
```

### Mobile Logging

**Debug Logging**:
```dart
import '../utils/debug_logger.dart';

DebugLogger.info('AuthService', 'User logged in');
DebugLogger.error('AuthService', 'Login failed', error);
```

**Sentry Logging**:
```dart
await Sentry.captureMessage('User action', level: SentryLevel.info);
```

---

## Health Checks & Metrics

### Health Check Endpoint

**Backend**:
```typescript
// GET /health
{
  "status": "ok",
  "timestamp": "2026-08-23T10:30:00.000Z",
  "environment": "production",
  "version": "1.0.0"
}
```

**Health Metrics**:
```typescript
import { getHealthMetrics } from './utils/monitoring';

const metrics = getHealthMetrics();
// {
//   status: "healthy",
//   uptime: 3600,
//   memory: {
//     heapUsed: "45.23MB",
//     heapTotal: "256.00MB",
//     external: "2.15MB",
//     rss: "300.00MB"
//   },
//   timestamp: "2026-08-23T10:30:00.000Z"
// }
```

### Metrics Endpoint

**Prometheus Format**:
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/health"} 1000

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 500
http_request_duration_seconds_bucket{le="1"} 950
http_request_duration_seconds_bucket{le="+Inf"} 1000
```

---

## Dashboards & Alerts

### Grafana Dashboards

**Setup**:
```bash
docker run -d --name grafana \
  -p 3000:3000 \
  grafana/grafana:latest
```

**Key Dashboards**:
1. **API Performance**
   - Request rate
   - Response time (p50, p95, p99)
   - Error rate
   - Uptime

2. **Error Tracking**
   - Error count
   - Error rate
   - Top errors
   - Error trends

3. **Resource Usage**
   - CPU usage
   - Memory usage
   - Disk usage
   - Network I/O

4. **User Analytics**
   - Active users
   - Signup rate
   - Login success rate
   - Feature usage

### Alert Rules

**Critical Alerts**:
- Error rate > 5%
- Response time p95 > 2 seconds
- Memory usage > 80%
- Uptime < 99%

**Warning Alerts**:
- Error rate > 1%
- Response time p95 > 1 second
- Memory usage > 60%
- Disk usage > 80%

**Example Alert**:
```yaml
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
for: 5m
annotations:
  summary: "High error rate detected"
  description: "Error rate is {{ $value | humanizePercentage }}"
```

---

## Best Practices

### Error Tracking

✅ **Do**:
- Capture all unhandled exceptions
- Include relevant context
- Set user information
- Use error codes
- Group similar errors

❌ **Don't**:
- Log sensitive data
- Capture too much data
- Ignore errors
- Duplicate error reporting
- Send errors to multiple services

### Analytics

✅ **Do**:
- Track important user actions
- Use consistent event names
- Include relevant parameters
- Set user properties
- Monitor conversion funnels

❌ **Don't**:
- Track PII
- Create too many events
- Use inconsistent naming
- Ignore user privacy
- Overload analytics

### Performance Monitoring

✅ **Do**:
- Monitor response times
- Track memory usage
- Monitor error rates
- Set performance budgets
- Alert on anomalies

❌ **Don't**:
- Ignore slow requests
- Let memory grow unbounded
- Ignore performance regressions
- Over-instrument code
- Create noisy alerts

### Logging

✅ **Do**:
- Use structured logging
- Include context
- Use appropriate log levels
- Rotate logs
- Archive old logs

❌ **Don't**:
- Log sensitive data
- Use unstructured logs
- Log too much
- Ignore log storage
- Mix log levels

---

## Monitoring Checklist

### Setup
- [ ] Sentry configured for backend
- [ ] Sentry configured for mobile
- [ ] Firebase Analytics configured
- [ ] Pino logging configured
- [ ] ELK stack deployed
- [ ] Prometheus configured
- [ ] Grafana dashboards created

### Monitoring
- [ ] Error tracking working
- [ ] Analytics events tracked
- [ ] Performance metrics collected
- [ ] Logs aggregated
- [ ] Health checks passing
- [ ] Alerts configured
- [ ] Dashboards updated

### Maintenance
- [ ] Logs rotated regularly
- [ ] Old data archived
- [ ] Alerts reviewed
- [ ] Dashboards updated
- [ ] Metrics analyzed
- [ ] Issues tracked
- [ ] Performance optimized

---

## Troubleshooting

### Sentry Not Capturing Errors

```typescript
// Verify DSN is set
console.log(process.env.SENTRY_DSN);

// Test error capture
try {
  throw new Error('Test error');
} catch (error) {
  captureException(error as Error);
}
```

### Firebase Analytics Not Tracking

```dart
// Verify initialization
await analyticsService.initialize();

// Test event
await analyticsService.logEvent('test_event');

// Check Firebase console
```

### Missing Metrics

```typescript
// Verify middleware is added
app.use(performanceMonitoring());

// Check metrics collection
const metrics = metricsCollector.getMetrics();
console.log(metrics);
```

---

## Resources

### Documentation
- [Sentry Documentation](https://docs.sentry.io/)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [ELK Stack Guide](https://www.elastic.co/guide/index.html)

### Tools
- [Sentry](https://sentry.io/)
- [Firebase Console](https://console.firebase.google.com/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Elastic Stack](https://www.elastic.co/)

---

*Generated: August 23, 2026*  
*Status: Phase 4 - Monitoring Implementation*  
*Next: Phase 5 - Database Migrations & Deployment*
