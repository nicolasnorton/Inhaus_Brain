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
# 1. Set the project
gcloud config set project inhausbrain

# 2. Submit build to Cloud Build (builds Dockerfile & pushes to GCR)
gcloud builds submit --tag gcr.io/inhausbrain/inhaus-brain . \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# 3. Deploy to Cloud Run
gcloud run deploy inhaus-brain \
  --image gcr.io/inhausbrain/inhaus-brain \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

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
