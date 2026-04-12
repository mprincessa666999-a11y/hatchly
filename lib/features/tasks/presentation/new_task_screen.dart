import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/tasks/providers/category_provider.dart';
import 'package:couple_app/features/friends/presentation/friends_screen.dart'
    show relationsProvider, FamilyMember;
import 'package:intl/intl.dart';

Widget _catIcon(String? assetPath, String colorHex, {double size = 20}) {
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

Widget _sheetHandle() => Center(
  child: Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

class NewTaskScreen extends ConsumerStatefulWidget {
  final TaskCategory? initialCategory;
  final Task? editTask;
  final DateTime? initialDate;

  const NewTaskScreen({
    super.key,
    this.initialCategory,
    this.editTask,
    this.initialDate,
  });

  @override
  ConsumerState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends ConsumerState<NewTaskScreen> {
  final _textController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskCategory? _selectedCategory;
  String _selectedAssignee = 'Вы';
  bool _reminderEnabled = false;
  int _reminderMinutes = 15;

  bool get _isEditing => widget.editTask != null;

  static const _reminderOptions = [5, 10, 15, 30, 60, 120];

  static const _colors = [
    // Оранжевые / красные
    '#F16001', '#C10801', '#FF7043', '#FF6B6B',
    '#E17055', '#D63031', '#B71540', '#6D214F',
    // Зелёные
    '#34D399', '#55EFC4', '#00CEC9', '#00B894',
    '#27AE60', '#2ECC71', '#A8E063', '#6AB04C',
    // Синие / фиолетовые
    '#6C5CE7', '#A29BFE', '#74B9FF', '#64B5F6',
    '#182C61', '#2C3E50', '#8E44AD', '#9B59B6',
    // Жёлтые / розовые
    '#FFCA28', '#FDCB6E', '#FD79A8', '#E84393',
    '#F9CA24', '#F0932B', '#EAB543', '#FFC312',
    // Нейтральные
    '#80CBC4', '#FFFFFF', '#B2BEC3', '#636E72',
    '#DFE6E9', '#2D3436', '#95A5A6', '#7F8C8D',
  ];

  static const _svgOptions = [
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

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.editTask!;
      _textController.text = t.title;
      _selectedDate = t.date;
      _selectedCategory = t.category;
      _selectedAssignee = t.assignedTo;
      _reminderEnabled = t.reminderMinutes != null;
      _reminderMinutes = t.reminderMinutes ?? 15;
      if (t.time != null) {
        final p = t.time!.split(':');
        if (p.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(p[0]) ?? 0,
            minute: int.tryParse(p[1]) ?? 0,
          );
        }
      }
    } else {
      _selectedCategory = widget.initialCategory;
      _selectedDate = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtReminder(int m) {
    if (m >= 60) {
      final h = m ~/ 60;
      final r = m % 60;
      return r > 0 ? 'За $h ч $r мин' : 'За $h ч';
    }
    return 'За $m мин';
  }

  void _save() {
    final title = _textController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введите название', style: AppTextStyles.bodyM),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }
    final timeStr = _selectedTime != null ? _fmt(_selectedTime!) : null;
    final cat =
        _selectedCategory ??
        const TaskCategory(
          id: 'other',
          name: 'Другое',
          iconAsset: 'stars.svg',
          colorHex: '#FFFFFF',
        );
    final reminder = _reminderEnabled ? _reminderMinutes : null;

    if (_isEditing) {
      ref
          .read(tasksNotifierProvider.notifier)
          .editTask(
            id: widget.editTask!.id,
            title: title,
            category: cat,
            date: _selectedDate ?? widget.editTask!.date,
            time: timeStr,
            reminderMinutes: reminder,
            assignedTo: _selectedAssignee,
          );
    } else {
      ref
          .read(tasksNotifierProvider.notifier)
          .addTask(
            title: title,
            category: cat,
            date: _selectedDate ?? DateTime.now(),
            time: timeStr,
            reminderMinutes: reminder,
            assignedTo: _selectedAssignee,
          );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Хедер
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: AppIcons.arrow(size: 22),
                  ),
                  const Spacer(),
                  Text(
                    _isEditing ? 'Редактирование' : 'Новая задача',
                    style: AppTextStyles.h3,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поле ввода
                    TextField(
                      controller: _textController,
                      autofocus: true,
                      maxLines: null,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Что нужно сделать?',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _FlatParam(
                      icon: Icons.calendar_month_outlined,
                      label: _selectedDate != null
                          ? DateFormat(
                              'd MMMM yyyy',
                              'ru',
                            ).format(_selectedDate!)
                          : 'Дата',
                      isSet: _selectedDate != null,
                      onTap: _pickDate,
                    ),

                    _FlatParam(
                      iconWidget: _selectedCategory?.iconAsset != null
                          ? _catIcon(
                              _selectedCategory!.iconAsset,
                              _selectedCategory!.colorHex ?? '#FFFFFF',
                              size: 20,
                            )
                          : null,
                      icon: Icons.grid_view_rounded,
                      label: _selectedCategory?.name ?? 'Категория',
                      isSet: _selectedCategory != null,
                      onTap: _pickCategory,
                    ),

                    _FlatParam(
                      icon: Icons.access_time_rounded,
                      label: _selectedTime != null
                          ? _fmt(_selectedTime!)
                          : 'Время',
                      isSet: _selectedTime != null,
                      onTap: _pickTime,
                    ),

                    _FlatParam(
                      icon: Icons.person_outline_rounded,
                      label: _selectedAssignee,
                      isSet: true,
                      onTap: _pickAssignee,
                    ),

                    _FlatParam(
                      icon: Icons.notifications_outlined,
                      label: _reminderEnabled
                          ? _fmtReminder(_reminderMinutes)
                          : 'Напоминание',
                      isSet: _reminderEnabled,
                      trailing: _ReminderToggle(
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                      ),
                      onTap: () =>
                          setState(() => _reminderEnabled = !_reminderEnabled),
                    ),

                    if (_reminderEnabled) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _reminderOptions.map((min) {
                          final sel = _reminderMinutes == min;
                          return GestureDetector(
                            onTap: () => setState(() => _reminderMinutes = min),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _fmtReminder(min),
                                style: AppTextStyles.bodyM.copyWith(
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('🐾', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(
                            'Питомец напомнит о задаче!',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Кнопка сохранить
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF16001), Color(0xFFC10801)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _isEditing ? 'Сохранить изменения' : 'Сохранить',
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text('Время задачи', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            _SheetOption(
              label: 'Весь день',
              icon: Icons.wb_sunny_outlined,
              onTap: () => Navigator.pop(ctx, 'allday'),
            ),
            const SizedBox(height: 10),
            _SheetOption(
              label: 'Выбрать время',
              icon: Icons.alarm_outlined,
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
          ],
        ),
      ),
    );
    if (choice == 'allday')
      setState(() => _selectedTime = null);
    else if (choice == 'pick') {
      final t = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (t != null) setState(() => _selectedTime = t);
    }
  }

  Future<void> _pickCategory() async {
    final categories = ref.read(categoriesProvider);
    final result = await showModalBottomSheet<TaskCategory>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CategorySheet(
        categories: categories,
        selectedId: _selectedCategory?.id,
        colors: _colors,
        svgOptions: _svgOptions,
        onSelect: (cat) => Navigator.pop(ctx, cat),
        onCreated: (cat) {
          ref.read(categoriesProvider.notifier).addCategory(cat);
          Navigator.pop(ctx, cat);
        },
      ),
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  Future<void> _pickAssignee() async {
    // Берём реальных членов семьи из relationsProvider
    final familyMembers = ref
        .read(relationsProvider)
        .where((m) => m.isFamily)
        .toList();
    // "Вы" + члены семьи
    final assignees = ['Вы', ...familyMembers.map((m) => m.name)];

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text('Исполнитель', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            if (assignees.length == 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Добавьте друзей в семью,\nчтобы назначать им задачи',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ...assignees.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SheetOption(
                  label: name,
                  icon: Icons.person_outline,
                  isSelected: name == _selectedAssignee,
                  onTap: () => Navigator.pop(ctx, name),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _selectedAssignee = result);
  }
}

// ── Лист категорий ────────────────────────────────────────────────────
class _CategorySheet extends StatefulWidget {
  final List<TaskCategory> categories;
  final String? selectedId;
  final List<String> colors;
  final List<String> svgOptions;
  final ValueChanged<TaskCategory> onSelect;
  final ValueChanged<TaskCategory> onCreated;

  const _CategorySheet({
    required this.categories,
    required this.selectedId,
    required this.colors,
    required this.svgOptions,
    required this.onSelect,
    required this.onCreated,
  });

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  bool _creating = false;
  final _nameCtrl = TextEditingController();
  String _color = '#F16001';
  String _asset = 'stars.svg';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _creating ? _buildCreate() : _buildList();

  Widget _buildList() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetHandle(),
        const SizedBox(height: 20),
        Text('Категория', style: AppTextStyles.h3),
        const SizedBox(height: 20),

        if (widget.categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Нет категорий. Создайте первую!',
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.categories.map((cat) {
              final sel = cat.id == widget.selectedId;
              final color = cat.colorHex != null
                  ? Color(int.parse(cat.colorHex!.replaceFirst('#', '0xFF')))
                  : AppColors.primary;
              return GestureDetector(
                onTap: () => widget.onSelect(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? color.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat.iconAsset != null) ...[
                        _catIcon(
                          cat.iconAsset,
                          cat.colorHex ?? '#FFFFFF',
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        cat.name,
                        style: AppTextStyles.bodyM.copyWith(
                          color: sel ? color : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: () => setState(() => _creating = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Создать новую категорию',
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCreate() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _creating = false),
              child: AppIcons.arrow(size: 22),
            ),
            const SizedBox(width: 12),
            Text('Новая категория', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            fillColor: const Color(0xFF2C2C2E),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Название категории',
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Цвет',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.colors.map((hex) {
            final sel = _color == hex;
            return GestureDetector(
              onTap: () => setState(() => _color = hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                  border: Border.all(
                    color: sel ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        const Text(
          'Иконка',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.svgOptions.map((asset) {
            final sel = _asset == asset;
            final color = Color(int.parse(_color.replaceFirst('#', '0xFF')));
            return GestureDetector(
              onTap: () => setState(() => _asset = asset),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sel
                      ? color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  child: SvgPicture.asset(
                    'assets/icons/categories/$asset',
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),
        GestureDetector(
          onTap: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            widget.onCreated(
              TaskCategory(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                iconAsset: _asset,
                colorHex: _color,
              ),
            );
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
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Плоский параметр ──────────────────────────────────────────────────
class _FlatParam extends StatelessWidget {
  final IconData icon;
  final Widget? iconWidget;
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FlatParam({
    required this.icon,
    required this.label,
    required this.isSet,
    required this.onTap,
    this.iconWidget,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child:
                  iconWidget ??
                  Icon(
                    icon,
                    size: 20,
                    color: isSet ? AppColors.primary : Colors.white24,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSet ? Colors.white : Colors.white38,
                  fontSize: 16,
                  fontWeight: isSet ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            trailing ?? AppIcons.arrow(size: 16, color: Colors.white12),
          ],
        ),
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ReminderToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? AppColors.primary : Colors.white12,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyL.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
