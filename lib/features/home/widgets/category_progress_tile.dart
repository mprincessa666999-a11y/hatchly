import 'package:flutter/material.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';

class CategoryProgressTile extends StatelessWidget {
  final TaskCategoryGroup group;
  final String categoryId;
  final Widget? customIcon;

  const CategoryProgressTile({
    super.key,
    required this.group,
    required this.categoryId,
    this.customIcon,
  });

  Color get _bgColor {
    final hex = group.category.colorHex;
    if (hex != null && hex.isNotEmpty) {
      try {
        return Color(
          int.parse(hex.replaceFirst('#', '0xFF')),
        ).withValues(alpha: 0.12);
      } catch (_) {}
    }
    return CategoryColors.forId(categoryId).withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: customIcon ?? AppIcons.category(categoryId, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              group.category.name,
              style: AppTextStyles.bodyM.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${group.doneCount}/${group.totalCount}',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
