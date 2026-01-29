class SecurityUtils {
  /// Simple PII scrubber for metadata extraction
  /// Masks emails, phone numbers, and potential SSNs
  static String scrubPII(String text) {
    String masked = text;
    
    // Mask emails
    masked = masked.replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[EMAIL_MASKED]');
    
    // Mask phone numbers (basic patterns)
    masked = masked.replaceAll(RegExp(r'(\+\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}'), '[PHONE_MASKED]');
    
    // Mask potential SSNs
    masked = masked.replaceAll(RegExp(r'\d{3}-\d{2}-\d{4}'), '[SSN_MASKED]');
    
    return masked;
  }
}
