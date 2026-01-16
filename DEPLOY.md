# Deployment Guide

This guide outlines the steps to deploy the **Inhaus Brain** application to Google Cloud Run. 

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
gcloud builds submit --tag gcr.io/inhausbrain/inhaus-brain-web .

# 3. Deploy to Cloud Run
gcloud run deploy inhaus-brain-web \
  --image gcr.io/inhausbrain/inhaus-brain-web \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## Domain Configuration
The custom domain `brain.inhauscorp.com` is configured via Cloud Run Domain Mappings.
To verify status:
```bash
gcloud beta run domain-mappings list --region us-central1
```
