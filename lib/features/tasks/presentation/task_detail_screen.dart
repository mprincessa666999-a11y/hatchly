import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:intl/intl.dart';

// Иконка категории с цветом
Widget _catIcon(String? assetPath, String? colorHex, {double size = 22}) {
  if (assetPath != null && assetPath.isNotEmpty && colorHex != null) {
    try {
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
    } catch (_) {}
  }
  return AppIcons.category(assetPath ?? 'other', size: size);
}

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksNotifierProvider);
    final task = tasks.where((t) => t.id == taskId).firstOrNull;

    if (task == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Text(
              'Задача не найдена',
              style: AppTextStyles.bodyL.copyWith(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final catColor = task.category.colorHex != null
        ? Color(int.parse(task.category.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Хедер ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: AppIcons.arrow(size: 22),
                  ),
                  const Spacer(),
                  // Кнопка редактировать
                  GestureDetector(
                    onTap: () => context.push('/tasks/new', extra: task),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Иконка категории + название ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _catIcon(
                        task.category.iconAsset,
                        task.category.colorHex,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.category.name,
                          style: AppTextStyles.caption.copyWith(
                            color: catColor,
                          ),
                        ),
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Детали ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      label: 'Дата',
                      value: task.date != null
                          ? DateFormat('d MMMM yyyy', 'ru').format(task.date!)
                          : 'Не указана',
                      onTap: () => context.push('/tasks/new', extra: task),
                    ),
                    _DetailRow(
                      icon: const Icon(
                        Icons.alarm_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      label: 'Время',
                      value: task.time ?? 'Весь день',
                      onTap: () => context.push('/tasks/new', extra: task),
                    ),
                    _DetailRow(
                      icon: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      label: 'Исполнитель',
                      value: task.assignedTo,
                      onTap: () => context.push('/tasks/new', extra: task),
                    ),
                    _DetailRow(
                      icon: Icon(
                        task.isDone
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        color: task.isDone
                            ? const Color(0xFF34D399)
                            : AppColors.primary,
                        size: 22,
                      ),
                      label: 'Статус',
                      value: task.isDone ? 'Выполнена' : 'В процессе',
                      onTap: () => ref
                          .read(tasksNotifierProvider.notifier)
                          .toggleDone(task.id),
                      valueColor: task.isDone
                          ? const Color(0xFF34D399)
                          : Colors.white,
                    ),
                    if (task.recurrenceType != RecurrenceType.none)
                      _DetailRow(
                        icon: const Icon(
                          Icons.repeat_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        label: 'Повторение',
                        value: _recurrenceLabel(task.recurrenceType),
                        onTap: () => context.push('/tasks/new', extra: task),
                      ),
                    if (task.reminderMinutes != null)
                      _DetailRow(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        label: 'Напоминание',
                        value: _reminderLabel(task.reminderMinutes!),
                        onTap: () => context.push('/tasks/new', extra: task),
                      ),
                  ],
                ),
              ),
            ),

            // ── Кнопки ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: GestureDetector(
                onTap: () {
                  ref.read(tasksNotifierProvider.notifier).deleteTask(task.id);
                  context.pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Удалить задачу',
                      style: AppTextStyles.bodyM.copyWith(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: () => context.push('/tasks/new', extra: task),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF16001), Color(0xFFC10801)],
                    ),
                  ),
                  child: Center(
                    child: Text('Редактировать', style: AppTextStyles.button),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Каждый день';
      case RecurrenceType.weekly:
        return 'Каждую неделю';
      case RecurrenceType.monthly:
        return 'Каждый месяц';
      case RecurrenceType.none:
        return 'Не повторяется';
    }
  }

  String _reminderLabel(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? 'За $h ч $m мин' : 'За $h ч';
    }
    return 'За $minutes мин';
  }
}

class _DetailRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
