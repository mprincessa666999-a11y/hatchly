import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/home/pet_system.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class PetFarmScreen extends ConsumerWidget {
  const PetFarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petSystemProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: AppIcons.arrow(size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Ферма питомцев', style: AppTextStyles.h3),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${petState.completedPets.length} выращено',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: allPets.length,
                itemBuilder: (context, i) {
                  final pet = allPets[i];
                  final isCompleted = i < petState.completedPets.length;
                  final isCurrent = i == petState.currentPetIndex;
                  final isLocked = i > petState.currentPetIndex;

                  int stage = 1;
                  int progress = 0;

                  if (isCompleted) {
                    stage = 6;
                    progress = 100;
                  } else if (isCurrent) {
                    progress = petState.currentPetProgress;
                    stage = stageFromPercent(progress);
                  }

                  return _PetFarmCard(
                    pet: pet,
                    stage: stage,
                    progress: progress,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isLocked: isLocked,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetFarmCard extends StatelessWidget {
  final PetInfo pet;
  final int stage;
  final int progress;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;

  const _PetFarmCard({
    required this.pet,
    required this.stage,
    required this.progress,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.9,
          colors: [
            isLocked
                ? const Color(0xFF1A1A1A)
                : pet.glowColor.withValues(alpha: isCompleted ? 0.3 : 0.2),
            const Color(0xFF0E0E0E),
          ],
        ),
        border: isCurrent
            ? Border.all(color: pet.glowColor, width: 1.5)
            : isCompleted
            ? Border.all(color: pet.glowColor.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLocked)
            Column(
              children: [
                Icon(Icons.lock_outline, color: AppColors.textHint, size: 48),
                const SizedBox(height: 8),
                Text(
                  pet.name,
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Выращивай питомцев\nчтобы открыть',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 110,
                  width: 110,
                  child: ModelViewer(
                    key: ValueKey('${pet.id}_$stage'),
                    src: 'assets/models/${pet.id}/stage_$stage.glb',
                    alt: pet.name,
                    autoRotate: true,
                    autoPlay: true,
                    backgroundColor: Colors.transparent,
                    cameraControls: false,
                    loading: Loading.lazy,
                    relatedCss:
                        'body { background-color: transparent !important; }',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pet.name,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? pet.glowColor : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isCompleted)
                  _Badge(label: 'Легендарный', color: pet.glowColor)
                else if (isCurrent)
                  _Badge(label: '$progress%', color: pet.glowColor),
              ],
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
