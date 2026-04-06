import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    assert(
      _prefs != null,
      'StorageService not initialized. Call init() first.',
    );
    return _prefs!;
  }

  // ── Tasks (Упрощено для поддержки новых полей) ──────────────────
  Future<void> saveTasks(List<Task> tasks) async {
    final list = tasks.map((t) => t.toMap()).toList();
    await prefs.setString('tasks', jsonEncode(list));
  }

  List<Task> loadTasks() {
    final raw = prefs.getString('tasks');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((m) => Task.fromMap(m as Map<String, dynamic>)).toList();
  }

  // ── Profile ────────────────────────────────────────────────────────
  Future<void> saveProfile({
    required String name,
    String? photoPath,
    String? inviteCode,
    String? partnerName,
  }) async {
    final map = {
      'name': name,
      'photoPath': photoPath,
      'inviteCode': inviteCode,
      'partnerName': partnerName,
    };
    await prefs.setString('profile', jsonEncode(map));
  }

  Map<String, dynamic>? loadProfile() {
    final raw = prefs.getString('profile');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Pet Counter ────────────────────────────────────────────────────
  Future<void> savePetCounter(int count) async =>
      await prefs.setInt('petCounter', count);
  int loadPetCounter() => prefs.getInt('petCounter') ?? 0;

  // ── Streak (Серия дней) ───────────────────────────────────────────
  Future<void> saveStreak(int count) async =>
      await prefs.setInt('user_streak', count);
  int loadStreak() => prefs.getInt('user_streak') ?? 0;

  Future<void> saveLastStreakDate(String dateStr) async =>
      await prefs.setString('last_streak_date', dateStr);
  String loadLastStreakDate() => prefs.getString('last_streak_date') ?? '';

  // ── Notes ──────────────────────────────────────────────────────────
  Future<void> saveNotes(List<Map<String, dynamic>> notes) async =>
      await prefs.setString('notes', jsonEncode(notes));
  List<Map<String, dynamic>> loadNotes() {
    final raw = prefs.getString('notes');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  // ── Wishes ─────────────────────────────────────────────────────────
  Future<void> saveWishes(List<Map<String, dynamic>> wishes) async =>
      await prefs.setString('wishes', jsonEncode(wishes));
  List<Map<String, dynamic>> loadWishes() {
    final raw = prefs.getString('wishes');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  // ── Custom Categories ─────────────────────────────────────────
  Future<void> saveCategories(List<TaskCategory> categories) async {
    final list = categories.map((c) => c.toMap()).toList();
    await prefs.setString('custom_categories', jsonEncode(list));
  }

  List<TaskCategory> loadCategories() {
    final raw = prefs.getString('custom_categories');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((m) => TaskCategory.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
