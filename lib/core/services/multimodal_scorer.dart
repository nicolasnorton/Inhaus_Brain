
import 'package:flutter/foundation.dart';

class MultimodalScorer {
  /// Strict quality thresholds for production readiness
  static const double textThreshold = 0.88;
  static const double imageThreshold = 0.90;
  static const double videoThreshold = 0.85;
  static const double uiThreshold = 0.92;

  /// Scores an image based on metadata and simple heuristics.
  /// In a real system, this might call a VQA model.
  static double scoreImage(Map<String, dynamic> metadata) {
    double score = 1.0;
    
    // Heuristic 1: Resolution check (if available)
    if (metadata.containsKey('width') && metadata['width'] < 1024) score -= 0.1;

    // Heuristic 2: Source reliability
    if (metadata['source'] == 'mock') score -= 0.3;

    // Heuristic 3: Prompt alignment (Simplified)
    if (metadata['prompt_alignment'] == 'low') score -= 0.4;

    return score.clamp(0.0, 1.0);
  }

  /// Scores a video generation result
  static double scoreVideo(Map<String, dynamic> metadata) {
    double score = 1.0;
    if (metadata['duration_seconds'] != null && metadata['duration_seconds'] < 2) score -= 0.2;
    if (metadata['fps'] != null && metadata['fps'] < 24) score -= 0.1;
    return score.clamp(0.0, 1.0);
  }

  /// Validates GenUI code (Simplified syntax check)
  static double scoreGenUI(String code) {
    double score = 1.0;
    if (!code.contains('class') || !code.contains('extends StatelessWidget')) score -= 0.2;
    if (code.contains('TODO:')) score -= 0.1; 
    if (code.length < 100) score -= 0.5; // Too short to be valid UI
    return score.clamp(0.0, 1.0);
  }

  /// Generates a polite rejection message if score is too low
  static String? getRejectionMessage(double score, String modality) {
    double threshold = 0.8;
    switch (modality) {
      case 'image': threshold = imageThreshold; break;
      case 'video': threshold = videoThreshold; break;
      case 'ui': threshold = uiThreshold; break;
      default: threshold = textThreshold;
    }

    if (score < threshold) {
      return "I'm not confident this $modality meets our quality bar yet (Score: ${score.toStringAsFixed(2)} / Required: $threshold) — would you like me to refine it?";
    }
    return null;
  }
}
