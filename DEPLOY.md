# Deployment Guide

This guide outlines the steps to deploy the **Inhaus Brain** application to Google Cloud Run. 
./deploy.sh. 
**Production URL**: [https://brain.inhauscorp.com](https://brain.inhauscorp.com)
**Project ID**: `inhausbrain`

## Prerequisites
1.  **Google Cloud SDK**: Install and initialize (`gcloud init`).
2.  **Access**: You must have permission to deploy to the `inhausbrain` project.
3.  **Google APIs**: Ensure the **Google People API** is ENABLED for the project. This is required for Google Sign-In to fetch user profiles.
    -   [Enable People API Console Link](https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=inhausbrain)

## Quick Start: One-Click Deployment
We have provided a helper script to automate the build and deployment process.

```bash
./deploy.sh
```

This script will:
1.  Build the Flutter Web app in a Docker container.
2.  Push the container to Google Cloud Artifact Registry.
3.  Deploy the new revision to Cloud Run.

## Manual Deployment Checklist
If you prefer to run commands manually:

```bash
```bash
# 1. Set the project
gcloud config set project inhausbrain

# 2. Generate a Tag (Git Short Hash or Timestamp)
TAG=$(git rev-parse --short HEAD)
# Or: TAG=$(date +%Y%m%d%H%M%S)

# 3. Submit build to Cloud Build (Pushes both :$TAG and :latest)
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions="_VERTEX_API_KEY=$VERTEX_API_KEY,_GEMINI_API_KEY=$GEMINI_API_KEY,_TAG=$TAG" \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# 4. Deploy the specific version to Cloud Run
gcloud run deploy inhaus-brain \
  --image gcr.io/inhausbrain/inhaus-brain:$TAG \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "VERTEX_API_KEY=$VERTEX_API_KEY,GEMINI_API_KEY=$GEMINI_API_KEY"
```
```

**Note**: You must have `VERTEX_API_KEY` and `GEMINI_API_KEY` exported in your terminal session for these commands to work.


## Troubleshooting

### Cloud Build: Permission Denied / Forbidden
If you see an error like `The user is forbidden from accessing the bucket [inhausbrain_cloudbuild]`, we have already provisioned a custom bucket to bypass this. Ensure you are using the latest `deploy.sh` which includes:
`--gcs-source-staging-dir gs://inhaus-source-staging/source`

Alternatively, try creating the bucket manually or ensure you are logged in with the correct account:
```bash
gcloud auth login
```

### Localhost: Focus or RenderBox Errors
We have implemented aggressive focus isolation with `ExcludeFocus` and `FocusScope`. If you still see focus-related errors on localhost during development, ensure your Chrome browser is up to date and clean the build:
```bash
flutter clean
flutter run -d chrome
```
