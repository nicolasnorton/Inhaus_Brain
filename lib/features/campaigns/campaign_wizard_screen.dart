import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/campaigns/models/campaign.dart';
import 'package:inhaus_brain/features/campaigns/providers/campaign_provider.dart';
import 'package:inhaus_brain/core/widgets/ai_status_badge.dart';
import 'package:inhaus_brain/features/campaigns/widgets/multi_modal_input_section.dart';
import 'package:inhaus_brain/core/widgets/research_workbench.dart';
import '../chat/providers/chat_provider.dart';
import '../chat/agentic_chat_view.dart';
import '../../core/auth/auth_service.dart';

class CampaignWizardScreen extends ConsumerStatefulWidget {
  const CampaignWizardScreen({super.key});

  @override
  ConsumerState<CampaignWizardScreen> createState() => _CampaignWizardScreenState();
}

class _CampaignWizardScreenState extends ConsumerState<CampaignWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  bool _isChatMode = false;
  bool _isSubmitting = false;
  String? _currentCampaignId;
  List<Attachment> _attachments = [];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _currentCampaignId = const Uuid().v4();
      });
      
      try {
        // Initialize Chat Session
        ref.read(chatProvider.notifier).startSession(_currentCampaignId!);
        
        // Initial Message from User
        await ref.read(chatProvider.notifier).sendMessage(
          AppLocalizations.of(context)!.startNewCampaignMsg(_titleController.text, _descriptionController.text),
          attachments: _attachments,
        );

        setState(() {
          _isChatMode = true;
          _isSubmitting = false;
        });

      } catch (e, stack) {
        debugPrint('CRITICAL: Campaign Initiation Error: $e');
        debugPrint('Stack Trace: $stack');
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isChatMode ? AppLocalizations.of(context)!.researchWorkshop : AppLocalizations.of(context)!.createNewCampaign),
        backgroundColor: Colors.transparent,
        leading: _isChatMode ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isChatMode = false),
        ) : null,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: AIStatusBadge(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _isChatMode ? 1000 : 600),
          padding: _isChatMode ? EdgeInsets.zero : const EdgeInsets.all(24.0),
          decoration: _isChatMode ? null : BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: _isChatMode 
            ? _buildChatMode()
            : _buildFormMode(),
        ),
      ),
    );
  }

  Widget _buildFormMode() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.campaignBrief,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const ResearchWorkbench(),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.tellAgentGoals,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.campaignTitle,
                hintText: AppLocalizations.of(context)!.campaignTitleHint,
              ),
              validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clientController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.clientNameLabel,
                hintText: AppLocalizations.of(context)!.clientNameHint,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.detailedBrief,
                hintText: AppLocalizations.of(context)!.detailedBriefHint,
              ),
              validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
            ),
            const SizedBox(height: 16),
            MultiModalInputSection(
              onAttachmentsChanged: (attachments) {
                _attachments = attachments;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : Text(AppLocalizations.of(context)!.startResearchChat),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMode() {
    return Column(
      children: [
        const Expanded(child: AgenticChatView()),
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                // Save campaign and exit
                final newCampaign = Campaign(
                  id: _currentCampaignId!,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  clientName: _clientController.text,
                  clientId: ref.read(appUserProvider).value?.assignedClientIds.firstOrNull,
                  createdAt: DateTime.now(),
                  status: CampaignStatus.researching,
                  attachments: _attachments,
                );
                await ref.read(campaignListProvider.notifier).addCampaign(newCampaign);
                if (mounted) context.pop();
              },
              child: Text(AppLocalizations.of(context)!.confirmStrategyCreate),
            ),
          ),
        ),
      ],
    );
  }
}
