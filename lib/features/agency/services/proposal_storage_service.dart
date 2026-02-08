import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for uploading and managing proposal output files in Firebase Storage
class ProposalStorageService {
  static final _storage = FirebaseStorage.instance;

  /// Upload a proposal output file (PDF or Slides) to Firebase Storage
  /// Returns the download URL
  static Future<String> uploadProposalOutput({
    required String proposalId,
    required String outputId,
    required Uint8List fileBytes,
    required String fileExtension, // 'pdf' or 'pptx'
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Path: proposals/{userId}/{proposalId}/{outputId}.{ext}
      final path = 'proposals/${user.uid}/$proposalId/$outputId.$fileExtension';
      final ref = _storage.ref().child(path);

      debugPrint('ProposalStorageService: Uploading to $path...');

      // Set metadata
      final metadata = SettableMetadata(
        contentType: fileExtension == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        customMetadata: {
          'proposalId': proposalId,
          'outputId': outputId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload
      final uploadTask = ref.putData(fileBytes, metadata);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('ProposalStorageService: Upload complete. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('ProposalStorageService: Upload failed: $e');
      rethrow;
    }
  }

  /// Download a proposal output file from Firebase Storage
  static Future<Uint8List> downloadProposalOutput(String downloadUrl) async {
    try {
      debugPrint('ProposalStorageService: Downloading from $downloadUrl...');
      final ref = _storage.refFromURL(downloadUrl);
      final bytes = await ref.getData();
      if (bytes == null) throw Exception('Failed to download file');
      debugPrint('ProposalStorageService: Download complete. Size: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      debugPrint('ProposalStorageService: Download failed: $e');
      rethrow;
    }
  }

  /// Delete a proposal output file from Firebase Storage
  static Future<void> deleteProposalOutput(String downloadUrl) async {
    try {
      debugPrint('ProposalStorageService: Deleting $downloadUrl...');
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('ProposalStorageService: Deletion complete');
    } catch (e) {
      debugPrint('ProposalStorageService: Deletion failed: $e');
      rethrow;
    }
  }

  /// Delete all outputs for a specific proposal
  static Future<void> deleteAllProposalOutputs({
    required String proposalId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final path = 'proposals/${user.uid}/$proposalId';
      final ref = _storage.ref().child(path);

      debugPrint('ProposalStorageService: Deleting all files in $path...');
      
      // List all files in the directory
      final listResult = await ref.listAll();
      
      // Delete each file
      for (final item in listResult.items) {
        await item.delete();
      }

      debugPrint('ProposalStorageService: Deleted ${listResult.items.length} files');  
    } catch (e) {
      debugPrint('ProposalStorageService: Deletion failed: $e');
      rethrow;
    }
  }
}
