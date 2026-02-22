# Inhaus Brain v1.2.1+28 - Agentic Workflow Management

**Inhaus Brain** is a premium, agent-led workflow orchestration platform designed for modern agencies. It leverages on-device AI and a human-in-the-loop architecture to automate campaign research, visual strategy, and creative execution.

![Logo](assets/images/logo.png)

## 🚀 Vision
To empower human creators with AI agents that handle the heavy lifting of research and planning, while maintaining high-quality standards through intuitive approval loops.

## ✨ Key Features

### 🧠 Hybrid Multi-Modal AI Engine
The Inhaus Brain intelligently coordinates a suite of specialized models via its **Hybrid Tiering Engine**:
- **Gemma / Gemini Pro**: Text-based reasoning and strategic analysis.
- **Imagen 3**: High-fidelity production imagery for concepts.
- **Veo**: SOTA video asset generation directly in the Workbench.
- **Lyria**: Advanced music and soundtrack composition for campaigns.
- **Nano Banana 🍌**: Agentic visual refinement and image editing.
- **Multi-Model Sovereignty**: Support for **OpenAI (GPT-4o)**, **Anthropic (Claude 3.5 Sonnet)**, **xAI (Grok Beta)**, **Eleven Labs (Voice)**, **Runway (Video)**, and **Midjourney** via BYOK (Bring Your Own Keys).
- **Edge Fallback**: Uses Chrome Built-in AI or local mocks if no API keys are provided.
- **Rich GenUI Library**: Triggers interactive Flutter widgets (`BudgetChart`, `KanbanBoard`, `StrategyBoard`) directly in the chat stream via natural language.

### 🤖 Agency-Wide Specialist Workforce (New)
The Inhaus Brain features a team of 11+ specialized agents, each with a custom markdown-driven persona:
- **Brian (Super Admin)**: The world-class Chief of Staff who orchestrates the entire agency.
- **Research Agent**: Deep market analysis and competitor scraping.
- **Strategist Agent**: Data-driven campaign plans and risk assessment.
- **Creative Agent**: Visual concepts, image prompts, and artistic direction.
- **Copywriter Agent**: High-converting text for ads and social media.
- **Design Agent**: Pixel-perfect UI/UX specs and wireframes.
- **Video Production Agent**: Storyboarding and 4K production management.
- **Customer Service Agent**: Empathetic client resolution and SLA tracking.
- **CRM Agent**: Record management and audience segmentation.
- **C-Suite Advisor Agent**: ROI projections and board-level strategy.
- **SEO Agent (New)**: Search engine optimization, keyword research, and regional audits.
- **AEO Agent (New)**: Answer engine optimization for AI search and voice assistants.
- **Auto-Handoffs (A2A)**: "Agent-to-Agent" protocols where Research outputs automatically prime the Creative agent.
- **Proposal Specialist (New)**: Bilingual agent capable of generating structured, service-mapped client proposals. Now supports high-fidelity **PDF Document** (Portrait) and **Slide Deck** (Landscape) generation with dynamic branding integration.

### 💼 Services Catalog & Profitability Management (New)
A comprehensive service portfolio management system designed for agency operations:
- **Service Catalog**: Full CRUD operations for service bundles and individual services with bilingual support (EN/ES).
- **Profitability Analytics**: Real-time margin calculations, portfolio metrics, and profitability ranking dashboard.
- **Pricing Optimization**: Track delivery costs, target margins, and identify services needing price adjustments.
- **Proposal Integration**: Seamlessly connect services to AI-powered proposal generation with catalog-backed pricing.
- **Smart Service Selection**: Multi-select service picker in proposal creation with real-time price display.
- **Target Services Display**: Visual scope clarity showing selected services in proposal detail screens.
- **Seed Data**: Pre-configured with 12 service bundles + 11 individual services for immediate use.
- **Firestore Security**: Production-ready security rules with role-based access control.

- **Demo Mode**: Special "Easter Egg" triggers for tailored client demos (e.g. Bajaj, Banco del Austro).

### 🦅 Blackboard 2.0 & Observability
A robust, event-driven architecture designed for stability and transparency:
- **Phase-Based State Machine**: Enforces strict transitions (Idle -> Research -> Creative -> Strategy) to prevent race conditions and ensure logical workflow progression.
- **Flight Recorder**: Real-time observability widget (accessible via the ⚡️ icon) that visualizes agent status, phase changes, and workflow events.
- **Semantic Cache**: Intelligent in-memory caching that stores LLM responses (hashed by intent and prompt) to reduce latency and token usage for repeated queries.
- **Resilient Parsing**: Enhanced JSON extraction logic ensures reliable tool execution even with "noisy" LLM outputs.
- **Human-in-the-Loop (The Gavel)**: Formal "Arbiter" pattern that detects stalled agents (retries > 2) and pauses execution for manual user review via specific `ApprovalCard` widgets.
- **Strict Schema Enforcement**: "Typed Agents" use strict JSON validation (A2UI compliant) to eliminate hallucinated structures.
- **A2UI Lifecycle**: Integrated with the Flutter GenUI SDK for streaming, token-efficient UI component delivery.

### 🖥️ A2UI Composer Support 
A fully-featured, built-in IDE experience for designing and testing AI UI components:
- **3-Pane Widget Editor**: Live integrated JSON syntax editor, real-time widget preview canvas (using `AtomicUIRenderer`), and an isolated Copilot Agent for automated structural editing.
- **Material 3 Parity**: Real-time rendering of complex Material 3 widgets via the Atomic Foundation Spec v3.0 (Buttons, Cards, Chips, Inputs, Media Players).
- **Gallery & Components Library**: Pre-built, native documentation grids featuring rich sample templates like Music Players, Cinematic Video, and full page layouts.
- **Cloud Persistence**: Seamlessly save and resume custom UI components to Firestore.

### 🏗️ Agent Development Kit (ADK)
A powerful orchestration layer that allows for complex, multi-step workflows:
- **Pipeline Builder**: Drag-and-drop interface to assemble custom AI workflows using any agent in the registry.
- **Visual Workflow Canvas**: Infinite, node-based editor for designing complex DAG (Directed Acyclic Graph) agent networks.
- **Master Agency Pipeline**: A factory-default, 11-step specialized workflow (Trend Scout -> Strategist -> Performance Analyst -> etc.) for end-to-end campaign automation.
- **Control Flow**: Advanced execution logic with **If-Else**, **Switch/Case**, and **Loop** (For Each/While) nodes.
- **Integrated Debugging**: Real-time **Variable Inspector**, **Test Run** dialogs, and **Run History** logging directly within the ADK.
- **Workflow Templates**: One-click creation of complex apps using pre-configured blueprints (Simple Chatbot, Twitter Analyzer, Customer Service Bot, etc.).
- **Import/Export (DSL)**: Full interoperability through JSON-based Domain Specific Language (DSL). Export your entire app configuration and import it into other environments.
- **Responsive Dashboard**: Premium home screen with intelligent quick-access widgets for all core modules.
- **User Input Node**: Dify-style variable collection with support for Text, Select, Number, Checkbox, and Files.
- **Variable Injection**: Dynamic mustache-style `{{variable}}` resolution across all node configurations.
- **Graph Validator (The Compiler)**: Topological sort engine that prevents infinite loops, detects dead ends, and ensures all dependencies are met before execution starts.
- **Budget Governor**: "Token Bucket" economic system that tracks and limits credit usage per workflow run to prevent runaway API costs.

### 🚀 Publishing & Distribution
Effortless deployment of your AI agents across multiple channels:
- **Web Applications**: Generate standalone, branded web apps with full session management.
- **API Integration**: RESTful endpoints with API key management and rate limiting.
- **Website Embedding**: Seamless chat widgets and iframe embedding for existing sites.
- **MCP Server Deployment**: Standardized tool integration via the Model Context Protocol.

### 🤖 Autonomous Platform Management (Copilot)
The Inhaus Brain features an **AI Super Admin** (Management Agent) that allows you to operate the entire platform via natural language:
- **Client & CRM**: Create, list, search, and update client records and project plans.
- **Campaign Orchestration**: Full CRUD support for marketing campaigns.
- **Brain Knowledge Management**: Autonomous injection and removal of websites, files, and documents from the system's global knowledge base. Now supports direct **Google Drive Integration** for seamless document importing.
- **App/Agent CRUD**: Design and deploy new AI application pipelines directly through chat commands.
- **Universal Search**: Intelligent retrieval of any platform entity (Tasks, Projects, Apps) across the workspace.

### 🛡️ Security Guardian
Enterprise-grade safety integrated directly into the agentic flow:
- **Input Audit**: Mandatory safety scan of all user input before a pipeline begins.
- **Sensitive Task Interception**: Automatically blocks or sanitizes high-stakes actions (Media Buying, Data Access) if they violate brand safety.
- **Final Output Verification**: A final security pass on all AI-generated content before it reaches the user.

### 🏢 Creative Studio & Client Factory
- **Streamlined Client Module**: Merged navigation for faster workflows (Contacts integrated into Overview, Commerce into Integrations).
- **Project Plans & Task Boards**: Comprehensive portfolio management with real-time tracking.
- **Third-Party Integrations**: Native connectors for **Gmail**, **Slack**, **Notion**, and **GoHighLevel**.
- **Human-in-the-Loop**: Approval cards ensure AI output is verified before proceeding to production.

### 🎨 Premium Auth & Settings
- **Full Auth Lifecycle**: Premium Sign Up / Login flow with Email/Password and Google support.
- **Account Management**: Edit profiles, manage API keys, and customize agent personas in a unified **Settings & Vault**.
- **Sleek UX**: Glassmorphic, dark-mode design using Google's *Outfit* typography and high-performance micro-animations.

### 🚀 Deployment & Scalability (Step #4)
- **Containerized Infrastructure**: Production-grade `Dockerfile` using Nginx to serve the Flutter Web app.
- **Automated CI/CD**: Pre-configured `cloudbuild.yaml` for seamless deployment via Google Cloud Build.
- **Premium Auth**: Google Sign-In with production-ready `renderButton` and GIS migration.
- **AI Stability**: Aggressive focus isolation and optimized image generation fallbacks.
- **Professional Branding**: Integrated asset-based watermarking and "Powered by INHAUS BRAIN" identity.

## 🛠 Tech Stack
- **Frontend**: Flutter (3.0+ architecture)
- **State Management**: Riverpod (Notifier system)
- **AI Integration**:
    - **Cloud**: `firebase_ai` (Unified SDK) for Gemini & Vertex AI features.
    - **Protocol**: Model Context Protocol (MCP) for tool definitions.
- **Auth & Storage**:
    - `firebase_auth` & `google_sign_in` for Identity.
    - **Full Auth Flow**: Secure login, account management, and role-based master prompts.
- **Secrets Vault**: Bring Your Own Keys (BYOK) for Gemini, Imagen, Veo, and more.
- **Orchestration**: Agent Development Kit (ADK) with Event Bus and Artifact Framework.

## Getting Started

To use the full version of the app with live AI capabilities, please follow our [Google AI & Cloud Setup Guide](file:///Users/nicolasnorton/.gemini/antigravity/brain/2bf1f2da-605e-4566-a3b9-1a7b5673ab0/google_ai_setup.md).

 1.  Clone the repository.
 2.  **Run Setup**: Execute the new setup script to bootstrap dependencies:
     ```bash
     ./setup.sh
     ```
 3.  **Agent Rules**: All AI agents contributing to this repo must follow the constraints defined in `agentrules.md` and `.cursorrules`.
 3.  **Environment Setup**: Copy `.env.example` to `.env` and add your keys:
    ```bash
    cp .env.example .env
    ```
 4.  Follow the setup guide to obtain your API keys if you haven't yet.
 5.  Launch with `flutter run`.
- Google Chrome (with [Built-in AI features enabled](https://developer.chrome.com/docs/ai/built-in-ai#get_started))

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/nicolasnorton/Inhaus_Brain.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run -d chrome --web-port 8080
   ```

### ☁️ Cloud Deployment
See [DEPLOY.md](DEPLOY.md) for full instructions on deploying to **Firebase Hosting** and **Cloud Run** using our automated scripts.

### 🛡️ App Check & Emulators
- **Production**: Uses ReCaptcha v3 (Site Key in `main.dart`).
- **Local Development**:
  - Uses `debug` App Check provider.
  - **Firestore Emulator** is **REQUIRED** for local database access (configured in `main.dart` for `kDebugMode`).
  - Run emulators: `npx firebase emulators:start --only functions,firestore`.
  - **Vertex AI**: Requires the "Vertex AI API" to be enabled in Google Cloud Console.

## 📂 Project Structure
- `lib/core`: Theming, routing, and centralized services.
- `lib/features/auth`: Role-based login and session management.
- `lib/features/campaigns`: Campaign creation, wizardry, and insight approval.
- `lib/features/creative`: Creative Studio, design concepts, and moodboards.
- `lib/features/workspace`: Management of Model Providers, Plugins, Apps, and Publishing.
- `lib/features/adk`: The core Agent Development Kit, including workflow logic and debug tools.
- `lib/core/services/edge_ai_service.dart`: The brain of the "Edge-First" implementation.

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0**. 
See the [LICENSE](lib/LICENSE.md) file for more information.

Built with ❤️ for the future of agency coordination.
