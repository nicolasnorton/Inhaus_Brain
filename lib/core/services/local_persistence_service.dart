
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/clients/models/project_model.dart';
import '../../features/clients/models/task_model.dart';

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
}

final persistenceServiceProvider = Provider<LocalPersistenceService>((ref) => LocalPersistenceService());
