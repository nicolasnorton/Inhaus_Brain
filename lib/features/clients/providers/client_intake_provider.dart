import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../chat/models/chat_models.dart';
import '../models/client_model.dart';
import '../models/intake_field_model.dart';
import '../providers/client_provider.dart';

final _log = Logger();

/// State for the conversational intake flow.
class IntakeConversationState {
  final List<ChatMessage> messages;
  final Map<String, String> collectedData;
  final int currentFieldIndex;
  final ClientType? clientType;
  final bool isComplete;
  final bool isSaving;
  final bool isResearching;
  final Map<String, String>? researchResults;
  final bool researchConfirmed;
  final String? error;

  const IntakeConversationState({
    this.messages = const [],
    this.collectedData = const {},
    this.currentFieldIndex = -1,
    this.clientType,
    this.isComplete = false,
    this.isSaving = false,
    this.isResearching = false,
    this.researchResults,
    this.researchConfirmed = false,
    this.error,
  });

  List<IntakeFormField> get fields => clientType == ClientType.independent
      ? IntakeFormField.independentFields
      : IntakeFormField.corporateFields;

  IntakeFormField? get currentField {
    if (currentFieldIndex < 0 || currentFieldIndex >= fields.length) return null;
    return fields[currentFieldIndex];
  }

  double get progress {
    if (fields.isEmpty) return 0;
    return (currentFieldIndex + 1).clamp(0, fields.length) / fields.length;
  }

  IntakeConversationState copyWith({
    List<ChatMessage>? messages,
    Map<String, String>? collectedData,
    int? currentFieldIndex,
    ClientType? clientType,
    bool? isComplete,
    bool? isSaving,
    bool? isResearching,
    Map<String, String>? researchResults,
    bool? researchConfirmed,
    String? error,
  }) {
    return IntakeConversationState(
      messages: messages ?? this.messages,
      collectedData: collectedData ?? this.collectedData,
      currentFieldIndex: currentFieldIndex ?? this.currentFieldIndex,
      clientType: clientType ?? this.clientType,
      isComplete: isComplete ?? this.isComplete,
      isSaving: isSaving ?? this.isSaving,
      isResearching: isResearching ?? this.isResearching,
      researchResults: researchResults ?? this.researchResults,
      researchConfirmed: researchConfirmed ?? this.researchConfirmed,
      error: error,
    );
  }
}

class IntakeConversationNotifier extends StateNotifier<IntakeConversationState> {
  final Ref _ref;

  IntakeConversationNotifier(this._ref) : super(const IntakeConversationState()) {
    _startConversation();
  }

  // ── Helpers ───────────────────────────────────────────────────
  ChatMessage _agentMsg(String content) => ChatMessage(
        id: const Uuid().v4(),
        content: content,
        sender: MessageSender.clientOnboardingAgent,
        createdAt: DateTime.now(),
      );

  ChatMessage _userMsg(String content) => ChatMessage(
        id: const Uuid().v4(),
        content: content,
        sender: MessageSender.user,
        createdAt: DateTime.now(),
      );

  void _addAgentMessage(String content) {
    state = state.copyWith(
      messages: [...state.messages, _agentMsg(content)],
    );
  }

  // ── Conversation Flow ─────────────────────────────────────────

  void _startConversation() {
    _addAgentMessage(
      "👋 Hey! I'm your onboarding assistant. Let's set up a new client.\n\nFirst — are we onboarding a **Corporate** client or an **Independent** professional?",
    );
  }

  void reset() {
    state = const IntakeConversationState();
    _startConversation();
  }

  void handleUserResponse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && state.currentField?.isRequired == true) return;

    state = state.copyWith(messages: [...state.messages, _userMsg(trimmed)]);

    // Phase 0: Client type selection
    if (state.clientType == null) {
      _handleTypeSelection(trimmed);
      return;
    }

    // Phase 1+: Field collection
    _handleFieldInput(trimmed);
  }

  void _handleTypeSelection(String input) {
    final lower = input.toLowerCase();
    ClientType? type;
    if (lower.contains('corporate') || lower.contains('company') || lower.contains('org')) {
      type = ClientType.corporate;
    } else if (lower.contains('independent') || lower.contains('freelan') || lower.contains('solo') || lower.contains('professional')) {
      type = ClientType.independent;
    }

    if (type == null) {
      _addAgentMessage(
        "I didn't catch that. Please choose **Corporate** or **Independent**.",
      );
      return;
    }

    final typeLabel = type == ClientType.corporate ? 'Corporate' : 'Independent';
    state = state.copyWith(clientType: type, currentFieldIndex: 0);
    _addAgentMessage(
      "✅ **$typeLabel** it is! Let's collect the details.\n\n${state.fields[0].question}",
    );
  }

  void _handleFieldInput(String input) {
    final field = state.currentField;
    if (field == null) return;

    final isSkip = input.isEmpty || input.toLowerCase() == 'skip' || input.contains('Skip →');

    if (isSkip && field.isRequired) {
      _addAgentMessage(
        "This one is **required** — I need a ${field.label.toLowerCase()} to continue.",
      );
      return;
    }

    // Validate
    final validationError = _validateField(field, input);
    if (validationError != null && !isSkip) {
      _addAgentMessage(validationError);
      return;
    }

    // Store
    if (!isSkip) {
      final updated = Map<String, String>.from(state.collectedData);
      updated[field.key] = input;
      state = state.copyWith(collectedData: updated);
    }

    // If we just got the name → research the client
    if (field.key == 'name' && !isSkip) {
      _researchClient(input);
      return;
    }

    _advanceToNextField(isSkip);
  }

  void _advanceToNextField(bool wasSkip, [bool showAck = true]) {
    final nextIndex = state.currentFieldIndex + 1;

    // Skip fields already filled by research
    int effectiveNext = nextIndex;
    while (effectiveNext < state.fields.length &&
        state.collectedData.containsKey(state.fields[effectiveNext].key)) {
      effectiveNext++;
    }

    if (effectiveNext >= state.fields.length) {
      final ack = wasSkip ? 'Skipped.' : '✅ Noted!';
      state = state.copyWith(currentFieldIndex: effectiveNext, isComplete: true);
      
      final msg = showAck 
          ? "$ack\n\n🎉 **All done!** Here's a summary of what I've collected. Please review and confirm."
          : "🎉 **All done!** Here's a summary of what I've collected. Please review and confirm.";
          
      _addAgentMessage(msg);
    } else {
      final ack = wasSkip 
          ? 'Skipped! No worries.' 
          : _acknowledgement(state.currentField?.key ?? '', state.collectedData[state.currentField?.key] ?? '');
      state = state.copyWith(currentFieldIndex: effectiveNext);
      
      final msg = showAck 
          ? "$ack\n\n${state.fields[effectiveNext].question}"
          : state.fields[effectiveNext].question;
          
      _addAgentMessage(msg);
    }
  }

  // ── Search Grounding ──────────────────────────────────────────

  Future<void> _researchClient(String name) async {
    state = state.copyWith(isResearching: true);
    _addAgentMessage(
      "Thanks! Let me analyze what you provided and do some background research to save you time... 🔍",
    );

    try {
      final prompt = '''You are a business research assistant. The user provided this information about their client: "$name". 
Extract any available details from their message AND perform web research to fill in any missing information about this entity. Return ONLY a valid JSON object. Do NOT include any text outside the JSON.

Return EXACTLY this structure (use null for fields you cannot find):
{
  "name": "the actual company or client name extracted from the message or research",
  "industry": "the industry or sector",
  "website": "company website URL",
  "address": "physical address (general address or headquarters)",
  "fiscalAddress": "official billing or fiscal address (if different from physical)",
  "size": "employee count range: 1-10, 11-50, 51-200, 201-500, or 500+",
  "description": "brief 1-2 sentence description of what they do",
  "legalName": "official legal/registered name",
  "taxId": "Tax ID or RUC (Registro Único de Contribuyentes)",
  "email": "general contact email",
  "linkedinUrl": "LinkedIn company page URL",
  "portfolioUrl": "portfolio or showcase URL"
}

Only include fields where you have high confidence. Omit or set to null anything uncertain.''';

      final result = await EdgeAIService.generateText(
        prompt,
        modelConfig: AIModelConfig.geminiResearch,
        outputMode: 'json',
        ref: _ref,
      );

      final parsed = _parseResearchResult(result.text);
      if (parsed.isNotEmpty) {
        state = state.copyWith(
          isResearching: false,
          researchResults: parsed,
        );
      } else {
        // Research returned nothing useful
        state = state.copyWith(isResearching: false, researchConfirmed: true);
        _addAgentMessage(
          "Couldn't find much online — no worries, I'll ask you directly!",
        );
        _advanceToNextField(false, true);
      }
    } catch (e) {
      _log.w('IntakeResearch: Error: $e');
      state = state.copyWith(isResearching: false, researchConfirmed: true);
      _addAgentMessage(
        "Research didn't work this time — let's continue manually!",
      );
      _advanceToNextField(false, true);
    }
  }

  Map<String, String> _parseResearchResult(String text) {
    try {
      // Strip markdown code fences if present
      var cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final result = <String, String>{};
      for (final entry in json.entries) {
        if (entry.value != null && entry.value.toString().trim().isNotEmpty &&
            entry.value.toString().toLowerCase() != 'null') {
          result[entry.key] = entry.value.toString().trim();
        }
      }
      return result;
    } catch (e) {
      _log.w('IntakeResearch: Parse error: $e');
      return {};
    }
  }

  /// User confirms the research results → merge into collectedData and skip those fields.
  void confirmResearch() {
    final results = state.researchResults;
    if (results == null) return;

    final updated = Map<String, String>.from(state.collectedData);
    updated.addAll(results);

    state = state.copyWith(
      collectedData: updated,
      researchConfirmed: true,
      researchResults: null,
    );

    _addAgentMessage(
      "Great — I've filled in what I found! Let me check if anything's still missing...",
    );

    // Advance past all researched/filled fields without acknowledging the previous field again
    _advanceToNextField(false, false);
  }

  /// User declines research → continue asking manually.
  void skipResearch() {
    state = state.copyWith(
      researchConfirmed: true,
      researchResults: null,
    );
    _addAgentMessage(
      "No problem! I'll ask you for each detail instead.",
    );
    _advanceToNextField(false, false);
  }

  String? _validateField(IntakeFormField field, String input) {
    if (field.key == 'email' && input.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(input)) {
        return "That doesn't look like a valid email. Try again? (e.g. name@company.com)";
      }
    }
    if (field.key == 'website' || field.key == 'portfolioUrl' || field.key == 'linkedinUrl') {
      if (input.isNotEmpty && !input.contains('.')) {
        return "That doesn't look like a valid URL. Please include the domain (e.g. example.com).";
      }
    }
    return null;
  }

  String _acknowledgement(String key, String value) {
    switch (key) {
      case 'name':
        return "Got it — **$value** 😊";
      case 'industry':
        return "Interesting space!";
      case 'legalName':
        return "Legal name recorded. ✅";
      case 'taxId':
        return "Tax ID saved securely. 🔒";
      case 'email':
        return "Email noted 📧";
      case 'size':
        return "Got it!";
      default:
        return "✅ Noted!";
    }
  }

  Future<bool> submitClient() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final data = state.collectedData;
      await _ref.read(clientProvider.notifier).addClient(
            name: data['name'] ?? 'Unnamed',
            clientType: state.clientType ?? ClientType.corporate,
            industry: data['industry'] ?? 'Other',
            email: data['email'],
            website: data['website'],
            address: data['address'],
            fiscalAddress: data['fiscalAddress'],
            size: data['size'],
            description: data['description'],
            legalName: data['legalName'],
            taxId: data['taxId'],
            profession: state.clientType == ClientType.independent ? data['industry'] : null,
            personalTaxId: state.clientType == ClientType.independent ? data['taxId'] : null,
            portfolioUrl: data['portfolioUrl'],
            linkedinUrl: data['linkedinUrl'],
          );
      state = state.copyWith(isSaving: false);
      _addAgentMessage("🚀 **Client created successfully!** Redirecting you to the client list...");
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      _addAgentMessage("❌ Oops, something went wrong: $e\n\nPlease try again.");
      return false;
    }
  }
}

// ── Providers ──────────────────────────────────────────────────
final intakeConversationProvider =
    StateNotifierProvider.autoDispose<IntakeConversationNotifier, IntakeConversationState>(
  (ref) => IntakeConversationNotifier(ref),
);
