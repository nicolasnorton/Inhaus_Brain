
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/clients/models/project_model.dart';
import '../../features/clients/models/task_model.dart';
import '../../features/assistant/services/assistant_service.dart';

/// Service for simple local persistence using SharedPreferences
class LocalPersistenceService {
  static final LocalPersistenceService _instance = LocalPersistenceService._internal();

  factory LocalPersistenceService() {
    return _instance;
  }

  LocalPersistenceService._internal();

  /// Save map to shared preferences
  Future<void> saveMap(String key, Map<String, dynamic> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (e) {
      debugPrint('Error saving map to prefs: $e');
    }
  }

  /// Get map from shared preferences
  Future<Map<String, dynamic>?> getMap(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getting map from prefs: $e');
    }
    return null;
  }

  /// Remove key from shared preferences
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error removing key from prefs: $e');
    }
  }

  // --- Onboarding Persistence ---
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
  }

  Future<bool> getOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  // --- Client Persistence ---
  Future<void> saveClients(List<Client> clients) async {
    final List<Map<String, dynamic>> json = clients.map((c) => c.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clients_data', jsonEncode(json));
  }

  Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('clients_data');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Client.fromJson(j)).toList();
    }
    return [];
  }

  // --- Project Persistence ---
  Future<void> saveProjects(List<Project> projects) async {
    final List<Map<String, dynamic>> json = projects.map((p) => p.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('projects_data', jsonEncode(json));
  }

  Future<List<Project>> getProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('projects_data');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Project.fromJson(j)).toList();
    }
    return [];
  }

  // --- Canvas Pinned Items Persistence ---
  Future<void> savePinnedItems(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('canvas_pinned_items', jsonEncode(items));
    } catch (e) {
      debugPrint('Error saving pinned items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPinnedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('canvas_pinned_items');
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint('Error getting pinned items: $e');
    }
    return [];
  }

  // --- Task Persistence ---
  Future<void> saveTasks(List<ProjectTask> tasks) async {
    final List<Map<String, dynamic>> json = tasks.map((t) => t.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks_data', jsonEncode(json));
  }

  Future<List<ProjectTask>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('tasks_data');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => ProjectTask.fromJson(j)).toList();
    }
    return [];
  }

  // --- Assistant History Persistence ---
  Future<void> saveAssistantHistory(List<AssistantMessage> messages) async {
    try {
      // 1. Truncate to last 20 messages to keep storage small
      final limitedHistory = messages.length > 20 
          ? messages.sublist(messages.length - 20) 
          : messages;

      // 2. Prepare JSON, stripping large base64 attachments if necessary
      final List<Map<String, dynamic>> jsonList = limitedHistory.map((m) {
        final j = m.toJson();
        // Clear large base64 strings to save space (~100kb limit)
        if (j['attachment'] != null && (j['attachment'] as String).length > 100000) {
          j['attachment'] = null; // Don't persist huge images
        }
        if (j['audioAttachment'] != null && (j['audioAttachment'] as String).length > 100000) {
          j['audioAttachment'] = null; // Don't persist huge audio
        }
        if (j['artifacts'] != null && j['artifacts'] is List) {
          final artifacts = j['artifacts'] as List;
          for (var i = 0; i < artifacts.length; i++) {
            final artifact = artifacts[i];
            if (artifact is Map && artifact['content'] != null && (artifact['content'] as String).length > 100000) {
                artifact['content'] = '[Media Content Trimmed for Local Storage]';
            }
          }
        }
        return j;
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('assistant_history', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('LocalPersistence: Quota or Save Error: ${_safeError(e)}');
      // Level 2: Try only last 3 messages without ANY non-essential meta
      try {
        final prefs = await SharedPreferences.getInstance();
        final tinyHistory = messages.length > 3 ? messages.sublist(messages.length - 3) : messages;
        final tinyJson = tinyHistory.map((m) => {
          'id': m.id,
          'text': m.text,
          'isUser': m.isUser,
          'timestamp': m.timestamp.toIso8601String(),
        }).toList();
        await prefs.setString('assistant_history', jsonEncode(tinyJson));
      } catch (e2) {
        // Level 3: Total Failure - clear everything to recover functionality
        debugPrint('LocalPersistence: CRITICAL QUOTA FAILURE. Clearing history key: ${_safeError(e2)}');
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('assistant_history');
        } catch (_) {}
      }
    }
  }

  Future<List<AssistantMessage>> getAssistantHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('assistant_history');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => AssistantMessage.fromJson(j)).toList();
    }
    return [];
  }

  static String _safeError(dynamic e) {
    if (e == null) return "Unknown Error (null)";
    try {
      final dynamic err = e;
      return err.toString();
    } catch (_) {
      try {
        return "$e";
      } catch (e2) {
        return "Internal error parsing exception stack";
      }
    }
  }
}

final persistenceServiceProvider = Provider<LocalPersistenceService>((ref) => LocalPersistenceService());
