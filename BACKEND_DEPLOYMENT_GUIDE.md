# Librio: Backend Deployment Guide

**Date:** 2026-08-22  
**Status:** Ready for Deployment  
**Target:** Week 17-18 (2026-09-29 to 2026-10-06)

---

## 🎯 OBJECTIVE

Deploy the Node.js backend API to production and configure Supabase for data persistence.

---

## 📋 PREREQUISITES

### **Required Accounts**
- [ ] Supabase account (https://supabase.com)
- [ ] Deployment platform account (Railway, Render, or AWS)
- [ ] GitHub account (for CI/CD)

### **Required Tools**
- [ ] Node.js v24.13.0
- [ ] npm 11.6.2
- [ ] Docker (for local testing)
- [ ] Git

---

## 🔧 STEP 1: SET UP SUPABASE PROJECT

### **1.1 Create Supabase Project**

```bash
# Go to https://supabase.com
# Click "New Project"
# Fill in project details:
# - Name: librio-prod
# - Database Password: [strong password]
# - Region: [closest to users]
# - Click "Create new project"
```

### **1.2 Get Connection Details**

```bash
# In Supabase dashboard:
# 1. Go to Settings > Database
# 2. Copy "Connection string" (PostgreSQL)
# 3. Copy "Project URL"
# 4. Copy "Anon Key"
# 5. Copy "Service Role Key"
```

### **1.3 Create Environment File**

```bash
cd services/api

# Create .env.production
cat > .env.production << EOF
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DATABASE_URL=postgresql://postgres:password@db.supabase.co:5432/postgres

# JWT
JWT_SECRET=your-jwt-secret-key-min-32-chars

# API
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# CORS
CORS_ORIGIN=https://librio.app

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Never commit .env files
echo ".env.production" >> .gitignore
```

---

## 🗄️ STEP 2: CREATE DATABASE SCHEMA

### **2.1 Create Migration Files**

```bash
cd services/api

# Create migrations directory
mkdir -p migrations

# Create user_profiles migration
cat > migrations/001_create_user_profiles.sql << 'EOF'
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_user_profiles_email ON user_profiles(email);
EOF

# Create documents migration
cat > migrations/002_create_documents.sql << 'EOF'
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id),
  title VARCHAR(255) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_documents_user_id ON documents(user_id);
EOF

# Create sessions migration
cat > migrations/003_create_sessions.sql << 'EOF'
CREATE TABLE IF NOT EXISTS sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id),
  token VARCHAR(500) NOT NULL UNIQUE,
  refresh_token VARCHAR(500) NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token);
EOF

# Create benchmarks migration
cat > migrations/004_create_benchmarks.sql << 'EOF'
CREATE TABLE IF NOT EXISTS benchmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id),
  model_name VARCHAR(100) NOT NULL,
  device_name VARCHAR(100) NOT NULL,
  battery_usage FLOAT,
  memory_usage FLOAT,
  load_time FLOAT,
  inference_speed FLOAT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_benchmarks_user_id ON benchmarks(user_id);
EOF

# Create messages migration
cat > migrations/005_create_messages.sql << 'EOF'
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id),
  content TEXT NOT NULL,
  role VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_user_id ON messages(user_id);
EOF
```

### **2.2 Run Migrations**

```bash
# Using Supabase SQL Editor:
# 1. Go to Supabase Dashboard
# 2. Click "SQL Editor"
# 3. Create new query
# 4. Copy and paste each migration file
# 5. Execute

# Or use psql:
psql "$DATABASE_URL" < migrations/001_create_user_profiles.sql
psql "$DATABASE_URL" < migrations/002_create_documents.sql
psql "$DATABASE_URL" < migrations/003_create_sessions.sql
psql "$DATABASE_URL" < migrations/004_create_benchmarks.sql
psql "$DATABASE_URL" < migrations/005_create_messages.sql
```

---

## 🚀 STEP 3: BUILD AND TEST LOCALLY

### **3.1 Install Dependencies**

```bash
cd services/api
npm install
```

### **3.2 Build TypeScript**

```bash
npm run build
```

### **3.3 Test API Locally**

```bash
# Start API
npm run dev

# In another terminal, test endpoints
curl http://localhost:3000/health
# Should return: { "status": "ok" }

# Test signup
curl -X POST http://localhost:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Test login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## 🌐 STEP 4: DEPLOY TO PRODUCTION

### **Option A: Deploy to Railway**

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Link project
cd services/api
railway link

# Set environment variables
railway variables set SUPABASE_URL=https://your-project.supabase.co
railway variables set SUPABASE_KEY=your-anon-key
railway variables set DATABASE_URL=postgresql://...
railway variables set JWT_SECRET=your-jwt-secret

# Deploy
railway up

# Get deployment URL
railway status
```

### **Option B: Deploy to Render**

```bash
# Create render.yaml in services/api
cat > render.yaml << 'EOF'
services:
  - type: web
    name: librio-api
    env: node
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm run start
    envVars:
      - key: NODE_ENV
        value: production
      - key: SUPABASE_URL
        fromDatabase:
          name: librio-db
          property: connectionString
      - key: JWT_SECRET
        sync: false
EOF

# Push to GitHub
git add render.yaml
git commit -m "Add Render deployment config"
git push

# Go to https://render.com
# Click "New +"
# Select "Web Service"
# Connect GitHub repository
# Configure environment variables
# Deploy
```

### **Option C: Deploy to AWS Lambda**

```bash
# Install serverless framework
npm install -g serverless

# Create serverless.yml
cat > serverless.yml << 'EOF'
service: librio-api

provider:
  name: aws
  runtime: nodejs18.x
  region: us-east-1
  environment:
    SUPABASE_URL: ${env:SUPABASE_URL}
    SUPABASE_KEY: ${env:SUPABASE_KEY}
    DATABASE_URL: ${env:DATABASE_URL}
    JWT_SECRET: ${env:JWT_SECRET}

functions:
  api:
    handler: dist/index.handler
    events:
      - http:
          path: /{proxy+}
          method: ANY
          cors: true
EOF

# Deploy
serverless deploy
```

---

## ✅ STEP 5: VERIFY DEPLOYMENT

### **5.1 Test Health Check**

```bash
# Replace with your deployment URL
curl https://librio-api.railway.app/health
# Should return: { "status": "ok" }
```

### **5.2 Test Authentication**

```bash
# Signup
curl -X POST https://librio-api.railway.app/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Should return: { "token": "...", "refreshToken": "...", "userId": "..." }
```

### **5.3 Test Content Endpoints**

```bash
# Get all packs
curl https://librio-api.railway.app/content/packs \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get topics
curl https://librio-api.railway.app/content/packs/Mathematics \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🔐 STEP 6: CONFIGURE SECURITY

### **6.1 Enable HTTPS**

```bash
# Most deployment platforms auto-enable HTTPS
# Verify: curl -I https://librio-api.railway.app
# Should show: HTTP/2 200
```

### **6.2 Set CORS Headers**

```bash
# In services/api/src/index.ts
app.use(cors({
  origin: ['https://librio.app', 'https://www.librio.app'],
  credentials: true,
}));
```

### **6.3 Enable Rate Limiting**

```bash
# Already implemented in api_service.dart
# Verify in services/api/src/middleware/rateLimit.ts
```

### **6.4 Set Database Permissions**

```sql
-- In Supabase SQL Editor
-- Enable RLS (Row Level Security)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);
```

---

## 📊 STEP 7: SET UP MONITORING

### **7.1 Enable Logging**

```bash
# In services/api/.env.production
LOG_LEVEL=info

# Logs will be sent to:
# - Railway: https://railway.app/project/[id]/logs
# - Render: https://dashboard.render.com/services/[id]/logs
# - AWS: CloudWatch Logs
```

### **7.2 Set Up Alerts**

```bash
# In deployment platform dashboard:
# 1. Go to Monitoring/Alerts
# 2. Create alert for:
#    - High error rate (>5%)
#    - High response time (>1000ms)
#    - Low uptime (<99%)
# 3. Set notification email
```

### **7.3 Enable Backups**

```bash
# In Supabase:
# 1. Go to Settings > Backups
# 2. Enable automatic backups
# 3. Set backup frequency: Daily
# 4. Set retention: 30 days
```

---

## 🔄 STEP 8: UPDATE MOBILE APP

### **8.1 Update API Base URL**

```dart
// In apps/mobile/lib/services/api_service.dart
static const String baseUrl = 'https://librio-api.railway.app';
```

### **8.2 Rebuild and Test**

```bash
cd apps/mobile
flutter pub get
flutter run
```

### **8.3 Test Authentication Flow**

```bash
# 1. Launch app
# 2. Go to signup screen
# 3. Create account with test email
# 4. Verify account created in Supabase
# 5. Login with same credentials
# 6. Verify login successful
```

---

## 📋 DEPLOYMENT CHECKLIST

- [ ] Supabase project created
- [ ] Database migrations applied
- [ ] Environment variables configured
- [ ] API built and tested locally
- [ ] API deployed to production
- [ ] Health check passing
- [ ] Authentication working
- [ ] Content endpoints working
- [ ] HTTPS enabled
- [ ] CORS configured
- [ ] Rate limiting enabled
- [ ] Logging enabled
- [ ] Backups enabled
- [ ] Mobile app updated with API URL
- [ ] End-to-end testing complete

---

## 🚨 TROUBLESHOOTING

### **Issue: Database Connection Failed**

```bash
# Check connection string
echo $DATABASE_URL

# Test connection
psql "$DATABASE_URL" -c "SELECT 1"

# If failed, verify:
# 1. Supabase project is running
# 2. Connection string is correct
# 3. Firewall allows connections
```

### **Issue: API Returns 500 Error**

```bash
# Check logs
# Railway: https://railway.app/project/[id]/logs
# Render: https://dashboard.render.com/services/[id]/logs

# Common causes:
# 1. Missing environment variables
# 2. Database connection failed
# 3. JWT secret not set
# 4. CORS misconfigured
```

### **Issue: Authentication Not Working**

```bash
# Verify:
# 1. JWT_SECRET is set
# 2. Token is being returned
# 3. Token is being sent in Authorization header
# 4. Token is valid (not expired)
```

---

## 📞 NEXT STEPS

1. [ ] Create Supabase project
2. [ ] Apply database migrations
3. [ ] Deploy API to production
4. [ ] Verify all endpoints working
5. [ ] Update mobile app with API URL
6. [ ] Test end-to-end authentication
7. [ ] Monitor logs and performance

---

Generated: 2026-08-22  
Target Deployment: Week 17-18 (2026-09-29 to 2026-10-06)
