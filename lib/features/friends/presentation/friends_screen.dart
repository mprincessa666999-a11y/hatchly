import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/core/ui/pet_assets.dart';
// ИСПРАВЛЕНО: Добавлен импорт
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';

class FamilyMember {
  final String id;
  final String name;
  final String code;
  final bool isFamily;
  final String? photoUrl;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.code,
    this.isFamily = false,
    this.photoUrl,
  });

  FamilyMember copyWith({bool? isFamily}) => FamilyMember(
    id: id,
    name: name,
    code: code,
    photoUrl: photoUrl,
    isFamily: isFamily ?? this.isFamily,
  );
}

class RelationsNotifier extends StateNotifier<List<FamilyMember>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RelationsNotifier() : super([]) {
    _load();
  }

  String? get _uid => _auth.currentUser?.uid;

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await _db.collection('users').doc(uid).get();
    final friends = List<Map<String, dynamic>>.from(
      doc.data()?['friends'] ?? [],
    );
    state = friends
        .map(
          (f) => FamilyMember(
            id: f['id'] as String,
            name: f['name'] as String,
            code: f['code'] as String,
            isFamily: f['isFamily'] as bool? ?? false,
            photoUrl: f['photoUrl'] as String?,
          ),
        )
        .toList();
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'friends': state
          .map(
            (m) => {
              'id': m.id,
              'name': m.name,
              'code': m.code,
              'isFamily': m.isFamily,
              'photoUrl': m.photoUrl ?? '',
            },
          )
          .toList(),
    });
  }

  Future<String> addFriendByCode(String code) async {
    if (state.any((m) => m.code == code)) return 'already';

    final couplesQuery = await _db
        .collection('couples')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    String friendName = 'Пользователь $code';
    String friendId = DateTime.now().millisecondsSinceEpoch.toString();
    String? friendPhotoUrl;

    if (couplesQuery.docs.isNotEmpty) {
      final members = List<String>.from(
        couplesQuery.docs.first.data()['members'] ?? [],
      );
      final myUid = _uid;
      final friendUid = members.firstWhere(
        (m) => m != myUid,
        orElse: () => members.first,
      );

      final userDoc = await _db.collection('users').doc(friendUid).get();
      if (userDoc.exists) {
        friendName = userDoc.data()?['name'] as String? ?? friendName;
        friendId = friendUid;
        friendPhotoUrl = userDoc.data()?['photoUrl'] as String?;
      }
    } else {
      final usersQuery = await _db
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (usersQuery.docs.isNotEmpty) {
        friendName =
            usersQuery.docs.first.data()['name'] as String? ?? friendName;
        friendId = usersQuery.docs.first.id;
        friendPhotoUrl = usersQuery.docs.first.data()['photoUrl'] as String?;
      }
    }

    final newFriend = FamilyMember(
      id: friendId,
      name: friendName,
      code: code,
      photoUrl: friendPhotoUrl,
    );
    state = [...state, newFriend];
    await _save();

    try {
      await _db
          .collection('users')
          .doc(friendId)
          .collection('notifications')
          .add({
            'type': 'friend_added',
            'fromName': _auth.currentUser?.displayName ?? 'Пользователь',
            'fromUid': _uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}

    return friendName;
  }

  Future<void> moveToFamily(String memberId) async {
    state = state
        .map((m) => m.id == memberId ? m.copyWith(isFamily: true) : m)
        .toList();
    await _save();

    try {
      await _db
          .collection('users')
          .doc(memberId)
          .collection('notifications')
          .add({
            'type': 'family_added',
            'fromName': _auth.currentUser?.displayName ?? 'Пользователь',
            'fromUid': _uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }
}

final relationsProvider =
    StateNotifierProvider<RelationsNotifier, List<FamilyMember>>(
      (ref) => RelationsNotifier(),
    );

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showEnterCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ввести код друга',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _codeController,
          style: const TextStyle(color: Colors.white, letterSpacing: 2),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Например: X9K2PM',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = _codeController.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              _codeController.clear();

              final name = await ref
                  .read(relationsProvider.notifier)
                  .addFriendByCode(code);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      name == 'already'
                          ? 'Этот друг уже добавлен'
                          : '$name добавлен(а) в друзья!',
                    ),
                    backgroundColor: name == 'already'
                        ? Colors.orange
                        : Colors.green,
                  ),
                );
              }
            },
            child: Text(
              'Добавить',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(tasksNotifierProvider);
    final totalTasks = allTasks.length;
    final doneTasks = allTasks.where((t) => t.isDone).length;
    final myPct = totalTasks == 0
        ? 0
        : ((doneTasks / totalTasks) * 100).round();

    final profile = ref.watch(profileProvider);
    final myInviteCode = profile.inviteCode ?? '......';
    final friendsList = ref
        .watch(relationsProvider)
        .where((m) => !m.isFamily)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(), // или context.go('/profile')
                      // ИСПРАВЛЕНО: Заменено на AppIcons.arrow()
                      child: AppIcons.arrow(size: 22),
                    ),
                    const SizedBox(width: 16),
                    Text('Друзья', style: AppTextStyles.h2),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Твой код приглашения',
                        style: AppTextStyles.bodyM.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        myInviteCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Поделись кодом с другом — и соревнуйтесь питомцами',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: myInviteCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Код скопирован!'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Скопировать код',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showEnterCodeDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Ввести код',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppPlate(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Что дают друзья?',
                        style: AppTextStyles.bodyL.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.visibility_outlined,
                        iconColor: AppColors.primary,
                        title: 'Совместные задачи',
                        subtitle: 'Видите прогресс друг друга',
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.emoji_events_outlined,
                        iconColor: const Color(0xFF34D399),
                        title: 'Соревнование питомцев',
                        subtitle: 'Чей питомец вырастет быстрее?',
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.card_giftcard_outlined,
                        iconColor: const Color(0xFFB39DDB),
                        title: 'Общий сундук желаний',
                        subtitle: 'Делитесь желаниями друг с другом',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Мои друзья',
                  style: AppTextStyles.bodyL.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            if (friendsList.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      PetAssets.sadPetWidget(petId: 'chunya', size: 100),
                      const SizedBox(height: 16),
                      Text(
                        'Друзей пока нет',
                        style: AppTextStyles.bodyM.copyWith(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Введите код друга выше, чтобы добавить его',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final friend = friendsList[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: AppPlate(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          _FriendAvatar(
                            name: friend.name,
                            photoUrl: friend.photoUrl,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Код: ${friend.code}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(relationsProvider.notifier)
                                  .moveToFamily(friend.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${friend.name} добавлен(а) в семью!',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'В семью',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: friendsList.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppPlate(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Рейтинг питомцев', style: AppTextStyles.bodyL),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            '#1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Вы (${profile.name.isEmpty ? "Без имени" : profile.name})',
                              style: AppTextStyles.bodyM.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '$myPct%',
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Пригласите друзей чтобы соревноваться',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;

  const _FriendAvatar({required this.name, this.photoUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF34D399).withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
    );
  }
}
