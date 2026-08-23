# Deployment Automation Guide - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: Phase 5 - Database Migrations & Deployment

---

## Table of Contents

1. [Overview](#overview)
2. [Deployment Pipeline](#deployment-pipeline)
3. [Docker Containerization](#docker-containerization)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [Deployment Scripts](#deployment-scripts)
6. [Rollback Procedures](#rollback-procedures)
7. [Deployment Checklist](#deployment-checklist)

---

## Overview

Librio uses a fully automated deployment pipeline with multiple stages and safety checks.

### Deployment Environments

| Environment | Purpose | Frequency | Approval |
|-------------|---------|-----------|----------|
| Development | Local testing | Continuous | None |
| Staging | Pre-production testing | Per PR | Automatic |
| Production | Live application | Scheduled | Manual |

### Deployment Strategy

**Blue-Green Deployment**:
- Deploy new version alongside current
- Route traffic after validation
- Instant rollback if issues
- Zero downtime

---

## Deployment Pipeline

### Pipeline Stages

```
┌─────────────┐
│ Git Commit  │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ 1. Build & Test     │
│ - Lint              │
│ - Type Check        │
│ - Unit Tests        │
│ - Integration Tests  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 2. Build Artifacts  │
│ - Docker Image      │
│ - Mobile APK        │
│ - API Docs          │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 3. Push to Registry │
│ - ECR/Docker Hub    │
│ - Artifact Storage  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 4. Deploy to Staging│
│ - Run Migrations    │
│ - Deploy Services   │
│ - Run Smoke Tests   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 5. Manual Approval  │
│ - Review Changes    │
│ - Verify Staging    │
│ - Approve Deploy    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 6. Deploy to Prod   │
│ - Blue-Green Deploy │
│ - Health Checks     │
│ - Traffic Shift     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 7. Monitor & Verify │
│ - Error Rates       │
│ - Performance       │
│ - User Feedback     │
└─────────────────────┘
```

### GitHub Actions Workflow

**File**: `.github/workflows/deploy.yml`

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: services/api
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  test:
    runs-on: ubuntu-latest
    needs: build

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: librio_test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'services/api/package-lock.json'

      - name: Install dependencies
        working-directory: services/api
        run: npm ci

      - name: Run tests
        working-directory: services/api
        run: npm test
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/librio_test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./services/api/coverage/coverage-final.json

  deploy-staging:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Staging
        run: |
          ./scripts/deploy.sh staging ${{ github.sha }}
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          STAGING_HOST: staging.librio.internal

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://librio.app

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Production
        run: |
          ./scripts/deploy.sh production ${{ github.sha }}
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          PROD_HOST: api.librio.app

      - name: Notify Slack
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK }}
          payload: |
            {
              "text": "✅ Deployment successful",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Librio Production Deployment*\nCommit: ${{ github.sha }}\nAuthor: ${{ github.actor }}"
                  }
                }
              ]
            }
```

---

## Docker Containerization

### Dockerfile (Backend)

**File**: `services/api/Dockerfile`

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Runtime stage
FROM node:20-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Copy from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Expose port
EXPOSE 3000

# Use dumb-init to handle signals
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/index.js"]
```

### Docker Compose (Local Development)

**File**: `docker-compose.yml`

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: librio_dev
      POSTGRES_USER: librio
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U librio"]
      interval: 10s
      timeout: 5s
      retries: 5

  api:
    build:
      context: services/api
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql://librio:dev_password@postgres:5432/librio_dev
      NODE_ENV: development
      JWT_SECRET: dev_secret_key_min_32_chars_long
      JWT_REFRESH_SECRET: dev_refresh_secret_key_min_32_chars
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./services/api/src:/app/src
    command: npm run dev

volumes:
  postgres_data:
```

---

## Kubernetes Deployment

### Kubernetes Manifests

**File**: `k8s/api-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: librio-api
  labels:
    app: librio-api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: librio-api
  template:
    metadata:
      labels:
        app: librio-api
    spec:
      containers:
      - name: api
        image: ghcr.io/librio/api:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: librio-secrets
              key: database-url
        - name: NODE_ENV
          value: "production"
        - name: SENTRY_DSN
          valueFrom:
            secretKeyRef:
              name: librio-secrets
              key: sentry-dsn
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        securityContext:
          runAsNonRoot: true
          runAsUser: 1001
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
              - ALL

---
apiVersion: v1
kind: Service
metadata:
  name: librio-api
spec:
  type: LoadBalancer
  selector:
    app: librio-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: librio-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: librio-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## Deployment Scripts

### Deploy Script

**File**: `scripts/deploy.sh`

```bash
#!/bin/bash
set -e

ENVIRONMENT=$1
COMMIT_SHA=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$COMMIT_SHA" ]; then
  echo "Usage: deploy.sh <environment> <commit_sha>"
  exit 1
fi

echo "🚀 Deploying to $ENVIRONMENT (commit: $COMMIT_SHA)"

# Load environment variables
source "scripts/env/$ENVIRONMENT.env"

# 1. Build Docker image
echo "📦 Building Docker image..."
docker build \
  --tag "$REGISTRY/$IMAGE_NAME:$COMMIT_SHA" \
  --tag "$REGISTRY/$IMAGE_NAME:latest" \
  services/api

# 2. Push to registry
echo "📤 Pushing to registry..."
docker push "$REGISTRY/$IMAGE_NAME:$COMMIT_SHA"
docker push "$REGISTRY/$IMAGE_NAME:latest"

# 3. Run migrations
echo "🗄️  Running database migrations..."
docker run --rm \
  -e DATABASE_URL="$DATABASE_URL" \
  "$REGISTRY/$IMAGE_NAME:$COMMIT_SHA" \
  npm run migrate

# 4. Deploy to Kubernetes
echo "☸️  Deploying to Kubernetes..."
kubectl set image deployment/librio-api \
  api="$REGISTRY/$IMAGE_NAME:$COMMIT_SHA" \
  --namespace=$K8S_NAMESPACE \
  --record

# 5. Wait for rollout
echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/librio-api \
  --namespace=$K8S_NAMESPACE \
  --timeout=5m

# 6. Run smoke tests
echo "🧪 Running smoke tests..."
./scripts/smoke-tests.sh "$ENVIRONMENT"

# 7. Notify
echo "✅ Deployment successful!"
```

### Rollback Script

**File**: `scripts/rollback.sh`

```bash
#!/bin/bash
set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: rollback.sh <environment>"
  exit 1
fi

echo "⏮️  Rolling back $ENVIRONMENT..."

source "scripts/env/$ENVIRONMENT.env"

# Rollback to previous revision
kubectl rollout undo deployment/librio-api \
  --namespace=$K8S_NAMESPACE

# Wait for rollout
kubectl rollout status deployment/librio-api \
  --namespace=$K8S_NAMESPACE \
  --timeout=5m

# Verify
./scripts/smoke-tests.sh "$ENVIRONMENT"

echo "✅ Rollback successful!"
```

---

## Rollback Procedures

### Automatic Rollback

**Triggers**:
- Health check failures (> 3 consecutive)
- Error rate spike (> 10%)
- Response time degradation (> 2x baseline)
- Out of memory errors

**Procedure**:
```bash
# 1. Detect failure
# 2. Trigger automatic rollback
# 3. Verify rollback
# 4. Notify team
# 5. Create incident
```

### Manual Rollback

**Steps**:
1. Assess issue
2. Decide to rollback
3. Run rollback script
4. Verify application
5. Investigate root cause
6. Document incident

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code review approved
- [ ] Security scan passed
- [ ] Performance benchmarks met
- [ ] Database migrations tested
- [ ] Rollback plan documented
- [ ] Team notified

### Deployment
- [ ] Backup created
- [ ] Migrations executed
- [ ] New version deployed
- [ ] Health checks passing
- [ ] Smoke tests passed
- [ ] Monitoring verified
- [ ] Alerts configured

### Post-Deployment
- [ ] Error rates normal
- [ ] Performance metrics good
- [ ] User reports monitored
- [ ] Logs reviewed
- [ ] Metrics analyzed
- [ ] Team debriefing
- [ ] Documentation updated

---

*Generated: August 23, 2026*  
*Status: Phase 5 - Deployment Automation*  
*Next: Operational Runbook*
