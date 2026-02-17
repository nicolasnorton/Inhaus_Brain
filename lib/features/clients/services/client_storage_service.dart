import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ClientStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  /// Uploads a client logo to Firebase Storage and returns the download URL.
  /// 
  /// [fileBytes] - The raw bytes of the image file.
  /// [fileName] - The original filename (for extension).
  static Future<String> uploadClientLogo({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final String fileExtension = fileName.split('.').last;
      final String uniqueId = _uuid.v4();
      final String storagePath = 'clients/logos/$uniqueId.$fileExtension';
      
      final Reference ref = _storage.ref().child(storagePath);
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/$fileExtension',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'client_logo',
        },
      );

      final UploadTask uploadTask = ref.putData(fileBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload client logo: $e');
    }
  }
}
