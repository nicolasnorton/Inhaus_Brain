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

# 2. Key Validation
# Critical Keys (Fail if missing)
CRITICAL_KEYS=("VERTEX_API_KEY" "GEMINI_API_KEY" "FIREBASE_API_KEY" "FIREBASE_PROJECT_ID" "FIREBASE_APP_ID")
for KEY in "${CRITICAL_KEYS[@]}"; do
  if [ -z "${!KEY}" ]; then
    echo "❌ Error: $KEY is missing or empty!"
    echo "👉 Ensure it is defined in .env or your shell environment."
    exit 1
  fi
done

# Non-Critical Keys (Warn if missing)
OPTIONAL_KEYS=("VEO_API_KEY" "OPENAI_API_KEY" "ANTHROPIC_API_KEY" "XAI_API_KEY" "IMAGEN_API_KEY" "ELEVEN_LABS_API_KEY" "DIFY_API_KEY" "RUNWAY_API_KEY")
for KEY in "${OPTIONAL_KEYS[@]}"; do
  if [ -z "${!KEY}" ]; then
    echo "⚠️  Warning: $KEY is missing. Some AI features may be disabled."
  fi
done

# Generate a dynamic tag (Git SHA or Timestamp)
# Generate a dynamic tag (Git Tag, SHA, or Timestamp)
if git describe --tags --exact-match > /dev/null 2>&1; then
  TAG=$(git describe --tags --exact-match)
elif git rev-parse --git-dir > /dev/null 2>&1; then
  TAG=$(git rev-parse --short HEAD)
else
  TAG=$(date +%Y%m%d%H%M%S)
fi

echo "🏷️  Deploying Version: $TAG"

# 3. Build via Cloud Build
echo "📦 Submitting build to Google Cloud Build..."
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions="_VERTEX_API_KEY=$VERTEX_API_KEY,_GEMINI_API_KEY=$GEMINI_API_KEY,_OPENAI_API_KEY=$OPENAI_API_KEY,_ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,_VEO_API_KEY=$VEO_API_KEY,_FIREBASE_API_KEY=$FIREBASE_API_KEY,_FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,_FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,_FIREBASE_APP_ID=$FIREBASE_APP_ID,_APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY,_DIFY_API_KEY=$DIFY_API_KEY,_ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY,_IMAGEN_API_KEY=$IMAGEN_API_KEY,_LYRIA_API_KEY=$LYRIA_API_KEY,_XAI_API_KEY=$XAI_API_KEY,_RUNWAY_API_KEY=$RUNWAY_API_KEY,_MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY,_TAG=$TAG" \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# 4. Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_TAG:$TAG \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --project $PROJECT_ID \
  --set-env-vars "VERTEX_API_KEY=$VERTEX_API_KEY,GEMINI_API_KEY=$GEMINI_API_KEY,OPENAI_API_KEY=$OPENAI_API_KEY,ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,VEO_API_KEY=$VEO_API_KEY,FIREBASE_API_KEY=$FIREBASE_API_KEY,FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,FIREBASE_APP_ID=$FIREBASE_APP_ID,APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY,DIFY_API_KEY=$DIFY_API_KEY,ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY,IMAGEN_API_KEY=$IMAGEN_API_KEY,LYRIA_API_KEY=$LYRIA_API_KEY,XAI_API_KEY=$XAI_API_KEY,RUNWAY_API_KEY=$RUNWAY_API_KEY,MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY"

echo "✅ Deployment Complete!"
echo "🌍 App available at: https://brain.inhauscorp.com"
