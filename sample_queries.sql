
-- 1. Identify Lowest Rated Output Patterns (By Model)
SELECT 
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'model_name') AS model_name,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'rating') = 'negative') AS negative_count,
  COUNT(*) AS total_ratings,
  SAFE_DIVIDE(COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'rating') = 'negative'), COUNT(*)) AS negative_rate
FROM `inhaus-brain.analytics_12345.events_*`
WHERE event_name = 'ai_feedback'
GROUP BY 1
ORDER BY negative_rate DESC;

-- 2. Identify Agents with Highest Failure/Arbitration Rate
SELECT 
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'agent') AS agent_name,
  AVG((SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'duration_ms')) AS avg_duration,
  COUNTIF((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'success') = 0) AS failure_count
FROM `inhaus-brain.analytics_12345.events_*`
WHERE event_name = 'agent_interaction'
GROUP BY 1
ORDER BY failure_count DESC;

-- 3. Temporal Drift: Quality over Time (Weekly)
SELECT 
  DATE_TRUNC(DATE(TIMESTAMP_MICROS(event_timestamp_micros)), WEEK) AS week,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'rating') = 'positive') AS positive_feedback,
  COUNTIF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'rating') = 'negative') AS negative_feedback
FROM `inhaus-brain.analytics_12345.events_*`
WHERE event_name = 'ai_feedback'
GROUP BY 1
ORDER BY 1 DESC;
