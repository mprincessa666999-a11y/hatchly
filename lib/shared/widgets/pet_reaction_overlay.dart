import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:couple_app/features/tasks/providers/task_provider.dart'
    show petReactionProvider;

class PetReactionOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const PetReactionOverlay({super.key, required this.child});

  @override
  ConsumerState<PetReactionOverlay> createState() => _PetReactionOverlayState();
}

class _PetReactionOverlayState extends ConsumerState<PetReactionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideIn;
  late Animation<double> _fadeOut;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _slideIn = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(petReactionProvider.notifier).state = null;
        setState(() => _showing = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onReaction(String? reaction) {
    if (reaction == 'happy' && !_showing) {
      setState(() => _showing = true);
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(petReactionProvider, (previous, next) {
      _onReaction(next);
    });

    return Stack(
      children: [
        widget.child,
        if (_showing)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeOut,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1.5),
                  end: Offset.zero,
                ).animate(_slideIn),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF34D399),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Чуня доволен!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Отличная работа!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Плавающие сердечки
                      ...List.generate(
                        3,
                        (i) => _FloatingHeart(delay: i * 0.15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FloatingHeart extends StatelessWidget {
  final double delay;
  const _FloatingHeart({required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value < 0.5 ? value * 2 : (1 - value) * 2,
          child: Transform.translate(
            offset: Offset(0, -value * 30),
            child: Text(
              ['💕', '❤️', '✨'][delay.toInt() % 3],
              style: TextStyle(fontSize: 16 + (1 - value) * 8),
            ),
          ),
        );
      },
    );
  }
}
