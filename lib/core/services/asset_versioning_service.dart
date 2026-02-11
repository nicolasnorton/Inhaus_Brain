import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Asset Version Model
class AssetVersion {
  final String id;
  final String assetId;
  final String assetType; // 'proposal', 'image', 'video', etc.
  final int versionNumber;
  final String createdBy;
  final DateTime createdAt;
  final String? downloadUrl;
  final Map<String, dynamic> metadata;
  final String? changeDescription;

  AssetVersion({
    required this.id,
    required this.assetId,
    required this.assetType,
    required this.versionNumber,
    required this.createdBy,
    required this.createdAt,
    this.downloadUrl,
    required this.metadata,
    this.changeDescription,
  });

  factory AssetVersion.fromJson(Map<String, dynamic> json) => AssetVersion(
    id: json['id'],
    assetId: json['assetId'],
    assetType: json['assetType'],
    versionNumber: json['versionNumber'],
    createdBy: json['createdBy'],
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    downloadUrl: json['downloadUrl'],
    metadata: json['metadata'] ?? {},
    changeDescription: json['changeDescription'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'assetType': assetType,
    'versionNumber': versionNumber,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'downloadUrl': downloadUrl,
    'metadata': metadata,
    'changeDescription': changeDescription,
  };
}

/// Asset Versioning Service
/// 
/// Tracks all versions of generated assets for audit and rollback.
class AssetVersioningService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createVersion({
    required String assetId,
    required String assetType,
    String? downloadUrl,
    Map<String, dynamic>? metadata,
    String? changeDescription,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');

    // Get current version count
    final existingVersions = await _db
        .collection('asset_versions')
        .where('assetId', isEqualTo: assetId)
        .orderBy('versionNumber', descending: true)
        .limit(1)
        .get();

    final nextVersion = existingVersions.docs.isEmpty 
        ? 1 
        : (existingVersions.docs.first.data()['versionNumber'] as int) + 1;

    final doc = _db.collection('asset_versions').doc();
    await doc.set({
      'id': doc.id,
      'assetId': assetId,
      'assetType': assetType,
      'versionNumber': nextVersion,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'downloadUrl': downloadUrl,
      'metadata': metadata ?? {},
      'changeDescription': changeDescription,
    });
  }

  Stream<List<AssetVersion>> streamVersions(String assetId) {
    return _db
        .collection('asset_versions')
        .where('assetId', isEqualTo: assetId)
        .orderBy('versionNumber', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssetVersion.fromJson(doc.data()))
            .toList());
  }
}

final assetVersioningServiceProvider = Provider<AssetVersioningService>(
  (ref) => AssetVersioningService(),
);

/// Asset Version History Widget
class AssetVersionHistory extends ConsumerWidget {
  final String assetId;

  const AssetVersionHistory({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(assetVersionsStreamProvider(assetId));

    return versions.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Text('No version history', style: TextStyle(color: Colors.white38)),
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final v = list[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Text('v${v.versionNumber}', style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
              ),
              title: Text(
                v.changeDescription ?? 'Version ${v.versionNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                '${_formatDate(v.createdAt)} • ${v.createdBy}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              trailing: v.downloadUrl != null
                  ? IconButton(
                      icon: const Icon(Icons.download, color: Colors.white54, size: 18),
                      onPressed: () {
                        // TODO: Download version
                      },
                    )
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

final assetVersionsStreamProvider = StreamProvider.family<List<AssetVersion>, String>((ref, assetId) {
  return ref.watch(assetVersioningServiceProvider).streamVersions(assetId);
});
