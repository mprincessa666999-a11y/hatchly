import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/core/services/storage_service.dart';

class UserProfile {
  final String name;
  final String? photoPath;
  final String? inviteCode;
  final String? partnerName;

  const UserProfile({
    this.name = '',
    this.photoPath,
    this.inviteCode,
    this.partnerName,
  });

  bool get isNotSet => name.trim().isEmpty;

  UserProfile copyWith({
    String? name,
    String? photoPath,
    String? inviteCode,
    String? partnerName,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      inviteCode: inviteCode ?? this.inviteCode,
      partnerName: partnerName ?? this.partnerName,
    );
  }
}

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(const UserProfile(name: ''));

  Future<void> initStorage() async {
    final saved = StorageService().loadProfile();
    if (saved != null) {
      state = UserProfile(
        name: saved['name'] as String? ?? '',
        photoPath: saved['photoPath'] as String?,
        inviteCode: saved['inviteCode'] as String?,
        partnerName: saved['partnerName'] as String?,
      );
    }
    // АВТОМАТИЧЕСКАЯ ГЕНЕРАЦИЯ КОДА (если его еще нет)
    await ensureInviteCodeExists();
  }

  Future<void> _saveToStorage() async {
    await StorageService().saveProfile(
      name: state.name,
      photoPath: state.photoPath,
      inviteCode: state.inviteCode,
      partnerName: state.partnerName,
    );
  }

  Future<void> ensureInviteCodeExists() async {
    if (state.inviteCode == null || state.inviteCode!.isEmpty) {
      final code = _generateCode();
      state = state.copyWith(inviteCode: code);
      await _saveToStorage();
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Убраны O, 0, I, 1
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> setName(String name) async {
    state = state.copyWith(name: name);
    await _saveToStorage();
  }

  Future<void> setPhoto(String path) async {
    state = state.copyWith(photoPath: path);
    await _saveToStorage();
  }

  Future<void> setPartnerName(String name) async {
    state = state.copyWith(partnerName: name);
    await _saveToStorage();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(),
);
