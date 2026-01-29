# 📖 Inhaus Brain Wiki

Welcome to the **Inhaus Brain** Wiki! This guide is designed to help you understand and operate the system, even if you've never used an AI tool before. 

---

## 🌟 What is Inhaus Brain?

**Inhaus Brain** is like a digital factory for your ideas. It helps you take a simple thought—like "I want to start a coffee brand"—and turns it into a full execution plan using AI "Agents" (digital workers) who handle the research, writing, and planning for you.

---

## 🏗️ Core Concepts

To use the system, you only need to understand three simple things:

1.  **Workflows**: A series of steps that the AI follows to complete a task.
2.  **Nodes**: The individual "blocks" or "steps" in that workflow (e.g., "Search the Web" or "Write a Letter").
3.  **Variables**: Pieces of information that get passed from one block to another (like a relay race baton).

---

## 🎨 Feature Guide

The system is divided into three main areas:

### 1. ⚒️ Workflow Canvas (The Designer)
This is where you "build" your automation. It's a visual board where you drag and drop blocks (Nodes) and connect them with lines to show the AI what to do first, second, and third.

### 2. 💬 Agent Workbench (The Chat)
This is where you talk to the AI. You can chat with specialized agents like a **Researcher**, **Strategist**, **Copywriter**, **SEO Specialist**, or **AEO Expert**. They can work together to answer your questions or execute the workflows you built.

### 3. 🤖 AI Copilot (The Manager)
The Copilot is your AI assistant for running the platform. Instead of clicking through menus, you can just ask it to do things.
*   **Manage Clients**: "Add a client called Acme Corp", "Show all my clients".
*   **Manage Campaigns**: "Create a new campaign for Summer Launch", "Delete the draft campaign".
*   **Manage Knowledge**: "Add https://inhaus.corp/manual to my knowledge base", "List all my knowledge sources".
*   **Create Apps**: "Build a new research app for Competitor Analysis".

### 4. 📚 Knowledge Base (The Library)
Inhaus Brain's Knowledge Module is designed for agency-level intelligence with enterprise security:
*   **Adaptive Chunking**: Automatically adjusts how it "reads" your documents. Data records (like Google Ads) are kept granular, while long PDFs use larger context windows.
*   **Semantic Caching**: The system remembers complex RAG queries. Repeat searches are nearly instantaneous and cost-saving.
*   **Hybrid Search**: Combines literal keyword matching with AI-powered "semantic" understanding for >90% retrieval accuracy.
*   **LiteRT Fallback**: If the cloud is unavailable, the platform automatically switches to local, on-device embedding models to ensure your knowledge is always accessible.
*   **PII Scrubbing**: Before any data is processed for metadata extraction, names, emails, and phone numbers are automatically masked to ensure privacy compliance.

### 5. 🚀 Publish Dashboard (Deployment)
This is where you turn your workflows into real applications. You can publish them as standalone **Web Apps**, integrate them into other systems via **API**, or embed them directly onto your own website using a **Chat Widget**.

### 6. 🎬 Flawless Video Generation & On-Device AI (DeepMind Only)
Generate high-fidelity branded video assets using an exclusive **Google DeepMind** pipeline.
*   **On-Device Previews (LiteRT)**: Instant, zero-cost previews using **Gemini Nano**, **Gemma 2**, and **Veo Fast** variants running directly on your device (NPU/GPU accelerated).
*   **DeepMind-Only Routing**:
    *   _Drafts/Previews_: **LiteRT / Veo Fast** (<2s generation time). Fallback to **Static Storyboard** if generation >3s.
    *   _Final/High-Fidelity_: **Veo 3 / Veo 3.1** via Vertex AI (Cloud).
*   **High-Fidelity Rendering**: Only uses flagship DeepMind models (Veo 3.1) for the **Final Render** once you are 100% satisfied.
*   **Bilingual Subtitles**: One-click generation of professional English/Spanish (LatAm) captions.
*   **Cultural Safety**: Automatically applies LatAm/Ecuadorian cultural filters to ensure brand-safe, respectful visuals.

### 7. 🛠️ Templates & Sharing
*   **Workflow Templates**: Don't start from scratch! Use professionally designed blueprints (like "Simple Chatbot" or "Twitter Account Analyzer") to jumpstart your project.
*   **Industry Blueprints (New)**: Explore over 100+ specialized blueprints across 10 major industries to solve real-world problems instantly:
    *   🛍️ **Retail**: AI Shopping Assistants, Inventory Management, Personalization.
    *   🎬 **Media & Entertainment**: Content Personalization, Script Analysis, Automated Editing.
    *   🚚 **Automotive & Logistics**: Fleet Management, Predictive Maintenance, Route Optimization.
    *   💸 **Financial Services**: Fraud Detection, Loan Processing, Personalized Banking.
    *   🏥 **Healthcare**: Patient Diagnosis Support, Drug Discovery, Telemedicine Triage.
    *   📡 **Telecommunications**: Network Optimization, Customer Churn Prediction.
    *   ✈️ **Travel & Hospitality**: Dynamic Pricing, Travel Itinerary Generation.
    *   🏭 **Manufacturing**: Quality Control, Supply Chain Optimization.
    *   🏛️ **Public Sector**: Citizen Services, Policy Analysis, Smart City Management.
    *   ⚡ **Productivity**: Meeting Summarizers, Email Assistants, Code Reviewers.
*   **Import/Export**: Move your workflows between workspaces or share them with others using the **Export JSON** and **Import** features.

### 7. 🐛 Debug Tools (The Inspector)
This area helps you fix problems. You can watch exactly how information moves through your workflow, inspect variables in real-time, and see a step-by-step history of every time your workflow has run.

### 8. 🏢 Client Module (Portfolio Management)
This module allows you to manage your client relationships and projects:
*   **Projects**: Organize work into specific project plans for each client.
*   **Task Board**: Track task status (Todo, In-Progress, Review, Done) and set due dates.
*   **Integrations**: Connect client workspaces to **Gmail**, **Slack**, **Notion**, and **GoHighLevel** to automate communication and data syncing.

---

## 🧱 Node Reference (The Building Blocks)

Here is a simple explanation of every block you can use in the **Workflow Canvas**:

### 📥 Inputs & Triggers
*   **User Input**: Asks the user for information (like a name or a topic) when the workflow starts.
*   **Trigger**: Automatically starts the workflow at a specific time or when something else happens.
*   **Doc Extractor**: "Reads" a file you uploaded and pulls out the important text.

### 🧠 Brain & Logic
*   **LLM (AI Model)**: The "Basic Brain." You give it a prompt, and it gives you an answer.
*   **Agent**: A "Specialized Brain" with a job (like a Researcher). It can use tools to find information.
*   **If-Else**: A fork in the road. "If the answer is 'Yes', go this way; if 'No', go that way."
*   **Switch/Case**: Multiple paths. Go to different steps based on specific values (e.g., Category A, B, or C).
*   **Loops (For Each/While)**: Repeats a series of steps for every item in a list or until a goal is met.
*   **Classifier**: Automatically puts information into categories (e.g., "Is this a complaint or a compliment?").

### ⚙️ Operations
*   **Variable Assigner**: Saves a piece of information for later use.
*   **Template**: Merges multiple pieces of information into a single neat package (like a form letter).
*   **List Operator**: Helps you sort or filter large lists of items.
*   **Parameter Extractor**: Turns messy text into a clean list of data (like pulling dates and prices from an email).

### 🛠️ External Tools
*   **HTTP Request**: Connects to other websites or apps to send or receive data.
*   **Tool**: Specific built-in actions like "Google Search" or "Check Weather."
*   **Knowledge Retrieval**: Searches your private **Knowledge Base** for answers.
*   **MCP Tools**: Connects to advanced external tools using the Model Context Protocol.

### 📤 Outputs
*   **Answer**: The final message shown to the user.
*   **Exit**: Safely ends the workflow and saves the results.

---

## 🔗 Working with Variables

Think of variables as labels for information. 
If you have a **User Input** block called "Topic", you can use that information later by typing `{{Topic}}` in any other block. The AI will automatically swap `{{Topic}}` with whatever the user typed.

---

## 🔧 How to Operate the System

1.  **Set Up**: Add your API keys in **Settings** (this is like putting fuel in the engine).
2.  **Gather Knowledge**: Upload any relevant documents to the **Library**.
3.  **Design**: Use the **Canvas** to draw your process.
4.  **Debug**: Use the **Debug Tools** to test your workflow and fix any issues.
5.  **Publish**: Use the **Publish Dashboard** to share your app with others.
6.  **Analyze**: Monitor your app's performance in the **Dashboard** analytics.
7.  **Approve**: Sometimes the AI will stop and ask "Does this look right?" You just click **Approve** to let it continue.

---

---

## 👥 User Roles & Access Control (RBAC)
Inhaus Brain features a robust Role-Based Access Control (RBAC) system to ensure data security and operational efficiency across the agency and its clients.

### 1. 🛡️ Super Admin / Admin
*   **Access**: Full system access.
*   **Capabilities**: Manage all users, system secrets, global settings, and audit logs.
*   **Target**: Agency owners and IT managers.

### 2. 👔 Human Agency Staff (New)
*   **Access**: Full operational access within the agency workspace.
*   **Capabilities**: Manage all clients, trigger AI workflows, create reports, and view analytics.
*   **Target**: Account managers, creative directors, and agency employees.

### 3. 👥 Client User (New)
*   **Access**: Restricted read-only access to assigned projects.
*   **Capabilities**: View their own Reports, Dashboards, and Campaign status. Cannot access agency-internal tools or other clients' data.
*   **Target**: External clients and project stakeholders.

### 4. 🤖 Specialized Roles
Additional roles like **Designer**, **Ad Manager**, and **Social Media Manager** provide tailored permissions for specific agency functions.

---

## 🛡️ Production & Security
Inhaus Brain is built with enterprise-grade safety:
*   **Role-Based Security**: Access is strictly enforced via Firebase Security Rules at the database level and Firebase Auth Custom Claims for fast, secure permission checking.
*   **Custom Claims Sync**: Cloud Functions automatically sync user roles from Firestore to Firebase Auth tokens, enabling instant RBAC validation without additional database reads.
*   **UI Masking**: Navigation and action buttons are automatically hidden based on the active user's role (e.g., Client Users cannot see Debug, Knowledge, or Admin tools).
*   **Automatic Redaction**: Sensitive data like emails and phone numbers are automatically hidden from AI models to protect privacy.
*   **Cultural Guardrails**: The system is tuned for LatAm and Ecuadorian cultural sensitivity, ensuring professional and inclusive communication.
*   **Validated Outputs**: Every AI response passes through an Orchestrator audit before being finalized.

---

## 🔧 Troubleshooting Video Generation

Is video generation stalling or failing? Use these steps to diagnose and fix common issues in the Video Generation Pipeline.

### ✅ What's New (Latest Updates)
**The video generation system has been significantly hardened:**
*   **180-Second Timeout**: Real video generation now allows up to **3 minutes** for cloud rendering (previously 5 minutes, now optimized to 180s with more frequent polling).
*   **Exponential Backoff**: Network errors trigger smart retry logic with increasing delays (capped at 10s).
*   **404 Recovery**: Up to **6 automatic retries** for "operation not found" errors before fallback.
*   **Non-Blocking Ingest**: Knowledge auto-ingest no longer blocks video generation (fire-and-forget pattern).
*   **Real Video Priority**: System always attempts real Veo cloud generation first. Fallback to static storyboard only after all retries exhausted.
*   **User Messaging**: Clear status updates like "Generating high-quality video... This may take up to 2 minutes."

### 1. Polling Errors (404/500)
*   **Symptom**: Console shows `Proxy Poll Error 500` or `404 Not Found` from Vertex AI.
*   **Cause**: Transient network issues or Google API propagation delay for LRO (Long Running Operation) IDs.
*   **Solution**: 
    *   ✅ **Automatic retries**: System now retries up to 6 times for 404 errors with exponential backoff.
    *   If 404 persists after 6 retries: fallback to static storyboard (last resort).
    *   Check GCP Console: Ensure Vertex AI API is enabled in `us-central1`.
    *   Telemetry will log `video_generation_failed` with reason `404_operation_not_found`.

### 2. "Operation ID must be a Long"
*   **Symptom**: Error about UUID vs Long format in operation ID.
*   **Cause**: Mismatch between `v1beta1` and `v1` Vertex AI endpoints.
*   **Solution**: ✅ **Fixed**. Proxy now routes polling to `v1` endpoint which accepts UUIDs. No action needed if latest functions are deployed.

### 3. Video Takes a Long Time (1-2 Minutes)
*   **Symptom**: Video generation shows "Still processing..." for 60-120 seconds.
*   **This is NORMAL**: 
    *   **Preview (veo-3.0-fast)**: ~10-30 seconds typical.
    *   **Final (veo-3.1)**: ~60-180 seconds typical for HQ render.
*   **What to expect**:
    *   Progress bar updates every 5 seconds.
    *   Status message: "Generating high-quality video... This may take up to 2 minutes."
    *   Total timeout: 180 seconds (36 polls).
*   **When to worry**: If it exceeds 180 seconds, it will timeout and show fallback.

### 4. Knowledge Ingest TimeoutException
*   **Symptom**: Console shows `TimeoutException after 0:00:10.000000` during video generation.
*   **Cause**: Knowledge auto-ingest was blocking the main flow (now fixed).
*   **Solution**: ✅ **Fixed**. Ingest is now fire-and-forget (unawaited) with 90s timeout. It won't block video generation.
*   **Impact**: You may still see the timeout warning in logs, but it's non-blocking and won't affect video generation.

### 5. Mock Video / Static Storyboard Appearing
*   **Symptom**: You see a static image or placeholder instead of real video.
*   **When this happens**:
    *   **Last Resort Fallback**: After all retries exhausted (2 preview retries + 36 polling attempts).
    *   **Quota Exceeded**: API quota hit (immediate fallback).
    *   **Network Failure**: 3+ consecutive network errors during polling.
*   **How to verify**:
    *   Check console for telemetry: `video_fallback_used` with reason.
    *   Look for 🚨 emoji in logs: "[LAST RESORT FALLBACK]".
    *   Result URL starts with `IMAGE:` prefix.
*   **What to do**:
    *   **First time**: Try again - might be transient network issue.
    *   **Repeated failures**: Check Firebase Auth, Vertex AI API quotas, network connectivity.
    *   **Expected in dev**: Non-web platforms use mock for fast iteration.

### 6. Progress Bar Stuck at Same Percentage
*   **Symptom**: Progress shows 45% and doesn't update.
*   **Cause**: Likely a polling timeout or dropped connection.
*   **Solution**:
    *   Wait for full 180s timeout - might resume.
    *   If stuck beyond 180s, operation timed out.
    *   Check network tab: Is `proxyVertexAI` returning 200?
    *   Telemetry will log `video_generation_timeout`.

### 7. How to Verify Real Video Generation
**Check these logs for successful REAL video:**
```
VideoService: 🎬 Starting REAL video generation poll
VideoService: Poll 1/36 (0s elapsed)
...
VideoService: Poll 17/36 (80s elapsed)
VideoService: ✅ Operation complete!
VideoService: 🎥 REAL video URL found: https://storage.googleapis.com/.../video.mp4
TelemetryService: video_generation_success { duration_s: 80, polls: 17, source: veo_cloud }
```

**Telemetry Events for Success:**
*   `video_preview_success` - Preview completed
*   `video_final_success` - Final render completed
*   `video_generation_success` - Cloud operation succeeded

**Telemetry Events for Issues:**
*   `video_generation_failed` - Operation failed (reason: 404_operation_not_found, consecutive_errors, quota)
*   `video_generation_timeout` - Exceeded 180s
*   `video_fallback_used` - Last resort fallback triggered
*   `video_preview_fallback` / `video_final_fallback` - Specific stage fallbacks

### 8. Cancel Long-Running Generation (Future)
*   **Current**: No cancel button yet.
*   **Workaround**: Wait for timeout (180s) or refresh page.
*   **Planned**: Cancel button to abort LRO during long generations.

---

## 📊 Expected Video Generation Times

| Type | Model | Typical Duration | Max Timeout | Fallback After |
|------|-------|------------------|-------------|----------------|
| **Preview** | veo-3.0-fast | 10-30s | 180s | 2 retries + 180s polling |
| **Final** | veo-3.1 | 60-180s | 180s | 36 polls (180s) |
| **Mock (Dev)** | Local | 1.5s | N/A | Immediate (non-web) |

---

*Built with ❤️ to make AI automation accessible for everyone.*
