import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/pet_assets.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _isExpanded = false;

  static const _weekDays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  static const _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  List<DateTime> get _currentWeekDates {
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksByDateProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Календарь (без хедера со стрелкой) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppPlate(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Заголовок месяца
                    Row(
                      children: [
                        if (_isExpanded)
                          GestureDetector(
                            onTap: () => setState(
                              () => _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month - 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const Spacer(),
                        Text(
                          _months[_focusedMonth.month - 1],
                          style: AppTextStyles.h3,
                        ),
                        const Spacer(),
                        if (_isExpanded)
                          GestureDetector(
                            onTap: () => setState(
                              () => _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month + 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isExpanded = !_isExpanded),
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Дни недели
                    Row(
                      children: _weekDays.map((day) {
                        final isWeekend = day == 'сб' || day == 'вс';
                        return Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: AppTextStyles.caption.copyWith(
                                color: isWeekend
                                    ? AppColors.calendarWeekend
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 8),

                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: _WeekView(
                        weekDates: _currentWeekDates,
                        selectedDate: _selectedDate,
                        onDateSelected: (d) =>
                            setState(() => _selectedDate = d),
                      ),
                      secondChild: _MonthView(
                        focusedMonth: _focusedMonth,
                        selectedDate: _selectedDate,
                        onDateSelected: (d) => setState(() {
                          _selectedDate = d;
                          _focusedMonth = d;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Список задач ──
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PetAssets.sadPetWidget(petId: 'chunya', size: 110),
                          const SizedBox(height: 16),
                          Text(
                            'Нет задач на этот день',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => context.push(
                              '/tasks/new',
                              extra: _selectedDate,
                            ),
                            child: Text(
                              'Добавить задачу',
                              style: AppTextStyles.bodyL.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == tasks.length) {
                          return _AddTaskButton(
                            onTap: () => context.push(
                              '/tasks/new',
                              extra: _selectedDate,
                            ),
                          );
                        }
                        return _TaskTile(task: tasks[i]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  final List<DateTime> weekDates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekView({
    required this.weekDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: weekDates.map((date) {
        final isSelected = _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final isWeekend = date.weekday == 6 || date.weekday == 7;
        return Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: AppTextStyles.bodyM.copyWith(
                    color: isSelected
                        ? AppColors.white
                        : isWeekend
                        ? AppColors.calendarWeekend
                        : AppColors.textPrimary,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MonthView extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthView({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final days = <DateTime>[];
    for (int i = 1; i < firstDay.weekday; i++) {
      days.add(firstDay.subtract(Duration(days: firstDay.weekday - i)));
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(focusedMonth.year, focusedMonth.month, i));
    }
    while (days.length % 7 != 0) {
      days.add(
        lastDay.add(
          Duration(days: days.length - lastDay.day - firstDay.weekday + 2),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        final isCurrentMonth = date.month == focusedMonth.month;
        final isSelected = _isSameDay(date, selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final isWeekend = date.weekday == 6 || date.weekday == 7;
        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: AppTextStyles.bodyM.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : !isCurrentMonth
                      ? AppColors.calendarOtherMonth
                      : isWeekend
                      ? AppColors.calendarWeekend
                      : AppColors.textPrimary,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.day == b.day && a.month == b.month && a.year == b.year;

class _TaskTile extends ConsumerWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/tasks/${task.id}'),
      child: AppPlate(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AppIcons.category(task.category.id, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
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
                        task.time ?? 'Целый день',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(tasksNotifierProvider.notifier).toggleDone(task.id),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: task.isDone ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: task.isDone
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: task.isDone
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.white,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
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
      child: AppPlate(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textSecondary, width: 1.5),
              ),
              child: const Icon(
                Icons.add,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Создать новую задачу',
              style: AppTextStyles.bodyL.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
