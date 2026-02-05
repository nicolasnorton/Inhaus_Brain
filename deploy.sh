#!/bin/bash
set -e

# --- Configuration ---
PROJECT_ID="inhausbrain"
SERVICE_NAME="inhaus-brain"
REGION="us-central1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"
PRODUCTION_URL="https://brain.inhauscorp.com"

echo "🚀 Starting Deployment for $PROJECT_ID..."

# 1. Load local environment variables if .env exists
if [ -f .env ]; then
  echo "📄 Loading environment variables from .env..."
  # Export variables from .env, excluding comments
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️  No .env file found. Proceeding with existing environment variables."
fi

# 2. Key Validation
CRITICAL_KEYS=(
  "VERTEX_API_KEY" 
  "GEMINI_API_KEY" 
  "FIREBASE_API_KEY" 
  "FIREBASE_PROJECT_ID" 
  "FIREBASE_APP_ID"
)

echo "🔍 Validating critical API keys..."
for KEY in "${CRITICAL_KEYS[@]}"; do
  if [ -z "${!KEY}" ]; then
    echo "❌ Error: $KEY is missing or empty!"
    echo "👉 Ensure it is defined in .env or your shell environment."
    exit 1
  fi
done

# Optional/Service Specific Keys
OPTIONAL_KEYS=(
  "VEO_API_KEY" 
  "OPENAI_API_KEY" 
  "ANTHROPIC_API_KEY" 
  "XAI_API_KEY" 
  "IMAGEN_API_KEY" 
  "ELEVEN_LABS_API_KEY" 
  "DIFY_API_KEY" 
  "RUNWAY_API_KEY" 
  "PINECONE_API_KEY"
  "LYRIA_API_KEY"
  "MIDJOURNEY_API_KEY"
)

for KEY in "${OPTIONAL_KEYS[@]}"; do
  if [ -z "${!KEY}" ]; then
    echo "⚠️  Warning: $KEY is missing. Associated AI features will be limited."
  fi
done

# Generate a dynamic tag
if git describe --tags --exact-match > /dev/null 2>&1; then
  TAG=$(git describe --tags --exact-match)
elif git rev-parse --git-dir > /dev/null 2>&1; then
  TAG=$(git rev-parse --short HEAD)
else
  TAG=$(date +%Y%m%d%H%M%S)
fi

echo "🏷️  Deploying Version Tag: $TAG"

# 3. Submit to Cloud Build
echo "📦 Submitting build to Google Cloud Build..."
# This bakes the keys into the Docker Image via build-args
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions="_VERTEX_API_KEY=$VERTEX_API_KEY,_GEMINI_API_KEY=$GEMINI_API_KEY,_OPENAI_API_KEY=$OPENAI_API_KEY,_ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,_VEO_API_KEY=$VEO_API_KEY,_FIREBASE_API_KEY=$FIREBASE_API_KEY,_FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,_FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,_FIREBASE_APP_ID=$FIREBASE_APP_ID,_APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY,_DIFY_API_KEY=$DIFY_API_KEY,_ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY,_IMAGEN_API_KEY=$IMAGEN_API_KEY,_LYRIA_API_KEY=$LYRIA_API_KEY,_XAI_API_KEY=$XAI_API_KEY,_RUNWAY_API_KEY=$RUNWAY_API_KEY,_MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY,_PINECONE_API_KEY=$PINECONE_API_KEY,_TAG=$TAG" \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# 4. Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run ($SERVICE_NAME in $REGION)..."
# We also set them as env vars for any server-side logic in the Nginx container (rare but good to have)
gcloud run deploy $SERVICE_NAME \
  --image $IMAGE_NAME:$TAG \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --project $PROJECT_ID \
  --port 8080 \
  --set-env-vars "VERTEX_API_KEY=$VERTEX_API_KEY,GEMINI_API_KEY=$GEMINI_API_KEY,OPENAI_API_KEY=$OPENAI_API_KEY,ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,VEO_API_KEY=$VEO_API_KEY,FIREBASE_API_KEY=$FIREBASE_API_KEY,FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,FIREBASE_APP_ID=$FIREBASE_APP_ID,APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY,DIFY_API_KEY=$DIFY_API_KEY,ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY,IMAGEN_API_KEY=$IMAGEN_API_KEY,LYRIA_API_KEY=$LYRIA_API_KEY,XAI_API_KEY=$XAI_API_KEY,RUNWAY_API_KEY=$RUNWAY_API_KEY,MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY,PINECONE_API_KEY=$PINECONE_API_KEY"

# 5. Firebase Functions Deployment (Optional optimization: only if local changes exist)
echo "🔥 Deploying Firebase Functions..."
npx firebase deploy --only functions --project $PROJECT_ID

echo "✅ Final Deployment Complete!"
echo "🌍 App available at: $PRODUCTION_URL"

# 6. Post-Deploy Health Check (Retry loop)
echo "🏥 Running Post-Deploy Health Check..."
MAX_RETRIES=5
COUNT=0
SUCCESS=false

while [ $COUNT -lt $MAX_RETRIES ]; do
  sleep 15
  if curl -sL --head "$PRODUCTION_URL" | grep "200 OK" > /dev/null; then
    echo "✨ Health Check Passed: $PRODUCTION_URL is responding."
    SUCCESS=true
    break
  else
    COUNT=$((COUNT+1))
    echo "⏳ Waiting for service warmup ($COUNT/$MAX_RETRIES)..."
  fi
done

if [ "$SUCCESS" = false ]; then
  echo "⚠️  Health Check Failed after $MAX_RETRIES attempts. Please check Cloud Run logs."
fi
