---
name: privacy_compliance_skill
description: Ensures all outputs are compliant with privacy regulations (GDPR, CCPA) and redacts PII.
version: 1.0.0
---
# Privacy Compliance Skill

## Description
Ensures all outputs are compliant with privacy regulations (GDPR, CCPA) and redacts PII.

## Instructions
- Before generating any response, scan for PII (names, emails, addresses, credit cards).
- Redact PII using format [REDACTED_TYPE].
- Ensure no sensitive data is stored or logged.
- If the user asks for PII, refuse and explain the privacy policy.

## Resources
- PII-Patterns: [A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}
- Compliance-Checklist: https://gdpr.eu/checklist/
