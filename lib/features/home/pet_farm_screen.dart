import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/core/ui/app_icons.dart';
import 'package:couple_app/features/home/pet_system.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// ── URL базы GitHub Releases ──────────────────────────────────────────
const _baseUrl =
    'https://github.com/mprincessa666999-a11y/hatchly/releases/download/v1.0-models';

// Первый питомец — локальный (офлайн)
const _localPetId = 'chunya';

// ── Провайдер кэша путей к моделям ───────────────────────────────────
final modelPathProvider =
    StateNotifierProvider<ModelCacheNotifier, Map<String, String>>(
      (ref) => ModelCacheNotifier(),
    );

class ModelCacheNotifier extends StateNotifier<Map<String, String>> {
  ModelCacheNotifier() : super({});

  void setPath(String key, String path) {
    state = {...state, key: path};
  }

  bool has(String key) => state.containsKey(key);
  String? get(String key) => state[key];
}

// ── Сервис загрузки модели ────────────────────────────────────────────
Future<String?> downloadModel(String petId, int stage) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/${petId}_stage_$stage.glb');

    // Уже скачан
    if (await file.exists()) return file.path;

    await file.parent.create(recursive: true);

    final url = '$_baseUrl/${petId}_stage_$stage.glb';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    return null;
  } catch (e) {
    return null;
  }
}

// ── Главный экран фермы ───────────────────────────────────────────────
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

// ── Карточка питомца ──────────────────────────────────────────────────
class _PetFarmCard extends ConsumerStatefulWidget {
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
  ConsumerState<_PetFarmCard> createState() => _PetFarmCardState();
}

class _PetFarmCardState extends ConsumerState<_PetFarmCard> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isLocked && widget.pet.id != _localPetId) {
      _ensureModel();
    }
  }

  Future<void> _ensureModel() async {
    final key = '${widget.pet.id}_${widget.stage}';
    if (ref.read(modelPathProvider).containsKey(key)) return;

    setState(() => _loading = true);
    final path = await downloadModel(widget.pet.id, widget.stage);
    if (path != null && mounted) {
      ref.read(modelPathProvider.notifier).setPath(key, path);
    }
    if (mounted) setState(() => _loading = false);
  }

  String _modelSrc() {
    if (widget.pet.id == _localPetId) {
      return 'assets/models/${widget.pet.id}/stage_${widget.stage}.glb';
    }
    final key = '${widget.pet.id}_${widget.stage}';
    final cached = ref.watch(modelPathProvider)[key];
    if (cached != null) return cached;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.9,
          colors: [
            widget.isLocked
                ? const Color(0xFF1A1A1A)
                : widget.pet.glowColor.withValues(
                    alpha: widget.isCompleted ? 0.3 : 0.2,
                  ),
            const Color(0xFF0E0E0E),
          ],
        ),
        border: widget.isCurrent
            ? Border.all(color: widget.pet.glowColor, width: 1.5)
            : widget.isCompleted
            ? Border.all(
                color: widget.pet.glowColor.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLocked)
            Column(
              children: [
                Icon(Icons.lock_outline, color: AppColors.textHint, size: 48),
                const SizedBox(height: 8),
                Text(
                  widget.pet.name,
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
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: widget.pet.glowColor,
                            strokeWidth: 2,
                          ),
                        )
                      : _modelSrc().isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_download_outlined,
                              color: widget.pet.glowColor.withValues(
                                alpha: 0.5,
                              ),
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Нет сети',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        )
                      : ModelViewer(
                          key: ValueKey('${widget.pet.id}_${widget.stage}'),
                          src: _modelSrc(),
                          alt: widget.pet.name,
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
                  widget.pet.name,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.isCurrent
                        ? widget.pet.glowColor
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.isCompleted)
                  _Badge(label: 'Легендарный', color: widget.pet.glowColor)
                else if (widget.isCurrent)
                  _Badge(
                    label: '${widget.progress}%',
                    color: widget.pet.glowColor,
                  ),
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
