import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/pet_assets.dart';
import 'package:couple_app/core/services/notification_service.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/tasks/providers/category_provider.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';
import 'package:couple_app/features/home/widgets/hero_progress_card.dart';
import 'package:couple_app/features/home/widgets/category_progress_tile.dart';
import 'package:couple_app/features/tasks/presentation/widgets/task_card.dart';

final GlobalKey<HeroProgressCardState> heroProgressCardKey =
    GlobalKey<HeroProgressCardState>();

Widget _buildColoredIcon(
  String? assetPath,
  String colorHex, {
  double size = 28,
}) {
  if (assetPath == null || assetPath.isEmpty) return const SizedBox.shrink();
  return ColorFiltered(
    colorFilter: ColorFilter.mode(
      Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
      BlendMode.srcIn,
    ),
    child: SvgPicture.asset(
      'assets/icons/categories/$assetPath',
      width: size,
      height: size,
    ),
  );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isTasksExpanded = false;
  static const int _visibleTasksCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(tasksNotifierProvider.notifier).initStorage();
      ref.read(categoriesProvider.notifier).initStorage();
      if (mounted) _checkYesterdayTasks();
    });
  }

  void _checkYesterdayTasks() {
    final allTasks = ref.read(tasksNotifierProvider);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final undone = allTasks.where((t) {
      if (t.date == null || t.isDone) return false;
      return t.date!.day == yesterday.day &&
          t.date!.month == yesterday.month &&
          t.date!.year == yesterday.year;
    }).toList();
    if (undone.isNotEmpty) {
      NotificationService().showPetReminder(
        petName: 'Чуня',
        petId: 'chunya',
        taskTitle: undone.first.title,
      );
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(tasksNotifierProvider.notifier).initStorage();
    ref.invalidate(todayTasksProvider);
    ref.invalidate(partnerProgressProvider);
  }

  void _showCreateGroupDialog() {
    final controller = TextEditingController();
    String selectedAssetPath = 'broom.svg';
    String selectedColor = '#F16001';

    final svgOptions = [
      'black_hole.svg',
      'broom.svg',
      'bus.svg',
      'case.svg',
      'cleaning.svg',
      'cooking.svg',
      'cosmetic.svg',
      'crown.svg',
      'dumbbells.svg',
      'events.svg',
      'flag.svg',
      'flame.svg',
      'funny_circle.svg',
      'gamepad.svg',
      'ghost_smile.svg',
      'hand-heart.svg',
      'hanger.svg',
      'health.svg',
      'magic_stick.svg',
      'pallete.svg',
      'pen.svg',
      'perfume.svg',
      'pets.svg',
      'plaster.svg',
      'shool.svg',
      'smile_circle.svg',
      'stars.svg',
    ];

    final colors = [
      '#F16001',
      '#C10801',
      '#FF7043',
      '#FF6B6B',
      '#E17055',
      '#D63031',
      '#B71540',
      '#6D214F',
      '#34D399',
      '#55EFC4',
      '#00CEC9',
      '#00B894',
      '#27AE60',
      '#2ECC71',
      '#A8E063',
      '#6AB04C',
      '#6C5CE7',
      '#A29BFE',
      '#74B9FF',
      '#64B5F6',
      '#182C61',
      '#2C3E50',
      '#8E44AD',
      '#9B59B6',
      '#FFCA28',
      '#FDCB6E',
      '#FD79A8',
      '#E84393',
      '#F9CA24',
      '#F0932B',
      '#EAB543',
      '#FFC312',
      '#80CBC4',
      '#FFFFFF',
      '#B2BEC3',
      '#636E72',
      '#DFE6E9',
      '#2D3436',
      '#95A5A6',
      '#7F8C8D',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Text('Новая группа', style: AppTextStyles.h3),
                  const Spacer(),
                  const SizedBox(width: 22),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF2C2C2E),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Название группы',
                  hintStyle: const TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Цвет', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: colors.map((hex) {
                  final isSelected = selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Иконка', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: svgOptions.map((asset) {
                  final isSelected = selectedAssetPath == asset;
                  final color = Color(
                    int.parse(selectedColor.replaceFirst('#', '0xFF')),
                  );
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedAssetPath = asset),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        child: SvgPicture.asset(
                          'assets/icons/categories/$asset',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  ref
                      .read(categoriesProvider.notifier)
                      .addCategory(
                        TaskCategory(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          iconAsset: selectedAssetPath,
                          colorHex: selectedColor,
                        ),
                      );
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF16001), Color(0xFFC10801)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Создать',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = ref.watch(todayTasksProvider);
    final allTasks = ref.watch(tasksNotifierProvider);
    final partnerProgress = ref.watch(partnerProgressProvider);
    final profile = ref.watch(profileProvider);
    final currentStreak = ref.watch(streakProvider);
    final categories = ref.watch(categoriesProvider);

    // ← FIX: ref.listen прямо в build, без Builder
    ref.listen<List<Task>>(tasksNotifierProvider, (previous, next) {
      if (previous != null && previous.length != next.length) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              previous.length > next.length
                  ? 'Задача удалена'
                  : 'Задача добавлена',
            ),
            backgroundColor: Colors.grey[800],
            action: SnackBarAction(
              label: 'Отменить',
              textColor: const Color(0xFFF16001),
              onPressed: () =>
                  ref.read(tasksNotifierProvider.notifier).undoLastAction(),
            ),
          ),
        );
      }
    });

    final hasMoreTasks = todayTasks.length > _visibleTasksCount;
    final visibleTasks = _isTasksExpanded
        ? todayTasks
        : todayTasks.take(_visibleTasksCount).toList();

    // Аватар профиля
    ImageProvider? avatarImage;
    if (profile.photoPath != null) {
      avatarImage = profile.photoPath!.startsWith('http')
          ? NetworkImage(profile.photoPath!) as ImageProvider
          : FileImage(File(profile.photoPath!));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Шапка профиля ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/profile'),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFD9D9D9),
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name
                                      : 'Без имени',
                                  style: AppTextStyles.h3.copyWith(
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => context.push('/search'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Hero карточка ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HeroProgressCard(
                    key: heroProgressCardKey,
                    progress: partnerProgress,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Стрик ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.15),
                          Colors.deepOrange.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Серия дней',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$currentStreak дней подряд!',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Задачи на сегодня ──
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Задачи на сегодня',
                  taskCount: todayTasks.length,
                  onAdd: () => context.push('/tasks/new'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (todayTasks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        PetAssets.sadPetWidget(petId: 'chunya', size: 120),
                        const SizedBox(height: 16),
                        Text(
                          'Задач пока нет',
                          style: AppTextStyles.bodyM.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Добавь задачу, чтобы Чуня не грустил',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: visibleTasks.length,
                    onReorder: (oldIndex, newIndex) => ref
                        .read(tasksNotifierProvider.notifier)
                        .reorderTasks(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return Padding(
                        key: ValueKey(task.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.white24,
                                  size: 20,
                                ),
                              ),
                            ),
                            Expanded(child: TaskCard(task: task)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // ── Кнопка Ещё ──
              if (hasMoreTasks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isTasksExpanded = !_isTasksExpanded),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcons.custom(
                            _isTasksExpanded ? 'close' : 'open',
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isTasksExpanded
                                ? 'Свернуть'
                                : 'Ещё ${todayTasks.length - _visibleTasksCount}',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Добавить задачу ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _AddTaskButton(
                    onTap: () => context.push('/tasks/new'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Задачи по группам ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Задачи по группам', style: AppTextStyles.h2),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showCreateGroupDialog,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final category = categories[i];
                    final categoryTasks = allTasks
                        .where((t) => t.category.id == category.id)
                        .toList();
                    final done = categoryTasks.where((t) => t.isDone).length;
                    return Dismissible(
                      key: ValueKey(category.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => ref
                          .read(categoriesProvider.notifier)
                          .deleteCategory(category.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/category/${category.id}',
                          extra: category,
                        ),
                        child: CategoryProgressTile(
                          group: TaskCategoryGroup(
                            category: category,
                            totalCount: categoryTasks.length,
                            doneCount: done,
                          ),
                          categoryId: category.id,
                          customIcon: _buildColoredIcon(
                            category.iconAsset,
                            category.colorHex ?? '#FFFFFF',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int taskCount;
  final VoidCallback onAdd;
  const _SectionHeader({
    required this.title,
    required this.taskCount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.h2),
          const SizedBox(width: 8),
          Text(
            '$taskCount',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTaskButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Colors.white60,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              'Создать новую задачу',
              style: AppTextStyles.bodyL.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
