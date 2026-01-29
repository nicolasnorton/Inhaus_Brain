
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connected_account_model.dart';

class ConnectedAccountsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'connected_accounts';

  Stream<List<ConnectedAccount>> getAccounts(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConnectedAccount.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> saveAccount(ConnectedAccount account) async {
    await _firestore.collection(_collection).doc(account.id).set(account.toJson());
  }

  Future<void> deleteAccount(String accountId) async {
    await _firestore.collection(_collection).doc(accountId).delete();
  }
}
