import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:couple_app/core/services/storage_service.dart';
import 'package:couple_app/features/partner/presentation/wish_detail_screen.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';
import 'package:couple_app/features/friends/presentation/friends_screen.dart'
    show relationsProvider, FamilyMember;

// ── Модели ────────────────────────────────────────────────────────────
class Collection {
  final String id;
  final String name;
  final String description;
  const Collection({
    required this.id,
    required this.name,
    required this.description,
  });
}

class WishItem {
  final String id;
  final String title;
  final String? url;
  final double? price;
  final String assignedTo;
  final String? imagePath;
  final String collectionId;
  final String? createdBy;

  const WishItem({
    required this.id,
    required this.title,
    required this.collectionId,
    this.url,
    this.price,
    this.assignedTo = 'Я',
    this.imagePath,
    this.createdBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'collectionId': collectionId,
    'url': url,
    'price': price,
    'assignedTo': assignedTo,
    'imagePath': imagePath,
    'createdBy': createdBy,
  };

  factory WishItem.fromMap(Map<String, dynamic> m) => WishItem(
    id: m['id'] as String,
    title: m['title'] as String,
    collectionId: m['collectionId'] as String,
    url: m['url'] as String?,
    price: m['price'] as double?,
    assignedTo: m['assignedTo'] as String? ?? 'Я',
    imagePath: m['imagePath'] as String?,
    createdBy: m['createdBy'] as String?,
  );
}

// ── Провайдеры ────────────────────────────────────────────────────────
class WishesNotifier extends StateNotifier<List<WishItem>> {
  WishesNotifier() : super([]);

  void initStorage() {
    final saved = StorageService().loadWishes();
    if (saved.isNotEmpty) {
      state = saved.map((m) => WishItem.fromMap(m)).toList();
    }
  }

  Future<void> _save() async =>
      StorageService().saveWishes(state.map((w) => w.toMap()).toList());

  void addWish(WishItem wish) {
    state = [...state, wish];
    _save();
  }

  void updateWish(WishItem updated) {
    state = [
      for (final w in state)
        if (w.id == updated.id) updated else w,
    ];
    _save();
  }

  void deleteWish(String id) {
    state = state.where((w) => w.id != id).toList();
    _save();
  }
}

final wishesProvider = StateNotifierProvider<WishesNotifier, List<WishItem>>(
  (ref) => WishesNotifier(),
);

final collectionsProvider = Provider<List<Collection>>(
  (ref) => const [
    Collection(
      id: 'gifts',
      name: 'Сундук желаний',
      description: 'Идеи для подарков: от мелочей до заветных желаний.',
    ),
    Collection(
      id: 'travel',
      name: 'Атлас мечтаний',
      description: 'Карта будущих путешествий, городов и маршрутов.',
    ),
    Collection(
      id: 'kino',
      name: 'Плед и попкорн',
      description: 'Кино, сериалы и мультфильмы для наших вечеров.',
    ),
    Collection(
      id: 'entertainment',
      name: 'Тихая гавань',
      description: 'Идеи для совместного отдыха и уютных вечеров.',
    ),
    Collection(
      id: 'cafe',
      name: 'Вкусные истории',
      description: 'Любимые кафе, рестораны и новые места.',
    ),
  ],
);

String _addButtonLabel(String id) {
  switch (id) {
    case 'travel':
      return 'Добавить место';
    case 'kino':
      return 'Добавить фильм/сериал';
    case 'entertainment':
      return 'Добавить игру';
    case 'cafe':
      return 'Добавить место';
    default:
      return 'Добавить желание';
  }
}

// ── Главный экран — без стрелки назад ────────────────────────────────
class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishesProvider.notifier).initStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final allWishes = ref.watch(wishesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: collections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final col = collections[i];
            final count = allWishes
                .where((w) => w.collectionId == col.id)
                .length;
            return _CollectionTile(
              collection: col,
              wishCount: count,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WishlistScreen(collection: col),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  final int wishCount;
  final VoidCallback onTap;

  const _CollectionTile({
    required this.collection,
    required this.wishCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPlate(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          AppIcons.category(collection.id, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: AppTextStyles.bodyL.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  collection.description,
                  style: AppTextStyles.caption.copyWith(color: Colors.white54),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$wishCount',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppIcons.arrow(size: 16, color: Colors.white24),
        ],
      ),
    );
  }
}

// ── Список желаний ────────────────────────────────────────────────────
class WishlistScreen extends ConsumerWidget {
  final Collection collection;
  const WishlistScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref
        .watch(wishesProvider)
        .where((w) => w.collectionId == collection.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.arrow(size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          collection.name,
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddWishScreen(collectionId: collection.id),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle,
                    color: Color(0xFFF16001),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _addButtonLabel(collection.id),
                    style: AppTextStyles.bodyL.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: wishes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Пока пусто',
                          style: AppTextStyles.bodyM.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите «Добавить желание»',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: wishes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _WishCard(
                      item: wishes[i],
                      onDelete: () => ref
                          .read(wishesProvider.notifier)
                          .deleteWish(wishes[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Добавление / редактирование желания ──────────────────────────────
class AddWishScreen extends ConsumerStatefulWidget {
  final String collectionId;
  final WishItem? editItem;

  const AddWishScreen({super.key, required this.collectionId, this.editItem});

  @override
  ConsumerState<AddWishScreen> createState() => _AddWishScreenState();
}

class _AddWishScreenState extends ConsumerState<AddWishScreen> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _selectedAssignee = 'Я';
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _titleCtrl.text = widget.editItem!.title;
      _urlCtrl.text = widget.editItem!.url ?? '';
      _priceCtrl.text = widget.editItem!.price?.toInt().toString() ?? '';
      _selectedAssignee = widget.editItem!.assignedTo;
      _imagePath = widget.editItem!.imagePath;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // Список "Для кого": Я + члены семьи
  List<String> _buildAssignees() {
    final myName = ref.read(profileProvider).name;
    final family = ref
        .read(relationsProvider)
        .where((m) => m.isFamily)
        .toList();
    return [
      'Я${myName.isNotEmpty ? " ($myName)" : ""}',
      ...family.map((m) => m.name),
    ];
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название желания'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final price = _priceCtrl.text.trim().isNotEmpty
        ? double.tryParse(_priceCtrl.text.trim())
        : null;
    final url = _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim();
    final myName = ref.read(profileProvider).name;

    final wish = WishItem(
      id:
          widget.editItem?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      collectionId: widget.collectionId,
      url: url,
      price: price,
      assignedTo: _selectedAssignee,
      imagePath: _imagePath,
      createdBy: myName.isNotEmpty ? myName : null,
    );

    if (widget.editItem != null) {
      ref.read(wishesProvider.notifier).updateWish(wish);
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ref.read(wishesProvider.notifier).addWish(wish);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignees = _buildAssignees();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editItem != null ? 'Редактировать желание' : 'Новое желание',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Фото
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  image: _imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Добавить фото',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Нажмите чтобы выбрать из галереи',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 28),

            // Название
            _FieldBlock(
              label: 'Название',
              icon: Icons.edit_outlined,
              child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: _inputDecor('Что вы хотите?'),
              ),
            ),
            const SizedBox(height: 16),

            // Ссылка
            _FieldBlock(
              label: 'Ссылка на товар',
              icon: Icons.link,
              child: TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                keyboardType: TextInputType.url,
                decoration: _inputDecor('https://...').copyWith(
                  suffixIcon: GestureDetector(
                    onTap: () {
                      final text = _urlCtrl.text.trim();
                      if (text.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ссылка скопирована'),
                            backgroundColor: AppColors.primary,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.copy,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Цена
            _FieldBlock(
              label: 'Цена',
              icon: Icons.attach_money,
              child: TextField(
                controller: _priceCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                keyboardType: TextInputType.number,
                decoration: _inputDecor('Например: 2500').copyWith(
                  prefixText: '₽ ',
                  prefixStyle: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Для кого
            _FieldBlock(
              label: 'Для кого',
              icon: Icons.person_outline,
              child: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            'Для кого',
                            style: AppTextStyles.bodyL.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...assignees.map(
                            (name) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedAssignee = name);
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedAssignee == name
                                        ? AppColors.primary
                                        : const Color(0xFF242424),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            _selectedAssignee == name
                                            ? Colors.white.withValues(
                                                alpha: 0.2,
                                              )
                                            : AppColors.border,
                                        child: Text(
                                          name[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedAssignee == name
                                                ? Colors.white
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedAssignee == name
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          _selectedAssignee[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedAssignee,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      AppIcons.arrow(size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Сохранить
            GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF16001),
                      Color(0xFFC10801),
                      Color(0xFF3A0000),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.editItem != null
                        ? 'Сохранить изменения'
                        : 'Сохранить желание',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
    filled: true,
    fillColor: const Color(0xFF1C1C1C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

// ── Вспомогательные виджеты ───────────────────────────────────────────
class _FieldBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _FieldBlock({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _WishCard extends StatelessWidget {
  final WishItem item;
  final VoidCallback onDelete;

  const _WishCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline,
          color: Color(0xFFFF4444),
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => WishDetailScreen(item: item))),
        child: AppPlate(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyL.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.url != null) ...[
                          const Icon(
                            Icons.link,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.url!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            item.assignedTo[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.createdBy != null
                              ? '${item.assignedTo} · ${item.createdBy}'
                              : item.assignedTo,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        if (item.price != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.price!.toInt()} ₽',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  image: item.imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(item.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imagePath == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: Colors.white38,
                            size: 18,
                          ),
                          SizedBox(height: 3),
                          Text(
                            'фото',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
