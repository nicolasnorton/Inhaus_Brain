config {
  type: "view",
  schema: "marketing_staging",
  description: "TikTok Ads Raw to Staging Transformation"
}

SELECT
  'tiktok' AS platform,
  CAST(ad_account_id AS STRING) AS ad_account_id,
  CAST(campaign_id AS STRING) AS campaign_id,
  CAST(adgroup_id AS STRING) AS ad_group_id,
  CAST(ad_id AS STRING) AS ad_id,
  CAST(stat_time_day AS DATE) AS report_date,
  CAST(impressions AS INT64) AS impressions,
  CAST(clicks AS INT64) AS clicks,
  CAST(spend AS FLOAT64) AS spend,
  CAST(conversions AS INT64) AS conversions,
  CAST(conversion_value AS FLOAT64) AS conversion_value,
  CURRENT_TIMESTAMP() AS recordstamp
FROM
  ${ref("tiktok_ads_raw")}
