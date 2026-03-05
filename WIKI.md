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

### 4. 📚 BrainWeave Knowledge Graph (The "Shared Mind")
Inhaus Brain's Knowledge Module (BrainWeave) is the agency's primary RAG (Retrieval-Augmented Generation) engine.
*   **BrainWeave 2.0 (Spanner & Vertex AI)**: The core graph has been upgraded to **Google Cloud Spanner**, enabling multi-billion node scalability and complex property graph queries.
*   **Agency-Wide Visibility**: Super Admins can toggle between their personal graph and a global **Agency View**, allowing them to manage knowledge across all client portfolios.
*   **Knowledge Promotion & Sharing**: Promoting insights from a personal workspace to **CLIENT** or **AGENCY** scope. This triggers aPub/Sub event for cross-team collaboration.
*   **6R Auto-Reweave Pipeline**: When knowledge is shared, a background **Cloud Run Job** automatically re-evaluates (6R) the surrounding context to ensure the shared mind remains consistent and high-quality.
*   **Performance & Cost Dashboard**: Real-time monitoring of graph growth (nodes/edges) and estimated operational costs, visible directly in the workspace.
*   **Vertex AI Search Grounding**: All agents are now grounded via an enterprise Vertex AI Search Data Store. High-value data extracted by agents is automatically synced to the GCP index.
*   **Media & Asset Integration**: BrainWeave now tracks generated media. When Brian creates an image or video, an **Asset Node** is automatically created in the graph with its source URL.
*   **3D Explorer**: An interactive 3D graph interface with advanced analysis tools including **Mermaid Export** and **Community Clustering**.

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

### 8. 🏢 Client Module (Production Grade)
This module allows you to manage diverse client portfolios with specialized support for both entities and individuals:
*   **Dual-Type Support**: 
    *   **Corporate**: For companies and agencies. Tracks **Legal Name**, **Tax ID (RUC)**, **Company Size**, and **Fiscal Address**.
    *   **Independent**: For freelancers and consultants. Tracks **Profession**, **Personal ID**, **Portfolio URL**, and **Birth Date**.
*   **Wizard Onboarding**: A streamlined 2-step creation workflow ensures accurate data entry for each client type.
*   **Deep Profile Views**: Dedicated overview screens display all legal and contact details at a glance.
*   **Projects & Tasks**: Organize work into specific project plans for each client.
*   **Integrations**: Connect client workspaces to **Google Ads**, **Meta Ads**, **TikTok**, and **Google Analytics** for automated data syncing.
*   **Data Ingestion**: The system automatically pulls performance metrics every 24 hours.
*   **Context Isolation**: All reports and dashboards are automatically filtered by the selected client, ensuring zero data leakage.

### 9. 📈 Analytics & Reporting Hub
A centralized command center for data-driven decision making:
*   **Unified Dashboards**: View across-platform performance (e.g., Facebook vs Google Ads) in a single pane of glass.
*   **Report Studio**: Generate beautiful PDF/Web reports using **ReportLM**.
    *   *Sources*: Add files, web URLs, or connected account data via the new **Integration Service**.
    *   *Formats*: Text summaries, charts, audio executive summaries (podcasts), and video previews.
*   **Knowledge Integration**: All ingested metrics are automatically added to the Vector Store, allowing you to ask questions like "Why did our CPA increase last week?"

### 10. 🕵️ Specialized Agents
Inhaus Brain deploys dedicated agents for specific operational tasks, governed by **Bilingual (English/Spanish)** prompts:
*   **Client Orchestrator**: Manages account health, monitors API connections, and handles client onboarding.
*   **Knowledge Maintainer**: A background agent that curates the Knowledge Base, identifying gaps (e.g., "Missing Brand Tone") and suggesting web searches to fill them.
*   **Reports Orchestrator**: An expert analyst that transforms raw data into narrative-driven insights, explaining *why* numbers changed, not just *what* happened.

### 11. 🧭 A2UI Composer IDE
A powerful internal tool specifically for visualizing GenUI JSON directly in the platform:
*   **3-Pane Sandbox**: A side-by-side view with a JSON Editor, a Live Canvas, and an AI Copilot Assistant that writes the structure for you. 
*   **Material 3 GenUI**: Built on the Atomic UI Renderer, the engine renders standard Material 3 layouts inside the chat dynamically.
*   **Gallery Templates**: Get started quickly using built-in interactive examples, including Audio/Video generation players.

### 12. 🛡️ Antigravity Agent Skills
To ensure consistent quality, safety, and cultural relevance, all agents operate using a unified **Skills System**. These reusable modules enforce strict guidelines:

*   **Cultural Safety**: Automatically adapts all content to be Ecuadorian/LatAm neutral, avoiding stereotypes and ensuring regional relevance.
*   **Privacy Compliance**: Redacts PII (emails, phones, IDs) from logs and external API calls before processing.
*   **Confidence Gates**: If an agent is less than 85% confident in a fact or code snippet, it will explicitly flag it or refuse the task rather than hallucinating.
*   **LiteRT Prediction**: Prioritizes fast, on-device models for drafts (text/code/video) to give you instant feedback (<2s) before using expensive cloud resources.
*   **Bilingual Output**: Enforces strict English/Spanish structural parity for all reports and client-facing text.

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

### 1. Polling Errors (404/500)
*   **Symptom**: The console shows `Proxy Poll Error 500` followed by a `404 Not Found` from the Google API.
*   **Cause**: The Veo model returns an operation ID with a special "publisher" path. While the proxy rewrites this, transient 404s may occur during propagation or if the region is overloaded.
*   **Solution**: The system now includes **automatic retries** (up to 5 attempts) and an extended fallback mechanism. If it persists, checking the GCP Console for 'Vertex AI' API enablement in `us-central1` is recommended.

### 2. "Operation ID must be a Long"
*   **Symptom**: Error message `"The Operation ID must be a Long, but was instead: UUID"`.
*   **Cause**: This happens when hitting the standard `v1` endpoint with a Veo UUID operation ID. The `v1` API version often expects numeric (Long) IDs.
*   **Solution**: The system now strictly uses the **`v1beta1`** regional endpoint (e.g., `us-central1-aiplatform.googleapis.com`) which supports UUIDs. 
*   **Hardening**: If a 400 error occurs, the proxy now automatically attempts to "repair" the operation name to the canonical format. If cloud polling still fails, the system instantly falls back to the **LiteRT Edge Preview** to ensure a real video is still produced.

### 3. Video Stuck in "Thinking..." or "Generating..."
*   **Symptom**: The generation indicator persists for a long time.
*   **Hardening**: Cloud rendering (Veo 3.1) is now supported with a **600-second (10-minute) timeout** and exponential backoff polling. If a generation takes time, it is likely in a queue.
*   **New Controls**:
    *   **Cancel**: You can now click "Cancel" next to the typing indicator to abort a stuck generation.
    *   **Retry**: If a preview times out and falls back to a storyboard, a **"Retry Generation"** button is now available directly on the image to restart the process.
*   **Background Ingest**: Knowledge ingestion (screencaps) is now **non-blocking**. Even if ingestion takes time, your video results will appear instantly once ready.

### 4. Mock Video / Storyboard (Big Buck Bunny) Appearing
*   **Symptom**: You see a cartoon bunny video or a static video placeholder.
*   **Cause**: This is the system's "Safety Fallback" or a "LiteRT Mock" in development environments. It appears if:
    *   **LiteRT Preview**: In non-web/dev environments, the system simulates a fast preview generation (<2s).
    *   **Failure Fallback**: If the API returned an error or timed out, the system defaults to this "Storyboard" so the UI remains functional.
*   **Fix**: Check your network tab. If `proxyVertexAI` failed, verify your Firebase Auth token. If you are in `Preview` mode, this is expected behavior for fast iteration if the cloud model is unreachable.

### 5. Gen UI: Detailed vs Placeholder Data
*   **Symptom**: Reports show "TBD%" or "XX%" rather than actual numbers.
*   **Cause**: The model chose a "fast" path or didn't have enough grounded data.
*   **Solution**: 
    1.  Ensure you are using **Google Search grounding** (automatically enabled for Research tasks).
    2.  The system now strictly forbids placeholders. If you see placeholders, try refreshing or re-prompting with "Use real data for the report."
    3.  Detailed reports require at least 5-7 sections; if the report is too short, the model may be ignoring quality guidelines.

### 6. "AI generation temporarily unavailable" or "UNEXPECTED_TOOL_CALL"
*   **Symptom**: Chat shows "AI generation temporarily unavailable" or displays raw `<tool_code>`/JSON blocks.
*   **Cause**: 
    1.  **Model Mapping**: The system was using "futuristic" IDs (e.g., `gemini-2.5-pro`) that don't exist in the Vertex AI API yet.
    2.  **Schema Validation**: Vertex AI rejected tool calls due to loosely defined `data` properties.
*   **Fix**: 
    1.  **Automated Mapping**: The system now maps futuristic IDs to stable ones (e.g., `2.5 Pro` → `1.5 Pro 002`, `3.0 Flash` → `2.0 Flash 001`).
    2.  **A2UI Enforcement**: All `gen_ui_component` calls now use strict property schemas.
    3.  **Robust Parsing**: Malformed outputs or `<tool_code>` artifacts are now repaired by the `JsonParserService`.

*Built with ❤️ by the Inhaus Automation Team.*
