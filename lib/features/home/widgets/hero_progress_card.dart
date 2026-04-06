import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/home/pet_system.dart';
import 'package:couple_app/features/home/pet_farm_screen.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

final heroProgressCardKey = GlobalKey<HeroProgressCardState>();

class HeroProgressCard extends ConsumerStatefulWidget {
  final PartnerProgress progress;
  const HeroProgressCard({Key? key, required this.progress}) : super(key: key);

  @override
  HeroProgressCardState createState() => HeroProgressCardState();
}

class HeroProgressCardState extends ConsumerState<HeroProgressCard>
    with TickerProviderStateMixin {
  int _resetKey = 0;

  late final AnimationController _wobbleController;
  late final Animation<double> _wobbleAnim;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;
  late final AnimationController _underGlowController;
  late final Animation<double> _underGlowAnim;
  final List<_Particle> _particles = [];
  late final AnimationController _particleController;
  late final AnimationController _ringPulseController;
  late final Animation<double> _ringPulseAnim;

  @override
  void initState() {
    super.initState();

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _wobbleAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.09), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.09, end: -0.09), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -0.09, end: 0.06), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.03), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
        );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 2),
    ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    _underGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _underGlowAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 2),
        ]).animate(
          CurvedAnimation(parent: _underGlowController, curve: Curves.easeOut),
        );

    _particleController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 950),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed)
            setState(() => _particles.clear());
        });

    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ringPulseAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _ringPulseController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _glowController.dispose();
    _underGlowController.dispose();
    _particleController.dispose();
    _ringPulseController.dispose();
    super.dispose();
  }

  void celebrate(Color glowColor) {
    final rng = Random();
    setState(() {
      _particles.clear();
      for (int i = 0; i < 20; i++) {
        _particles.add(
          _Particle(
            angle: rng.nextDouble() * 2 * pi,
            speed: 55 + rng.nextDouble() * 85,
            color: _celebColors[rng.nextInt(_celebColors.length)],
            size: 4.0 + rng.nextDouble() * 5.0,
            shape: rng.nextBool() ? _Shape.circle : _Shape.star,
          ),
        );
      }
    });
    _wobbleController.forward(from: 0);
    _glowController.forward(from: 0);
    _underGlowController.forward(from: 0);
    _particleController.forward(from: 0);
    _ringPulseController.forward(from: 0);
  }

  static const _celebColors = [
    Color(0xFFF16001),
    Color(0xFFFFCA28),
    Color(0xFF4FC3F7),
    Color(0xFFBA68C8),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
    Color(0xFFF06292),
  ];

  void _resetCamera() => setState(() => _resetKey++);

  @override
  Widget build(BuildContext context) {
    final petState = ref.watch(petSystemProvider);
    final currentPet = allPets[petState.currentPetIndex];
    final petProgress = petState.currentPetProgress;
    final stage = stageFromPercent(petProgress);
    final modelPath = 'assets/models/${currentPet.id}/stage_$stage.glb';
    final statusText = statusFromStageAndPet(
      stage,
      currentPet.name,
      petProgress,
    );

    return GestureDetector(
      onTap: () => context.push('/pet-farm'),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, child) => Container(
          height: 360,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF0E0E0E),
            boxShadow: [
              BoxShadow(
                color: currentPet.glowColor.withValues(
                  alpha: _glowController.isAnimating
                      ? 0.15 + _glowAnim.value * 0.55
                      : 0.18,
                ),
                blurRadius: _glowController.isAnimating
                    ? 40 + _glowAnim.value * 40
                    : 40,
                spreadRadius: _glowController.isAnimating
                    ? 4 + _glowAnim.value * 14
                    : 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Фоновое радиальное свечение
            Positioned(
              top: 30,
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        currentPet.glowColor.withValues(
                          alpha: _glowController.isAnimating
                              ? 0.12 + _glowAnim.value * 0.28
                              : 0.15,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Кнопка сброса камеры
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _resetCamera,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.rotate_left_rounded,
                    size: 18,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Имя + счётчик
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentPet.name,
                      style: AppTextStyles.bodyM.copyWith(
                        color: currentPet.glowColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${petState.currentPetIndex + 1}/${allPets.length}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 250,
                  width: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Кольцо с пульсом
                      AnimatedBuilder(
                        animation: _ringPulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _ringPulseAnim.value,
                          child: child,
                        ),
                        child: _ProgressRing(
                          percent: petProgress,
                          color: currentPet.glowColor,
                        ),
                      ),

                      // Питомец + underglow
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _wobbleAnim,
                            builder: (_, child) => Transform.rotate(
                              angle: _wobbleAnim.value,
                              child: child,
                            ),
                            child: SizedBox(
                              width: 180,
                              height: 190,
                              child: ModelViewer(
                                key: ValueKey('$modelPath:$_resetKey'),
                                src: modelPath,
                                alt: currentPet.name,
                                autoRotate: false,
                                autoPlay: true,
                                cameraControls: true,
                                minCameraOrbit: 'auto 80deg auto',
                                maxCameraOrbit: 'auto 80deg auto',
                                cameraOrbit: '0deg 80deg 2.5m',
                                fieldOfView: '28deg',
                                backgroundColor: Colors.transparent,
                                loading: Loading.eager,
                                relatedCss: """
                                  body { background-color: transparent !important; overflow: hidden; }
                                  model-viewer { background: transparent !important; }
                                """,
                              ),
                            ),
                          ),

                          // Мягкое свечение под питомцем
                          AnimatedBuilder(
                            animation: _underGlowAnim,
                            builder: (_, __) {
                              final alpha = _underGlowController.isAnimating
                                  ? _underGlowAnim.value * 0.75
                                  : 0.25;
                              final blur = _underGlowController.isAnimating
                                  ? 16.0 + _underGlowAnim.value * 16.0
                                  : 16.0;
                              final spread = _underGlowController.isAnimating
                                  ? 2.0 + _underGlowAnim.value * 6.0
                                  : 2.0;
                              return Container(
                                width: 90,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentPet.glowColor.withValues(
                                        alpha: alpha,
                                      ),
                                      blurRadius: blur,
                                      spreadRadius: spread,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Частицы
                      if (_particles.isNotEmpty)
                        AnimatedBuilder(
                          animation: _particleController,
                          builder: (_, __) => CustomPaint(
                            size: const Size(260, 250),
                            painter: _ParticlePainter(
                              particles: _particles,
                              progress: _particleController.value,
                            ),
                          ),
                        ),

                      // Плашка %
                      Positioned(
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E0E0E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentPet.glowColor.withValues(
                                alpha: 0.5,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$petProgress%',
                            style: TextStyle(
                              color: currentPet.glowColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  statusText,
                  style: AppTextStyles.bodyM.copyWith(
                    color: stage == 6
                        ? currentPet.glowColor
                        : Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Нажми для фермы · Крути питомца пальцем',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Частицы ───────────────────────────────────────────────────────────
enum _Shape { circle, star }

class _Particle {
  final double angle, speed, size;
  final Color color;
  final _Shape shape;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.shape,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (progress < 0.5 ? 1.0 : 1.0 - (progress - 0.5) * 2.0).clamp(
      0.0,
      1.0,
    );
    for (final p in particles) {
      final dist = p.speed * progress;
      final pos =
          center +
          Offset(cos(p.angle) * dist, sin(p.angle) * dist - 40 * progress);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final r = p.size * (1 - progress * 0.25);
      if (p.shape == _Shape.circle) {
        canvas.drawCircle(pos, r, paint);
      } else {
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final radius = i.isEven ? r : r * 0.4;
          final a = (i * pi) / 4 - pi / 2;
          final pt = Offset(pos.dx + cos(a) * radius, pos.dy + sin(a) * radius);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Кольцо прогресса ──────────────────────────────────────────────────
class _ProgressRing extends StatelessWidget {
  final int percent;
  final Color color;
  const _ProgressRing({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 230,
          height: 230,
          child: CircularProgressIndicator(
            value: 1,
            strokeWidth: 5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: percent / 100),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => SizedBox(
            width: 230,
            height: 230,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
