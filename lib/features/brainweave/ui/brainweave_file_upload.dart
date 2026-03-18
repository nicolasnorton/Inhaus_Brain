/// BrainWeave File Upload Widget
/// ═══════════════════════════════════
/// Reusable upload component for PDF ingestion into the knowledge graph.
/// Only visible when brainweave_pdf_parser_evolution_enabled is true.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/feature_flags.dart';
import '../services/brainweave_mcp_client.dart';

/// Reusable file upload button for BrainWeave PDF ingestion.
/// Styled consistently with the BrainWeave gradient theme.
class BrainWeaveFileUploadButton extends StatefulWidget {
  final String? clientId;
  final String scope;
  final VoidCallback? onUploadComplete;

  const BrainWeaveFileUploadButton({
    super.key,
    this.clientId,
    this.scope = 'PRIVATE',
    this.onUploadComplete,
  });

  @override
  State<BrainWeaveFileUploadButton> createState() =>
      _BrainWeaveFileUploadButtonState();
}

class _BrainWeaveFileUploadButtonState
    extends State<BrainWeaveFileUploadButton>
    with SingleTickerProviderStateMixin {
  final _mcpClient = BrainWeaveMcpClient();
  bool _isUploading = false;
  double _progress = 0.0;
  String? _statusMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    if (_isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'csv', 'txt', 'md'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showStatus('Failed to read file data', isError: true);
        return;
      }

      // Size guard (50MB)
      if (file.bytes!.length > 50 * 1024 * 1024) {
        _showStatus('File too large (max 50MB)', isError: true);
        return;
      }

      setState(() {
        _isUploading = true;
        _progress = 0.1;
        _statusMessage = 'Preparing ${file.name}…';
      });
      _pulseController.repeat(reverse: true);

      final base64Content = base64Encode(file.bytes!);

      setState(() {
        _progress = 0.3;
        _statusMessage = 'Parsing PDF with hybrid engine…';
      });

      // Only PDF files use the hybrid parser endpoint
      final isPdf = file.extension?.toLowerCase() == 'pdf';

      if (isPdf) {
        final response = await _mcpClient.pdfIngest(
          base64Pdf: base64Content,
          filename: file.name,
          clientId: widget.clientId,
          scope: widget.scope,
        );

        setState(() {
          _progress = 1.0;
          _statusMessage =
              '✓ Created ${response['nodes_created'] ?? 0} nodes from ${file.name}';
        });
      } else {
        // Non-PDF files: decode as text and create a single node
        final textContent = utf8.decode(file.bytes!);
        await _mcpClient.create(
          title: file.name,
          content: textContent,
          nodeType: 'atomic',
          scope: widget.scope,
        );

        setState(() {
          _progress = 1.0;
          _statusMessage = '✓ Imported ${file.name} as knowledge node';
        });
      }

      _pulseController.stop();
      _pulseController.reset();

      widget.onUploadComplete?.call();

      // Reset after delay
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 0.0;
          _statusMessage = null;
        });
      }
    } catch (e) {
      _pulseController.stop();
      _pulseController.reset();
      _showStatus('Upload failed: $e', isError: true);
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 0.0;
          _statusMessage = null;
        });
      }
    }
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = isError ? '✗ $message' : message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.brainweavePdfParserEvolutionEnabled) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withOpacity(_isUploading ? _pulseAnimation.value : 1.0),
                const Color(0xFF16213E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isUploading
                  ? const Color(0xFF00D9FF).withOpacity(0.6)
                  : const Color(0xFF00D9FF).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              if (_isUploading)
                BoxShadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isUploading ? null : _pickAndUploadFile,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D9FF), Color(0xFF0099CC)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isUploading ? Icons.auto_awesome : Icons.upload_file_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PDF Parser Evolution',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isUploading
                                    ? 'Processing…'
                                    : 'Upload PDF • CSV • TXT • MD',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isUploading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9FF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00D9FF).withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Color(0xFF00D9FF), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Upload',
                                  style: TextStyle(
                                    color: Color(0xFF00D9FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Progress indicator
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D9FF),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],

                    // Status message
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.startsWith('✗')
                              ? const Color(0xFFFF6B6B)
                              : _statusMessage!.startsWith('✓')
                                  ? const Color(0xFF51CF66)
                                  : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
