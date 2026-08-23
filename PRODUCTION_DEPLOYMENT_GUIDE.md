# Production Deployment Guide - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: READY FOR IMPLEMENTATION

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Setup](#environment-setup)
3. [Database Setup](#database-setup)
4. [Backend Deployment](#backend-deployment)
5. [Mobile App Deployment](#mobile-app-deployment)
6. [Post-Deployment Verification](#post-deployment-verification)
7. [Monitoring & Alerting](#monitoring--alerting)
8. [Rollback Procedures](#rollback-procedures)
9. [Troubleshooting](#troubleshooting)

---

## Pre-Deployment Checklist

### Security ✅

- [ ] All secrets rotated and stored in secure vault (AWS Secrets Manager, HashiCorp Vault, etc.)
- [ ] `.env` files NOT committed to git
- [ ] `.env.example` with placeholders committed to git
- [ ] SSL/TLS certificates obtained and configured
- [ ] CORS origins configured for production domains
- [ ] Rate limiting enabled
- [ ] CSRF protection enabled
- [ ] Security headers configured
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention verified (parameterized queries)

### Code Quality ✅

- [ ] All tests passing (unit, integration, API)
- [ ] Code coverage > 70%
- [ ] Linting passes (ESLint, Dart analyzer)
- [ ] Type checking passes (TypeScript strict mode)
- [ ] No console.log statements in production code
- [ ] No hardcoded credentials in code
- [ ] No TODO comments in critical code paths

### Database ✅

- [ ] Database migrations tested on staging
- [ ] Backup strategy implemented
- [ ] Restore procedures tested
- [ ] Database indexes optimized
- [ ] Connection pooling configured
- [ ] Monitoring queries set up

### Infrastructure ✅

- [ ] Production servers provisioned
- [ ] Load balancer configured
- [ ] CDN configured (if applicable)
- [ ] DNS records updated
- [ ] SSL certificates installed
- [ ] Firewall rules configured
- [ ] Monitoring tools installed

### Documentation ✅

- [ ] Deployment runbook completed
- [ ] Operational runbook completed
- [ ] Architecture documentation updated
- [ ] API documentation up-to-date
- [ ] Incident response plan created
- [ ] Team trained on deployment procedures

---

## Environment Setup

### 1. Production Environment Variables

Create `.env` file on production server (NEVER commit to git):

```bash
# Server Configuration
NODE_ENV=production
PORT=3000

# Database
DATABASE_URL=postgresql://prod_user:strong_password@prod-db.example.com:5432/librio_prod

# JWT Secrets (generate new ones for production)
JWT_SECRET=<generate-with-openssl-rand-hex-32>
JWT_REFRESH_SECRET=<generate-with-openssl-rand-hex-32>

# Supabase (production project)
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=<production-key>
SUPABASE_SECRET_KEY=<production-secret>
SUPABASE_JWKS_URL=https://your-prod-project.supabase.co/auth/v1/.well-known/jwks.json

# Google OAuth (production credentials)
GOOGLE_CLIENT_ID=<production-client-id>
GOOGLE_CLIENT_SECRET=<production-client-secret>

# Error Tracking
SENTRY_DSN=<production-sentry-dsn>

# Analytics
FIREBASE_PROJECT_ID=<production-firebase-project>

# Email Service
SENDGRID_API_KEY=<production-sendgrid-key>

# Production Configuration
ENABLE_RATE_LIMITING=true
ENABLE_ABUSE_DETECTION=true
ENABLE_SECURITY_HEADERS=true

# CORS Configuration
CORS_ORIGINS=https://app.librio.com,https://www.librio.com

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
```

### 2. Generate Secure Secrets

```bash
# Generate JWT secrets (32 bytes = 64 hex characters)
openssl rand -hex 32

# Generate database password
openssl rand -base64 32

# Generate API keys
openssl rand -hex 16
```

### 3. Store Secrets Securely

**Option A: AWS Secrets Manager**
```bash
aws secretsmanager create-secret \
  --name librio/production \
  --secret-string file://secrets.json
```

**Option B: HashiCorp Vault**
```bash
vault kv put secret/librio/production \
  jwt_secret="..." \
  jwt_refresh_secret="..." \
  database_url="..."
```

**Option C: Environment Variables**
```bash
# On production server (e.g., systemd service)
export JWT_SECRET="..."
export JWT_REFRESH_SECRET="..."
```

---

## Database Setup

### 1. Create Production Database

```bash
# Connect to production PostgreSQL
psql -h prod-db.example.com -U postgres

# Create database
CREATE DATABASE librio_prod;

# Create user with limited privileges
CREATE USER librio_prod WITH PASSWORD 'strong_password';

# Grant privileges
GRANT CONNECT ON DATABASE librio_prod TO librio_prod;
GRANT USAGE ON SCHEMA public TO librio_prod;
GRANT CREATE ON SCHEMA public TO librio_prod;
```

### 2. Run Database Migrations

```bash
cd services/api

# Set production database URL
export DATABASE_URL="postgresql://librio_prod:password@prod-db.example.com:5432/librio_prod"

# Run migrations
npm run migrate:up

# Verify migrations
npm run migrate:status
```

### 3. Create Backups

```bash
# Full backup
pg_dump -h prod-db.example.com -U librio_prod librio_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
pg_dump -h prod-db.example.com -U librio_prod librio_prod | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Store backups securely
aws s3 cp backup_*.sql.gz s3://librio-backups/
```

### 4. Configure Connection Pooling

```javascript
// services/api/src/config/database.ts
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // Max connections
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 2000,
});
```

---

## Backend Deployment

### Option 1: Docker + Kubernetes

```bash
# Build Docker image
cd services/api
docker build -t librio-api:1.0.0 .

# Push to registry
docker tag librio-api:1.0.0 your-registry.com/librio-api:1.0.0
docker push your-registry.com/librio-api:1.0.0

# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Verify deployment
kubectl get pods
kubectl logs -f deployment/librio-api
```

### Option 2: Traditional Server (Node.js)

```bash
# SSH into production server
ssh ubuntu@prod-server.example.com

# Clone repository
git clone https://github.com/your-org/librio.git
cd librio/services/api

# Install dependencies
npm ci --production

# Build TypeScript
npm run build

# Create systemd service
sudo tee /etc/systemd/system/librio-api.service << EOF
[Unit]
Description=Librio API Server
After=network.target

[Service]
Type=simple
User=librio
WorkingDirectory=/home/librio/librio/services/api
EnvironmentFile=/home/librio/.env
ExecStart=/usr/bin/node dist/index.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable librio-api
sudo systemctl start librio-api

# Check status
sudo systemctl status librio-api
```

### Option 3: Heroku

```bash
# Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# Login to Heroku
heroku login

# Create app
heroku create librio-api

# Set environment variables
heroku config:set NODE_ENV=production
heroku config:set JWT_SECRET=...
heroku config:set DATABASE_URL=...

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

---

## Mobile App Deployment

### Android (Google Play)

```bash
# Build release APK
cd apps/mobile
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Sign APK (if not already signed)
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore librio-release-key.jks \
  build/app/outputs/flutter-apk/app-release.apk \
  librio-key

# Upload to Google Play Console
# 1. Go to https://play.google.com/console
# 2. Select your app
# 3. Go to Release > Production
# 4. Upload App Bundle
# 5. Review and publish
```

### iOS (App Store)

```bash
# Build release IPA
cd apps/mobile
flutter build ios --release

# Archive for App Store
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device (arm64)"
# 2. Product > Archive
# 3. Distribute App
# 4. Select "App Store Connect"
# 5. Upload
```

---

## Post-Deployment Verification

### 1. Health Checks

```bash
# Check API health
curl https://api.librio.com/health

# Expected response:
# {
#   "status": "ok",
#   "timestamp": "2026-08-23T...",
#   "environment": "production",
#   "version": "1.0.0"
# }
```

### 2. Database Connectivity

```bash
# Test database connection
curl https://api.librio.com/api/v1/status

# Expected response:
# {
#   "service": "librio-api",
#   "version": "1.0.0",
#   "environment": "production",
#   "features": { ... }
# }
```

### 3. Authentication Flow

```bash
# Test signup
curl -X POST https://api.librio.com/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123",
    "fullName": "Test User"
  }'

# Test login
curl -X POST https://api.librio.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123"
  }'
```

### 4. Mobile App Testing

- [ ] Install app from Play Store/App Store
- [ ] Test signup flow
- [ ] Test login flow
- [ ] Test Google Sign-In
- [ ] Test flashcard creation
- [ ] Test flashcard review
- [ ] Test offline functionality
- [ ] Test sync when online

---

## Monitoring & Alerting

### 1. Set Up Error Tracking (Sentry)

```bash
# Install Sentry CLI
npm install -g @sentry/cli

# Create Sentry project
sentry-cli projects create --organization your-org librio-api

# Configure in app
# services/api/src/index.ts
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());
```

### 2. Set Up Monitoring (Prometheus + Grafana)

```bash
# Install Prometheus client
npm install prom-client

# Configure metrics
# services/api/src/middleware/metrics.ts
import promClient from 'prom-client';

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});
```

### 3. Set Up Logging (ELK Stack or CloudWatch)

```bash
# AWS CloudWatch
npm install aws-sdk winston-cloudwatch

# Configure logging
import WinstonCloudWatch from 'winston-cloudwatch';

logger.add(new WinstonCloudWatch({
  logGroupName: '/aws/lambda/librio-api',
  logStreamName: 'production',
}));
```

### 4. Create Alerts

**Alert Rules**:
- API response time > 1 second
- Error rate > 1%
- Database connection errors
- Memory usage > 80%
- Disk usage > 90%
- Unauthorized access attempts

---

## Rollback Procedures

### Rollback to Previous Version

```bash
# Get previous deployment
git log --oneline | head -5

# Checkout previous version
git checkout <previous-commit-hash>

# Rebuild and redeploy
npm run build
npm run start

# Or with Docker
docker pull your-registry.com/librio-api:previous-version
docker run -d --name librio-api your-registry.com/librio-api:previous-version
```

### Database Rollback

```bash
# Restore from backup
psql -h prod-db.example.com -U librio_prod librio_prod < backup_20260823_120000.sql

# Or with AWS RDS
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier librio-prod-restored \
  --db-snapshot-identifier librio-prod-snapshot-20260823
```

### Mobile App Rollback

**Google Play**:
1. Go to Google Play Console
2. Select app
3. Go to Release > Production
4. Click "Manage releases"
5. Select previous version
6. Click "Rollback"

---

## Troubleshooting

### API Not Responding

```bash
# Check service status
sudo systemctl status librio-api

# Check logs
sudo journalctl -u librio-api -n 50

# Check port
sudo netstat -tlnp | grep 3000

# Restart service
sudo systemctl restart librio-api
```

### Database Connection Issues

```bash
# Test connection
psql -h prod-db.example.com -U librio_prod -d librio_prod -c "SELECT 1"

# Check connection pool
curl https://api.librio.com/api/v1/status | jq .database

# Increase pool size if needed
# services/api/src/config/database.ts
max: 50  // Increase from 20
```

### High Memory Usage

```bash
# Check memory
free -h

# Check Node.js memory
node --max-old-space-size=4096 dist/index.js

# Enable garbage collection logging
node --trace-gc dist/index.js
```

### SSL Certificate Issues

```bash
# Check certificate expiration
openssl s_client -connect api.librio.com:443 -showcerts | grep "Not After"

# Renew certificate (Let's Encrypt)
sudo certbot renew --force-renewal

# Restart service
sudo systemctl restart librio-api
```

---

## Deployment Checklist

### Pre-Deployment (24 hours before)

- [ ] All tests passing
- [ ] Code review completed
- [ ] Security audit passed
- [ ] Database backups created
- [ ] Rollback plan documented
- [ ] Team notified
- [ ] Maintenance window scheduled

### Deployment Day

- [ ] Deploy to staging first
- [ ] Run smoke tests on staging
- [ ] Get approval from tech lead
- [ ] Deploy to production
- [ ] Monitor error rates
- [ ] Monitor response times
- [ ] Monitor database performance
- [ ] Verify all features working

### Post-Deployment (24 hours after)

- [ ] Monitor error tracking
- [ ] Monitor performance metrics
- [ ] Collect user feedback
- [ ] Document any issues
- [ ] Update documentation
- [ ] Schedule retrospective

---

## Support & Escalation

**Issues During Deployment**:
1. Check logs: `sudo journalctl -u librio-api -n 100`
2. Check metrics: `curl https://api.librio.com/metrics`
3. Check database: `psql ... -c "SELECT 1"`
4. Rollback if critical: See [Rollback Procedures](#rollback-procedures)
5. Escalate to on-call engineer

**Contact**:
- On-Call: `#librio-oncall` Slack channel
- Tech Lead: `@tech-lead` Slack
- DevOps: `#devops` Slack

---

*Last Updated: August 23, 2026*  
*Next Review: After first production deployment*
