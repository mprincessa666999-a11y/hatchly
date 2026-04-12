import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';

const _defaultCategories = [
  TaskCategory(
    id: 'cleaning',
    name: 'Уборка',
    iconAsset: 'cleaning.svg',
    colorHex: '#64B5F6',
  ),
  TaskCategory(
    id: 'cooking',
    name: 'Готовка',
    iconAsset: 'cooking.svg',
    colorHex: '#34D399',
  ),
  TaskCategory(
    id: 'events',
    name: 'Мероприятия',
    iconAsset: 'events.svg',
    colorHex: '#FFCA28',
  ),
  TaskCategory(
    id: 'pets',
    name: 'Питомцы',
    iconAsset: 'pets.svg',
    colorHex: '#F16001',
  ),
  TaskCategory(
    id: 'health',
    name: 'Здоровье',
    iconAsset: 'health.svg',
    colorHex: '#FF6B6B',
  ),
];

class CategoriesNotifier extends StateNotifier<List<TaskCategory>> {
  CategoriesNotifier() : super([]);

  void initStorage() {
    final saved = StorageService().loadCategories();

    if (saved.isEmpty) {
      // Первый запуск — пустой список, пользователь создаёт сам
      state = [];
      return;
    }

    // Мигрируем: если у категории нет иконки — ставим дефолтную
    final migrated = saved.map((c) {
      final hasIcon = c.iconAsset != null && c.iconAsset!.isNotEmpty;
      final hasColor = c.colorHex != null && c.colorHex!.isNotEmpty;
      if (!hasIcon || !hasColor) {
        final def = _defaultCategories.where((d) => d.id == c.id).firstOrNull;
        if (def != null) return def;
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
    _save();
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
