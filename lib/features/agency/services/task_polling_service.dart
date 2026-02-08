import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the granular progress of a campaign generation.
class TaskProgress {
  final double researchProgress;
  final double strategyProgress;
  final double creativeProgress;
  final bool isCancelled;
  final String? error;

  const TaskProgress({
    this.researchProgress = 0.0,
    this.strategyProgress = 0.0,
    this.creativeProgress = 0.0,
    this.isCancelled = false,
    this.error,
  });

  factory TaskProgress.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const TaskProgress();
    final data = doc.data() as Map<String, dynamic>;

    final status = data['status'] as String? ?? 'pending';
    final research = data['researchStatus'] as String?;
    final strategy = data['strategyStatus'] as String?;
    
    // Determine progress based on status flags set by Cloud Tasks
    double r = 0.0;
    if (research == 'completed') r = 1.0;
    else if (status == 'research_queued') r = 0.2;
    else if (status == 'researching') r = 0.5;

    double s = 0.0;
    if (strategy == 'completed') s = 1.0;
    else if (r == 1.0 && (data['strategyStatus'] == 'queued' || status == 'strategizing')) s = 0.5;

    // Creative usually follows
    double c = 0.0;
    // ... logic for creative

    return TaskProgress(
      researchProgress: r,
      strategyProgress: s,
      creativeProgress: c,
      isCancelled: status == 'cancelled',
      error: data['error'],
    );
  }
  
  double get totalProgress => (researchProgress + strategyProgress + creativeProgress) / 3.0;
}

/// Provider that listens to a specific campaign's progress
final taskProgressProvider = StreamProvider.autoDispose.family<TaskProgress, String>((ref, campaignId) {
  return FirebaseFirestore.instance
      .collection('campaigns')
      .doc(campaignId)
      .snapshots()
      .map((doc) => TaskProgress.fromFirestore(doc));
});
