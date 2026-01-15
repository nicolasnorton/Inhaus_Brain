#!/bin/bash

# Configuration
PROJECT_ID="inhausbrain"
REGION="us-central1"
SERVICE_NAME="inhaus-brain"

echo "🚀 Starting Deployment for $SERVICE_NAME..."

# Check for gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: 'gcloud' CLI is not found."
    echo "Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Confirm Project
CURRENT_PROJECT=$(gcloud config get-value project)
echo "ℹ️  Current gcloud project: $CURRENT_PROJECT"
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "⚠️  Switching to project: $PROJECT_ID"
    gcloud config set project $PROJECT_ID
fi

# Get current Git SHA
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
echo "📌 Using tag: $COMMIT_SHA"

# Run Build & Deploy
echo "🔨 Submitting build to Cloud Build..."
gcloud builds submit --config cloudbuild.yaml --project $PROJECT_ID --substitutions=_TAG=$COMMIT_SHA .

if [ $? -eq 0 ]; then
    echo "✅ Deployment Successful!"
    
    # Ensure public access
    echo "🔓 Ensuring service is publicly accessible..."
    gcloud run services add-iam-policy-binding $SERVICE_NAME \
        --member="allUsers" \
        --role="roles/run.invoker" \
        --region=$REGION \
        --project=$PROJECT_ID > /dev/null 2>&1

    echo "🌍 Service URL:"
    gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --project $PROJECT_ID --format 'value(status.url)'
else
    echo "❌ Deployment Failed."
    exit 1
fi
