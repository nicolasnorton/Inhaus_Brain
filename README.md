# Inhaus Brain - Agentic Workflow Management

**Inhaus Brain** is a premium, agent-led workflow orchestration platform designed for modern agencies. It leverages on-device AI and a human-in-the-loop architecture to automate campaign research, visual strategy, and creative execution.

![Logo](assets/images/logo.png)

## 🚀 Vision
To empower human creators with AI agents that handle the heavy lifting of research and planning, while maintaining high-quality standards through intuitive approval loops.

## ✨ Key Features

### 🧠 Edge-First AI Strategy
Prioritizes privacy and efficiency by utilizing on-device and in-browser AI resources:
- **Chrome Prompt API**: Native in-browser text generation using local LLMs.
- **On-Device Agents**: Research and Creative agents run locally to minimize latency and token consumption.
- **Local Persistence**: Full campaign workflow persistence using `SharedPreferences`, enabling a backend-less initial experience.

### 🏢 Modular Creative Factory
- **Campaign Wizard**: Dynamic brief injection with automatic agent-led research.
- **Research Approval Loop**: Human review of AI-generated insights before proceeding.
- **Creative Studio**: Visual strategy workspace featuring AI-generated ad copy and visual prompts.
- **Moodboard Generation**: Strategic color palettes and visual directions proposed by the Design Agent.

### 🎨 Premium User Experience
- **Glassmorphic UI**: Sleek, modern dark-mode interface with semi-transparent elements.
- **Outfit Typography**: Modern and professional typography powered by Google Fonts.
- **Role-Based Access**: Specific views and permissions for Account Managers, Designers, and Admins.

## 🛠 Tech Stack
- **Frontend**: Flutter (3.0+ architecture)
- **State Management**: Riverpod (Notifier system)
- **Navigation**: GoRouter (Declarative routing)
- **AI Integration**: JS Interop for Chrome Built-in AI + local dynamic agents.
- **Persistence**: SharedPreferences (On-device) / Firebase-Ready architecture.

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
   flutter run -d chrome
   ```

## 📂 Project Structure
- `lib/core`: Theming, routing, and centralized services.
- `lib/features/auth`: Role-based login and session management.
- `lib/features/campaigns`: Campaign creation, wizardry, and insight approval.
- `lib/features/creative`: Creative Studio, design concepts, and moodboards.
- `lib/core/services/edge_ai_service.dart`: The brain of the "Edge-First" implementation.

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0**. 
See the [LICENSE](lib/LICENSE.md) file for more information.

Built with ❤️ for the future of agency coordination.
