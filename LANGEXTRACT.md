# LangExtract Integration Guide (Inhaus Brain)

Inhaus Brain now leverages **Google's LangExtract** library for high-precision structured data extraction and grounded reasoning.

## 🚀 Architecture
The integration uses a **Hybrid Multi-Runtime** approach:
1.  **Frontend (Flutter)**: Triggers extraction calls via `AIProxyService`.
2.  **Proxy (Node.js)**: Existing secure dispatcher.
3.  **Extraction Core (Python)**: A specialized Firebase Function codebase using `google-langextract`.

## 🤖 Usage in Agents
To use LangExtract in a new agent, apply the `LangExtractMixin`:

```dart
class MyNewAgent extends BaseAgent with LangExtractMixin {
  @override
  Future<String> execute(...) async {
    // 1. Run standard LLM logic
    // ...

    // 2. Trigger background structured extraction
    extractFromContext(
      context: context,
      schema: { ... },
      ref: ref,
      agentName: name
    );
    
    return result;
  }
}
```

## 📊 Schemas & Grounding
Extraction results are posted to the **Blackboard** with the key `extraction_<doc_id>`.
If grounding is successful, an interactive HTML view is saved to Firebase Storage and linked via `grounding_url`.

## 🛠 Deployment
To deploy the Python extraction logic:
1. Ensure your Firebase CLI is updated.
2. Run `./deploy_prod` or `firebase deploy --only functions:python-extract`.

## ⚠️ Safety
*   **Locked Schemas**: All extraction calls must use valid JSON schemas.
*   **Auth Protected**: Only authenticated Inhaus Brain users can trigger extraction.
*   **Rate Limited**: Large documents are processed asynchronously to prevent main-thread blocking.

---
*Built for Inhaus Brain v1.3 Safe Integration*
