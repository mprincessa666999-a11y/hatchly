import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';
import 'package:couple_app/features/auth/providers/auth_provider.dart'
    show authRepositoryProvider;

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final file = File(pickedFile.path);

      if (uid != null) {
        // Загружаем в Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('$uid.jpg');

        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();

        // Сохраняем URL в Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': url,
        });

        // Сохраняем и URL и локальный путь в profileProvider
        ref.read(profileProvider.notifier).setPhoto(url);
      } else {
        // Нет авторизации — сохраняем только локально
        ref.read(profileProvider.notifier).setPhoto(pickedFile.path);
      }
    } catch (e) {
      // Если ошибка загрузки — сохраняем локально
      ref.read(profileProvider.notifier).setPhoto(pickedFile.path);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    await ref.read(profileProvider.notifier).setName(name);

    // Также обновляем имя в Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': name,
        });
      }
    } catch (_) {}

    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() => _isSaving = false);
      context.go('/');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Выход',
          style: AppTextStyles.bodyL.copyWith(color: Colors.white),
        ),
        content: Text(
          'Вы действительно хотите выйти из аккаунта?',
          style: AppTextStyles.bodyM.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authRepositoryProvider).signOut();
              context.go('/welcome');
            },
            child: const Text(
              'Выйти',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isNameEmpty = _nameController.text.trim().isEmpty;

    // Определяем ImageProvider
    ImageProvider? imageProvider;
    if (profile.photoPath != null) {
      if (profile.photoPath!.startsWith('http')) {
        imageProvider = NetworkImage(profile.photoPath!);
      } else {
        imageProvider = FileImage(File(profile.photoPath!));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Хедер ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: AppIcons.arrow(size: 22),
                    ),
                    const Spacer(),
                    Text('Профиль', style: AppTextStyles.h2),
                    const Spacer(),
                    const SizedBox(width: 22),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Аватар ──
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: AppColors.surface,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person_outline,
                              color: AppColors.textSecondary,
                              size: 40,
                            )
                          : null,
                    ),
                    // Индикатор загрузки поверх аватара
                    if (_isUploadingPhoto)
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    if (!_isUploadingPhoto)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Имя ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Введите имя',
                    hintStyle: AppTextStyles.h2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),

              const SizedBox(height: 20),

              // ── Сохранить ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GestureDetector(
                  onTap: isNameEmpty || _isSaving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: isNameEmpty
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFFF16001),
                                Color(0xFFC10801),
                                Color(0xFF3A0000),
                              ],
                            ),
                      color: isNameEmpty ? AppColors.surface : null,
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'СОХРАНИТЬ',
                              style: AppTextStyles.button.copyWith(
                                color: isNameEmpty
                                    ? AppColors.textSecondary
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Разделы ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Разделы',
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuRow(
                      icon: AppIcons.analytics(size: 20),
                      bgColor: const Color(0xFF6C5CE7),
                      title: 'Аналитика',
                      subtitle: 'Статистика задач за неделю и месяц',
                      onTap: () => context.push('/stats'),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: AppIcons.friends(size: 20),
                      bgColor: const Color(0xFF34D399),
                      title: 'Друзья',
                      subtitle: 'Рейтинг питомцев и приглашения',
                      onTap: () => context.push('/friends'),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: AppIcons.farm(size: 20),
                      bgColor: const Color(0xFFB39DDB),
                      title: 'Ферма питомцев',
                      subtitle: 'Все твои питомцы',
                      onTap: () => context.push('/pet-farm'),
                    ),
                    const SizedBox(height: 10),
                    _MenuRow(
                      icon: AppIcons.family(size: 20),
                      bgColor: const Color(0xFFFFB74D),
                      title: 'Семья',
                      subtitle: 'Общие дела и пространство',
                      onTap: () => context.push('/family'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Код приглашения ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Код приглашения',
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (profile.inviteCode != null &&
                        profile.inviteCode!.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.inviteCode!,
                            style: AppTextStyles.h3.copyWith(
                              letterSpacing: 6,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: profile.inviteCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Код скопирован!'),
                                  backgroundColor: AppColors.primary,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.copy,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Поделитесь этим кодом, чтобы добавить друзей',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Выход ──
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout,
                        size: 18,
                        color: Color(0xFFFF4444),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Выйти из аккаунта',
                        style: AppTextStyles.bodyM.copyWith(
                          color: const Color(0xFFFF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final Widget icon;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AppIcons.arrow(size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
