# ===================================================================
# Marketing Intelligence Warehouse
# Cortex-compatible BigQuery star schema for cross-platform ad data
# ===================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ===========================
# Local Values
# ===========================
locals {
  labels = {
    environment = var.environment
    managed_by  = "terraform"
    component   = "marketing-intelligence"
  }
}

# ===========================
# BigQuery Datasets
# ===========================
resource "google_bigquery_dataset" "marketing_raw" {
  dataset_id    = "marketing_raw"
  friendly_name = "Marketing Raw"
  description   = "Raw ingested data from Meta, TikTok, LinkedIn, Google Ads, GA4"
  location      = var.bq_location
  project       = var.project_id

  default_table_expiration_ms = null

  labels = local.labels
}

resource "google_bigquery_dataset" "marketing_staging" {
  dataset_id    = "marketing_staging"
  friendly_name = "Marketing Staging"
  description   = "Intermediate cleaned and deduplicated marketing data"
  location      = var.bq_location
  project       = var.project_id

  default_table_expiration_ms = null

  labels = local.labels
}

resource "google_bigquery_dataset" "marketing_mart" {
  dataset_id    = "marketing_mart"
  friendly_name = "Marketing Mart"
  description   = "Production-ready Cortex-compatible star schema for agents and dashboards"
  location      = var.bq_location
  project       = var.project_id

  default_table_expiration_ms = null

  labels = local.labels
}

# ===========================
# Dimension: Campaigns
# ===========================
resource "google_bigquery_table" "dim_campaign" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "dim_campaign"
  project             = var.project_id
  deletion_protection = true

  schema = jsonencode([
    { name = "campaign_id",    type = "STRING",    mode = "REQUIRED", description = "Platform-native campaign ID" },
    { name = "client_id",      type = "STRING",    mode = "REQUIRED", description = "Inhaus Brain client identifier" },
    { name = "ad_account_id",  type = "STRING",    mode = "REQUIRED", description = "Platform ad account ID" },
    { name = "platform",       type = "STRING",    mode = "REQUIRED", description = "Source platform: meta, tiktok, linkedin, google_ads, ga4" },
    { name = "campaign_name",  type = "STRING",    mode = "NULLABLE" },
    { name = "objective",      type = "STRING",    mode = "NULLABLE", description = "Campaign objective (e.g. CONVERSIONS, TRAFFIC)" },
    { name = "buying_type",    type = "STRING",    mode = "NULLABLE" },
    { name = "status",         type = "STRING",    mode = "NULLABLE", description = "ACTIVE, PAUSED, ARCHIVED, DELETED" },
    { name = "budget_amount",  type = "FLOAT64",   mode = "NULLABLE" },
    { name = "currency",       type = "STRING",    mode = "NULLABLE" },
    { name = "start_date",     type = "DATE",      mode = "NULLABLE" },
    { name = "end_date",       type = "DATE",      mode = "NULLABLE" },
    { name = "created_at",     type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "updated_at",     type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "recordstamp",    type = "TIMESTAMP", mode = "REQUIRED", description = "Cortex CDC recordstamp" }
  ])

  labels = local.labels
}

# ===========================
# Dimension: Ad Groups / Ad Sets
# ===========================
resource "google_bigquery_table" "dim_ad_group" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "dim_ad_group"
  project             = var.project_id
  deletion_protection = true

  schema = jsonencode([
    { name = "ad_group_id",    type = "STRING",    mode = "REQUIRED", description = "Platform-native ad group / ad set ID" },
    { name = "campaign_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "client_id",      type = "STRING",    mode = "REQUIRED" },
    { name = "ad_account_id",  type = "STRING",    mode = "REQUIRED" },
    { name = "platform",       type = "STRING",    mode = "REQUIRED" },
    { name = "ad_group_name",  type = "STRING",    mode = "NULLABLE" },
    { name = "status",         type = "STRING",    mode = "NULLABLE" },
    { name = "targeting",      type = "JSON",      mode = "NULLABLE", description = "Platform-specific targeting config" },
    { name = "placement",      type = "STRING",    mode = "NULLABLE", description = "Ad placement (feed, stories, reels, etc.)" },
    { name = "optimization_goal", type = "STRING", mode = "NULLABLE" },
    { name = "bid_strategy",   type = "STRING",    mode = "NULLABLE" },
    { name = "created_at",     type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "updated_at",     type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "recordstamp",    type = "TIMESTAMP", mode = "REQUIRED" }
  ])

  labels = local.labels
}

# ===========================
# Dimension: Ads
# ===========================
resource "google_bigquery_table" "dim_ad" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "dim_ad"
  project             = var.project_id
  deletion_protection = true

  schema = jsonencode([
    { name = "ad_id",          type = "STRING",    mode = "REQUIRED", description = "Platform-native ad ID" },
    { name = "ad_group_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "campaign_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "client_id",      type = "STRING",    mode = "REQUIRED" },
    { name = "ad_account_id",  type = "STRING",    mode = "REQUIRED" },
    { name = "platform",       type = "STRING",    mode = "REQUIRED" },
    { name = "ad_name",        type = "STRING",    mode = "NULLABLE" },
    { name = "creative_type",  type = "STRING",    mode = "NULLABLE", description = "IMAGE, VIDEO, CAROUSEL, COLLECTION" },
    { name = "creative_url",   type = "STRING",    mode = "NULLABLE" },
    { name = "headline",       type = "STRING",    mode = "NULLABLE" },
    { name = "body_text",      type = "STRING",    mode = "NULLABLE" },
    { name = "call_to_action", type = "STRING",    mode = "NULLABLE" },
    { name = "landing_page_url", type = "STRING",  mode = "NULLABLE" },
    { name = "status",         type = "STRING",    mode = "NULLABLE" },
    { name = "created_at",     type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "updated_at",     type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "recordstamp",    type = "TIMESTAMP", mode = "REQUIRED" }
  ])

  labels = local.labels
}

# ===========================
# Fact: Daily Ad Performance
# (Cortex-aligned: fact_daily_ad_performance)
# ===========================
resource "google_bigquery_table" "fact_daily_ad_performance" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "fact_daily_ad_performance"
  project             = var.project_id
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "report_date"
  }

  clustering = ["client_id", "platform", "campaign_id"]

  schema = jsonencode([
    # ── Keys ──────────────────────────────────────────────────────
    { name = "report_date",    type = "DATE",      mode = "REQUIRED", description = "Reporting date (partition key)" },
    { name = "ad_id",          type = "STRING",    mode = "REQUIRED" },
    { name = "ad_group_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "campaign_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "client_id",      type = "STRING",    mode = "REQUIRED" },
    { name = "ad_account_id",  type = "STRING",    mode = "REQUIRED" },
    { name = "platform",       type = "STRING",    mode = "REQUIRED", description = "meta | tiktok | linkedin | google_ads | ga4" },

    # ── Dimensions (Cortex breakdowns) ────────────────────────────
    { name = "device",         type = "STRING",    mode = "NULLABLE", description = "mobile, desktop, tablet, all" },
    { name = "placement",      type = "STRING",    mode = "NULLABLE", description = "feed, stories, reels, right_column, search, etc." },
    { name = "age",            type = "STRING",    mode = "NULLABLE", description = "Age bucket: 18-24, 25-34, etc." },
    { name = "gender",         type = "STRING",    mode = "NULLABLE", description = "male, female, unknown" },
    { name = "country",        type = "STRING",    mode = "NULLABLE", description = "ISO 3166-1 alpha-2" },
    { name = "region",         type = "STRING",    mode = "NULLABLE" },
    { name = "objective",      type = "STRING",    mode = "NULLABLE" },
    { name = "attribution_window", type = "STRING", mode = "NULLABLE", description = "e.g. 7d_click, 1d_view, 28d_click" },

    # ── Core Metrics ──────────────────────────────────────────────
    { name = "impressions",       type = "INT64",   mode = "NULLABLE" },
    { name = "clicks",            type = "INT64",   mode = "NULLABLE" },
    { name = "spend",             type = "FLOAT64", mode = "NULLABLE", description = "Spend in account currency" },
    { name = "reach",             type = "INT64",   mode = "NULLABLE" },
    { name = "frequency",         type = "FLOAT64", mode = "NULLABLE" },

    # ── Conversion Metrics ────────────────────────────────────────
    { name = "conversions",       type = "INT64",   mode = "NULLABLE" },
    { name = "conversion_value",  type = "FLOAT64", mode = "NULLABLE" },
    { name = "purchase_roas",     type = "FLOAT64", mode = "NULLABLE", description = "Cortex: purchase_roas" },

    # ── Derived Rates ─────────────────────────────────────────────
    { name = "ctr",               type = "FLOAT64", mode = "NULLABLE", description = "Click-through rate" },
    { name = "cpc",               type = "FLOAT64", mode = "NULLABLE", description = "Cost per click" },
    { name = "cpm",               type = "FLOAT64", mode = "NULLABLE", description = "Cost per mille" },

    # ── Video Metrics (Cortex-aligned) ────────────────────────────
    { name = "video_views",           type = "INT64",   mode = "NULLABLE" },
    { name = "video_p25_watched",     type = "INT64",   mode = "NULLABLE" },
    { name = "video_p50_watched",     type = "INT64",   mode = "NULLABLE" },
    { name = "video_p75_watched",     type = "INT64",   mode = "NULLABLE" },
    { name = "video_p100_watched",    type = "INT64",   mode = "NULLABLE" },
    { name = "video_thruplay",        type = "INT64",   mode = "NULLABLE" },

    # ── Engagement ────────────────────────────────────────────────
    { name = "inline_link_clicks",    type = "INT64",   mode = "NULLABLE" },
    { name = "outbound_clicks",       type = "INT64",   mode = "NULLABLE" },
    { name = "social_spend",          type = "FLOAT64", mode = "NULLABLE" },
    { name = "inline_post_engagement", type = "INT64",  mode = "NULLABLE" },

    # ── Extended Action Data (JSON for platform-specific detail) ──
    { name = "actions",              type = "JSON",     mode = "NULLABLE", description = "Cortex: raw actions array" },
    { name = "action_values",        type = "JSON",     mode = "NULLABLE" },
    { name = "cost_per_action_type", type = "JSON",     mode = "NULLABLE" },

    # ── Currency & Metadata ───────────────────────────────────────
    { name = "currency",          type = "STRING",    mode = "NULLABLE" },
    { name = "recordstamp",       type = "TIMESTAMP", mode = "REQUIRED", description = "Cortex CDC recordstamp" }
  ])

  labels = local.labels
}

# ===========================
# Fact: Conversions
# ===========================
resource "google_bigquery_table" "fact_conversions" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "fact_conversions"
  project             = var.project_id
  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "report_date"
  }

  clustering = ["client_id", "platform", "conversion_type"]

  schema = jsonencode([
    { name = "conversion_id",      type = "STRING",    mode = "REQUIRED" },
    { name = "report_date",        type = "DATE",      mode = "REQUIRED" },
    { name = "campaign_id",        type = "STRING",    mode = "REQUIRED" },
    { name = "ad_group_id",        type = "STRING",    mode = "NULLABLE" },
    { name = "ad_id",              type = "STRING",    mode = "NULLABLE" },
    { name = "client_id",          type = "STRING",    mode = "REQUIRED" },
    { name = "ad_account_id",      type = "STRING",    mode = "REQUIRED" },
    { name = "platform",           type = "STRING",    mode = "REQUIRED" },
    { name = "conversion_type",    type = "STRING",    mode = "REQUIRED", description = "e.g. PURCHASE, LEAD, ADD_TO_CART, SIGNUP" },
    { name = "conversion_value",   type = "FLOAT64",   mode = "NULLABLE" },
    { name = "currency",           type = "STRING",    mode = "NULLABLE" },
    { name = "attribution_model",  type = "STRING",    mode = "NULLABLE", description = "last_click, first_click, linear, data_driven" },
    { name = "attribution_window", type = "STRING",    mode = "NULLABLE" },
    { name = "device",             type = "STRING",    mode = "NULLABLE" },
    { name = "country",            type = "STRING",    mode = "NULLABLE" },
    { name = "recordstamp",        type = "TIMESTAMP", mode = "REQUIRED" }
  ])

  labels = local.labels
}

# ===========================
# User-Client Mapping (RLS)
# ===========================
resource "google_bigquery_table" "user_client_mapping" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "user_client_mapping"
  project             = var.project_id
  deletion_protection = true

  schema = jsonencode([
    { name = "firebase_uid", type = "STRING",    mode = "REQUIRED", description = "Firebase Auth UID" },
    { name = "client_id",    type = "STRING",    mode = "REQUIRED", description = "Inhaus Brain client_id" },
    { name = "granted_at",   type = "TIMESTAMP", mode = "REQUIRED", description = "When access was granted" }
  ])

  labels = local.labels
}

# ===========================
# Cross-Platform Summary View
# ===========================
resource "google_bigquery_table" "v_cross_platform_summary" {
  dataset_id          = google_bigquery_dataset.marketing_mart.dataset_id
  table_id            = "v_cross_platform_summary"
  project             = var.project_id
  deletion_protection = false

  view {
    query = <<-SQL
      SELECT
        f.client_id,
        f.platform,
        f.report_date,
        f.campaign_id,
        c.campaign_name,
        c.objective,
        c.status          AS campaign_status,
        SUM(f.impressions)       AS total_impressions,
        SUM(f.clicks)            AS total_clicks,
        SUM(f.spend)             AS total_spend,
        SUM(f.conversions)       AS total_conversions,
        SUM(f.conversion_value)  AS total_conversion_value,
        SUM(f.reach)             AS total_reach,
        SAFE_DIVIDE(SUM(f.clicks),       NULLIF(SUM(f.impressions), 0)) AS avg_ctr,
        SAFE_DIVIDE(SUM(f.spend),        NULLIF(SUM(f.clicks), 0))      AS avg_cpc,
        SAFE_DIVIDE(SUM(f.spend) * 1000, NULLIF(SUM(f.impressions), 0)) AS avg_cpm,
        SAFE_DIVIDE(SUM(f.conversion_value), NULLIF(SUM(f.spend), 0))   AS roas,
        f.currency
      FROM `${var.project_id}.marketing_mart.fact_daily_ad_performance` AS f
      LEFT JOIN `${var.project_id}.marketing_mart.dim_campaign` AS c
        ON  f.campaign_id = c.campaign_id
        AND f.platform    = c.platform
        AND f.client_id   = c.client_id
      GROUP BY
        f.client_id, f.platform, f.report_date,
        f.campaign_id, c.campaign_name, c.objective,
        c.status, f.currency
    SQL

    use_legacy_sql = false
  }

  labels = local.labels
}

# ===========================
# IAM: Ingestion Service Account
# ===========================
resource "google_bigquery_dataset_iam_member" "raw_editor" {
  dataset_id = google_bigquery_dataset.marketing_raw.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "staging_editor" {
  dataset_id = google_bigquery_dataset.marketing_staging.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}

resource "google_bigquery_dataset_iam_member" "mart_viewer" {
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.service_account_email}"
}

# Backend (App Engine) also needs dataEditor on mart for CDC writeback
resource "google_bigquery_dataset_iam_member" "mart_editor_backend" {
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

# ===========================
# Row-Level Security Policies
# ===========================
resource "google_bigquery_row_access_policy" "rls_fact_daily_ad_performance" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  table_id   = google_bigquery_table.fact_daily_ad_performance.table_id
  policy_id  = "client_isolation"
  
  filter_predicate = "client_id IN (SELECT ucm.client_id FROM `${var.project_id}.marketing_mart.user_client_mapping` AS ucm WHERE ucm.firebase_uid = SESSION_USER())"
  granted_to       = ["allAuthenticatedUsers"]
}

resource "google_bigquery_row_access_policy" "rls_fact_conversions" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  table_id   = google_bigquery_table.fact_conversions.table_id
  policy_id  = "client_isolation"
  
  filter_predicate = "client_id IN (SELECT ucm.client_id FROM `${var.project_id}.marketing_mart.user_client_mapping` AS ucm WHERE ucm.firebase_uid = SESSION_USER())"
  granted_to       = ["allAuthenticatedUsers"]
}

resource "google_bigquery_row_access_policy" "rls_dim_campaign" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  table_id   = google_bigquery_table.dim_campaign.table_id
  policy_id  = "client_isolation"
  
  filter_predicate = "client_id IN (SELECT ucm.client_id FROM `${var.project_id}.marketing_mart.user_client_mapping` AS ucm WHERE ucm.firebase_uid = SESSION_USER())"
  granted_to       = ["allAuthenticatedUsers"]
}

resource "google_bigquery_row_access_policy" "rls_dim_ad_group" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  table_id   = google_bigquery_table.dim_ad_group.table_id
  policy_id  = "client_isolation"
  
  filter_predicate = "client_id IN (SELECT ucm.client_id FROM `${var.project_id}.marketing_mart.user_client_mapping` AS ucm WHERE ucm.firebase_uid = SESSION_USER())"
  granted_to       = ["allAuthenticatedUsers"]
}

resource "google_bigquery_row_access_policy" "rls_dim_ad" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.marketing_mart.dataset_id
  table_id   = google_bigquery_table.dim_ad.table_id
  policy_id  = "client_isolation"
  
  filter_predicate = "client_id IN (SELECT ucm.client_id FROM `${var.project_id}.marketing_mart.user_client_mapping` AS ucm WHERE ucm.firebase_uid = SESSION_USER())"
  granted_to       = ["allAuthenticatedUsers"]
}
