import 'package:flutter/material.dart';

enum ChunkStructure {
  general,
  parentChild,
  questionAnswer,
}

enum IndexMethod {
  economical,
  highQuality,
}

enum RetrievalSetting {
  invertedIndex,
  hybridSearch,
  vectorSearch,
  hybridSearchWeighted,
}

class PipelineTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final ChunkStructure chunkStructure;
  final IndexMethod indexMethod;
  final RetrievalSetting retrievalSetting;
  final List<String> tags;
  final bool isBuiltIn;

  const PipelineTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.chunkStructure,
    required this.indexMethod,
    required this.retrievalSetting,
    this.tags = const [],
    this.isBuiltIn = true,
  });

  static const List<PipelineTemplate> builtInTemplates = [
    PipelineTemplate(
      id: 'general-eco',
      name: 'General Mode-ECO',
      description: 'Divide document content into smaller paragraphs, directly used for matching user queries and retrieval.',
      icon: Icons.grid_view,
      color: Colors.blueAccent,
      chunkStructure: ChunkStructure.general,
      indexMethod: IndexMethod.economical,
      retrievalSetting: RetrievalSetting.invertedIndex,
      tags: ['GENERAL', 'ECO', 'INVERTED'],
    ),
    PipelineTemplate(
      id: 'parent-child-hq',
      name: 'Parent-child-HQ',
      description: 'Adopt advanced chunking strategy, dividing document text into larger parent chunks and smaller child chunks.',
      icon: Icons.account_tree_outlined,
      color: Colors.purpleAccent,
      chunkStructure: ChunkStructure.parentChild,
      indexMethod: IndexMethod.highQuality,
      retrievalSetting: RetrievalSetting.hybridSearch,
      tags: ['PARENT-CHILD', 'HQ', 'VECTOR'],
    ),
    PipelineTemplate(
      id: 'simple-qa',
      name: 'Simple Q&A',
      description: 'Convert tabular data into question-answer format, using question matching to quickly hit corresponding answer information.',
      icon: Icons.question_answer_outlined,
      color: Colors.greenAccent,
      chunkStructure: ChunkStructure.questionAnswer,
      indexMethod: IndexMethod.highQuality,
      retrievalSetting: RetrievalSetting.vectorSearch,
      tags: ['Q&A', 'HQ', 'VECTOR'],
    ),
    PipelineTemplate(
      id: 'llm-qa',
      name: 'LLM Generated Q&A',
      description: 'Generate structured question-answer pairs with large language models based on original text paragraphs.',
      icon: Icons.psychology_outlined,
      color: Colors.orangeAccent,
      chunkStructure: ChunkStructure.questionAnswer,
      indexMethod: IndexMethod.highQuality,
      retrievalSetting: RetrievalSetting.vectorSearch,
      tags: ['Q&A', 'HQ', 'VECTOR'],
    ),
    PipelineTemplate(
      id: 'conv-markdown',
      name: 'Convert to Markdown',
      description: 'Designed for Office native file formats such as DOCX, XLSX, and PPTX, converting them to Markdown format.',
      icon: Icons.description_outlined,
      color: Colors.blue,
      chunkStructure: ChunkStructure.parentChild,
      indexMethod: IndexMethod.highQuality,
      retrievalSetting: RetrievalSetting.hybridSearchWeighted,
      tags: ['PARENT-CHILD', 'HQ', 'WEIGHTED'],
    ),
  ];
}
