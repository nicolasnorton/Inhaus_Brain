# Inhaus Brain - Reports & Dashboards Walkthrough

## 1. Overview
The **Analytics Hub** provides a centralized space for creating data-driven reports and monitoring real-time performance through dashboards. It is powered by:
- **Reports Module**: Deep-dive analysis tools with AI summarization (Audio, Video, Mind Maps).
- **Dashboards Module**: Real-time visualization grids.
- **Client Integrations**: Direct connections to ad platforms, analytics, and social media.

## 2. Managing Connections (Integrations)
Connections are managed at the **Client Level** to ensure data isolation.

1. Navigate to **Clients** and select a specific client.
2. Switch to the **"Integrations"** tab.
3. Modules are categorized into:
   - **Productivity & CRM**: Gmail, Slack, Notion, GoHighLevel.
   - **Advertising Platforms**: Google Ads, Meta Ads, TikTok Ads, LinkedIn, etc.
   - **Analytics & Insights**: GA4, Search Console, Google Business.
   - **Social Media (Organic)**: Meta Organic, TikTok Organic.
4. **Authorizing**: 
   - **Real OAuth**: Google Ads and Google Analytics 4 use real Google Sign-In flows. Clicking "Connect" will prompt for Google authorization.
   - **Mock Flow**: Other platforms (Meta, TikTok, etc.) currently use a mock authorization framework but are ready for future API integration.

## 3. Creating a New Report
1. Go to the **Reports** section from the sidebar.
2. Use the **Search Bar** to find existing reports or use **Filter Chips** (Recent, Pinned).
3. Click the **"New Report"** card to create a fresh analysis workspace.

## 4. Adding Sources
You can now pull data from your connected accounts or upload manual files:

- **From Connected Account**: Click "+ Add Source" -> "From Connected Account". Select from the client's authorized accounts (e.g., "Google Ads: Inhaus Main").
- **Analytics**: Specifically add GA4 or Search Console properties as sources.
- **Files**: Upload PDF, CSV, or Text files.
- **Paste Text**: Manually paste content like emails or meeting notes.
- **Web Source**: Scrape content from a URL.

## 5. Generating AI Content (The "Studio")
Once sources are added, use the **Studio** panel to generate multi-modal insights:

- **Audio Overview**: Creates a podcast-style conversation (Nova & Sage) summarizing the sources.
- **Video Overview (powered by Google Veo & LiteRT)**:
   - **Progress Tracking**: Real-time feedback and progress percentages during generation.
   - **Preview & Refine**: Uses **LiteRT On-Device AI** (Gemma/Veo Fast) for instant, low-cost previews (<200ms).
   - **Bilingual Subtitles**: Option to include English/Spanish (LatAm) captions in the video composition.
   - **Render Final**: Once satisfied with the preview/refinement, generate a high-quality final asset.
- **Mind Map**: Generates a hierarchical JSON structure of key concepts.

## 6. Creating Dashboards
1. Switch to the **Dashboards** view in the Analytics Hub.
2. Monitor key performance indicators (KPIs) via visual widgets.
3. Dashboards can integrate data from any authorized source connected in the Client Integrations area.

## 7. Troubleshooting
- **LRO Timeout/Error**: Video generation can take up to 2 minutes. The system uses a secure proxy to poll for completion. If a "500" error occurs, verify the Firebase Emulator status.
- **OAuth Canceled**: If the popup window is closed without confirming, the status will remain "Not Connected".
- **Vertex AI Error**: Ensure the project has the necessary Vertex AI APIs enabled in the Google Cloud Console.
