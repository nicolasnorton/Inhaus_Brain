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
  --substitutions="_VERTEX_API_KEY=$VERTEX_API_KEY,_GEMINI_API_KEY=$GEMINI_API_KEY,_OPENAI_API_KEY=$OPENAI_API_KEY,_ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,_VEO_API_KEY=$VEO_API_KEY,_FIREBASE_API_KEY=$FIREBASE_API_KEY,_FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,_FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,_FIREBASE_APP_ID=$FIREBASE_APP_ID,_APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY,_DIFY_API_KEY=$DIFY_API_KEY,_ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY,_IMAGEN_API_KEY=$IMAGEN_API_KEY,_LYRIA_API_KEY=$LYRIA_API_KEY,_XAI_API_KEY=$XAI_API_KEY,_RUNWAY_API_KEY=$RUNWAY_API_KEY,_MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY,_TAG=$TAG" \
  --gcs-source-staging-dir gs://inhaus-source-staging/source

# 4. Deploy the specific version to Cloud Run
gcloud run deploy inhaus-brain \
  --image gcr.io/inhausbrain/inhaus-brain:$TAG \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --project inhausbrain \
  --set-env-vars "VERTEX_API_KEY=$VERTEX_API_KEY,GEMINI_API_KEY=$GEMINI_API_KEY,OPENAI_API_KEY=$OPENAI_API_KEY,ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,VEO_API_KEY=$VEO_API_KEY,FIREBASE_API_KEY=$FIREBASE_API_KEY,FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID,FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID,FIREBASE_APP_ID=$FIREBASE_APP_ID,APP_ENCRYPTION_KEY=$APP_ENCRYPTION_KEY,DIFY_API_KEY=$DIFY_API_KEY,ELEVEN_LABS_API_KEY=$ELEVEN_LABS_API_KEY,IMAGEN_API_KEY=$IMAGEN_API_KEY,LYRIA_API_KEY=$LYRIA_API_KEY,XAI_API_KEY=$XAI_API_KEY,RUNWAY_API_KEY=$RUNWAY_API_KEY,MIDJOURNEY_API_KEY=$MIDJOURNEY_API_KEY"
```
```

**Note**: You must have `VERTEX_API_KEY` and `GEMINI_API_KEY` exported in your terminal session for these commands to work.



### 5. Deploy Cloud Functions (Backend)
The AI Proxy service runs on Firebase Cloud Functions. If you made changes to `functions/`, deploy them separately:

```bash
firebase deploy --only functions
```

Note: Ensure you are logged in via `firebase login` and have the correct project selected (`firebase use inhausbrain`).

## Troubleshooting


### Vertex AI: 401 Unauthorized / API Key Blocked
If you see a 401 error in the console related to Vertex AI despite having a valid key:
1.  Ensure the **Vertex AI API** (also known as "AI Platform API") is explicitly enabled in your Google Cloud project.
2.  **Verification**: If using an API Key, ensure it is not restricted to specific services, or add "Vertex AI API" to its allowed services list in the Google Cloud Console.
3.  The app now automatically falls back from Vertex AI to the standard Google Generative Language API if transport fails.

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
### Knowledge Module: Infrastructure Requirements
The hardened Knowledge Module requires specific Firestore configurations:
1.  **Composite Indexes**: While primary queries are handled by single-field indexes, complex filters (e.g., ClientID + CreatedAt) may require composite indexes. If you see index errors in `KnowledgeLibraryWidget`, click the link provided in the Firebase Console log to auto-generate the index.
2.  **Security Rules**: Ensure the latest `firestore.rules` are deployed:
    ```bash
    firebase deploy --only firestore:rules
    ```
3.  **LiteRT (On-Device AI)**: No server-side setup required. On-device models are downloaded by the client on-demand or pre-bundled in the asset folder for offline/reliable fallback.

## 🚀 Recent Enhancements (v1.1.0)
- **Bilingual SEO/AEO Workforce**: New agents for search and answer engine optimization integrated.
- **Agentic Tooling**: Deployment now includes the latest `KeywordResearcher`, `TechnicalAuditor`, and `SchemaGenerator` tool configurations.
- **Orchestration Hardening**: Updated `RouterAgent` logic for more accurate intent detection across marketing domains.
- **Proposal Generation**: Production-ready PDF and Slide Deck generation for agency sales.


---
*Built with ❤️ to make AI automation accessible for everyone.*
