import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/home/widgets/hero_progress_card.dart';
import 'package:couple_app/features/home/pet_system.dart';

// Иконка категории с цветом
Widget _buildCatIcon(TaskCategory cat, {double size = 28}) {
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

class TaskCard extends ConsumerStatefulWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleDone() {
    HapticFeedback.mediumImpact();
    final wasNotDone = !widget.task.isDone;
    ref.read(tasksNotifierProvider.notifier).toggleDone(widget.task.id);
    if (wasNotDone) {
      _scaleController.forward().then((_) => _scaleController.reverse());
      final petState = ref.read(petSystemProvider);
      final currentPet = allPets[petState.currentPetIndex];
      heroProgressCardKey.currentState?.celebrate(currentPet.glowColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) =>
          ref.read(tasksNotifierProvider.notifier).deleteTask(widget.task.id),
      child: GestureDetector(
        onTap: () => context.push('/tasks/${widget.task.id}'),
        child: AppPlate(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _buildCatIcon(widget.task.category, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: AppTextStyles.bodyL.copyWith(
                        decoration: widget.task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: widget.task.isDone
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.alarm_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.task.time ?? 'Целый день',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleDone,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: widget.task.isDone
                            ? AppColors.primary
                            : AppColors.transparent,
                        border: Border.all(
                          color: widget.task.isDone
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          width: 1.5,
                        ),
                      ),
                      child: widget.task.isDone
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.white,
                            )
                          : null,
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
}
