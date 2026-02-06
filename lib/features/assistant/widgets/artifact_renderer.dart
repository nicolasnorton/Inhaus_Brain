import 'package:flutter/material.dart';
import '../../chat/models/chat_models.dart';

class ArtifactRenderer extends StatelessWidget {
  final List<Artifact> artifacts;

  const ArtifactRenderer({
    Key? key,
    required this.artifacts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (artifacts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            'Created Artifacts (${artifacts.length})',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 140, 
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: artifacts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final artifact = artifacts[index];
              return _ArtifactCard(artifact: artifact);
            },
          ),
        ),
      ],
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  final Artifact artifact;

  const _ArtifactCard({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Open full artifact view
            showDialog(context: context, builder: (c) => _ArtifactDetailDialog(artifact: artifact));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const Spacer(),
                Text(
                  artifact.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artifact.type.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    switch (artifact.type) {
      case ArtifactType.markdown:
        icon = Icons.article_outlined;
        color = Colors.blueAccent;
        break;
      case ArtifactType.code:
        icon = Icons.code;
        color = Colors.greenAccent;
        break;
      case ArtifactType.plan:
        icon = Icons.assignment_outlined;
        color = Colors.orangeAccent;
        break;
      case ArtifactType.image:
        icon = Icons.image_outlined;
        color = Colors.purpleAccent;
        break;
      case ArtifactType.file:
      default:
        icon = Icons.insert_drive_file_outlined;
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ArtifactDetailDialog extends StatelessWidget {
  final Artifact artifact;
  const _ArtifactDetailDialog({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return Dialog(
       backgroundColor: const Color(0xFF1E1E1E),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Container(
         width: 600,
         height: 500,
         padding: const EdgeInsets.all(24),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Expanded(child: Text(artifact.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white))),
                 IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70))
               ],
             ),
             const Divider(color: Colors.white24, height: 32),
             Expanded(
               child: SingleChildScrollView(
                 child: Text(
                   artifact.content,
                   style: const TextStyle(color: Colors.white70, fontFamily: 'FiraCode', fontSize: 13),
                 ),
               ),
             ),
           ],
         ),
       ),
    );
  }
}
