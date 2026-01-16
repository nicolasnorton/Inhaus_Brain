#!/bin/bash
set -e

PROJECT_ID="inhausbrain"
SERVICE_NAME="inhaus-brain"
REGION="us-central1"
IMAGE_TAG="gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "🚀 Starting Deployment for $PROJECT_ID..."

# 1. Build and Deploy via Cloud Build
echo "📦 Submitting build to Google Cloud Build..."
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions="_VERTEX_API_KEY=AQ.Ab8RN6I1yaY9ppyDT0RljTgXlmAUwxvhca2mxAbqsQPwz5EMbg,_GEMINI_API_KEY=AIzaSyCiGMMlAdmooQjaRA7H2YYYyZGTSpuHYWY,_TAG=latest" \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# Deployment progress is managed by Cloud Build

echo "✅ Deployment Complete!"
echo "🌍 App available at: https://brain.inhauscorp.com"
