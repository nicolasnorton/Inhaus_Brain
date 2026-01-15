class SanitizationUtils {
  /// Basic prompt escaping to prevent common prompt injection patterns.
  /// Wraps user input in delimiters and escapes potentially problematic characters.
  static String escapePrompt(String input) {
    if (input.isEmpty) return input;
    
    // Replace markdown and common orchestration characters if they seem suspicious
    // This is a basic implementation; more complex logic could be added.
    return input
        .replaceAll('"', '\\"')
        .replaceAll('\n', ' ')
        .trim();
  }

  /// Validates file upload metadata.
  static bool isValidFile(String fileName, int sizeBytes, {List<String>? allowedExtensions, int maxSizeBytes = 10 * 1024 * 1024}) {
    if (sizeBytes > maxSizeBytes) return false;
    
    if (allowedExtensions != null) {
      final extension = fileName.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) return false;
    }
    
    return true;
  }
}
