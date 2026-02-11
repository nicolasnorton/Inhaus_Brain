# Knowledge Module v2.0 Architecture Plan & Implementation Guide

## 1. Executive Summary
This upgrade transforms the "Knowledge Module" from a basic Firestore document store into a production-grade, scalable intelligence system. The core architectural shift moves long-term storage and heavy analytical workloads to **BigQuery**, while utilizing **Vertex AI Vector Search** for low-latency semantic retrieval.

**Key Goals:**
- **Scalability**: Handle millions of social posts, ad performance records, and documents without performance degradation.
- **Intelligence**: Use `gemini-embedding-001` / `004` for state-of-the-art multilingual understanding.
- **connectedness**: Direct integrations with Social (Meta, LinkedIn, X, TikTok) and Paid Media (Google Ads, Meta Ads, etc.).
- **Security**: Strict client isolation via Row-Level Security (RLS) and dataset separation.

---

## 2. BigQuery Data Architecture
We will use BigQuery as the "Source of Truth". All raw data, processed chunks, and embeddings reside here. Vector Search indexes will sync from BigQuery.

### 2.1. Dataset Structure
- **Dataset**: `inhaus_brain_knowledge`
- **Location**: `US` (or `eu` based on compliance)

### 2.2. Core Tables Schema

#### Table: `documents` (Metadata & Source Info)
| Field Name | Type | Mode | Description |
| :--- | :--- | :--- | :--- |
| `document_id` | STRING | REQUIRED | UUID |
| `client_id` | STRING | REQUIRED | Client Isolation Key |
| `source_platform` | STRING | REQUIRED | e.g., 'meta', 'google_ads', 'file_upload' |
| `source_type` | STRING | REQUIRED | e.g., 'social_post', 'campaign_report', 'contract' |
| `title` | STRING | NULLABLE | Human-readable title |
| `external_id` | STRING | NULLABLE | ID on external platform (e.g., Post ID) |
| `created_at` | TIMESTAMP | REQUIRED | Ingestion time |
| `published_at` | TIMESTAMP | NULLABLE | Original content time |
| `metadata` | JSON | NULLABLE | Flexible key-value store (author, campaign_id, etc.) |
| `content_hash` | STRING | NULLABLE | For deduplication |
| `status` | STRING | REQUIRED | 'active', 'archived', 'processing' |

*Partitioning*: By `created_at` (MONTH)
*Clustering*: `client_id`, `source_platform`

#### Table: `content_chunks` (Embeddings & Text)
| Field Name | Type | Mode | Description |
| :--- | :--- | :--- | :--- |
| `chunk_id` | STRING | REQUIRED | UUID |
| `document_id` | STRING | REQUIRED | FK to `documents` |
| `content` | STRING | REQUIRED | The actual text chunk |
| `embedding` | ARRAY<FLOAT64> | OPTIONAL | 768-dim vector (Gemini Embedding) |
| `token_count` | INT64 | NULLABLE | For billing/context management |

*Clustering*: `document_id`

#### Table: `social_metrics` (TimeSeries Data)
| Field Name | Type | Mode | Description |
| :--- | :--- | :--- | :--- |
| `record_id` | STRING | REQUIRED | UUID |
| `document_id` | STRING | REQUIRED | Link to the post in `documents` |
| `client_id` | STRING | REQUIRED | Isolation Key |
| `platform` | STRING | REQUIRED | 'facebook', 'instagram', 'linkedin', etc. |
| `metric_date` | DATE | REQUIRED | Date of metric capture |
| `impressions` | INT64 | NULLABLE | |
| `clicks` | INT64 | NULLABLE | |
| `engagement` | INT64 | NULLABLE | (Likes + Comments + Shares) |
| `spend` | FLOAT64 | NULLABLE | For boosted posts |
| `raw_data` | JSON | NULLABLE | Full platform payload |

*Partitioning*: By `metric_date` (DAY)

#### Table: `paid_media_performance` (Campaign Analytics)
| Field Name | Type | Mode | Description |
| :--- | :--- | :--- | :--- |
| `record_id` | STRING | REQUIRED | |
| `client_id` | STRING | REQUIRED | |
| `platform` | STRING | REQUIRED | 'google_ads', 'meta_ads' |
| `campaign_id` | STRING | REQUIRED | |
| `ad_group_id` | STRING | NULLABLE | |
| `date` | DATE | REQUIRED | |
| `impressions` | INT64 | |
| `clicks` | INT64 | |
| `cost` | FLOAT64 | |
| `conversions` | FLOAT64 | |
| `roas` | FLOAT64 | NULLABLE | |

---

## 3. Vertex AI Vector Search
- **Index**: `inhaus_knowledge_index`
- **Dimensions**: 768 (matching `gemini-embedding-004`)
- **Update Frequency**: Streaming or Batch (1hr) depending on volume.
- **Metadata**: Store `client_id` and `source_platform` in the vector index metadata for filtering during retrieval.

---

## 4. Ingestion & Connector Strategy

### 4.1. Universal Connector Architecture
We will build a `ConnectorService` interface that all specific sources must implement:

```dart
abstract class KnowledgeConnector {
  String get sourceId;
  Future<void> authenticate();
  Future<List<KnowledgeDocument>> fetchRecentUpdates({DateTime? since});
  Future<Map<String, dynamic>> fetchMetrics(String externalId);
}
```

### 4.2. Planned Connectors
1.  **Social Media**:
    *   **Meta Graph API**: Facebook Pages, Instagram Business.
    *   **LinkedIn API**: Organization Pages (Share & Social Media API).
    *   **X (Twitter) API**: Tweets, Timeline.
    *   **TikTok Research API / Business API**: Trending & Account videos.
2.  **Paid Media**:
    *   **Google Ads API**: Campaign performance reports.
    *   **Meta Marketing API**: Ad Account insights.
3.  **Documents & Files**:
    *   **Google Drive**: Watch changes in specific folders.
    *   **Uploads**: Direct PDF/Docx uploads (parsed via `syncfusion_flutter_pdf`).
    *   **Web**: Deep Research crawler.

---

## 5. Implementation Roadmap (Parallel Tracks)

### Phase 1: Foundation (Current Branch)
1.  Set up BigQuery Datasets & Tables (via Terraform or Setup Script).
2.  Create `BigQueryService` class in Dart (using `googleapis` package).
3.  Implement `EmbeddingsService` using `google_generative_ai` (Gemini).

### Phase 2: Ingestion Logic
1.  Implement `IngestionPipeline` triggered by Gavel/Manual upload.
2.  Chunking logic (Recursive Character Splitter).
3.  Load data into BigQuery `documents` and `content_chunks`.

### Phase 3: Connectors
1.  Implement `SocialConnector` (starting with Meta/LinkedIn).
2.  Implement `PaidMediaConnector`.
3.  Ensure OAuth2 token storage in `SecretVaultService`.

### Phase 4: Retrieval & Search
1.  Set up Vertex AI Vector Search Index.
2.  Implement `HybridRetriever`:
    *   Step 1: Vector Search for top N semantic matches.
    *   Step 2: BigQuery text search for specific keywords (Product Codes, Names).
    *   Step 3: Rerank / Filter by Client ID & Recency.

### Phase 5: UI & Integration
1.  Update Agents to call `KnowledgeRetriever`.
2.  Build `KnowledgeDashboard` (GenUI) to visualize ingestion status and stats.

---

## 6. Migration Plan
- **Dual Write**: For a transition period, write to both Firestore (old) and BigQuery (new).
- **Backfill**: Script to read all Firestore `KnowledgeDocument`s and push to BigQuery.
- **Cutover**: Once verified, update `AssistantService` to use `KnowledgeRetriever` exclusively.
