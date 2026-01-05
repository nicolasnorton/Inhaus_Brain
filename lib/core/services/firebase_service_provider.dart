import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  // Toggle this to switch between Mock and Prod
  const useProd = false;
  return useProd ? ProdFirebaseService() : MockFirebaseService();
});
