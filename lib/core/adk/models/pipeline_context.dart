import '../../../features/knowledge/models/knowledge_source.dart';
import 'adk_artifact.dart';
import 'adk_session.dart';

/// Manages the state and intermediate results of a multi-agent pipeline.
/// Prevents "context rot" by providing a structured way to pass data between agents.
class PipelineContext {
  final String pipelineId;
  final List<AdkArtifact> _artifacts = [];
  final List<KnowledgeSource> sharedKnowledge;
  final AdkSession? session;
  final Map<String, dynamic> _variables = {};

  PipelineContext({
    required this.pipelineId,
    this.sharedKnowledge = const [],
    this.session,
  });

  /// Adds a result from an agent step as an artifact
  void addArtifact(AdkArtifact artifact) {
    _artifacts.add(artifact);
    if (session != null) {
      session!.artifacts.add(artifact); // Propagate to session
    }
  }

  /// Retrieves an artifact by its label or ID
  AdkArtifact? getArtifact(String query) {
    try {
      return _artifacts.firstWhere(
        (a) => a.id == query || a.label == query,
        orElse: () => session?.artifacts.firstWhere(
              (a) => a.id == query || a.label == query,
            ) ?? (throw Exception("Artifact $query not found")),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns all artifacts as a formatted string for injection into future prompts
  String getArtifactsSummary() {
    final all = [...?session?.artifacts, ..._artifacts];
    if (all.isEmpty) return "No prior artifacts.";
    
    final buffer = StringBuffer("PREVIOUS PIPELINE RESULTS:\n");
    for (var artifact in all) {
      buffer.writeln("--- Artifact: ${artifact.label ?? artifact.id} (${artifact.sourceAgent}) ---");
      buffer.writeln(artifact.content.toString());
    }
    return buffer.toString();
  }

  List<AdkArtifact> get artifacts => List.unmodifiable(_artifacts);

  void setVariable(String name, dynamic value) {
    _variables[name] = value;
  }

  dynamic getVariable(String name) {
    return _variables[name];
  }

  Map<String, dynamic> get variables => Map.unmodifiable(_variables);
}
