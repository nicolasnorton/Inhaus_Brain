#!/bin/bash
set -e

echo "Deploying PicoClaw to inhaus-brain-full-staging (Cloud Run)..."

gcloud config set project inhaus-brain-full-staging

gcloud builds submit --tag gcr.io/inhaus-brain-full-staging/picoclaw .

gcloud run deploy picoclaw \
  --image gcr.io/inhaus-brain-full-staging/picoclaw \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "GEMINI_API_KEY=$GEMINI_API_KEY,FIREBASE_PROJECT_ID=inhausbrain"

echo "Deploy complete!"
