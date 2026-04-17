import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/pet_assets.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/tasks/presentation/widgets/task_card.dart';

Widget _buildCatIcon(TaskCategory cat, {double size = 26}) {
  final asset = cat.iconAsset;
  final hex = cat.colorHex;
  if (asset != null && asset.isNotEmpty && hex != null && hex.isNotEmpty) {
    try {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color(int.parse(hex.replaceFirst('#', '0xFF'))),
          BlendMode.srcIn,
        ),
        child: SvgPicture.asset(
          'assets/icons/categories/$asset',
          width: size,
          height: size,
        ),
      );
    } catch (_) {}
  }
  return AppIcons.category(cat.id, size: size);
}

class CategoryTasksScreen extends ConsumerWidget {
  final TaskCategory category;
  const CategoryTasksScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(tasksNotifierProvider);
    final categoryTasks = allTasks
        .where((t) => t.category.id == category.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Хедер ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: AppIcons.arrow(size: 22),
                  ),
                  const Spacer(),
                  _buildCatIcon(category, size: 26),
                  const SizedBox(width: 10),
                  Text(category.name, style: AppTextStyles.h2),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${categoryTasks.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: categoryTasks.isEmpty
                  ? _EmptyCategory(category: category)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categoryTasks.length + 1,
                      itemBuilder: (context, i) {
                        if (i < categoryTasks.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TaskCard(task: categoryTasks[i]),
                          );
                        }
                        return _AddTaskButton(
                          onTap: () =>
                              context.push('/tasks/new', extra: category),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  final TaskCategory category;
  const _EmptyCategory({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PetAssets.sadPetWidget(petId: 'chunya', size: 120),
        const SizedBox(height: 20),
        Text(
          'Задач в «${category.name}» пока нет',
          style: AppTextStyles.bodyM.copyWith(
            color: Colors.white.withValues(alpha: 0.35),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Добавь первую — питомец будет рад!',
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => context.push('/tasks/new', extra: category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF16001), Color(0xFFC10801)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Добавить задачу',
                  style: AppTextStyles.bodyM.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Colors.white38,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Создать новую задачу',
              style: AppTextStyles.bodyM.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
