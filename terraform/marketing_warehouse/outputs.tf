# ===========================
# Outputs — Marketing Warehouse
# ===========================

output "marketing_raw_dataset_id" {
  value       = google_bigquery_dataset.marketing_raw.dataset_id
  description = "Marketing raw dataset ID"
}

output "marketing_staging_dataset_id" {
  value       = google_bigquery_dataset.marketing_staging.dataset_id
  description = "Marketing staging dataset ID"
}

output "marketing_mart_dataset_id" {
  value       = google_bigquery_dataset.marketing_mart.dataset_id
  description = "Marketing mart dataset ID"
}

output "cross_platform_view_id" {
  value       = google_bigquery_table.v_cross_platform_summary.table_id
  description = "Cross-platform summary view ID"
}

output "tables" {
  value = {
    dim_campaign              = google_bigquery_table.dim_campaign.table_id
    dim_ad_group              = google_bigquery_table.dim_ad_group.table_id
    dim_ad                    = google_bigquery_table.dim_ad.table_id
    fact_daily_ad_performance = google_bigquery_table.fact_daily_ad_performance.table_id
    fact_conversions          = google_bigquery_table.fact_conversions.table_id
    user_client_mapping       = google_bigquery_table.user_client_mapping.table_id
  }
  description = "All marketing mart table IDs"
}
