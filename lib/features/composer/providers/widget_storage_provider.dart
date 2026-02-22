import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/auth/auth_service.dart';
import '../models/a2ui_widget_model.dart';

final widgetStorageProvider = StateNotifierProvider<WidgetStorageNotifier, AsyncValue<List<A2uiWidgetModel>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  return WidgetStorageNotifier(user?.uid);
});

class WidgetStorageNotifier extends StateNotifier<AsyncValue<List<A2uiWidgetModel>>> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WidgetStorageNotifier(this._userId) : super(const AsyncLoading()) {
    if (_userId != null) {
      _loadWidgets();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void _loadWidgets() {
    _firestore
        .collection('a2ui_widgets')
        .where('ownerId', isEqualTo: _userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final widgets = snapshot.docs.map((doc) => A2uiWidgetModel.fromFirestore(doc)).toList();
      state = AsyncValue.data(widgets);
    }, onError: (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  Future<String> saveWidget(String name, String jsonSchema, {String? existingId}) async {
    if (_userId == null) throw Exception('User not authenticated');

    final collection = _firestore.collection('a2ui_widgets');
    final now = DateTime.now();

    if (existingId != null) {
      await collection.doc(existingId).update({
        'name': name,
        'jsonSchema': jsonSchema,
        'updatedAt': Timestamp.fromDate(now),
      });
      return existingId;
    } else {
      final docRef = await collection.add({
        'name': name,
        'jsonSchema': jsonSchema,
        'ownerId': _userId,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      return docRef.id;
    }
  }

  Future<void> deleteWidget(String id) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _firestore.collection('a2ui_widgets').doc(id).delete();
  }
}
