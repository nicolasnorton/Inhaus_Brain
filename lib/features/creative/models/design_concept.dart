class Moodboard {
  final String id;
  final String title;
  final List<String> imageUrls;
  final String description;

  Moodboard({
    required this.id,
    required this.title,
    required this.imageUrls,
    required this.description,
  });
}

class DesignConcept {
  final String id;
  final String campaignId;
  final String title;
  final String copy;
  final String visualPrompt;
  final List<Moodboard> moodboards;
  final bool isApproved;
  final String? finalCopy;
  final String? finalImageURL;
  final bool isFinalReady;

  DesignConcept({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.copy,
    required this.visualPrompt,
    this.moodboards = const [],
    this.isApproved = false,
    this.finalCopy,
    this.finalImageURL,
    this.isFinalReady = false,
  });

  DesignConcept copyWith({
    String? id,
    String? campaignId,
    String? title,
    String? copy,
    String? visualPrompt,
    List<Moodboard>? moodboards,
    bool? isApproved,
    String? finalCopy,
    String? finalImageURL,
    bool? isFinalReady,
  }) {
    return DesignConcept(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      copy: copy ?? this.copy,
      visualPrompt: visualPrompt ?? this.visualPrompt,
      moodboards: moodboards ?? this.moodboards,
      isApproved: isApproved ?? this.isApproved,
      finalCopy: finalCopy ?? this.finalCopy,
      finalImageURL: finalImageURL ?? this.finalImageURL,
      isFinalReady: isFinalReady ?? this.isFinalReady,
    );
  }
}
