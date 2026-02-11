# InhausBrain Production Deployment Guide

## Prerequisites
- Google Cloud SDK installed (`gcloud`)
- Terraform installed (`terraform`)
- Firebase CLI installed (`firebase`)
- Access to `inhausbrain` GCP project

## 1. Infrastructure Setup (Terraform)

### Initialize Terraform
```bash
cd terraform
terraform init
```

### Create terraform.tfvars
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Plan & Apply
```bash
terraform plan
terraform apply
```

This will create:
- Cloud Tasks queue for agent processing
- BigQuery dataset for analytics
- Cloud Run service for backend
- Secret Manager secrets
- Monitoring alerts

## 2. Deploy Cloud Functions (Python)

### Install Dependencies
```bash
cd functions-python
pip install -r requirements.txt
```

### Deploy to Firebase
```bash
firebase deploy --only functions
```

Functions deployed:
- `generate_content` - Gemini content generation
- `generate_image` - Imagen image generation
- `start_research` - Deep Research initiation
- `poll_research` - Deep Research polling
- `extract_structured` - LangExtract structured extraction
- `enqueue_agent_task` - Task queue endpoint
- `get_live_token` - Multimodal Live API token
- `dialogue_engine` - Dialogue system

## 3. Deploy Flutter Web App

### Build Production Bundle
```bash
flutter build web --release --dart-define=FLAVOR=production
```

### Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

## 4. Configure Secrets

### Google API Key
```bash
echo -n "YOUR_GOOGLE_API_KEY" | gcloud secrets create google-api-key --data-file=-
```

### Firebase Admin SDK
```bash
gcloud secrets create firebase-admin-sdk --data-file=path/to/service-account.json
```

## 5. Firestore Security Rules

Deploy security rules:
```bash
firebase deploy --only firestore:rules
```

Key rules:
- Users can only read/write their own data
- Audit logs are write-only
- Admin role required for user management

## 6. Monitoring & Alerts

### View Logs
```bash
gcloud logging read "resource.type=cloud_function" --limit 50
```

### Check Alerts
Navigate to: https://console.cloud.google.com/monitoring/alerting

## 7. Post-Deployment Verification

### Health Checks
1. Visit: https://inhausbrain.web.app
2. Sign in with test account
3. Create a test campaign
4. Verify agent execution
5. Check audit logs in Firestore

### Performance Monitoring
- Cloud Run metrics: https://console.cloud.google.com/run
- BigQuery analytics: https://console.cloud.google.com/bigquery
- Error rates: Cloud Logging

## 8. Rollback Procedure

### Revert to Previous Version
```bash
# Hosting
firebase hosting:rollback

# Functions
firebase deploy --only functions --force

# Infrastructure
cd terraform
terraform apply -var="image_tag=PREVIOUS_TAG"
```

## 9. Staging Environment

For staging deployments:
```bash
# Use staging Firebase project
firebase use staging

# Deploy with staging flag
flutter build web --release --dart-define=FLAVOR=staging
firebase deploy --only hosting,functions
```

## 10. CI/CD Pipeline

GitHub Actions automatically deploys on push to `main`:
- Runs tests
- Builds Flutter web
- Deploys to Firebase
- Logs deployment to audit trail

See: `.github/workflows/production_deploy.yml`

## Troubleshooting

### Common Issues

**Cloud Functions timeout:**
- Increase timeout in `firebase.json`
- Check function logs for errors

**Firestore permission denied:**
- Verify security rules
- Check user authentication

**BigQuery streaming errors:**
- Verify dataset exists
- Check IAM permissions

## Support
For issues, contact: nicolas@inhausbrain.com
