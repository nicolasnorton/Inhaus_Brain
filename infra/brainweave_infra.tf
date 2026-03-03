# ═══════════════════════════════════════════════════════════
# BrainWeave 2.0 — Terraform Infrastructure
# Pure Google Cloud Edition
# ═══════════════════════════════════════════════════════════

variable "project_id" {
  default = "inhausbrain"
}

variable "region" {
  default = "us-central1"
}

# ─── Cloud Spanner ─────────────────────────────────────────
resource "google_spanner_instance" "brainweave" {
  name             = "brainweave-graph"
  config           = "regional-${var.region}"
  display_name     = "BrainWeave Graph Engine"
  processing_units = 100
}

resource "google_spanner_database" "brainweave_db" {
  instance = google_spanner_instance.brainweave.name
  name     = "brainweave"

  ddl = [file("spanner_schema.sql")]

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
}

resource "google_storage_notification" "vault_notify" {
  bucket         = google_storage_bucket.brainweave_vault.name
  topic          = google_pubsub_topic.vault_changes.id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE", "OBJECT_DELETE"]

  depends_on = [google_pubsub_topic.vault_changes]
}

# ─── Cloud Run — Indexer Service ───────────────────────────
resource "google_cloud_run_v2_service" "indexer" {
  name     = "brainweave-indexer"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/brainweave/indexer:latest"

      resources {
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
      }

      env {
        name  = "SPANNER_INSTANCE"
        value = "brainweave-graph"
      }
      env {
        name  = "SPANNER_DB"
        value = "brainweave"
      }
      env {
        name  = "GEMINI_MODEL"
        value = "gemini-3.1-pro"
      }
      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }
}

# ─── Cloud Run — MCP API Service ───────────────────────────
resource "google_cloud_run_v2_service" "mcp_api" {
  name     = "brainweave-mcp"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/brainweave/mcp-api:latest"

      resources {
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
      }

      env {
        name  = "SPANNER_INSTANCE"
        value = "brainweave-graph"
      }
      env {
        name  = "SPANNER_DB"
        value = "brainweave"
      }
      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 20
    }
  }
}

# ─── Artifact Registry (Docker images) ────────────────────
resource "google_artifact_registry_repository" "brainweave" {
  location      = var.region
  repository_id = "brainweave"
  format        = "DOCKER"
}

# ─── Output ───────────────────────────────────────────────
output "spanner_instance" {
  value = google_spanner_instance.brainweave.name
}

output "vault_bucket" {
  value = google_storage_bucket.brainweave_vault.name
}

output "indexer_url" {
  value = google_cloud_run_v2_service.indexer.uri
}

output "mcp_api_url" {
  value = google_cloud_run_v2_service.mcp_api.uri
}
