#!/bin/bash
set -e

PROJECT_ID="inhausbrain"
SERVICE_NAME="inhaus-brain-web"
REGION="us-central1"
IMAGE_TAG="gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "🚀 Starting Deployment for $PROJECT_ID..."

# 1. Build and Submit to Artifact Registry/GCR
echo "📦 Building container image..."
gcloud builds submit --tag $IMAGE_TAG .

# 2. Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_TAG \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated

echo "✅ Deployment Complete!"
echo "🌍 App available at: https://brain.inhauscorp.com"
