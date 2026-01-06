import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/campaign.dart';

class MultiModalInputSection extends StatefulWidget {
  final Function(List<Attachment>) onAttachmentsChanged;

  const MultiModalInputSection({super.key, required this.onAttachmentsChanged});

  @override
  State<MultiModalInputSection> createState() => _MultiModalInputSectionState();
}

class _MultiModalInputSectionState extends State<MultiModalInputSection> {
  final List<Attachment> _attachments = [];
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: kIsWeb, // Important for web if we want bytes
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          final type = _getAttachmentType(file.extension);
          // On web, path is null. We use name for now as a placeholder.
          final safePath = kIsWeb ? 'web_upload://${file.name}' : (file.path ?? '');
          
          _attachments.add(Attachment(
            id: const Uuid().v4(),
            url: safePath,
            name: file.name,
            type: type,
            createdAt: DateTime.now(),
          ));
        }
      });
      widget.onAttachmentsChanged(_attachments);
    }
  }

  AttachmentType _getAttachmentType(String? extension) {
    if (extension == null) return AttachmentType.file;
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return AttachmentType.image;
    if (['mp4', 'mov', 'avi'].contains(ext)) return AttachmentType.video;
    if (['mp3', 'wav', 'm4a'].contains(ext)) return AttachmentType.voice;
    return AttachmentType.file;
  }

  Future<void> _pickFromDrive() async {
    // Phase 21: Mock Drive Integration
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _attachments.add(Attachment(
        id: const Uuid().v4(),
        url: 'https://docs.google.com/document/d/mock_doc_id',
        name: 'Market_Analysis_2026.gdoc',
        type: AttachmentType.file,
        createdAt: DateTime.now(),
      ));
    });
    widget.onAttachmentsChanged(_attachments);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Linked file from Google Drive')),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        setState(() {
          _attachments.add(Attachment(
            id: const Uuid().v4(),
            url: path,
            name: 'Voice Brief ${DateTime.now().toIso8601String()}',
            type: AttachmentType.voice,
            createdAt: DateTime.now(),
          ));
        });
        widget.onAttachmentsChanged(_attachments);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig();
        // For web, path is not used, it returns a blob URL
        await _audioRecorder.start(config, path: ''); 
        setState(() => _isRecording = true);
      }
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Multi-Modal Context',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_link, color: Colors.blueAccent),
              onPressed: _pickFiles,
              tooltip: 'Attach Files',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              icon: FontAwesomeIcons.microphone,
              label: _isRecording ? 'Stop' : 'Voice',
              color: _isRecording ? Colors.redAccent : Colors.white10,
              onTap: _toggleRecording,
            ),
            _buildActionButton(
              icon: FontAwesomeIcons.camera,
              label: 'Camera',
              color: Colors.white10,
              onTap: () {
                // TODO: Implement Camera Screen
              },
            ),
            _buildActionButton(
              icon: FontAwesomeIcons.fileArrowUp,
              label: 'Upload',
              color: Colors.white10,
              onTap: _pickFiles,
            ),
            _buildActionButton(
              icon: FontAwesomeIcons.googleDrive,
              label: 'Drive',
              color: Colors.white10,
              onTap: _pickFromDrive,
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              final attachment = _attachments[index];
              return ListTile(
                leading: _buildAttachmentIcon(attachment.type),
                title: Text(attachment.name, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white30),
                  onPressed: () {
                    setState(() => _attachments.removeAt(index));
                    widget.onAttachmentsChanged(_attachments);
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 20, color: label == 'Stop' ? Colors.white : Colors.white70),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon(AttachmentType type) {
    IconData icon;
    Color color;
    switch (type) {
      case AttachmentType.image:
        icon = FontAwesomeIcons.image;
        color = Colors.purpleAccent;
        break;
      case AttachmentType.video:
        icon = FontAwesomeIcons.video;
        color = Colors.blueAccent;
        break;
      case AttachmentType.voice:
        icon = FontAwesomeIcons.microphoneLines;
        color = Colors.orangeAccent;
        break;
      case AttachmentType.file:
        icon = FontAwesomeIcons.fileLines;
        color = Colors.greenAccent;
        break;
    }
    return FaIcon(icon, size: 16, color: color.withOpacity(0.7));
  }
}
