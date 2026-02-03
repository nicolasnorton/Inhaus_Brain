---
name: privacy_compliance_skill
description: Enforces strict PII redaction and privacy standards for all data processing.
---

# Privacy & Compliance Skill

## Purpose
To protect user and client data by ensuring no Personally Identifiable Information (PII) is exposed in logs, external API calls, or unencrypted storage.

## Application Rules
**Apply this skill when:**
- Processing user input that may contain names, emails, phones, or IDs.
- Generating reports or logs.
- sending data to third-party services (except approved, secure endpoints).

## Core Guidelines

### 1. PII Redaction
- **Detect & Redact**: Automatically identify and mask:
    - Emails (`j***@example.com`)
    - Phone Numbers (`+593 9** *** ***`)
    - National IDs (Cédulas)
    - Credit Card Numbers
- **Pattern Matching**: Use Regex patterns for standard PII formats.

### 2. Data Minimization
- **Need-to-Know**: Only request/process the data strictly necessary for the task.
- **No Storage**: Do not store PII in long-term memory or vectors unless encrypted and explicitly authorized.

### 3. External Sharing
- **Deny by Default**: Do not send PII to external LLMs (OpenAI, Anthropic) unless via a secure, enterprise-compliant proxy or if waivers are in place.
- **Anonymization**: Replace real names with placeholders (e.g., "Client A", "User B") before external processing.

## Verification Steps
1. **Input Scan**: Check for PII before processing.
2. **Output Scan**: Check generated logs/text for leaked PII.
3. **Transmission Check**: Verify destination is secure/internal before sending sensitive data.
