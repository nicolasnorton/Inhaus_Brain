# Cloud Scheduler: PicoClaw Heartbeat Configuration

## Setup Instructions

To enable the PicoClaw heartbeat (proactive task execution), create a Cloud Scheduler job
that calls the `run_heartbeat_endpoint` function periodically.

### Using gcloud CLI

```bash
# Create a daily heartbeat job (runs at 9 AM UTC)
gcloud scheduler jobs create http picoclaw-heartbeat-daily \
  --schedule="0 9 * * *" \
  --uri="https://us-central1-inhausbrain.cloudfunctions.net/run_heartbeat_endpoint" \
  --http-method=POST \
  --headers="Content-Type=application/json" \
  --message-body='{}' \
  --oidc-service-account-email="inhausbrain@appspot.gserviceaccount.com" \
  --oidc-token-audience="https://us-central1-inhausbrain.cloudfunctions.net/run_heartbeat_endpoint" \
  --location=us-central1 \
  --project=inhausbrain
```

### Notes

- **Authentication**: The endpoint uses Firebase Auth. For Cloud Scheduler, you'll need to either:
  1. Create a service account with custom claims to pass auth verification, or
  2. Add a special scheduler bypass token to the heartbeat endpoint
- **Frequency**: Start with daily. Adjust based on usage patterns.
- **Tasks**: The heartbeat reads from `/workspaces/{userId}/docs/heartbeat` in Firestore. Configure tasks there.

### Heartbeat Task Format (Firestore)

```json
{
  "content": "## Daily Tasks\n- Check calendar and summarize today's events\n- Review pending Proposals\n- Log a brief daily status"
}
```
