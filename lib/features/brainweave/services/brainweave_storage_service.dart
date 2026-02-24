import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/brainweave_node.dart';

/// Handles exporting the Weave Space into versioned Markdown, ZIP, and PDF formats.
class BrainWeaveStorageService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  BrainWeaveStorageService(this._firestore, this._storage, this._auth);

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _nodes => _firestore.collection('brainweave_nodes');

  /// Exports a single node as a versioned Markdown file to Firebase Storage.
  Future<String> exportNodeToMarkdown(BrainWeaveNode node) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'brainweave/$_userId/weave/${node.title.replaceAll(' ', '_')}_$timestamp.md';

    final markdownContent = '''
# ${node.title}

**Type:** ${node.type.name}
**Topics:** ${node.topics.join(', ')}

> ${node.description}

---

${node.content}

''';

    final ref = _storage.ref().child(path);
    final data = utf8.encode(markdownContent);
    await ref.putData(Uint8List.fromList(data), SettableMetadata(contentType: 'text/markdown'));
    return await ref.getDownloadURL();
  }

  /// Exports the entire Weave Space as a ZIP file containing Markdown notes.
  Future<String> exportVaultAsZip() async {
    final querySnapshot = await _nodes.where('clientId', isEqualTo: _userId).get();
    final nodes = querySnapshot.docs.map((doc) => BrainWeaveNode.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();

    final archive = Archive();

    for (var node in nodes) {
      final markdownContent = '''
# ${node.title}

**Type:** ${node.type.name}
**Topics:** ${node.topics.join(', ')}

> ${node.description}

---

${node.content}
''';
      final fileData = utf8.encode(markdownContent);
      final filename = '${node.title.replaceAll(' ', '_')}.md';
      archive.addFile(ArchiveFile(filename, fileData.length, fileData));
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to encode ZIP array.');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'brainweave/$_userId/exports/vault_export_$timestamp.zip';

    final ref = _storage.ref().child(path);
    await ref.putData(Uint8List.fromList(zipData), SettableMetadata(contentType: 'application/zip'));
    return await ref.getDownloadURL();
  }

  /// Exports a PDF summary of all MOCs and Topics.
  Future<String> exportVaultSummaryPdf() async {
    final querySnapshot = await _nodes.where('clientId', isEqualTo: _userId).get();
    final nodes = querySnapshot.docs.map((doc) => BrainWeaveNode.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [
            pw.Header(level: 0, child: pw.Text('BrainWeave Vault Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
          ];

          for (var node in nodes) {
            widgets.add(pw.Header(level: 1, child: pw.Text(node.title)));
            widgets.add(pw.Paragraph(text: node.description));
            widgets.add(pw.Text('Topics: ${node.topics.join(', ')}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)));
            widgets.add(pw.SizedBox(height: 10));
          }

          return widgets;
        },
      ),
    );

    final pdfData = await pdf.save();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'brainweave/$_userId/exports/vault_summary_$timestamp.pdf';

    final ref = _storage.ref().child(path);
    await ref.putData(pdfData, SettableMetadata(contentType: 'application/pdf'));
    return await ref.getDownloadURL();
  }
}


final brainWeaveStorageServiceProvider = Provider<BrainWeaveStorageService>((ref) {
  return BrainWeaveStorageService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    FirebaseAuth.instance,
  );
});
