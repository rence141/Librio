# Railway Deployment Guide - Librio

This guide covers deploying the Librio API (`services/api`) and Admin web app (`apps/admin`) to [Railway](https://railway.app).

## Architecture

```
Railway Project
├── PostgreSQL (Railway provisioned)
├── librio-api      (services/api - Node.js + Express)
└── librio-admin    (apps/admin  - Next.js)
```

## Prerequisites

- [Railway CLI](https://docs.railway.app/develop/cli) installed: `npm install -g @railway/cli`
- Railway account: `railway login`
- Git repo pushed to GitHub (for CI/CD via Railway GitHub integration)

## Step 1: Create Railway Project

```bash
railway init
```

Choose "Empty Project" and name it `librio`.

## Step 2: Add PostgreSQL Database

```bash
railway add postgresql
```

Railway provisions a PostgreSQL instance and provides a `DATABASE_URL` variable automatically.

## Step 3: Deploy the API

### Option A: Railway CLI (manual)

```bash
cd services/api
railway link    # link to the librio project
railway up      # deploy using Dockerfile
```

### Option B: Railway GitHub integration (auto-deploy)

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. New Service > GitHub Repo > Select your repo
3. Set **Root Directory** to `services/api`
4. Railway auto-detects `Dockerfile` and `railway.json`

### API Environment Variables

Set these in the Railway dashboard (or via CLI):

```bash
railway variables set NODE_ENV=production
railway variables set DATABASE_URL=${{Postgres.DATABASE_URL}}
railway variables set JWT_SECRET=<generate 32+ char hex>
railway variables set JWT_REFRESH_SECRET=<generate 32+ char hex>
railway variables set SUPABASE_URL=https://your-project.supabase.co
railway variables set SUPABASE_PUBLISHABLE_KEY=your_publishable_key
railway variables set SUPABASE_SECRET_KEY=your_secret_key
railway variables set SUPABASE_JWKS_URL=https://your-project.supabase.co/auth/v1/.well-known/jwks.json
railway variables set GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
railway variables set GOOGLE_CLIENT_SECRET=your_client_secret
railway variables set CORS_ORIGINS=https://librio-admin.up.railway.app,https://your-custom-domain.com
railway variables set ENABLE_RATE_LIMITING=true
railway variables set ENABLE_ABUSE_DETECTION=true
railway variables set LOG_LEVEL=info
```

Generate JWT secrets:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### API Health Check

After deployment, verify:
```bash
curl https://librio-api.up.railway.app/health
# Expected: {"status":"ok","timestamp":"...","environment":"production","version":"1.0.0"}
```

## Step 4: Deploy the Admin Web App

### Option A: Railway CLI (manual)

```bash
cd apps/admin
railway link    # link to the librio project
railway up      # deploy using Dockerfile
```

### Option B: Railway GitHub integration (auto-deploy)

1. New Service > GitHub Repo > Select your repo
2. Set **Root Directory** to `apps/admin`
3. Railway auto-detects `Dockerfile` and `railway.json`

### Admin Environment Variables

```bash
railway variables set NEXT_PUBLIC_API_URL=https://librio-api.up.railway.app
```

Replace the URL with your actual API Railway domain.

## Step 5: Configure Custom Domains (Optional)

1. Go to Railway dashboard > Service > Settings > Networking
2. Add custom domain (e.g., `app.librio.com` for admin, `api.librio.com` for API)
3. Add a CNAME record in your DNS provider pointing to the Railway-generated domain
4. Update `CORS_ORIGINS` on the API to include the custom admin domain

## Step 6: Database Migrations

Run migrations against the Railway PostgreSQL instance:

```bash
# Get the database URL
railway variables get DATABASE_URL

# Run migrations (from services/api)
cd services/api
DATABASE_URL=<railway-database-url> npm run build && node dist/db/migration-runner.js
```

Or use Railway's shell:
```bash
railway shell
npm run build && node dist/db/migration-runner.js
```

## Files Added

| File | Purpose |
|------|---------|
| `services/api/railway.json` | Railway build/deploy config for API |
| `services/api/Dockerfile` | Docker build for API (multi-stage) |
| `apps/admin/railway.json` | Railway build/deploy config for Admin |
| `apps/admin/Dockerfile` | Updated for Railway (PORT env, healthcheck) |

## Environment Variables Reference

### API (`services/api`)

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string (auto from Railway Postgres) |
| `JWT_SECRET` | Yes | JWT signing secret (32+ chars) |
| `JWT_REFRESH_SECRET` | Yes | JWT refresh token secret (32+ chars) |
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | Supabase anon/publishable key |
| `SUPABASE_SECRET_KEY` | Yes | Supabase service role key |
| `SUPABASE_JWKS_URL` | Yes | Supabase JWKS URL for token verification |
| `GOOGLE_CLIENT_ID` | No | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | No | Google OAuth client secret |
| `CORS_ORIGINS` | No | Comma-separated allowed origins (defaults to localhost) |
| `SENTRY_DSN` | No | Sentry error tracking DSN |
| `PORT` | Auto | Set by Railway automatically |
| `NODE_ENV` | Recommended | Set to `production` |

### Admin (`apps/admin`)

| Variable | Required | Description |
|----------|----------|-------------|
| `NEXT_PUBLIC_API_URL` | Yes | URL of the deployed API service |
| `PORT` | Auto | Set by Railway automatically |

## Troubleshooting

### Build fails: "npm ci" error
Ensure `package-lock.json` exists in the service directory. Run `npm install` locally first to generate it.

### Health check fails
- Verify the service is listening on the PORT env var (Railway sets this automatically)
- API: checks `/health` endpoint
- Admin: checks `/` endpoint

### CORS errors
Set `CORS_ORIGINS` on the API to include the admin's Railway domain:
```bash
railway variables set CORS_ORIGINS=https://librio-admin.up.railway.app
```

### Database connection fails
- Verify PostgreSQL service is running in Railway
- Verify `DATABASE_URL` is set (should reference `${{Postgres.DATABASE_URL}}`)
- Check that migrations have been run

### Next.js images not loading
The admin app uses `images: { unoptimized: true }` in `next.config.js`, which is compatible with Railway without needing an image optimization server.
