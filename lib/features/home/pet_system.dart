import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/core/services/storage_service.dart';

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

const int tasksPerStage = 8;
const int stagesPerPet = 6;
const int tasksPerPet = tasksPerStage * stagesPerPet;

int stageFromTasks(int tasksForCurrentPet) =>
    ((tasksForCurrentPet ~/ tasksPerStage) + 1).clamp(1, stagesPerPet);

int progressInStage(int tasksForCurrentPet) {
  final tasksInCurrentStage = tasksForCurrentPet % tasksPerStage;
  return ((tasksInCurrentStage / tasksPerStage) * 100).round();
}

int petOverallProgress(int tasksForCurrentPet) =>
    ((tasksForCurrentPet / tasksPerPet) * 100).clamp(0, 100).round();

int stageFromPercent(int percent) {
  if (percent < 15) return 1;
  if (percent < 30) return 2;
  if (percent < 50) return 3;
  if (percent < 70) return 4;
  if (percent < 90) return 5;
  return 6;
}

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

class PetSystemState {
  final int currentPetIndex;
  final List<CompletedPet> completedPets;
  final int totalTasksDone;

  const PetSystemState({
    required this.currentPetIndex,
    required this.completedPets,
    required this.totalTasksDone,
  });

  int get tasksForCurrentPet =>
      (totalTasksDone - completedPets.length * tasksPerPet).clamp(
        0,
        tasksPerPet,
      );

  int get currentPetProgress => petOverallProgress(tasksForCurrentPet);
  int get currentStage => stageFromTasks(tasksForCurrentPet);

  PetSystemState copyWith({
    int? currentPetIndex,
    List<CompletedPet>? completedPets,
    int? totalTasksDone,
  }) => PetSystemState(
    currentPetIndex: currentPetIndex ?? this.currentPetIndex,
    completedPets: completedPets ?? this.completedPets,
    totalTasksDone: totalTasksDone ?? this.totalTasksDone,
  );
}

class CompletedPet {
  final int petIndex;
  final DateTime completedAt;
  const CompletedPet({required this.petIndex, required this.completedAt});
}

class PetSystemNotifier extends StateNotifier<PetSystemState> {
  int _totalDone = 0;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  PetSystemNotifier()
    : super(
        const PetSystemState(
          currentPetIndex: 0,
          completedPets: [],
          totalTasksDone: 0,
        ),
      );

  String? get _uid => _auth.currentUser?.uid;

  void initStorage() {
    final storage = StorageService();
    final saved = storage.loadPetCounter();
    if (saved > 0) {
      _totalDone = saved;
      _recalculate();
    }
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final counter = doc.data()?['petCounter'] as int?;
      if (counter != null && counter > _totalDone) {
        _totalDone = counter;
        _recalculate();
        StorageService().savePetCounter(_totalDone);
      }
    } catch (_) {}
  }

  void onCountChanged(int count) {
    _totalDone = count;
    _recalculate();
    _saveToStorage();
    _saveToFirestore();
  }

  Future<void> _saveToStorage() async =>
      StorageService().savePetCounter(_totalDone);

  Future<void> _saveToFirestore() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set({
        'petCounter': _totalDone,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _recalculate() {
    final expectedPetIndex = (_totalDone ~/ tasksPerPet).clamp(
      0,
      allPets.length - 1,
    );
    if (expectedPetIndex > state.currentPetIndex) {
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
      notifier.initStorage();
      ref.listen(petTaskCounterProvider, (prev, count) {
        notifier.onCountChanged(count);
      });
      return notifier;
    });
