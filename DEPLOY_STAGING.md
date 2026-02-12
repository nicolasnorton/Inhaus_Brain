# Staging Deployment Guide — InhausBrain

## Overview

Deploy InhausBrain to the **staging environment** (`inhausbrain-beta.web.app`).
This guide is for changes on the `gemini-gemma-vertex-overhaul-staging-2026` branch only.

> ⚠️ This script never touches production. It deploys ONLY to the `inhaus-brain` (beta) hosting target.

## Prerequisites

1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged in: `firebase login`
3. On the correct branch: `git branch --show-current` → `gemini-gemma-vertex-overhaul-staging-2026`
4. `.env` file populated with required API keys

## Quick Deploy

```bash
./deploy_staging.sh
```

## Manual Steps

### 1. Build Web App (Staging)

```bash
flutter build web --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=ENVIRONMENT=staging
```

### 2. Deploy Firebase Hosting (Beta Target Only)

```bash
firebase deploy --only hosting:inhaus-brain
```

This deploys to `inhausbrain-beta.web.app` (NOT `brain.inhauscorp.com`).

### 3. Deploy Cloud Functions (Optional)

```bash
# JS Functions
firebase deploy --only functions:default

# Python Functions
firebase deploy --only functions:python-extract
```

> **Note**: Cloud Functions are shared between staging and production.
> New behavior is guarded by `AppConfig.isStaging` and `FeatureFlags`.

### 4. Verify

- Open https://inhausbrain-beta.web.app
- Check environment indicator shows "STAGING"
- Test AI chat — confirm Gemini 2.5 Flash responses
- If Gemma flags enabled, verify Gemma model option appears in picker

## Environment Detection

The app detects staging via (in order of priority):
1. `--dart-define=ENVIRONMENT=staging` (compile-time)
2. Hostname contains `beta` or `staging` (runtime)
3. Debug mode = staging, Release mode = production (fallback)

## Safety Checks

- ✅ `deploy_staging.sh` only targets `inhaus-brain` hosting
- ✅ No Cloud Run deployment (that's production-only via `deploy.sh`)
- ✅ Gemma/experimental features gated behind `FeatureFlags`
- ✅ Production URL `brain.inhauscorp.com` remains untouched
