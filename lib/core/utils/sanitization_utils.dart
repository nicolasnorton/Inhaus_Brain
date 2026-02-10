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

  /// Detects if the input is a simple salutation (Hi, Hello, etc.) to allow fast-path responses.
  static bool isSimpleSalutation(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return false;
    
    // Words to match (English, Spanish, Portuguese)
    final salutations = {
      'hi', 'hello', 'hey', 'yo', 'sup',
      'hola', 'buenas', 'alo', 'saludos',
      'oi', 'olá', 'ola', 'tudobem', 'tudo bem',
      'brian', 'hi brian', 'hello brian', 'hola brian'
    };

    // Exact matches or very short greetings
    if (salutations.contains(text)) return true;

    // Pattern for "Hi Brian!" etc.
    final regExp = RegExp(r'^(hi|hello|hey|hola|oi|ola|buenas|saludos)\s*(brian)?[\!\?\.]*$', caseSensitive: false);
    if (regExp.hasMatch(text)) return true;

    // Length check: If it's more than 3 words, it's probably not a "simple" salutation
    if (text.split(' ').length > 3) return false;

    return false;
  }

  /// Validates file size and basic extension checks
  static bool isValidFile(String fileName, int sizeBytes, {int maxSizeBytes = 20 * 1024 * 1024}) {
    if (sizeBytes > maxSizeBytes) return false;
    
    final ext = fileName.split('.').last.toLowerCase();
    final allowedExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'mp3', 'wav', 'm4a', 'pdf', 'doc', 'docx', 'txt', 'csv', 'gdoc'};
    
    return allowedExts.contains(ext);
  }
}
