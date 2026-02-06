/// Additional app feature models
library;

/// File type for uploads
enum FileType {
  image,
  document,
  audio,
  video;

  String get displayName {
    switch (this) {
      case FileType.image:
        return 'Image';
      case FileType.document:
        return 'Document';
      case FileType.audio:
        return 'Audio';
      case FileType.video:
        return 'Video';
    }
  }

  String get icon {
    switch (this) {
      case FileType.image:
        return '🖼️';
      case FileType.document:
        return '📄';
      case FileType.audio:
        return '🎵';
      case FileType.video:
        return '🎬';
    }
  }

  List<String> get extensions {
    switch (this) {
      case FileType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case FileType.document:
        return ['pdf', 'txt', 'doc', 'docx', 'md'];
      case FileType.audio:
        return ['mp3', 'wav', 'm4a'];
      case FileType.video:
        return ['mp4', 'mov', 'avi'];
    }
  }
}

/// Uploaded file
class UploadedFile {
  final String id;
  final String name;
  final FileType type;
  final int size;
  final String url;
  final DateTime uploadedAt;
  final String? thumbnailUrl;

  const UploadedFile({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.url,
    required this.uploadedAt,
    this.thumbnailUrl,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString().split('.').last,
        'size': size,
        'url': url,
        'uploaded_at': uploadedAt.toIso8601String(),
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      };

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: FileType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FileType.document,
      ),
      size: json['size'] as int,
      url: json['url'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
}

/// File upload configuration
class FileUploadConfig {
  final bool enabled;
  final List<FileType> allowedTypes;
  final int maxFileSize; // bytes
  final int maxFiles;

  const FileUploadConfig({
    this.enabled = false,
    this.allowedTypes = const [FileType.image, FileType.document],
    this.maxFileSize = 15 * 1024 * 1024, // 15MB
    this.maxFiles = 10,
  });

  FileUploadConfig copyWith({
    bool? enabled,
    List<FileType>? allowedTypes,
    int? maxFileSize,
    int? maxFiles,
  }) {
    return FileUploadConfig(
      enabled: enabled ?? this.enabled,
      allowedTypes: allowedTypes ?? this.allowedTypes,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxFiles: maxFiles ?? this.maxFiles,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'allowed_types': allowedTypes.map((t) => t.toString().split('.').last).toList(),
        'max_file_size': maxFileSize,
        'max_files': maxFiles,
      };

  factory FileUploadConfig.fromJson(Map<String, dynamic> json) {
    return FileUploadConfig(
      enabled: json['enabled'] as bool? ?? false,
      allowedTypes: (json['allowed_types'] as List?)
              ?.map((t) => FileType.values.firstWhere(
                    (e) => e.toString().split('.').last == t,
                    orElse: () => FileType.document,
                  ))
              .toList() ??
          [FileType.image, FileType.document],
      maxFileSize: json['max_file_size'] as int? ?? 15 * 1024 * 1024,
      maxFiles: json['max_files'] as int? ?? 10,
    );
  }
}

/// Conversation opener configuration
class ConversationOpenerConfig {
  final bool enabled;
  final String message;

  const ConversationOpenerConfig({
    this.enabled = false,
    this.message = 'Hello! How can I help you today?',
  });

  ConversationOpenerConfig copyWith({
    bool? enabled,
    String? message,
  }) {
    return ConversationOpenerConfig(
      enabled: enabled ?? this.enabled,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'message': message,
      };

  factory ConversationOpenerConfig.fromJson(Map<String, dynamic> json) {
    return ConversationOpenerConfig(
      enabled: json['enabled'] as bool? ?? false,
      message: json['message'] as String? ?? 'Hello! How can I help you today?',
    );
  }
}

/// Follow-up suggestions configuration
class FollowUpSuggestionsConfig {
  final bool enabled;
  final int maxSuggestions;

  const FollowUpSuggestionsConfig({
    this.enabled = false,
    this.maxSuggestions = 5,
  });

  FollowUpSuggestionsConfig copyWith({
    bool? enabled,
    int? maxSuggestions,
  }) {
    return FollowUpSuggestionsConfig(
      enabled: enabled ?? this.enabled,
      maxSuggestions: maxSuggestions ?? this.maxSuggestions,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'max_suggestions': maxSuggestions,
      };

  factory FollowUpSuggestionsConfig.fromJson(Map<String, dynamic> json) {
    return FollowUpSuggestionsConfig(
      enabled: json['enabled'] as bool? ?? false,
      maxSuggestions: json['max_suggestions'] as int? ?? 5,
    );
  }
}

/// TTS provider
enum TTSProvider {
  openai,
  google,
  azure,
  elevenlabs;

  String get displayName {
    switch (this) {
      case TTSProvider.openai:
        return 'OpenAI TTS';
      case TTSProvider.google:
        return 'Google Cloud TTS';
      case TTSProvider.azure:
        return 'Azure TTS';
      case TTSProvider.elevenlabs:
        return 'ElevenLabs';
    }
  }
}

/// Text-to-speech configuration
class TextToSpeechConfig {
  final bool enabled;
  final TTSProvider provider;
  final String voice;
  final double speed;

  const TextToSpeechConfig({
    this.enabled = false,
    this.provider = TTSProvider.openai,
    this.voice = 'alloy',
    this.speed = 1.0,
  });

  TextToSpeechConfig copyWith({
    bool? enabled,
    TTSProvider? provider,
    String? voice,
    double? speed,
  }) {
    return TextToSpeechConfig(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      voice: voice ?? this.voice,
      speed: speed ?? this.speed,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'provider': provider.toString().split('.').last,
        'voice': voice,
        'speed': speed,
      };

  factory TextToSpeechConfig.fromJson(Map<String, dynamic> json) {
    return TextToSpeechConfig(
      enabled: json['enabled'] as bool? ?? false,
      provider: TTSProvider.values.firstWhere(
        (e) => e.toString().split('.').last == (json['provider'] ?? 'openai'),
        orElse: () => TTSProvider.openai,
      ),
      voice: json['voice'] as String? ?? 'alloy',
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Citation configuration
class CitationConfig {
  final bool enabled;
  final bool showConfidence;
  final bool linkToSource;

  const CitationConfig({
    this.enabled = false,
    this.showConfidence = true,
    this.linkToSource = true,
  });

  CitationConfig copyWith({
    bool? enabled,
    bool? showConfidence,
    bool? linkToSource,
  }) {
    return CitationConfig(
      enabled: enabled ?? this.enabled,
      showConfidence: showConfidence ?? this.showConfidence,
      linkToSource: linkToSource ?? this.linkToSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'show_confidence': showConfidence,
        'link_to_source': linkToSource,
      };

  factory CitationConfig.fromJson(Map<String, dynamic> json) {
    return CitationConfig(
      enabled: json['enabled'] as bool? ?? false,
      showConfidence: json['show_confidence'] as bool? ?? true,
      linkToSource: json['link_to_source'] as bool? ?? true,
    );
  }
}

/// Content moderation category
enum ModerationCategory {
  hateSpeech,
  violence,
  sexualContent,
  selfHarm,
  illegalActivities;

  String get displayName {
    switch (this) {
      case ModerationCategory.hateSpeech:
        return 'Hate Speech';
      case ModerationCategory.violence:
        return 'Violence';
      case ModerationCategory.sexualContent:
        return 'Sexual Content';
      case ModerationCategory.selfHarm:
        return 'Self-Harm';
      case ModerationCategory.illegalActivities:
        return 'Illegal Activities';
    }
  }
}

/// Content moderation configuration
class ContentModerationConfig {
  final bool enabled;
  final List<ModerationCategory> blockedCategories;
  final String customRules;

  const ContentModerationConfig({
    this.enabled = false,
    this.blockedCategories = const [],
    this.customRules = '',
  });

  ContentModerationConfig copyWith({
    bool? enabled,
    List<ModerationCategory>? blockedCategories,
    String? customRules,
  }) {
    return ContentModerationConfig(
      enabled: enabled ?? this.enabled,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      customRules: customRules ?? this.customRules,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'blocked_categories': blockedCategories.map((c) => c.toString().split('.').last).toList(),
        'custom_rules': customRules,
      };

  factory ContentModerationConfig.fromJson(Map<String, dynamic> json) {
    return ContentModerationConfig(
      enabled: json['enabled'] as bool? ?? false,
      blockedCategories: (json['blocked_categories'] as List?)
              ?.map((c) => ModerationCategory.values.firstWhere(
                    (e) => e.toString().split('.').last == c,
                    orElse: () => ModerationCategory.hateSpeech,
                  ))
              .toList() ??
          [],
      customRules: json['custom_rules'] as String? ?? '',
    );
  }
}

/// App features configuration
class AppFeaturesConfig {
  final FileUploadConfig fileUpload;
  final ConversationOpenerConfig conversationOpener;
  final FollowUpSuggestionsConfig followUpSuggestions;
  final TextToSpeechConfig textToSpeech;
  final CitationConfig citation;
  final ContentModerationConfig contentModeration;

  const AppFeaturesConfig({
    this.fileUpload = const FileUploadConfig(),
    this.conversationOpener = const ConversationOpenerConfig(),
    this.followUpSuggestions = const FollowUpSuggestionsConfig(),
    this.textToSpeech = const TextToSpeechConfig(),
    this.citation = const CitationConfig(),
    this.contentModeration = const ContentModerationConfig(),
  });

  Map<String, dynamic> toJson() => {
        'file_upload': fileUpload.toJson(),
        'conversation_opener': conversationOpener.toJson(),
        'follow_up_suggestions': followUpSuggestions.toJson(),
        'text_to_speech': textToSpeech.toJson(),
        'citation': citation.toJson(),
        'content_moderation': contentModeration.toJson(),
      };

  factory AppFeaturesConfig.fromJson(Map<String, dynamic> json) {
    return AppFeaturesConfig(
      fileUpload: FileUploadConfig.fromJson(
          json['file_upload'] as Map<String, dynamic>? ?? {}),
      conversationOpener: ConversationOpenerConfig.fromJson(
          json['conversation_opener'] as Map<String, dynamic>? ?? {}),
      followUpSuggestions: FollowUpSuggestionsConfig.fromJson(
          json['follow_up_suggestions'] as Map<String, dynamic>? ?? {}),
      textToSpeech: TextToSpeechConfig.fromJson(
          json['text_to_speech'] as Map<String, dynamic>? ?? {}),
      citation: CitationConfig.fromJson(
          json['citation'] as Map<String, dynamic>? ?? {}),
      contentModeration: ContentModerationConfig.fromJson(
          json['content_moderation'] as Map<String, dynamic>? ?? {}),
    );
  }
}
