import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/tasks/providers/category_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _DayData {
  final String label;
  final int done;
  final int total;
  const _DayData({
    required this.label,
    required this.done,
    required this.total,
  });
}

class _CatStat {
  final TaskCategory category;
  final int total;
  final int done;
  final int pct;
  final Color color;
  const _CatStat({
    required this.category,
    required this.total,
    required this.done,
    required this.pct,
    required this.color,
  });
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  // Цвет категории: сначала из colorHex, потом из CategoryColors
  Color _colorForCategory(TaskCategory cat) {
    if (cat.colorHex != null && cat.colorHex!.isNotEmpty) {
      try {
        return Color(int.parse(cat.colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return CategoryColors.forId(cat.id);
  }

  // Иконка категории: SVG из assets/icons/categories/ или стандартная
  Widget _iconForCategory(TaskCategory cat, {double size = 18, Color? color}) {
    if (cat.iconAsset != null && cat.iconAsset!.isNotEmpty) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color ?? Colors.white, BlendMode.srcIn),
        child: SvgPicture.asset(
          'assets/icons/categories/${cat.iconAsset}',
          width: size,
          height: size,
        ),
      );
    }
    return AppIcons.category(cat.id, size: size, color: color);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(tasksNotifierProvider);
    // ← берём реальные категории пользователя
    final categories = ref.watch(categoriesProvider);

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final weekTasks = allTasks
        .where((t) => t.date != null && !t.date!.isBefore(weekAgo))
        .toList();
    final monthTasks = allTasks
        .where((t) => t.date != null && !t.date!.isBefore(monthAgo))
        .toList();

    final weekDone = weekTasks.where((t) => t.isDone).length;
    final monthDone = monthTasks.where((t) => t.isDone).length;

    final last7Days = List<_DayData>.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dt = allTasks
          .where(
            (t) =>
                t.date != null &&
                t.date!.year == day.year &&
                t.date!.month == day.month &&
                t.date!.day == day.day,
          )
          .toList();
      return _DayData(
        label: _dayNames[day.weekday - 1],
        done: dt.where((t) => t.isDone).length,
        total: dt.length,
      );
    });

    final maxDayTotal = last7Days
        .fold(0, (m, d) => d.total > m ? d.total : m)
        .clamp(1, 99);

    // ← статистика по реальным категориям пользователя
    final catStats = categories.map((cat) {
      final ct = allTasks.where((t) => t.category.id == cat.id).toList();
      final done = ct.where((t) => t.isDone).length;
      return _CatStat(
        category: cat,
        total: ct.length,
        done: done,
        pct: ct.isEmpty ? 0 : ((done / ct.length) * 100).round(),
        color: _colorForCategory(cat),
      );
    }).toList();

    final weakest =
        (catStats.where((c) => c.total > 0).toList()
              ..sort((a, b) => a.pct.compareTo(b.pct)))
            .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Хедер ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: AppIcons.arrow(size: 22),
                    ),
                    const SizedBox(width: 14),
                    Text('Аналитика', style: AppTextStyles.h2),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── За неделю / за месяц ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'За неделю',
                        value: '$weekDone',
                        sub: 'из ${weekTasks.length} задач',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'За месяц',
                        value: '$monthDone',
                        sub: 'из ${monthTasks.length} задач',
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── График 7 дней ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppPlate(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Последние 7 дней',
                        style: AppTextStyles.bodyL.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: last7Days
                              .map(
                                (d) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          height: 85,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height:
                                                      d.done / maxDayTotal * 85,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            4,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Container(
                                                  height:
                                                      (d.total - d.done) /
                                                      maxDayTotal *
                                                      85,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.border,
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            4,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          d.label,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend(color: AppColors.primary, label: 'Выполнено'),
                          const SizedBox(width: 16),
                          _Legend(color: AppColors.border, label: 'Осталось'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── По категориям ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppPlate(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'По категориям',
                        style: AppTextStyles.bodyL.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (catStats.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Нет категорий',
                              style: AppTextStyles.bodyM.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...catStats.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: c.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: _iconForCategory(
                                          c.category,
                                          size: 18,
                                          color: c.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        c.category.name,
                                        style: AppTextStyles.bodyM.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${c.done}/${c.total}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: c.pct / 100,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation(c.color),
                                    minHeight: 5,
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

            // ── Слабая категория ──
            if (weakest != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: weakest.color.withValues(alpha: 0.2),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          weakest.color.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: weakest.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _iconForCategory(
                              weakest.category,
                              size: 22,
                              color: weakest.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Слабая сторона',
                                style: AppTextStyles.bodyM.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${weakest.category.name} — ${weakest.pct}% выполнения',
                                style: AppTextStyles.caption.copyWith(
                                  color: weakest.color,
                                ),
                              ),
                            ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppPlate(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            sub,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
