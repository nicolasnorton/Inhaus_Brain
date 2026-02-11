import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'audit_log_service.dart';

enum WebhookEvent {
  campaignCreated,
  campaignUpdated,
  taskCompleted,
  leadGenerated,
  userSignedUp,
}

class Webhook {
  final String id;
  final String url;
  final String secret; // For signing
  final List<WebhookEvent> events;
  final bool isActive;
  final DateTime createdAt;

  Webhook({
    required this.id,
    required this.url,
    required this.secret,
    required this.events,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'events': events.map((e) => e.name).toList(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Webhook.fromJson(Map<String, dynamic> json) => Webhook(
    id: json['id'],
    url: json['url'],
    secret: '********', // Redacted in UI
    events: (json['events'] as List).map((e) => WebhookEvent.values.byName(e)).toList(),
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// Webhook Service (Inhaus Brain v2.0)
/// 
/// Manages outbound webhooks for third-party integrations (Pabbly/Make/Zapier).
class WebhookService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  WebhookService(this._ref);

  Future<void> createWebhook({
    required String url,
    required List<WebhookEvent> events,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');

    final doc = _db.collection('webhooks').doc();
    final secret = 'ib_wh_' + DateTime.now().millisecondsSinceEpoch.toString();
    
    await doc.set({
      'id': doc.id,
      'creatorId': user.uid,
      'url': url,
      'secret': secret,
      'events': events.map((e) => e.name).toList(),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _ref.read(auditLogServiceProvider).log(
      action: 'integration/webhook_created',
      resourceType: 'webhook',
      resourceId: doc.id,
      metadata: {'url': url, 'events': events.map((e) => e.name).toList()},
    );
  }

  Stream<List<Webhook>> streamWebhooks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _db.collection('webhooks')
        .where('creatorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Webhook.fromJson(doc.data())).toList());
  }

  Future<void> deleteWebhook(String id) async {
    await _db.collection('webhooks').doc(id).delete();
    _ref.read(auditLogServiceProvider).log(
      action: 'integration/webhook_deleted',
      resourceType: 'webhook',
      resourceId: id,
    );
  }
}

final webhookServiceProvider = Provider<WebhookService>((ref) => WebhookService(ref));
