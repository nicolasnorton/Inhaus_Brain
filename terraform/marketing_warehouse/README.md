# Marketing Intelligence Warehouse

> **Phase 0** — Cortex-compatible BigQuery star schema for cross-platform ad data.
> Part of the BrainWeave Marketing Intelligence layer (BunkerDB replacement).

## Architecture

This Terraform module provisions three BigQuery datasets and a Cortex-compatible star schema that centralizes performance data from Meta, TikTok, LinkedIn, Google Ads, and GA4.

### Data Flow

```
Ad Platforms (Meta/TikTok/LinkedIn/Google Ads/GA4)
         │
         ▼
  ┌─────────────┐   Cloud Functions / BQ Data Transfer
  │ marketing_raw │   (Phase 1 ingestion)
  └─────┬───────┘
        │  Dataform (raw → CDC → staging)
        ▼
  ┌──────────────────┐
  │ marketing_staging │   Cleaned, deduplicated, typed
  └─────┬────────────┘
        │  Dataform (staging → mart)
        ▼
  ┌────────────────┐
  │ marketing_mart │   Star schema (dims + facts)
  └─────┬──────────┘
        │
        ├──► BrainWeave Agents (bigquery_query tool)
        ├──► GenUI Dashboards (MarketingIntelligencePanel)
        └──► Proposal Specialist (auto-pull live data)
```

### Star Schema (ER Diagram)

```mermaid
erDiagram
    dim_campaign ||--o{ dim_ad_group : "has"
    dim_ad_group ||--o{ dim_ad : "contains"
    dim_ad ||--o{ fact_daily_ad_performance : "reports"
    dim_campaign ||--o{ fact_daily_ad_performance : "aggregates"
    dim_campaign ||--o{ fact_conversions : "tracks"

    dim_campaign {
        STRING campaign_id PK
        STRING client_id FK
        STRING ad_account_id
        STRING platform
        STRING campaign_name
        STRING objective
        STRING buying_type
        STRING status
        FLOAT64 budget_amount
        STRING currency
        DATE start_date
        DATE end_date
        TIMESTAMP recordstamp
    }

    dim_ad_group {
        STRING ad_group_id PK
        STRING campaign_id FK
        STRING client_id FK
        STRING ad_account_id
        STRING platform
        STRING ad_group_name
        STRING status
        JSON targeting
        STRING placement
        STRING optimization_goal
        STRING bid_strategy
        TIMESTAMP recordstamp
    }

    dim_ad {
        STRING ad_id PK
        STRING ad_group_id FK
        STRING campaign_id FK
        STRING client_id FK
        STRING ad_account_id
        STRING platform
        STRING ad_name
        STRING creative_type
        STRING creative_url
        STRING headline
        STRING call_to_action
        STRING landing_page_url
        STRING status
        TIMESTAMP recordstamp
    }

    fact_daily_ad_performance {
        DATE report_date PK
        STRING ad_id FK
        STRING campaign_id FK
        STRING client_id FK
        STRING ad_account_id
        STRING platform
        STRING device
        STRING placement
        STRING age
        STRING gender
        STRING country
        STRING attribution_window
        INT64 impressions
        INT64 clicks
        FLOAT64 spend
        INT64 conversions
        FLOAT64 conversion_value
        FLOAT64 purchase_roas
        FLOAT64 ctr
        FLOAT64 cpc
        FLOAT64 cpm
        INT64 video_views
        JSON actions
        JSON action_values
        TIMESTAMP recordstamp
    }

    fact_conversions {
        STRING conversion_id PK
        DATE report_date
        STRING campaign_id FK
        STRING client_id FK
        STRING ad_account_id
        STRING platform
        STRING conversion_type
        FLOAT64 conversion_value
        STRING attribution_model
        STRING attribution_window
        STRING device
        STRING country
        TIMESTAMP recordstamp
    }

    user_client_mapping {
        STRING firebase_uid PK
        STRING client_id PK
        TIMESTAMP granted_at
    }
```

## Datasets

| Dataset | Purpose |
|---|---|
| `marketing_raw` | Raw ingested data from all platforms (retained indefinitely) |
| `marketing_staging` | Intermediate cleaned/deduplicated data (Dataform transforms) |
| `marketing_mart` | Production star schema — agents and dashboards query here |

## Row-Level Security

All tables in `marketing_mart` enforce strict data isolation mapped back to the Firebase Auth token.
- `google_bigquery_row_access_policy` is applied using the `SESSION_USER()` mapping technique. 
- BrainWeave stores the `user.uid` inside BigQuery as `firebase_uid`.
- The filter dynamically matches to `client_id` inside `user_client_mapping`.

## Apply

```bash
terraform init
terraform validate
terraform plan -var="service_account_email=YOUR_INGESTION_SA@inhausbrain.iam.gserviceaccount.com"
terraform apply -var="service_account_email=YOUR_INGESTION_SA@inhausbrain.iam.gserviceaccount.com"
```
