terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "inhausbrain-terraform-state"
    prefix = "production"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ===========================
# Cloud Tasks Queue for Agents
# ===========================
resource "google_cloud_tasks_queue" "agent_tasks" {
  name     = "agent-tasks"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 500
    max_concurrent_dispatches = 1000
  }

  retry_config {
    max_attempts       = 3
    max_retry_duration = "600s"
    min_backoff        = "5s"
    max_backoff        = "60s"
  }
}

# ===========================
# BigQuery Dataset for Analytics
# ===========================
resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "inhaus_analytics"
  friendly_name               = "InhausBrain Analytics"
  description                 = "Centralized analytics and AI profitability tracking"
  location                    = "US"
  default_table_expiration_ms = 7776000000 # 90 days

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Events Table (Streamed from Firestore)
resource "google_bigquery_table" "events" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "events"

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  schema = jsonencode([
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "userId"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "eventName"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "parameters"
      type = "JSON"
      mode = "NULLABLE"
    },
    {
      name = "platform"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])
}

# Audit Logs Table
resource "google_bigquery_table" "audit_logs" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "audit_logs"

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  schema = jsonencode([
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "actorId"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "action"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "resourceType"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "resourceId"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "metadata"
      type = "JSON"
      mode = "NULLABLE"
    },
    {
      name = "isCritical"
      type = "BOOLEAN"
      mode = "NULLABLE"
    }
  ])
}

# ===========================
# Cloud Run Service (Backend)
# ===========================
resource "google_cloud_run_service" "backend" {
  name     = "inhaus-brain-backend"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/inhaus-brain:${var.image_tag}"
        
        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = "2000m"
            memory = "2Gi"
          }
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      }

      service_account_name = google_service_account.backend.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = var.environment == "production" ? "2" : "0"
        "autoscaling.knative.dev/maxScale" = var.environment == "production" ? "100" : "10"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["run.googleapis.com/client-version"],
    ]
  }
}

# Service Account for Backend
resource "google_service_account" "backend" {
  account_id   = "inhaus-brain-backend"
  display_name = "InhausBrain Backend Service Account"
}

# IAM: Allow public access (Firebase Auth handles authorization)
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.backend.name
  location = google_cloud_run_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ===========================
# Secret Manager Secrets
# ===========================
resource "google_secret_manager_secret" "google_api_key" {
  secret_id = "google-api-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "firebase_admin_sdk" {
  secret_id = "firebase-admin-sdk"

  replication {
    auto {}
  }
}

# Grant Cloud Functions access to secrets
resource "google_secret_manager_secret_iam_member" "functions_access" {
  for_each = toset([
    google_secret_manager_secret.google_api_key.id,
    google_secret_manager_secret.firebase_admin_sdk.id,
  ])

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

# ===========================
# Monitoring & Alerting
# ===========================
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate - Cloud Functions"
  combiner     = "OR"

  conditions {
    display_name = "Error rate > 5%"

    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.label.status!=\"ok\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "InhausBrain Alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# ===========================
# Variables
# ===========================
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "inhausbrain"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (staging/production)"
  type        = string
  default     = "production"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "alert_email" {
  description = "Email for monitoring alerts"
  type        = string
}

# ===========================
# Outputs
# ===========================
output "backend_url" {
  value       = google_cloud_run_service.backend.status[0].url
  description = "Cloud Run backend URL"
}

output "tasks_queue_name" {
  value       = google_cloud_tasks_queue.agent_tasks.name
  description = "Cloud Tasks queue for agents"
}

output "bigquery_dataset" {
  value       = google_bigquery_dataset.analytics.dataset_id
  description = "BigQuery dataset for analytics"
}

# ===========================
# BrainWeave 3.0 Agent Skills Evolution 
# ===========================
resource "google_cloud_scheduler_job" "brainweave_skill_scanner" {
  name             = "brainweave-skill-scanner-nightly"
  description      = "Nightly job to scan new BrainWeave skill nodes for security risks"
  schedule         = "0 2 * * *" # Every day at 2:00 AM
  time_zone        = "America/New_York"
  attempt_deadline = "300s"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.backend.status[0].url}/brainweave_skill_scan_job"
    
    # Needs real authentication for production, placeholder for now
    headers = {
      "Content-Type"  = "application/json"
      "Authorization" = "Bearer ${var.project_id}-scheduler"
    }
  }
}

