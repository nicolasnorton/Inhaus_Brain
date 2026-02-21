#!/bin/bash
# setup_scheduler.sh — Idempotent Cloud Scheduler setup for Heartbeat
#
# Usage: ./scripts/setup_scheduler.sh [PROJECT_ID]
# Default project: inhausbrain

set -euo pipefail

PROJECT="${1:-inhausbrain}"
REGION="us-central1"
JOB_NAME="heartbeat-cron"
SCHEDULE="*/30 * * * *"  # Every 30 minutes
ENDPOINT="https://run-heartbeat-endpoint-btdf7nijqa-uc.a.run.app"
TIMEZONE="America/New_York"

echo "🔧 Setting up Cloud Scheduler for project: $PROJECT"

# Check if job exists
if gcloud scheduler jobs describe "$JOB_NAME" \
    --project="$PROJECT" \
    --location="$REGION" &>/dev/null; then
  echo "📝 Job '$JOB_NAME' exists. Updating..."
  gcloud scheduler jobs update http "$JOB_NAME" \
    --project="$PROJECT" \
    --location="$REGION" \
    --schedule="$SCHEDULE" \
    --uri="$ENDPOINT" \
    --http-method=POST \
    --headers="Content-Type=application/json" \
    --message-body='{}' \
    --time-zone="$TIMEZONE" \
    --attempt-deadline="300s" \
    --description="Inhaus Brain Heartbeat — proactive background tasks"
else
  echo "🆕 Creating job '$JOB_NAME'..."
  gcloud scheduler jobs create http "$JOB_NAME" \
    --project="$PROJECT" \
    --location="$REGION" \
    --schedule="$SCHEDULE" \
    --uri="$ENDPOINT" \
    --http-method=POST \
    --headers="Content-Type=application/json" \
    --message-body='{}' \
    --time-zone="$TIMEZONE" \
    --attempt-deadline="300s" \
    --description="Inhaus Brain Heartbeat — proactive background tasks"
fi

echo "✅ Cloud Scheduler job '$JOB_NAME' is ready."
echo "   Schedule: $SCHEDULE ($TIMEZONE)"
echo "   Endpoint: $ENDPOINT"
