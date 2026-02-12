import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/features/clients/models/task_model.dart';
import 'package:inhaus_brain/features/clients/providers/task_provider.dart';
import 'package:inhaus_brain/core/auth/auth_service.dart';

class ClientTaskDetailPane extends ConsumerStatefulWidget {
  final ProjectTask task;
  final VoidCallback onClose;
  final Function(String) onTaskSelected; // To support subtask navigation

  const ClientTaskDetailPane({
    super.key,
    required this.task,
    required this.onClose,
    required this.onTaskSelected,
  });

  @override
  ConsumerState<ClientTaskDetailPane> createState() => _ClientTaskDetailPaneState();
}

class _ClientTaskDetailPaneState extends ConsumerState<ClientTaskDetailPane> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subtaskController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _subtaskController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant ClientTaskDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id) {
       _titleController.text = widget.task.title;
       _descController.text = widget.task.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _saveChanges() {
     if (_titleController.text != widget.task.title || _descController.text != widget.task.description) {
        ref.read(taskProvider.notifier).updateTask(
          widget.task.copyWith(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
          )
        );
     }
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);
    final subtasks = allTasks.where((t) => t.parentId == widget.task.id).toList();

    return Container(
      width: 600, // Fixed width for desktop pane
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        border: const Border(left: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (widget.task.parentId != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 12.0),
                     child: InkWell(
                       onTap: () => widget.onTaskSelected(widget.task.parentId!),
                       child: const Row(
                         children: [
                           Icon(Icons.arrow_upward, size: 14, color: Colors.blueAccent),
                           SizedBox(width: 4),
                           Text('Return to Parent Task', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                         ],
                       ),
                     ),
                   ),

                // Title
                 TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Task Title',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  onSubmitted: (_) => _saveChanges(),
                  onEditingComplete: _saveChanges, // Save on focus loss or enter
                ),
                const SizedBox(height: 16),
                
                // Metadata Row
                _buildMetadataRow(),
                const SizedBox(height: 24),

                // Description
                const Text('Description', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: null,
                    decoration: const InputDecoration.collapsed(hintText: 'Add a description...'),
                    onSubmitted: (_) => _saveChanges(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Subtasks
                const Text('Subtasks', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...subtasks.map((st) => _SubtaskItem(subtask: st, onTaskSelected: widget.onTaskSelected)).toList(),
                _buildAddSubtaskRow(),

                const SizedBox(height: 32),
                
                // Activity Stream (Placeholder)
                 const Text('Activity', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 Row(
                   children: [
                     const CircleAvatar(backgroundColor: Colors.purple, radius: 12, child: Text('N', style: TextStyle(fontSize: 10))),
                     const SizedBox(width: 8),
                     const Expanded(child: Text('Nicolas created this task.', style: TextStyle(color: Colors.white38, fontSize: 12))),
                     Text(DateFormat.jm().format(DateTime.now()), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                   ],
                 ),
              ],
            ),
          ),
          
          // Comment Bar
          _buildCommentBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userId = AuthService.currentUserId;
    final isLiked = widget.task.likedBy.contains(userId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               ElevatedButton.icon(
                onPressed: () {
                   ref.read(taskProvider.notifier).updateTask(widget.task.copyWith(status: widget.task.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done));
                },
                icon: Icon(Icons.check, size: 16, color: widget.task.status == TaskStatus.done ? Colors.white : Colors.green),
                label: Text(widget.task.status == TaskStatus.done ? 'Completed' : 'Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.task.status == TaskStatus.done ? Colors.green : Colors.transparent,
                  foregroundColor: widget.task.status == TaskStatus.done ? Colors.white : Colors.green,
                  side: const BorderSide(color: Colors.green),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: isLiked ? Colors.blueAccent : Colors.white54),
                tooltip: 'Like',
                onPressed: () {
                   List<String> newLikes = List.from(widget.task.likedBy);
                   if (isLiked) {
                     newLikes.remove(userId);
                   } else {
                     newLikes.add(userId);
                   }
                   ref.read(taskProvider.notifier).updateTask(widget.task.copyWith(likedBy: newLikes));
                },
              ),
              IconButton(
                icon: const Icon(Icons.attach_file, size: 20, color: Colors.white54),
                tooltip: 'Attach files',
                onPressed: () { 
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment functionality coming soon')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.link, size: 20, color: Colors.white54),
                tooltip: 'Copy link',
                onPressed: () { 
                   // Clipboard.setData(ClipboardData(text: 'https://inhausbrain.com/task/${widget.task.id}')); // Requires services
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_full, size: 20, color: Colors.white54),
                tooltip: 'Full screen',
                onPressed: () { 
                   Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => Scaffold(
                     appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.task.title)),
                     backgroundColor: Colors.black,
                     body: Center(child: ClientTaskDetailPane(task: widget.task, onClose: () => Navigator.pop(ctx), onTaskSelected: widget.onTaskSelected)),
                   )));
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 20, color: Colors.white54),
                onSelected: (val) {
                   if (val == 'delete') {
                      ref.read(taskProvider.notifier).deleteTask(widget.task.id);
                      widget.onClose();
                   }
                },
                itemBuilder: (context) => [
                   const PopupMenuItem(value: 'delete', child: Text('Delete Task', style: TextStyle(color: Colors.redAccent))),
                ]
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    // We are now building a vertical list of fields (Label | Value) similar to Asana
    return Column(
      children: [
        _buildFieldRow('Assignee', widget.task.assigneeId ?? 'No assignee', Icons.person_outline, onTap: () {}),
        _buildFieldRow('Due date', widget.task.dueDate != null ? DateFormat.yMMMd().format(widget.task.dueDate!) : 'No due date', Icons.calendar_today, onTap: () async {
             final picked = await showDatePicker(
                 context: context, 
                 initialDate: widget.task.dueDate ?? DateTime.now(), 
                 firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                 lastDate: DateTime.now().add(const Duration(days: 365))
             );
             if (picked != null) {
                ref.read(taskProvider.notifier).updateTask(widget.task.copyWith(dueDate: picked));
             }
        }),
        _buildFieldRow('Projects', _getProjectListText(), Icons.folder_outlined, onTap: _showProjectSelector),
        _buildFieldRow('Priority', widget.task.priority.name.toUpperCase(), Icons.flag_outlined, 
          valueColor: widget.task.priority == TaskPriority.urgent ? Colors.red : null,
          onTap: _showPrioritySelector
        ),
        _buildFieldRow('Dependencies', widget.task.dependencyIds.isEmpty ? 'Add dependencies' : '${widget.task.dependencyIds.length} dependencies', Icons.account_tree, onTap: () {}), // Using AccountTree as proxy for flowchart
        _buildFieldRow('Tags', widget.task.tags.isEmpty ? 'Add tags' : widget.task.tags.join(', '), Icons.label_outline, onTap: () {}),
      ],
    );
  }

  String _getProjectListText() {
     // TODO: Resolve project names from IDs. For now, just show main project ID
     return 'Main Project';
  }

  void _showProjectSelector() {
     // Placeholder for multi-home selector
  }

  void _showPrioritySelector() {
     // Placeholder for priority selector
  }

  Widget _buildFieldRow(String label, String value, IconData icon, {VoidCallback? onTap, Color? valueColor}) {
     return InkWell(
       onTap: onTap,
       child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 8.0),
         child: Row(
           children: [
             SizedBox(
               width: 120,
               child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
             ),
             Expanded(
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Row(
                      children: [
                         if (label == 'Assignee') ...[
                           const CircleAvatar(radius: 10, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 12, color: Colors.white)),
                           const SizedBox(width: 8),
                         ],
                         if (label == 'Due date') ...[
                           Icon(icon, size: 16, color: Colors.white38),
                           const SizedBox(width: 8),
                         ],
                         Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13)),
                      ],
                    ),
                    if (onTap != null)
                      const Icon(Icons.close, size: 14, color: Colors.transparent), // Hidden close button for hover effect later? Or just keep clean.
                 ],
               )
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildAddSubtaskRow() {
    return Row(
      children: [
        const Icon(Icons.add, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _subtaskController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Add subtask...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                 ref.read(taskProvider.notifier).addTask(
                   widget.task.projectId, 
                   val, 
                   '', 
                   parentId: widget.task.id, // Link as subtask
                 );
                 _subtaskController.clear();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBar() {
    return Column(
      children: [
        // Collaborators Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E2128),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              const Text('Collaborators', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 12),
              const CircleAvatar(radius: 12, backgroundColor: Colors.purple, child: Text('N', style: TextStyle(fontSize: 10, color: Colors.white))),
              const SizedBox(width: 4),
              const CircleAvatar(radius: 12, backgroundColor: Colors.amber, child: Text('TB', style: TextStyle(fontSize: 10, color: Colors.black))),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {},
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                  child: const Icon(Icons.add, size: 14, color: Colors.white54),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, size: 16, color: Colors.white54),
                label: const Text('Join task', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ),
        // Comment Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E2128),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
               const CircleAvatar(radius: 16, backgroundColor: Colors.purple, child: Text('N')),
               const SizedBox(width: 12),
               Expanded(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   height: 48,
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.05),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.white10),
                   ),
                   alignment: Alignment.centerLeft,
                   child: const TextField(
                     decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ask a question or post an update...',
                        hintStyle: TextStyle(color: Colors.white38),
                        suffixIcon: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                              Icon(Icons.alternate_email, color: Colors.white24, size: 18),
                              SizedBox(width: 8),
                              Icon(Icons.mood, color: Colors.white24, size: 18),
                              SizedBox(width: 8),
                              Icon(Icons.mic, color: Colors.white24, size: 18),
                              SizedBox(width: 8),
                           ],
                        ),
                     ),
                     style: TextStyle(color: Colors.white),
                   ),
                 ),
               ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _MetadataChip({required this.label, required this.value, required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
           const SizedBox(height: 4),
           Row(
             children: [
                Icon(icon, size: 14, color: color ?? Colors.white70),
                const SizedBox(width: 6),
                Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13)),
             ],
           ),
        ],
      ),
    );
  }
}

class _SubtaskItem extends ConsumerWidget {
  final ProjectTask subtask;
  final Function(String) onTaskSelected;

  const _SubtaskItem({required this.subtask, required this.onTaskSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
           InkWell(
             onTap: () {
                ref.read(taskProvider.notifier).updateTask(subtask.copyWith(status: subtask.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done));
             },
             child: Icon(
               subtask.status == TaskStatus.done ? Icons.check_circle : Icons.radio_button_unchecked, 
               size: 20, 
               color: subtask.status == TaskStatus.done ? Colors.green : Colors.white38
             ),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: InkWell(
               onTap: () => onTaskSelected(subtask.id),
               child: Text(
                 subtask.title, 
                 style: TextStyle(
                   color: Colors.white, 
                   decoration: subtask.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                   decorationColor: Colors.white38,
                 )
               ),
             ),
           ),
           // We could add a button to open the subtask in the main pane here for infinite nesting
           IconButton(
             icon: const Icon(Icons.chevron_right, size: 16, color: Colors.white38),
             onPressed: () => onTaskSelected(subtask.id),
           ),
        ],
      ),
    );
  }
}
