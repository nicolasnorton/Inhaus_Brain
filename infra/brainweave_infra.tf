# ═══════════════════════════════════════════════════════════
# BrainWeave 2.0 — Terraform Infrastructure
# Pure Google Cloud Edition
#
# Usage:
#   terraform init
#   terraform apply
#
# Cloud Run services are deployed separately via:
#   gcloud run deploy brainweave-indexer --source ../indexer/
#   gcloud run deploy brainweave-mcp --source ../mcp-api/
# ═══════════════════════════════════════════════════════════

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  default = "inhausbrain"
}

variable "region" {
  default = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─── Enable required APIs ──────────────────────────────────
resource "google_project_service" "spanner" {
  service            = "spanner.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# ─── Cloud Spanner ─────────────────────────────────────────
resource "google_spanner_instance" "brainweave" {
  name             = "brainweave-graph"
  config           = "regional-${var.region}"
  display_name     = "BrainWeave Graph Engine"
  processing_units = 100

  depends_on = [google_project_service.spanner]
}

resource "google_spanner_database" "brainweave_db" {
  instance = google_spanner_instance.brainweave.name
  name     = "brainweave"

  ddl = [
    "CREATE TABLE BrainWeaveNodes (node_id STRING(36) NOT NULL DEFAULT (GENERATE_UUID()), owner_id STRING(128) NOT NULL, client_id STRING(128), project_id STRING(128), scope STRING(16) NOT NULL, title STRING(512) NOT NULL, description STRING(2048), content STRING(MAX), node_type STRING(32) NOT NULL, topics ARRAY<STRING(256)>, markdown_uri STRING(1024), embedding ARRAY<FLOAT32>, source_agent STRING(128), confidence FLOAT64, version INT64, created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true), updated_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)) PRIMARY KEY (node_id)",

    "CREATE INDEX NodesByOwner ON BrainWeaveNodes(owner_id, scope)",
    "CREATE INDEX NodesByClient ON BrainWeaveNodes(client_id, scope)",
    "CREATE INDEX NodesByType ON BrainWeaveNodes(node_type)",

    "CREATE TABLE BrainWeaveEdges (edge_id STRING(36) NOT NULL DEFAULT (GENERATE_UUID()), owner_id STRING(128) NOT NULL, source_node_id STRING(36) NOT NULL, target_node_id STRING(36) NOT NULL, relationship_type STRING(64) NOT NULL, weight FLOAT64, confidence FLOAT64, embedding ARRAY<FLOAT32>, created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true), CONSTRAINT FK_Edge_Source FOREIGN KEY (source_node_id) REFERENCES BrainWeaveNodes(node_id), CONSTRAINT FK_Edge_Target FOREIGN KEY (target_node_id) REFERENCES BrainWeaveNodes(node_id)) PRIMARY KEY (edge_id)",

    "CREATE INDEX EdgesBySource ON BrainWeaveEdges(source_node_id)",
    "CREATE INDEX EdgesByTarget ON BrainWeaveEdges(target_node_id)",

    "CREATE PROPERTY GRAPH BrainWeaveGraph NODE TABLES (BrainWeaveNodes) EDGE TABLES (BrainWeaveEdges SOURCE KEY (source_node_id) REFERENCES BrainWeaveNodes(node_id) DESTINATION KEY (target_node_id) REFERENCES BrainWeaveNodes(node_id))",

    "CREATE TABLE BrainWeaveSessions (session_id STRING(36) NOT NULL DEFAULT (GENERATE_UUID()), owner_id STRING(128) NOT NULL, client_id STRING(128), current_phase STRING(32) NOT NULL, session_logs ARRAY<STRING(MAX)>, raw_input STRING(MAX), created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true), updated_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)) PRIMARY KEY (session_id)",

    "CREATE TABLE PendingPromotions (promotion_id STRING(36) NOT NULL DEFAULT (GENERATE_UUID()), node_id STRING(36) NOT NULL, requested_by STRING(128) NOT NULL, reason STRING(MAX), status STRING(16), created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp = true)) PRIMARY KEY (promotion_id)",
  ]

  deletion_protection = false
}

# ─── Cloud Storage Vault ───────────────────────────────────
resource "google_storage_bucket" "brainweave_vault" {
  name          = "${var.project_id}-brainweave-vault"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 30
    }
    action {
      type = "Delete"
    }
  }
}

# ─── Pub/Sub (Indexer trigger) ─────────────────────────────
resource "google_pubsub_topic" "vault_changes" {
  name = "brainweave-vault-changes"

  depends_on = [google_project_service.pubsub]
}

# Grant GCS service account permission to publish to Pub/Sub
data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "gcs_publisher" {
  topic   = google_pubsub_topic.vault_changes.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_storage_notification" "vault_notify" {
  bucket         = google_storage_bucket.brainweave_vault.name
  topic          = google_pubsub_topic.vault_changes.id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE", "OBJECT_DELETE"]

  depends_on = [
    google_pubsub_topic.vault_changes,
    google_pubsub_topic_iam_binding.gcs_publisher,
  ]
}

# ─── Contradiction Detector (Nightly Job) ──────────────────
resource "google_cloud_run_v2_job" "contradiction_detector" {
  name     = "brainweave-contradiction-detector"
  location = var.region

  template {
    template {
      service_account = google_service_account.brainweave_reweave.email
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/brainweave/contradiction-detector:latest"
        env {
          name  = "GCP_PROJECT"
          value = var.project_id
        }
        env {
          name  = "SPANNER_INSTANCE"
          value = google_spanner_instance.brainweave.name
        }
        env {
          name  = "SPANNER_DB"
          value = google_spanner_database.brainweave_db.name
        }
      }
    }
  }

  depends_on = [google_project_service.run]
}

resource "google_cloud_scheduler_job" "nightly_contradiction_check" {
  name             = "brainweave-nightly-contradiction-check"
  description      = "Triggers the BrainWeave contradiction detector job nightly"
  schedule         = "0 2 * * *" # 2 AM daily
  time_zone        = "UTC"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.contradiction_detector.name}:run"

    oauth_token {
      service_account_email = google_service_account.brainweave_reweave.email
    }
  }

  depends_on = [google_cloud_run_v2_job.contradiction_detector]
}

# ─── Artifact Registry (Docker images) ────────────────────
resource "google_artifact_registry_repository" "brainweave" {
  location      = var.region
  repository_id = "brainweave"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}


# ═══════════════════════════════════════════════════════════
# SECURITY HARDENING — Dedicated Service Accounts
# ═══════════════════════════════════════════════════════════

resource "google_service_account" "brainweave_mcp_api" {
  account_id   = "brainweave-mcp-api"
  display_name = "BrainWeave MCP API"
  project      = var.project_id
}

resource "google_service_account" "brainweave_indexer" {
  account_id   = "brainweave-indexer"
  display_name = "BrainWeave Indexer"
  project      = var.project_id
}

resource "google_service_account" "brainweave_reweave" {
  account_id   = "brainweave-reweave"
  display_name = "BrainWeave Reweave Job"
  project      = var.project_id
}

resource "google_service_account" "brainweave_export" {
  account_id   = "brainweave-export"
  display_name = "BrainWeave Export Function"
  project      = var.project_id
}

# ─── IAM: Spanner databaseUser for each SA ─────────────────
resource "google_spanner_database_iam_member" "mcp_api_db_user" {
  instance = google_spanner_instance.brainweave.name
  database = google_spanner_database.brainweave_db.name
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.brainweave_mcp_api.email}"
}

resource "google_spanner_database_iam_member" "indexer_db_user" {
  instance = google_spanner_instance.brainweave.name
  database = google_spanner_database.brainweave_db.name
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.brainweave_indexer.email}"
}

resource "google_spanner_database_iam_member" "reweave_db_user" {
  instance = google_spanner_instance.brainweave.name
  database = google_spanner_database.brainweave_db.name
  role     = "roles/spanner.databaseUser"
  member   = "serviceAccount:${google_service_account.brainweave_reweave.email}"
}

resource "google_spanner_database_iam_member" "export_db_reader" {
  instance = google_spanner_instance.brainweave.name
  database = google_spanner_database.brainweave_db.name
  role     = "roles/spanner.databaseReader"
  member   = "serviceAccount:${google_service_account.brainweave_export.email}"
}

# ─── IAM: Pub/Sub publisher for MCP API SA ─────────────────
resource "google_pubsub_topic_iam_member" "mcp_api_pubsub" {
  topic  = google_pubsub_topic.vault_changes.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.brainweave_mcp_api.email}"
}

# ─── IAM: Vertex AI user for MCP API + Indexer ─────────────
resource "google_project_iam_member" "mcp_api_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.brainweave_mcp_api.email}"
}

resource "google_project_iam_member" "indexer_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.brainweave_indexer.email}"
}


# ═══════════════════════════════════════════════════════════
# SECURITY HARDENING — Cloud KMS (CMEK)
# ═══════════════════════════════════════════════════════════

resource "google_project_service" "kms" {
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_kms_key_ring" "brainweave" {
  name     = "brainweave-keyring"
  location = var.region

  depends_on = [google_project_service.kms]
}

resource "google_kms_crypto_key" "brainweave_cmek" {
  name     = "brainweave-cmek-key"
  key_ring = google_kms_key_ring.brainweave.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}


# ═══════════════════════════════════════════════════════════
# SECURITY HARDENING — Cloud Monitoring Alert
# ═══════════════════════════════════════════════════════════

resource "google_project_service" "monitoring" {
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}


# ─── Output ───────────────────────────────────────────────
output "spanner_instance" {
  value = google_spanner_instance.brainweave.name
}

output "spanner_database" {
  value = google_spanner_database.brainweave_db.name
}

output "vault_bucket" {
  value = google_storage_bucket.brainweave_vault.name
}

output "pubsub_topic" {
  value = google_pubsub_topic.vault_changes.name
}

output "artifact_registry" {
  value = google_artifact_registry_repository.brainweave.name
}

output "kms_key" {
  value = google_kms_crypto_key.brainweave_cmek.id
}

output "mcp_api_sa" {
  value = google_service_account.brainweave_mcp_api.email
}

output "indexer_sa" {
  value = google_service_account.brainweave_indexer.email
}

output "reweave_sa" {
  value = google_service_account.brainweave_reweave.email
}

output "export_sa" {
  value = google_service_account.brainweave_export.email
}
