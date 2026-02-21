import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proposal_style.dart';

class ProposalStyleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _stylesCollection => _firestore.collection('agency_styles');

  Future<List<ProposalStyle>> getStyles() async {
    final snapshot = await _stylesCollection.get();
    
    final styles = snapshot.docs.map(
      (doc) => ProposalStyle.fromFirestore(doc)
    ).toList();

    // Always ensure the default INHAUS style is present at the top
    if (!styles.any((s) => s.id == ProposalStyle.inhausClasico.id)) {
      styles.insert(0, ProposalStyle.inhausClasico);
    }

    return styles;
  }

  Future<ProposalStyle> getStyleById(String id) async {
    if (id == ProposalStyle.inhausClasico.id) {
      return ProposalStyle.inhausClasico;
    }
    
    final doc = await _stylesCollection.doc(id).get();
    if (!doc.exists) return ProposalStyle.inhausClasico;
    
    return ProposalStyle.fromFirestore(doc);
  }

  Future<ProposalStyle> createStyle(ProposalStyle style) async {
    final docRef = _stylesCollection.doc();
    final newStyle = style.copyWith(id: docRef.id);
    await docRef.set(newStyle.toJson());
    return newStyle;
  }

  Future<void> updateStyle(ProposalStyle style) async {
    if (style.id == ProposalStyle.inhausClasico.id) return; // Cannot edit default
    await _stylesCollection.doc(style.id).update(style.toJson());
  }

  Future<void> deleteStyle(String id) async {
    if (id == ProposalStyle.inhausClasico.id) return; // Cannot delete default
    await _stylesCollection.doc(id).delete();
  }
}
