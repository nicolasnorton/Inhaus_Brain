# ===========================
# Variables — Marketing Warehouse
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

variable "bq_location" {
  description = "BigQuery dataset location (must match existing datasets)"
  type        = string
  default     = "US"
}

variable "service_account_email" {
  description = "Ingestion service account email (for IAM bindings)"
  type        = string
}
