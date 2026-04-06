import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';

class CategoriesNotifier extends StateNotifier<List<TaskCategory>> {
  CategoriesNotifier() : super([]);

  void initStorage() {
    final saved = StorageService().loadCategories();
    if (saved.isNotEmpty) {
      state = saved;
    } else {
      // Стандартные группы при первом запуске
      state = [
        const TaskCategory(id: 'cleaning', name: 'Уборка', emoji: '🧹'),
        const TaskCategory(id: 'cooking', name: 'Готовка', emoji: '🍳'),
        const TaskCategory(id: 'events', name: 'Мероприятия', emoji: '🎭'),
        const TaskCategory(id: 'pets', name: 'Питомцы', emoji: '🐱'),
        const TaskCategory(id: 'health', name: 'Здоровье', emoji: '🫀'),
      ];
      _save();
    }
  }

  Future<void> _save() async => StorageService().saveCategories(state);

  void addCategory(TaskCategory category) {
    state = [...state, category];
    _save();
  }

  void deleteCategory(String id) {
    state = state.where((c) => c.id != id).toList();
    _save();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<TaskCategory>>(
      (ref) => CategoriesNotifier(),
    );
