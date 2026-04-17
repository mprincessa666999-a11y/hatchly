import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';

class CategoriesNotifier extends StateNotifier<List<TaskCategory>> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CategoriesNotifier() : super([]);

  String? get _uid => _auth.currentUser?.uid;

  void initStorage() {
    final saved = StorageService().loadCategories();

    if (saved.isEmpty) {
      state = [];
      // Попробуем загрузить из Firestore
      _loadFromFirestore();
      return;
    }

    // Мигрируем категории без иконок
    final migrated = saved.map((c) {
      final hasIcon = c.iconAsset != null && c.iconAsset!.isNotEmpty;
      final hasColor = c.colorHex != null && c.colorHex!.isNotEmpty;
      if (!hasIcon || !hasColor) {
        return TaskCategory(
          id: c.id,
          name: c.name,
          iconAsset: 'stars.svg',
          colorHex: '#F16001',
        );
      }
      return c;
    }).toList();

    state = migrated;
    _saveLocal();
    // Синхронизируем с Firestore
    _syncToFirestore(migrated);
  }

  Future<void> _loadFromFirestore() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final cats = doc.data()?['categories'];
      if (cats != null) {
        final list = (cats as List)
            .map((m) => TaskCategory.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        state = list;
        _saveLocal();
      }
    } catch (_) {}
  }

  Future<void> _syncToFirestore(List<TaskCategory> cats) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set({
        'categories': cats.map((c) => c.toMap()).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _saveLocal() async => StorageService().saveCategories(state);

  Future<void> _save() async {
    _saveLocal();
    _syncToFirestore(state);
  }

  void addCategory(TaskCategory category) {
    state = [...state, category];
    _save();
  }

  void deleteCategory(String id) {
    state = state.where((c) => c.id != id).toList();
    _save();
  }

  void updateCategory(TaskCategory category) {
    state = [
      for (final c in state)
        if (c.id == category.id) category else c,
    ];
    _save();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<TaskCategory>>(
      (ref) => CategoriesNotifier(),
    );
