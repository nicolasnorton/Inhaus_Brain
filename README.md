# Inhaus Brain - Agentic Workflow Management

**Inhaus Brain** is a premium, agent-led workflow orchestration platform designed for modern agencies. It leverages on-device AI and a human-in-the-loop architecture to automate campaign research, visual strategy, and creative execution.

![Logo](assets/images/logo.png)

## 🚀 Vision
To empower human creators with AI agents that handle the heavy lifting of research and planning, while maintaining high-quality standards through intuitive approval loops.

## ✨ Key Features

### 🧠 Hybrid Edge-Cloud AI
Prioritizes privacy and flexibility by intelligently switching between resources:
- **Local/Edge**: Uses Chrome Built-in AI (Prompt API) or simulated reasoning for fast, cost-free drafting.
- **Cloud High-Fidelity**: Seamlessly upgrades to **Gemini Pro via Google Vertex AI** if the user provides an API key in the Secrets Vault.
- **BYO-Key Architecture**: Users maintain full control over their API usage and quotas via a secure, local-only "Secrets Vault".

### 🤖 Multi-Modal Agentic Workbench
- **Collaborative Chat**: A unified "Workshop" interface where users, Research Agents, and Creative Agents collaborate.
- **Knowledge Module**: Users can inject "Ground Truth" context (URLs, PDFs, Briefs) via a dedicated **Context Board**. Agents reference this data for grounded responses.
- **MCP Tools**: Implemented using the **Model Context Protocol**, allowing standard agents to use tools like `WebSearch` and `VisualAnalysis`.
- **Auto-Handoffs (A2A)**: Strategic approvals automatically trigger the next agent in the pipeline (e.g., Strategy Approval -> Creative Agent Concept Gen).

### 🏢 Modular Creative Factory
- **Campaign Wizard**: Dynamic brief injection with automatic agent-led research.
- **Human-in-the-Loop**: Custom approval widgets integrated directly into the chat stream ensure no AI output proceeds without sign-off.
- **Creative Studio**: Visual strategy workspace featuring AI-generated ad copy and visual prompts.
- **Moodboard Generation**: Strategic color palettes and visual directions proposed by the Design Agent.

### 🎨 Premium User Experience
- **Glassmorphic UI**: Sleek, modern dark-mode interface with semi-transparent elements.
- **Interactive Profiles**: Integrated Google Sign-In and user profile management.
- **Role-Based Access**: Specific views and permissions for Account Managers, Designers, and Admins.

## 🛠 Tech Stack
- **Frontend**: Flutter (3.0+ architecture)
- **State Management**: Riverpod (Notifier system)
- **AI Integration**:
    - **Edge**: `dart:js_interop` for Chrome Built-in AI.
    - **Cloud**: `google_generative_ai` for Vertex AI features.
    - **Protocol**: Model Context Protocol (MCP) for tool definitions.
- **Auth & Storage**:
    - `firebase_auth` & `google_sign_in` for Identity.
    - `flutter_secure_storage` for local API Key Vault.
    - `shared_preferences` / mock `firebase` for persistence.

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
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

## 📂 Project Structure
- `lib/core`: Theming, routing, and centralized services.
- `lib/features/auth`: Role-based login and session management.
- `lib/features/campaigns`: Campaign creation, wizardry, and insight approval.
- `lib/features/creative`: Creative Studio, design concepts, and moodboards.
- `lib/core/services/edge_ai_service.dart`: The brain of the "Edge-First" implementation.

---
Built with ❤️ for the future of agency coordination.
