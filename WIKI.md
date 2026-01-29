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
This is where you talk to the AI. You can chat with specialized agents like a **Researcher**, **Strategist**, or **Copywriter**. They can work together to answer your questions or execute the workflows you built.

### 3. 🤖 AI Copilot (The Manager)
The Copilot is your AI assistant for running the platform. Instead of clicking through menus, you can just ask it to do things.
*   **Manage Clients**: "Add a client called Acme Corp", "Show all my clients".
*   **Manage Campaigns**: "Create a new campaign for Summer Launch", "Delete the draft campaign".
*   **Manage Knowledge**: "Add https://inhaus.corp/manual to my knowledge base", "List all my knowledge sources".
*   **Create Apps**: "Build a new research app for Competitor Analysis".

### 4. 📚 Knowledge Base (The Library)
You can upload your own PDFs, documents, or website links here. The AI will "read" them and use that information to make sure its answers are accurate and specific to your business.

### 5. 🚀 Publish Dashboard (Deployment)
This is where you turn your workflows into real applications. You can publish them as standalone **Web Apps**, integrate them into other systems via **API**, or embed them directly onto your own website using a **Chat Widget**.

### 6. 🎬 Flawless Video Generation & On-Device AI
Generate high-fidelity branded video assets directly from your research or creative concepts, powered by a hybrid engine.
*   **On-Device Previews (LiteRT)**: Instant, zero-cost previews using **Gemma 2B** and **Veo 3 Fast** running directly on your device (NPU/GPU accelerated).
*   **Cost-Aware Routing**: The system automatically chooses the best model:
    *   _Drafts/Previews_: LiteRT (Local)
    *   _Final/High-Fidelity_: Veo 3.1 (Cloud)
*   **High-Fidelity Rendering**: Only uses flagship models (Veo 3.1) for the **Final Render** once you are 100% satisfied.
*   **Bilingual Subtitles**: One-click generation of professional English/Spanish captions for international reach.
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

## 🛡️ Production & Security
Inhaus Brain is built with enterprise-grade safety:
*   **Automatic Redaction**: Sensitive data like emails and phone numbers are automatically hidden from AI models to protect privacy.
*   **Cultural Guardrails**: The system is tuned for LatAm and Ecuadorian cultural sensitivity, ensuring professional and inclusive communication.
*   **Validated Outputs**: Every AI response passes through an Orchestrator audit before being finalized.
*   **Secure Access**: Your data is protected by strict Firebase Security Rules—only you can see your campaigns and research.

*Built with ❤️ to make AI automation accessible for everyone.*
