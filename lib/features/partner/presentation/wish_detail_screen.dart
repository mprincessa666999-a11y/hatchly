import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/core/ui/widgets/app_plate.dart';
import 'package:couple_app/features/partner/presentation/partner_screen.dart';

class WishDetailScreen extends StatelessWidget {
  final WishItem item;
  const WishDetailScreen({super.key, required this.item});

  void _copyToClipboard(BuildContext context) {
    if (item.url != null) {
      Clipboard.setData(ClipboardData(text: item.url!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ссылка скопирована'),
          backgroundColor: Color(0xFFF16001),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openUrl(BuildContext context) async {
    if (item.url == null) return;
    final uri = Uri.tryParse(item.url!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть ссылку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcons.arrow(size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Детали желания',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddWishScreen(
                  collectionId: item.collectionId,
                  editItem: item,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Фото ──
            AppPlate(
              height: 250,
              child: item.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(item.imagePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.white10,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Фото не добавлено',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // ── Название ──
            Text(
              item.title,
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),

            // ── Цена ──
            if (item.price != null)
              Text(
                '${item.price!.toInt()} ₽',
                style: const TextStyle(
                  color: Color(0xFFF16001),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 24),

            // ── Ссылка ──
            if (item.url != null) ...[
              AppPlate(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ссылка на товар',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.url!,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _copyToClipboard(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Скопировать',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openUrl(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF16001),
                                    Color(0xFFC10801),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Открыть',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Для кого ──
            AppPlate(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFFF16001)),
                  const SizedBox(width: 12),
                  const Text(
                    'Для кого:',
                    style: TextStyle(color: Colors.white38),
                  ),
                  const Spacer(),
                  Text(
                    item.assignedTo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Добавил ──
            if (item.createdBy != null) ...[
              const SizedBox(height: 12),
              AppPlate(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, color: Color(0xFFF16001)),
                    const SizedBox(width: 12),
                    const Text(
                      'Добавил:',
                      style: TextStyle(color: Colors.white38),
                    ),
                    const Spacer(),
                    Text(
                      item.createdBy!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
