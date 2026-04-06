import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _emojiController;
  late final Animation<double> _emojiScale;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  static const _slides = [
    _OnboardingSlide(
      emoji: '🥚',
      title: 'Растите питомца вместе',
      subtitle:
          'Выполняйте совместные задачи — и ваш питомец будет расти. Чем больше делаете вместе, тем быстрее он вылупится!',
    ),
    _OnboardingSlide(
      emoji: '📋',
      title: 'Планируйте и делайте',
      subtitle:
          'Добавляйте задачи на день, отмечайте выполненные и следите за прогрессом в общем календаре.',
    ),
    _OnboardingSlide(
      emoji: '🔗',
      title: 'Как подключить партнёра?',
      subtitle:
          'Зарегистрируйтесь и получите код приглашения. Поделитесь им с партнёром — и вы сразу начнёте растить питомца вместе!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _emojiScale = CurvedAnimation(
      parent: _emojiController,
      curve: Curves.elasticOut,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _emojiController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emojiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _emojiController.reset();
    _fadeController.reset();
    _emojiController.forward();
    _fadeController.forward();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF16001), Color(0xFFC10801), Color(0xFF3A0000)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 20),
                  child: GestureDetector(
                    onTap: _finish,
                    child: Text(
                      'Пропустить',
                      style: AppTextStyles.bodyM.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _emojiScale,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  slide.emoji,
                                  style: const TextStyle(fontSize: 56),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Text(
                              slide.title,
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Text(
                              slide.subtitle,
                              style: AppTextStyles.bodyL.copyWith(
                                color: Colors.white.withOpacity(0.80),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GestureDetector(
                  onTap: _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isLast
                          ? Colors.white
                          : Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(isLast ? 0 : 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isLast ? 'Начать' : 'Далее',
                        style: AppTextStyles.button.copyWith(
                          color: isLast
                              ? const Color(0xFFC10801)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
