# Ad Performance KPI Reference

## Industry Benchmark Ranges (LatAm / General)

| Metric | Poor | Average | Good | Excellent |
| :--- | :--- | :--- | :--- | :--- |
| CTR (Meta) | <0.5% | 0.5–1.5% | 1.5–3% | >3% |
| CTR (TikTok) | <0.3% | 0.3–1% | 1–2% | >2% |
| CTR (LinkedIn) | <0.3% | 0.3–0.6% | 0.6–1% | >1% |
| ROAS (eComm) | <1× | 1–2× | 2–4× | >4× |
| ROAS (Lead Gen) | <2× | 2–4× | 4–8× | >8× |
| CPC (Meta) | >$2 | $1–2 | $0.50–1 | <$0.50 |
| CPC (LinkedIn) | >$8 | $5–8 | $3–5 | <$3 |

## BigQuery Table Schema

| Table | Key Columns |
| :--- | :--- |
| `tiktok_ads_raw` | ad_id, campaign_id, stat_time_day, impressions, clicks, spend, conversions, conversion_value |
| `linkedin_ads_raw` | ad_id, campaign_id, stat_time_day, impressions, clicks, spend, conversions, conversion_value |
| `meta_ads_raw` | ad_id, adset_id, campaign_id, date_start, impressions, clicks, spend, conversions, conversion_values |

## Anomaly Thresholds

- **CTR drop**: >20% decline vs. 7-day average → creative fatigue likely.
- **CPC spike**: >30% increase → auction competition or audience exhaustion.
- **ROAS collapse**: >25% decline → landing page or offer issue, not ad.
