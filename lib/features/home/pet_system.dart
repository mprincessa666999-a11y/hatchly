import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/core/services/storage_service.dart';

// ── Описание питомцев ─────────────────────────────────────────────────
class PetInfo {
  final String id;
  final String name;
  final String description;
  final Color glowColor;

  const PetInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.glowColor,
  });
}

const allPets = [
  PetInfo(
    id: 'chunya',
    name: 'Чуня',
    description: 'Первый питомец семьи',
    glowColor: Color(0xFF5B9BE9),
  ),
  PetInfo(
    id: 'lumi',
    name: 'Люми',
    description: 'Светящийся малыш',
    glowColor: Color.fromARGB(255, 255, 115, 0),
  ),
  PetInfo(
    id: 'flik',
    name: 'Флик',
    description: 'Быстрый и игривый',
    glowColor: Color.fromARGB(255, 0, 247, 255),
  ),
  PetInfo(
    id: 'nyx',
    name: 'Никс',
    description: 'Таинственный ночной страж',
    glowColor: Color.fromARGB(255, 255, 81, 0),
  ),
  PetInfo(
    id: 'astra',
    name: 'Астра',
    description: 'Звёздный путешественник',
    glowColor: Color.fromARGB(255, 228, 2, 216),
  ),
  PetInfo(
    id: 'plyukh',
    name: 'Плюх',
    description: 'Добродушный и пушистый',
    glowColor: Color.fromARGB(255, 132, 0, 255),
  ),
  PetInfo(
    id: 'zippo',
    name: 'Зиппо',
    description: 'Огненный дух',
    glowColor: Color(0xFFE9815B),
  ),
];

// ── 8 задач на стадию, 6 стадий = 48 задач на питомца ──────────────
const int tasksPerStage = 8;
const int stagesPerPet = 6;
const int tasksPerPet = tasksPerStage * stagesPerPet;

// ── Стадия по количеству выполненных задач для текущего питомца ───────
int stageFromTasks(int tasksForCurrentPet) {
  final stage = (tasksForCurrentPet ~/ tasksPerStage) + 1;
  return stage.clamp(1, stagesPerPet);
}

// ── Прогресс внутри текущей стадии (0-100%) ───────────────────────────
int progressInStage(int tasksForCurrentPet) {
  final tasksInCurrentStage = tasksForCurrentPet % tasksPerStage;
  return ((tasksInCurrentStage / tasksPerStage) * 100).round();
}

// ── Общий прогресс питомца (0-100%) ──────────────────────────────────
int petOverallProgress(int tasksForCurrentPet) {
  return ((tasksForCurrentPet / tasksPerPet) * 100).clamp(0, 100).round();
}

// ── Стадия по проценту (0-100) ───────────────────────────────────────
int stageFromPercent(int percent) {
  if (percent < 15) return 1;
  if (percent < 30) return 2;
  if (percent < 50) return 3;
  if (percent < 70) return 4;
  if (percent < 90) return 5;
  return 6;
}

// ── Текстовый статус ──────────────────────────────────────────────────
String statusFromStageAndPet(int stage, String petName, int percent) {
  if (percent == 0) return 'Ждёт тебя...';
  switch (stage) {
    case 1:
      return 'Яйцо согревается...';
    case 2:
      return 'Малыш $petName';
    case 3:
      return 'Активный рост';
    case 4:
      return 'Подросток $petName';
    case 5:
      return 'Взрослый $petName';
    case 6:
      return 'Легендарный $petName ✨';
    default:
      return petName;
  }
}

// ── Состояние системы питомцев ────────────────────────────────────────
class PetSystemState {
  final int currentPetIndex;
  final List<CompletedPet> completedPets;
  final int totalTasksDone;

  const PetSystemState({
    required this.currentPetIndex,
    required this.completedPets,
    required this.totalTasksDone,
  });

  // Задач выполнено для текущего питомца
  int get tasksForCurrentPet {
    return (totalTasksDone - completedPets.length * tasksPerPet).clamp(
      0,
      tasksPerPet,
    );
  }

  // Прогресс текущего питомца 0-100%
  int get currentPetProgress => petOverallProgress(tasksForCurrentPet);

  // Стадия текущего питомца
  int get currentStage => stageFromTasks(tasksForCurrentPet);

  PetSystemState copyWith({
    int? currentPetIndex,
    List<CompletedPet>? completedPets,
    int? totalTasksDone,
  }) {
    return PetSystemState(
      currentPetIndex: currentPetIndex ?? this.currentPetIndex,
      completedPets: completedPets ?? this.completedPets,
      totalTasksDone: totalTasksDone ?? this.totalTasksDone,
    );
  }
}

class CompletedPet {
  final int petIndex;
  final DateTime completedAt;

  const CompletedPet({required this.petIndex, required this.completedAt});
}

// ── Notifier ──────────────────────────────────────────────────────────
class PetSystemNotifier extends StateNotifier<PetSystemState> {
  int _totalDone = 0;

  PetSystemNotifier()
    : super(
        const PetSystemState(
          currentPetIndex: 0,
          completedPets: [],
          totalTasksDone: 0,
        ),
      );

  /// Загружает petCounter из хранилища
  void initStorage() {
    final storage = StorageService();
    final saved = storage.loadPetCounter();
    if (saved > 0) {
      _totalDone = saved;
      _recalculate();
    }
  }

  /// Обновляет прогресс на основе счётчика (не зависит от списка задач)
  void onCountChanged(int count) {
    _totalDone = count;
    _recalculate();
    _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final storage = StorageService();
    await storage.savePetCounter(_totalDone);
  }

  void _recalculate() {
    final expectedPetIndex = (_totalDone ~/ tasksPerPet).clamp(
      0,
      allPets.length - 1,
    );

    if (expectedPetIndex > state.currentPetIndex) {
      // Питомец вырос! Добавляем в выращенные
      final newCompleted = List<CompletedPet>.from(state.completedPets);
      for (int i = state.currentPetIndex; i < expectedPetIndex; i++) {
        newCompleted.add(
          CompletedPet(petIndex: i, completedAt: DateTime.now()),
        );
      }
      state = state.copyWith(
        currentPetIndex: expectedPetIndex,
        completedPets: newCompleted,
        totalTasksDone: _totalDone,
      );
    } else {
      state = state.copyWith(totalTasksDone: _totalDone);
    }
  }
}

final petSystemProvider =
    StateNotifierProvider<PetSystemNotifier, PetSystemState>((ref) {
      final notifier = PetSystemNotifier();

      // Загружаем сохранённый счётчик
      notifier.initStorage();

      // Следим за отдельным счётчиком выполненных задач
      // (не зависит от списка — автоудаление не влияет на прогресс)
      ref.listen(petTaskCounterProvider, (prev, count) {
        notifier.onCountChanged(count);
      });

      return notifier;
    });
