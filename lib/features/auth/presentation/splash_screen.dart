import 'dart:math';
import 'package:flutter/material.dart';
import 'package:couple_app/core/theme/app_colors.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _quotes = [
    "Главное – не количество сделанного, а радость от того, что делаем это вместе.",
    "Маленькие шаги вместе важнее больших шагов в одиночку.",
    "Каждый день — это новая возможность сделать что-то хорошее вместе.",
    "Дом — это не место, а люди рядом с тобой.",
    "Вместе мы справимся с любыми задачами.",
    "Любовь — это не смотреть друг на друга, а смотреть в одном направлении.",
    "Мы — команда, и мы непобедимы.",
    "Сложности проще, когда есть с кем их делить.",
    "Наша сила — в единстве.",
    "Любовь начинается с малого: с улыбки, с заботы, с совместных дел.",
    "Вместе — значит сильнее.",
    "Каждый совместный шаг делает нас ближе.",
    "Любовь — это выбор, который мы делаем каждый день.",
    "С тобой даже трудности — это приключение.",
    "Мы строим не просто дом, мы строим жизнь.",
    "Наша история пишется каждым днём.",
    "Забота — это тоже язык любви.",
    "Любовь не требует совершенства, она требует присутствия.",
    "Сделаем этот мир лучше, начиная с нашей семьи.",
    "Вместе мы растём, вместе мы достигаем большего.",
    "Наши задачи решаются вдвое быстрее, когда мы берёмся за них вместе.",
    "Любовь — это искусство быть вместе, не теряя себя.",
    "Вместе мы — лучшая версия себя.",
    "Ты — мой самый важный проект.",
    "Любовь — это общее дыхание, общие цели, общий путь.",
    "Каждый день — новая возможность для маленького чуда.",
    "Наша любовь — это самый надёжный фундамент.",
    "Мы вместе, и нам всё по плечу.",
    "Любить — значит действовать.",
  ];

  late String _currentQuote;
  late String _greeting;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    _greeting = _getGreeting();

    // Переход через 3 секунды
    Future.delayed(const Duration(seconds: 3), widget.onFinished);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Доброе утро';
    if (hour >= 12 && hour < 17) return 'Добрый день';
    if (hour >= 17 && hour < 22) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _greeting,
                style: AppTextStyles.h1.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF16001),
                      Color(0xFFC10801),
                      Color(0xFF3A0000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  _currentQuote,
                  style: AppTextStyles.bodyL.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
