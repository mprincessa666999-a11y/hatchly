import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/core/services/notification_service.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';

final petTaskCounterProvider = StateProvider<int>(
  (ref) => StorageService().loadPetCounter(),
);
final petReactionProvider = StateProvider<String?>((ref) => null);

// Провайдер для Стрика
final streakProvider = StateProvider<int>((ref) {
  return StorageService().loadStreak();
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final VoidCallback onTaskDone;
  final VoidCallback onTaskUndone;
  final Ref ref; // Нужен для доступа к streakProvider

  List<Task> _prevState = []; // Для функции "Отмены"

  TasksNotifier({
    required this.onTaskDone,
    required this.onTaskUndone,
    required this.ref,
  }) : super([]);

  Future<void> initStorage() async {
    final saved = StorageService().loadTasks();
    if (saved.isNotEmpty) state = saved;
  }

  Future<void> _saveToStorage() async => StorageService().saveTasks(state);

  Future<void> addTask({
    required String title,
    required TaskCategory category,
    DateTime? date,
    String? time,
    int? reminderMinutes,
    required String assignedTo,
    RecurrenceType recurrenceType = RecurrenceType.none,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      category: category,
      date: date,
      time: time,
      reminderMinutes: reminderMinutes,
      assignedTo: assignedTo,
      createdBy: 'user1',
      sortOrder: state.length, // Новая задача в конец
      recurrenceType: recurrenceType,
    );
    state = [...state, task];
    await NotificationService().scheduleTaskNotification(task);
    await _saveToStorage();
  }

  void toggleDone(String id) {
    _prevState = List.from(
      state,
    ); // Сохраняем состояние ДО изменения для "Отмены"

    final task = state.firstWhere((t) => t.id == id);
    final wasDone = task.isDone;

    state = state.map((t) {
      if (t.id != id) return t;
      return t.copyWith(
        isDone: !t.isDone,
        completedDate: !t.isDone
            ? DateTime.now()
            : null, // Записываем время выполнения для стрика
      );
    }).toList();

    if (!wasDone) {
      HapticFeedback.mediumImpact(); // ВИБРАЦИЯ при выполнении
      onTaskDone();
      NotificationService().cancelTaskNotification(id);
      _updateStreak(); // Обновляем стрик
      _handleRecurrence(task); // Создаем следующую задачу, если нужно
    } else {
      onTaskUndone();
    }
    _saveToStorage();
  }

  // === НОВАЯ ФУНКЦИЯ: ОТМЕНА ===
  void undoLastAction() {
    if (_prevState.isNotEmpty) {
      state = _prevState;
      _prevState = [];
      _saveToStorage();
      HapticFeedback.lightImpact();
    }
  }

  // === НОВАЯ ФУНКЦИЯ: ПЕРЕТАСКИВАНИЕ ===
  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final tasks = List<Task>.from(state);
    final task = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, task);

    // Обновляем порядковые номера
    state = tasks.asMap().entries.map((e) {
      return e.value.copyWith(sortOrder: e.key);
    }).toList();
    _saveToStorage();
  }

  // === ЛОГИКА СТРИКА ===
  void _updateStreak() {
    final storage = StorageService();
    final lastDateStr = storage.loadLastStreakDate();
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    int currentStreak = storage.loadStreak();

    if (lastDateStr == todayStr) {
      return; // Уже выполнили сегодня, стрик не растим
    }

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month}-${yesterday.day}";

    if (lastDateStr == yesterdayStr) {
      currentStreak++; // Вчера делали, сегодня делаем -> +1
    } else {
      currentStreak = 1; // Пропустили день -> сброс до 1
    }

    storage.saveStreak(currentStreak);
    storage.saveLastStreakDate(todayStr);
    ref.read(streakProvider.notifier).state = currentStreak;
  }

  // === ЛОГИКА ПОВТОРЕНИЯ ===
  void _handleRecurrence(Task completedTask) {
    if (completedTask.recurrenceType == RecurrenceType.none) return;

    DateTime nextDate = completedTask.date ?? DateTime.now();
    switch (completedTask.recurrenceType) {
      case RecurrenceType.daily:
        nextDate = nextDate.add(const Duration(days: 1));
        break;
      case RecurrenceType.weekly:
        nextDate = nextDate.add(const Duration(days: 7));
        break;
      case RecurrenceType.monthly:
        nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        break;
      case RecurrenceType.none:
        return;
    }

    // Создаем новую задачу в будущем
    addTask(
      title: completedTask.title,
      category: completedTask.category,
      date: nextDate,
      time: completedTask.time,
      reminderMinutes: completedTask.reminderMinutes,
      assignedTo: completedTask.assignedTo,
      recurrenceType: completedTask.recurrenceType,
    );
  }

  Future<void> editTask({
    required String id,
    required String title,
    required TaskCategory category,
    DateTime? date,
    String? time,
    int? reminderMinutes,
    required String assignedTo,
    RecurrenceType recurrenceType = RecurrenceType.none,
  }) async {
    state = state.map((t) {
      if (t.id != id) return t;
      return Task(
        id: t.id,
        title: title,
        category: category,
        date: date,
        time: time,
        reminderMinutes: reminderMinutes,
        assignedTo: assignedTo,
        isDone: t.isDone,
        createdBy: t.createdBy,
        recurrenceType: recurrenceType,
        sortOrder: t.sortOrder,
      );
    }).toList();
    final updated = state.firstWhere((t) => t.id == id);
    await NotificationService().cancelTaskNotification(id);
    await NotificationService().scheduleTaskNotification(updated);
    await _saveToStorage();
  }

  Future<void> deleteTask(String id) async {
    _prevState = List.from(state); // Сохраняем для отмены
    await NotificationService().cancelTaskNotification(id);
    state = state.where((t) => t.id != id).toList();
    HapticFeedback.heavyImpact(); // ВИБРАЦИЯ при удалении
    _saveToStorage();
  }
}

final tasksNotifierProvider = StateNotifierProvider<TasksNotifier, List<Task>>((
  ref,
) {
  return TasksNotifier(
    ref: ref, // Передаем ref
    onTaskDone: () {
      ref.read(petTaskCounterProvider.notifier).state++;
      ref.read(petReactionProvider.notifier).state = 'happy';
    },
    onTaskUndone: () {
      final current = ref.read(petTaskCounterProvider);
      if (current > 0) ref.read(petTaskCounterProvider.notifier).state--;
    },
  );
});

// Сортировка (выполненные в конец, с учетом ручной сортировки)
List<Task> _sortTasks(List<Task> tasks) {
  final result = [...tasks];
  result.sort((a, b) {
    if (a.isDone == b.isDone)
      return a.sortOrder.compareTo(b.sortOrder); // Учитываем ручную сортировку
    return a.isDone ? 1 : -1;
  });
  return result;
}

final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksNotifierProvider);
  final today = DateTime.now();
  final filtered = tasks.where((t) {
    if (t.date == null) return false;
    return t.date!.day == today.day &&
        t.date!.month == today.month &&
        t.date!.year == today.year;
  }).toList();
  return _sortTasks(filtered);
});

final tasksByDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  final tasks = ref.watch(tasksNotifierProvider);
  final filtered = tasks.where((t) {
    if (t.date == null) return false;
    return t.date!.day == date.day &&
        t.date!.month == date.month &&
        t.date!.year == date.year;
  }).toList();
  return _sortTasks(filtered);
});

final tasksByCategoryProvider = Provider<List<TaskCategoryGroup>>((ref) {
  final tasks = ref.watch(tasksNotifierProvider);
  final Map<String, List<Task>> grouped = {};
  for (final task in tasks) {
    grouped.putIfAbsent(task.category.id, () => []).add(task);
  }
  return grouped.entries.map((e) {
    final done = e.value.where((t) => t.isDone).length;
    return TaskCategoryGroup(
      category: e.value.first.category,
      totalCount: e.value.length,
      doneCount: done,
    );
  }).toList();
});

final partnerProgressProvider = Provider<PartnerProgress>((ref) {
  final profileName = ref.watch(profileNameProvider);
  final tasks = ref.watch(tasksNotifierProvider);
  final total = tasks.length;
  if (total == 0)
    return const PartnerProgress(
      myPercent: 0,
      partnerPercent: 0,
      partnerName: 'Партнёр',
    );
  final done = tasks.where((t) => t.isDone).length;
  final myPercent = ((done / total) * 100).round();
  return PartnerProgress(
    myPercent: myPercent,
    partnerPercent: (myPercent * 0.6).round(),
    partnerName: profileName.isNotEmpty ? profileName : 'Партнёр',
  );
});

final profileNameProvider = Provider<String>((ref) {
  final profile = ref.watch(profileProvider);
  return profile.partnerName ?? profile.name;
});
