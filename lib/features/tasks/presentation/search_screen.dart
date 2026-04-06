import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart';
import 'package:couple_app/features/tasks/presentation/widgets/task_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final allTasks = ref.watch(tasksNotifierProvider);
    final filtered = query.isEmpty
        ? <dynamic>[]
        : allTasks.where((t) => t.title.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: AppIcons.arrow(size: 22),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTextStyles.bodyL.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Поиск задач...',
            hintStyle: AppTextStyles.bodyM.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: query.isEmpty
          ? Center(
              child: Text(
                'Введите название задачи',
                style: AppTextStyles.bodyM.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            )
          : filtered.isEmpty
          ? Center(
              child: Text(
                'Ничего не найдено',
                style: AppTextStyles.bodyM.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(
                  bottom: i < filtered.length - 1 ? 12 : 0,
                ),
                child: TaskCard(task: filtered[i]),
              ),
            ),
    );
  }
}
