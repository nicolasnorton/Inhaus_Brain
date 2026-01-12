import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_api_models.dart';
import '../providers/knowledge_provider.dart';
import '../widgets/chunk_editor_dialog.dart';

class DocumentDetailScreen extends ConsumerWidget {
  final String datasetId;
  final KnowledgeDocument document;

  const DocumentDetailScreen({
    super.key,
    required this.datasetId,
    required this.document,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chunksAsync = ref.watch(documentChunksProvider((datasetId: datasetId, documentId: document.id)));

    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(document.indexingStatus.toUpperCase(), _getStatusColor(document.indexingStatus)),
                      const SizedBox(width: 12),
                      Text(
                        'Tokens: ${document.tokens} • Words: ${document.wordCount} • Hits: ${document.hitCount}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showMetadataPanel(context, ref),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Metadata'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Re-index'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _deleteDocument(context, ref),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: 'Delete Document',
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'Segments',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chunksAsync.when(
              data: (chunks) => ListView.separated(
                itemCount: chunks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildChunkItem(context, ref, chunks[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  void _showMetadataPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Document Metadata', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 24),
            _buildMetadataItem('Document ID', document.id),
            _buildMetadataItem('Data Source', document.dataSourceType),
            _buildMetadataItem('Word Count', document.wordCount.toString()),
            _buildMetadataItem('Token Count', document.tokens.toString()),
            _buildMetadataItem('Created At', DateTime.fromMillisecondsSinceEpoch(document.createdAt * 1000).toString()),
            _buildMetadataItem('Indexing Status', document.indexingStatus),
            const SizedBox(height: 32),
            const Text('Processing Info', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (document.dataSourceInfo != null)
              ...document.dataSourceInfo!.entries.map((e) => _buildMetadataItem(e.key, e.value.toString())),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildChunkItem(BuildContext context, WidgetRef ref, DocumentChunk chunk) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${chunk.position}',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${chunk.tokens} tokens • ${chunk.wordCount} words',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Hits: ${chunk.hitCount}',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showEditChunk(context, ref, chunk),
                icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white38),
                tooltip: 'Edit Segment',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            chunk.content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (chunk.keywords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chunk.keywords.map((k) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(k, style: const TextStyle(color: Colors.white24, fontSize: 10)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.greenAccent;
      case 'indexing':
        return Colors.blueAccent;
      case 'error':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  void _showEditChunk(BuildContext context, WidgetRef ref, DocumentChunk chunk) {
    showDialog(
      context: context,
      builder: (context) => ChunkEditorDialog(
        datasetId: datasetId,
        documentId: document.id,
        chunk: chunk,
      ),
    );
  }

  Future<void> _deleteDocument(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Delete Document', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this document and all its segments?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(knowledgeApiServiceProvider);
        await service.deleteDocument(datasetId: datasetId, documentId: document.id);
        ref.invalidate(documentsProvider(datasetId));
        ref.read(selectedDatasetIdProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document: $e')),
        );
      }
    }
  }
}
