import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/core/ui/pet_assets.dart';

// ── МОДЕЛИ ────────────────────────────────────────────────────────────
enum NoteType { note, ideas, shoppingList, password }

extension NoteTypeExt on NoteType {
  String get label {
    switch (this) {
      case NoteType.note:
        return 'Заметка';
      case NoteType.ideas:
        return 'Идея';
      case NoteType.shoppingList:
        return 'Список покупок';
      case NoteType.password:
        return 'Важное';
    }
  }

  Widget getIcon({double size = 24, Color? color}) {
    switch (this) {
      case NoteType.note:
        return AppIcons.note(size: size, color: color);
      case NoteType.ideas:
        return AppIcons.ideas(size: size, color: color);
      case NoteType.shoppingList:
        return AppIcons.purchases(size: size, color: color);
      case NoteType.password:
        return AppIcons.important(size: size, color: color);
    }
  }

  Color get accentColor {
    switch (this) {
      case NoteType.note:
        return const Color(0xFF64B5F6);
      case NoteType.ideas:
        return const Color(0xFFFFCA28);
      case NoteType.shoppingList:
        return const Color(0xFF80CBC4);
      case NoteType.password:
        return const Color(0xFFFF7043);
    }
  }
}

class ShoppingItem {
  String title;
  bool isChecked;
  ShoppingItem({required this.title, this.isChecked = false});
  ShoppingItem copy() => ShoppingItem(title: title, isChecked: isChecked);
  Map<String, dynamic> toMap() => {'title': title, 'isChecked': isChecked};
  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
    title: m['title'] as String,
    isChecked: m['isChecked'] as bool? ?? false,
  );
}

class NoteItem {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final List<ShoppingItem> shoppingItems;
  final bool isPrivate;
  final DateTime createdAt;

  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.shoppingItems,
    this.isPrivate = false,
    required this.createdAt,
  });

  NoteItem copyWith({
    String? title,
    String? content,
    List<ShoppingItem>? shoppingItems,
    bool? isPrivate,
  }) {
    return NoteItem(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type,
      shoppingItems: shoppingItems ?? this.shoppingItems,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type.index,
    'shoppingItems': shoppingItems.map((e) => e.toMap()).toList(),
    'isPrivate': isPrivate,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NoteItem.fromMap(Map<String, dynamic> m) => NoteItem(
    id: m['id'] as String,
    title: m['title'] as String,
    content: m['content'] as String,
    type: NoteType.values[m['type'] as int? ?? 0],
    shoppingItems:
        (m['shoppingItems'] as List?)
            ?.map((e) => ShoppingItem.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    isPrivate: m['isPrivate'] as bool? ?? false,
    createdAt: m['createdAt'] != null
        ? DateTime.parse(m['createdAt'] as String)
        : DateTime.now(),
  );
}

// ── ПРОВАЙДЕР ─────────────────────────────────────────────────────────
class NotesNotifier extends StateNotifier<List<NoteItem>> {
  NotesNotifier() : super([]);

  void initStorage() {
    final saved = StorageService().loadNotes();
    if (saved.isNotEmpty) {
      state = saved.map((m) => NoteItem.fromMap(m)).toList();
    }
  }

  Future<void> _save() async =>
      StorageService().saveNotes(state.map((n) => n.toMap()).toList());

  void addNote(NoteItem note) {
    state = [note, ...state];
    _save();
  }

  void updateNote(NoteItem note) {
    state = [
      for (final n in state)
        if (n.id == note.id) note else n,
    ];
    _save();
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
    _save();
  }
}

final notesNotifierProvider =
    StateNotifierProvider<NotesNotifier, List<NoteItem>>(
      (ref) => NotesNotifier(),
    );

// ── ГЛАВНЫЙ ЭКРАН ─────────────────────────────────────────────────────
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(notesNotifierProvider.notifier).initStorage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Заметки', style: AppTextStyles.h2),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showTypeSelector(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PetAssets.sadPetWidget(petId: 'chunya', size: 120),
                          const SizedBox(height: 20),
                          Text(
                            'Заметок пока нет',
                            style: AppTextStyles.bodyM.copyWith(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите + чтобы создать',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _NoteCard(note: notes[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NoteTypeSheet(),
    );
  }
}

// ── ЭКРАН СОЗДАНИЯ / РЕДАКТИРОВАНИЯ ───────────────────────────────────
class NoteDetailScreen extends ConsumerStatefulWidget {
  final NoteItem? note;
  final NoteType initialType;
  const NoteDetailScreen({super.key, this.note, required this.initialType});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<ShoppingItem> _shoppingItems;
  late List<TextEditingController> _shoppingControllers;
  bool _isPrivate = false;

  NoteType get _type => widget.note?.type ?? widget.initialType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _isPrivate = widget.note?.isPrivate ?? false;
    _shoppingItems = widget.note != null
        ? widget.note!.shoppingItems.map((e) => e.copy()).toList()
        : [];
    _shoppingControllers = _shoppingItems
        .map((e) => TextEditingController(text: e.title))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (final c in _shoppingControllers) c.dispose();
    super.dispose();
  }

  void _syncShoppingTitles() {
    for (
      int i = 0;
      i < _shoppingItems.length && i < _shoppingControllers.length;
      i++
    ) {
      _shoppingItems[i].title = _shoppingControllers[i].text;
    }
  }

  void _onSave() {
    _syncShoppingTitles();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final note = NoteItem(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? _type.label : title,
      content: content,
      type: _type,
      shoppingItems: _shoppingItems,
      isPrivate: _isPrivate,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
    );
    if (widget.note == null) {
      ref.read(notesNotifierProvider.notifier).addNote(note);
    } else {
      ref.read(notesNotifierProvider.notifier).updateNote(note);
    }
    context.pop();
  }

  void _addItem() {
    setState(() {
      _shoppingItems.add(ShoppingItem(title: ''));
      _shoppingControllers.add(TextEditingController());
    });
  }

  void _removeItem(int i) {
    setState(() {
      _shoppingControllers[i].dispose();
      _shoppingControllers.removeAt(i);
      _shoppingItems.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isShoppingList = _type == NoteType.shoppingList;
    final accentColor = _type.accentColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Хедер ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: AppIcons.arrow(size: 22),
                  ),
                  const Spacer(),
                  // Тип заметки с иконкой
                  _type.getIcon(size: 20, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.note == null ? 'Создание' : 'Редактирование',
                    style: AppTextStyles.h3,
                  ),
                  const Spacer(),
                  if (widget.note != null)
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(notesNotifierProvider.notifier)
                            .deleteNote(widget.note!.id);
                        context.pop();
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 30),
                ],
              ),
            ),

            // ── Контент ──
            Expanded(
              child: isShoppingList
                  ? _buildShoppingListEditor()
                  : _buildTextEditor(),
            ),

            // ── Футер ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  // Переключатель видимости — плоский, без рамок
                  GestureDetector(
                    onTap: () => setState(() => _isPrivate = !_isPrivate),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _isPrivate
                                ? Icons.lock_outline
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isPrivate ? 'Только для меня' : 'Для всех',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          _MiniToggle(
                            value: _isPrivate,
                            onChanged: (v) => setState(() => _isPrivate = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Кнопка сохранить
                  GestureDetector(
                    onTap: _onSave,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF16001), Color(0xFFC10801)],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Сохранить',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      children: [
        // Заголовок — крупный, без рамок
        TextField(
          controller: _titleController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: 'Заголовок',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.18),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
        const SizedBox(height: 20),
        // Контент — чуть меньше
        TextField(
          controller: _contentController,
          maxLines: null,
          autofocus: widget.note == null,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 17,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: 'Начните писать...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.18),
              fontSize: 17,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingListEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Название списка',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.18),
                fontSize: 22,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            itemCount: _shoppingItems.length + 1,
            itemBuilder: (_, i) {
              if (i == _shoppingItems.length) return _buildAddRow();
              final item = _shoppingItems[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => item.isChecked = !item.isChecked),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isChecked
                                ? AppColors.primary
                                : Colors.white24,
                            width: 1.5,
                          ),
                          color: item.isChecked
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        child: item.isChecked
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _shoppingControllers[i],
                        onChanged: (v) => item.title = v,
                        style: TextStyle(
                          color: item.isChecked ? Colors.white24 : Colors.white,
                          fontSize: 16,
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeItem(i),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddRow() {
    return GestureDetector(
      onTap: _addItem,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.white.withValues(alpha: 0.25),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              'Добавить',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Мини-переключатель ────────────────────────────────────────────────
class _MiniToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MiniToggle({required this.value, required this.onChanged});

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

// ── Карточка заметки ──────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final NoteItem note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return AppPlate(
      onTap: () => context.push('/notes/${note.id}', extra: note),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Цветной индикатор типа
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: note.type.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: note.type.getIcon(size: 20, color: note.type.accentColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note.type == NoteType.shoppingList
                      ? '${note.shoppingItems.length} пунктов'
                      : note.content.isEmpty
                      ? note.type.label
                      : note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (note.isPrivate)
            const Icon(Icons.lock_outline, color: Colors.white24, size: 14),
          AppIcons.arrow(size: 16, color: Colors.white12),
        ],
      ),
    );
  }
}

// ── Выбор типа заметки ────────────────────────────────────────────────
class _NoteTypeSheet extends StatelessWidget {
  const _NoteTypeSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Что создаём?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _TypeOption(
            type: NoteType.note,
            title: 'Заметка',
            subtitle: 'Свободный текст, мысли, планы',
          ),
          const SizedBox(height: 10),
          _TypeOption(
            type: NoteType.ideas,
            title: 'Идея',
            subtitle: 'Для путешествий, подарков, дел',
          ),
          const SizedBox(height: 10),
          _TypeOption(
            type: NoteType.shoppingList,
            title: 'Список покупок',
            subtitle: 'Продукты, вещи, всё нужное',
          ),
          const SizedBox(height: 10),
          _TypeOption(
            type: NoteType.password,
            title: 'Важное',
            subtitle: 'Пароли, документы, данные',
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final NoteType type;
  final String title;
  final String subtitle;
  const _TypeOption({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push('/notes/create', extra: type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: type.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: type.getIcon(size: 20, color: type.accentColor),
              ),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
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

// Заметки видные всем — для экрана семьи
final publicNotesProvider = Provider<List<NoteItem>>((ref) {
  final notes = ref.watch(notesNotifierProvider);
  return notes.where((n) => !n.isPrivate).toList();
});
