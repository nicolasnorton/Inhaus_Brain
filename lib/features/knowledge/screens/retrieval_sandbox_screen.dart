import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RetrievalSandboxScreen extends ConsumerStatefulWidget {
  const RetrievalSandboxScreen({super.key});

  @override
  ConsumerState<RetrievalSandboxScreen> createState() => _RetrievalSandboxScreenState();
}

class _RetrievalSandboxScreenState extends ConsumerState<RetrievalSandboxScreen> {
  final _queryController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  void _runSearch() {
    if (_queryController.text.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    // Simulate API delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _results = [
          {
            'score': 0.942,
            'content': 'Introducing Hybrid Search and Rerank to Improve the Retrieval Accuracy of the RAG System. Hybrid search combines full-text search and vector search to leverage the strengths of both keyword matching and semantic understanding.',
            'source': 'Internal Documentation.pdf',
            'metadata': {'page': 12, 'type': 'PDF'}
          },
          {
            'score': 0.815,
            'content': 'The basic idea of hybrid search is to leverage the strengths of both keyword matching and semantic understanding. While vector search is great for catching similar meaning, full-text search is better for exact terms.',
            'source': 'Wiki: Hybrid Search',
            'metadata': {'url': 'https://kb.inhaus.ai/hybrid', 'type': 'URL'}
          },
          {
            'score': 0.720,
            'content': 'Wait for the data processing to complete. Once finished, your knowledge base will be ready for integration into your AI applications. You can then select this knowledge base in the Knowledge Retrieval node.',
            'source': 'User Guide v2',
            'metadata': {'section': 'Workflow Setup'}
          }
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retrieval Test',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search the knowledge base to see how well it retrieves the information you need.',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          _buildSearchBox(),
          
          const SizedBox(height: 32),
          
          if (_results.isNotEmpty || _isSearching)
            Expanded(
              child: _buildResultsList(),
            )
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _queryController,
              onSubmitted: (_) => _runSearch(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Enter a query to test retrieval...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_queryController.text.isNotEmpty)
            IconButton(
              onPressed: () => setState(() {
                _queryController.clear();
                _results = [];
              }),
              icon: const Icon(Icons.close, color: Colors.white24, size: 18),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _runSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('Searching Knowledge Base...', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TOP ${_results.length} RESULTS', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const Text('Retrieval Mode: Hybrid', style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) => _buildResultItem(_results[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Score: ${result['score']}',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result['source'],
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white10, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result['content'],
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: (result['metadata'] as Map<String, dynamic>).entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(4)),
                child: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.plumbing_outlined, size: 64, color: Colors.white.withValues(alpha: 0.03)),
            const SizedBox(height: 16),
            const Text(
              'No Search Activity',
              style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Perform a test query to validate your retrieval settings.',
              style: TextStyle(color: Colors.white12, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
