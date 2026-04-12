import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/core/ui/pet_assets.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/partner/presentation/partner_screen.dart'
    show Collection, wishesProvider;
import 'package:couple_app/features/friends/presentation/friends_screen.dart'
    show relationsProvider, FamilyMember;
import 'package:couple_app/features/notes/presentation/notes_screen.dart'
    show publicNotesProvider, NoteItem, NoteType, NoteTypeExt;

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  static const _collections = [
    Collection(id: 'gifts', name: 'Сундук желаний', description: ''),
    Collection(id: 'travel', name: 'Атлас мечтаний', description: ''),
    Collection(id: 'kino', name: 'Плед и попкорн', description: ''),
    Collection(id: 'entertainment', name: 'Тихая гавань', description: ''),
    Collection(id: 'cafe', name: 'Вкусные истории', description: ''),
  ];

  String _collectionName(String id) =>
      _collections.where((c) => c.id == id).firstOrNull?.name ?? 'Другое';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(tasksNotifierProvider);
    final petCounter = ref.watch(petTaskCounterProvider);
    final familyTasks = allTasks
        .where((t) => t.assignedTo == 'Партнёр' || t.assignedTo == 'Вы')
        .toList();
    final familyDone = familyTasks.where((t) => t.isDone).length;
    final petLevel = (petCounter ~/ 10) + 1;
    final petProgress = (petCounter % 10) * 10;
    final allWishes = ref.watch(wishesProvider);
    final publicNotes = ref.watch(publicNotesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Хедер ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: AppIcons.arrow(size: 22),
                    ),
                    const SizedBox(width: 16),
                    Text('Семья', style: AppTextStyles.h2),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Общий питомец ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      PetAssets.sadPetWidget(petId: 'chunya', size: 90),
                      const SizedBox(height: 12),
                      Text('Чуня', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Уровень $petLevel',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: petProgress / 100,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                                minHeight: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$petProgress%',
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Вместе выполнено задач: $petCounter',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Общие задачи ──
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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.task_alt,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Общие задачи',
                                  style: AppTextStyles.bodyM.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Задачи всех членов семьи',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Всего',
                            value: '${familyTasks.length}',
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: 'Выполнено',
                            value: '$familyDone',
                            color: const Color(0xFF34D399),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: 'Осталось',
                            value: '${familyTasks.length - familyDone}',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      if (familyTasks.isEmpty) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Задач пока нет',
                            style: AppTextStyles.bodyM.copyWith(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 8),
                        ...familyTasks
                            .take(3)
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: t.isDone
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: t.isDone
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: t.isDone
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t.title,
                                        style: AppTextStyles.bodyM.copyWith(
                                          decoration: t.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: t.isDone
                                              ? AppColors.textSecondary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      t.assignedTo,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => context.push('/tasks/new'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Добавить задачу',
                                style: AppTextStyles.bodyM.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Желания семьи ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Желания семьи',
                      style: AppTextStyles.bodyL.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            size: 12,
                            color: Color(0xFFFF6B6B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Видно всем',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (allWishes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.card_giftcard_outlined,
                          size: 44,
                          color: Color(0x1FFFFFFF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Желаний пока нет',
                          style: AppTextStyles.bodyM.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Добавьте в Сундук желаний',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList.separated(
                  itemCount: allWishes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final w = allWishes[i];
                    return AppPlate(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.card_giftcard,
                              size: 18,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.title,
                                  style: AppTextStyles.bodyM.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _collectionName(w.collectionId),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (w.price != null)
                            Text(
                              '${w.price!.toInt()} ₽',
                              style: AppTextStyles.bodyM.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Участники ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Участники',
                  style: AppTextStyles.bodyL.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: _FamilyMembersList()),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Общие заметки ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Общие заметки',
                      style: AppTextStyles.bodyL.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/notes/create'),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (publicNotes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Text(
                      'Заметок пока нет',
                      style: AppTextStyles.bodyM.copyWith(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList.separated(
                  itemCount: publicNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final note = publicNotes[i];
                    final color = note.type == NoteType.shoppingList
                        ? const Color(0xFF80CBC4)
                        : note.type == NoteType.ideas
                        ? const Color(0xFFFFCA28)
                        : const Color(0xFF64B5F6);
                    return AppPlate(
                      padding: const EdgeInsets.all(14),
                      onTap: () =>
                          context.push('/notes/${note.id}', extra: note),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                note.type == NoteType.shoppingList
                                    ? Icons.shopping_basket_outlined
                                    : note.type == NoteType.ideas
                                    ? Icons.lightbulb_outline
                                    : Icons.note_outlined,
                                size: 18,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  style: AppTextStyles.bodyM.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  note.type == NoteType.shoppingList
                                      ? '${note.shoppingItems.length} пунктов'
                                      : note.content.isEmpty
                                      ? note.type.label
                                      : note.content,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          AppIcons.arrow(size: 22, color: Colors.white12),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Пригласить ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push('/friends'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_add_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Пригласить в семью',
                          style: AppTextStyles.bodyL.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

// ── Участники семьи ───────────────────────────────────────────────────
class _FamilyMembersList extends ConsumerWidget {
  const _FamilyMembersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyMembers = ref
        .watch(relationsProvider)
        .where((m) => m.isFamily)
        .toList();

    if (familyMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            PetAssets.sadPetWidget(petId: 'chunya', size: 90),
            const SizedBox(height: 16),
            Text(
              'Семья пока пустая',
              style: AppTextStyles.bodyM.copyWith(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Добавь друга в разделе Друзья и переведи его в семью',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.25),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: familyMembers
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppPlate(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _FamilyAvatar(name: m.name, photoUrl: m.photoUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: AppTextStyles.bodyM.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Участник',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'В семье',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Аватар ───────────────────────────────────────────────────────────
class _FamilyAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _FamilyAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

// ── Чип статистики ────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
