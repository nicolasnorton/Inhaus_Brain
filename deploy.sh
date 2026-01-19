#!/bin/bash
set -e

PROJECT_ID="inhausbrain"
SERVICE_NAME="inhaus-brain"
REGION="us-central1"
IMAGE_TAG="gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "🚀 Starting Deployment for $PROJECT_ID..."

# 1. Load local environment variables if .env exists
if [ -f .env ]; then
  echo "📄 Loading environment variables from .env..."
  # Export variables from .env, ignoring comments and empty lines
  export $(grep -v '^#' .env | xargs)
fi

# Verify critical keys are present
if [ -z "$VERTEX_API_KEY" ]; then
  echo "❌ Error: VERTEX_API_KEY is missing or empty!"
  echo "👉 Should be in .env or exported in shell."
  exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
  echo "❌ Error: GEMINI_API_KEY is missing or empty!"
  echo "👉 Should be in .env or exported in shell."
  exit 1
fi

# Generate a dynamic tag (Git SHA or Timestamp)
if git rev-parse --git-dir > /dev/null 2>&1; then
  TAG=$(git rev-parse --short HEAD)
else
  TAG=$(date +%Y%m%d%H%M%S)
fi

echo "🏷️  Deploying Version: $TAG"

# 1. Build and Deploy via Cloud Build
echo "📦 Submitting build to Google Cloud Build..."
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions="_VERTEX_API_KEY=$VERTEX_API_KEY,_GEMINI_API_KEY=$GEMINI_API_KEY,_TAG=$TAG" \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# 2. Deploy to Cloud Run (Run locally as Cloud Build SA lacks permissions)
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_TAG:$TAG \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --project $PROJECT_ID \
  --set-env-vars "VERTEX_API_KEY=$VERTEX_API_KEY,GEMINI_API_KEY=$GEMINI_API_KEY"

echo "✅ Deployment Complete!"
echo "🌍 App available at: https://brain.inhauscorp.com"
