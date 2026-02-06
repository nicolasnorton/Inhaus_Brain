# Walkthrough: Testing the INHAUS Proposal Generator

This guide provides step-by-step instructions to verify the fixes and visual upgrades applied to the Proposal Generator module.

## 1. Prerequisites
Before testing, ensure your development environment is ready:
- **Firebase Emulators**: Ensure `npx firebase emulators:start` is running in your terminal.
- **Flutter App**: Relaunch the app on Chrome (Web) to ensure the latest Dart changes and Cloud Function endpoints are active.
- **Login**: Log in as an administrator or account manager to access campaign features.

## 2. Navigation & Setup
1.  **Navigate to Campaigns**: From the main dashboard, click on the **Campaigns** icon in the sidebar.
2.  **Select a Campaign**: Choose an existing campaign (e.g., "Campaign Strategy Brief - Bajaj") or create a new one.
3.  **Advance to Design Phase**: 
    - If the campaign is in "Researching" status, you must **Approve all Insights** first.
    - Click **Proceed to Design Plan**. The status will change to **Designing**, and the "Creative Studio" and "Proposal" buttons will appear.

## 3. Testing Generation (Detailed Proposal)
1.  **Locate the Button**: Find the blueprint-blue card titled **Design Phase Active**.
2.  **Click Generate**: Click on **Generate Client Proposal (PDF)**.
3.  **Observe Logs**:
    - **UI**: A loading indicator ("Generating Proposal...") should appear.
    - **Terminal (Functions)**: You should see the `copilotRuntime` log trigger and the `Proposal Specialist` execution start.
4.  **Verification**: 
    - A success snackbar should appear: "Proposal Generated Successfully!".
    - The PDF should automatically open in a new tab or trigger a system share/view dialog.

## 4. Visual Audit (The INHAUS Style)
Once the PDF is open, verify the following visual markers to ensure the **"Premium Agency"** look:
- [ ] **Background**: Entire page should have a dark purple-black theme (#1A0F2E).
- [ ] **Cover Page**: Should feature "INHAUS ESTUDIO CREATIVO" in purple, with a large, bold white title "BUSINESS PROPOSAL".
- [ ] **Internal Sections**:
    - [ ] Section headers (e.g., "RRSS") should be inside purple rounded blocks.
    - [ ] Descriptions and bullets should be clear white/gray text.
    - [ ] **Pricing**: Look for a purple price box on the right side of each section.
- [ ] **Bilingual Check**: Verify that the content is professionally written in Spanish (ES).

## 5. Testing the "One Page Quote" (Quick Path)
*Note: This usually triggers via a specific user prompt in the Copilot chat or a specific campaign type.*
1.  **Open Copilot**: Click the Chat icon.
2.  **Prompt**: Type *"Generate a quick one-page quote for a social media package for this client."*
3.  **Review**: 
    - The resulting JSON should have `type: "one_page"`.
    - The PDF should be a single, high-impact page with a summary intro and a large "TOTAL PRICE" box at the bottom.

## 6. Troubleshooting
- **Error 500/Polling Error**: Ensure you are using the latest `lib/core/tokens/llm_provider.dart` with `gemini-1.5-pro-001`.
- **JSON Parsing Error**: If the agent returns text instead of code, check the `proposal_specialist.md` prompt at `assets/prompts/` is being correctly loaded by the `SystemPromptsService`.
- **Missing Images**: Ensure "Creative Studio" has been opened at least once to generate visual concepts that can be pulled into the proposal.
