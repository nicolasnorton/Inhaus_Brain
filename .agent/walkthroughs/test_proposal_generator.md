# Walkthrough: Testing the INHAUS Proposal Generator

This guide provides step-by-step instructions to verify the fixes and visual upgrades applied to the Proposal Generator module.

## 1. Prerequisites
Before testing, ensure your development environment is ready:
- **Firebase Emulators**: Ensure `npx firebase emulators:start` is running in your terminal.
- **Flutter App**: Relaunch the app on Chrome (Web) to ensure the latest Dart changes and Cloud Function endpoints are active.
- **Login**: Log in as an administrator or account manager to access campaign features.

## 2. Navigation & Setup
1.  **Navigate to Agency Hub**: Click the **Agency** (Building) icon in the sidebar.
2.  **Go to Sales**: Select the **Proposals** tab in the Sales Hub.
3.  **Select Client**: Use the dropdown at the top to select a client (e.g., "Banco del Austro").
4.  **Open Proposal**: Click on an existing proposal card (e.g., "SEO 2026") or create a new one.

## 3. Testing Generation
1.  **Add Sources**: Ensure the proposal has sources (links, text, or files).
2.  **Click Detailed Proposal**: In the **Studio** panel on the right, click **Detailed Proposal**.
3.  **Observe**:
    - **UI**: A circular progress indicator appears.
    - **Proxy Bypass**: The app now uses the `proxyVertexAI` Cloud Function to bypass App Check and CORS issues.
4.  **Verification**: 
    - A success snackbar appears.
    - The PDF preview/share dialog opens.

## 4. Persistent Outputs
1.  **View History**: Generated outputs are listed in the **Outputs** section of the Studio panel.
2.  **Re-viewing**: Click any item in the **Outputs** list; the app will re-generate and open the PDF immediately.

## 5. Troubleshooting (Production)
- **App Check Error**: If you see "App Check verification failed", the app will still function via the Proxy fallback.
- **400 Bad Request**: Resolved by payload optimization (limit set to 8,000 chars) and automated JSON markdown stripping.
- **Service Worker (404)**: If navigation fails, the app automatically unregisters stale service workers on reload.

## 6. Visual Audit (The INHAUS Style)
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
