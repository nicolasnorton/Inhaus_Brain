---
description: Build and deploy to Firebase Hosting staging (inhausbrain-beta.web.app)
---

# Deploy to Staging

Builds the Flutter web app with staging environment flags and deploys to the `inhausbrain-beta` Firebase Hosting target.

## Prerequisites
- Must be on a staging-safe branch (not `main` or `master`)
- Firebase CLI authenticated (`firebase login`)
- Flutter SDK installed

## Steps

// turbo-all

1. Verify you're not on the production branch:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then echo "❌ ABORT: Cannot deploy to staging from $BRANCH"; exit 1; fi
echo "✅ Branch: $BRANCH"
```

2. Build the Flutter web app with staging defines:
```bash
cd /Users/nicolasnorton/AudioTherapy/audio_therapy_app/InhausBrain && flutter build web --release --dart-define=ENVIRONMENT=staging
```

3. Deploy to the Firebase Hosting beta target & Cloud Functions (Full Stack):
```bash
cd /Users/nicolasnorton/AudioTherapy/audio_therapy_app/InhausBrain && firebase use staging && firebase deploy --only hosting:inhaus-brain,functions
```

4. Verify the deployment is live:
```bash
echo "✅ Deployed! Verify at: https://inhaus-brain-full-staging.web.app"
```

5. Clean up local build artifacts:
```bash
flutter clean
```

## Notes
- The `inhaus-brain` hosting target maps to `inhausbrain-beta.web.app`
- The `ENVIRONMENT=staging` dart-define activates staging feature flags via `AppConfig`
- This does NOT deploy Cloud Functions — do that separately if needed with:
  ```bash
  firebase deploy --only functions
  ```
