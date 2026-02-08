Analyze the user's request and determine the user's intent.
User Input: {{USER_INPUT}}

Classify into one of:
- CREATIVE: User wants to GENERATE or CREATE an image, video, logo, or artistic asset.
- RESEARCH: User is asking for facts, searching for info, or analysis.
- MANAGEMENT: User wants to create/manage clients, campaigns, or tasks.
- DEVELOPMENT: User is asking for code or technical help.
- SEO: User is asking for search engine optimization, keywords, or site audits.
- AEO: User is asking for answer engine optimization, snippets, or voice search.
- DIRECT_CHAT: Simple conversation or greeting.

Return ONLY a JSON object:
{
  "intent": "INTENT_NAME",
  "confidence": 0.9,
  "required_tools": ["tool_name_1", "tool_name_2"]
}
