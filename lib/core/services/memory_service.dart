import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chat/models/memory_models.dart';

class MemoryService {
  static const String _fileName = 'inhaus_memory.json';
  List<MemoryItem> _memory = [];

  MemoryService() {
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    try {
      final file = await _getMemoryFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _memory = jsonList.map((j) => MemoryItem.fromJson(j)).toList();
      }
    } catch (e) {
      print('MemoryService: Error loading memory: $e');
    }
  }

  Future<void> _saveMemory() async {
    try {
      final file = await _getMemoryFile();
      final jsonList = _memory.map((m) => m.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('MemoryService: Error saving memory: $e');
    }
  }

  Future<File> _getMemoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  List<MemoryItem> get memory => List.unmodifiable(_memory);

  Future<void> addMemory(MemoryItem item) async {
    // Check for existing key to avoid duplicates (lean & smart)
    final index = _memory.indexWhere((m) => m.key == item.key && m.campaignId == item.campaignId);
    if (index != -1) {
      _memory[index] = item;
    } else {
      _memory.add(item);
    }
    await _saveMemory();
  }

  List<MemoryItem> getMemoriesForCampaign(String campaignId) {
    return _memory.where((m) => m.campaignId == campaignId).toList();
  }

  List<MemoryItem> getMemoriesByCategory(String category) {
    return _memory.where((m) => m.category == category).toList();
  }

  Future<void> clearMemory() async {
    _memory.clear();
    await _saveMemory();
  }

  // Retrieve relevant context for an AI prompt
  String getContextString({String? campaignId}) {
    final relevant = campaignId != null 
        ? getMemoriesForCampaign(campaignId) 
        : _memory;
    
    if (relevant.isEmpty) return "";
    
    return "\n[REMEMBERED FACTS & PREFERENCES]:\n${relevant.map((m) => "- ${m.key}: ${m.value}").join("\n")}";
  }
}

final memoryServiceProvider = Provider<MemoryService>((ref) => MemoryService());
