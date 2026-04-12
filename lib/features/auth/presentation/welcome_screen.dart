import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:couple_app/core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Логотип
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF16001).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  size: 50,
                  color: Color(0xFFF16001),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Добро пожаловать\nв Hatchly',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ведите задачи вместе, растите питомца\nи выполняйте желания.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyM.copyWith(color: Colors.white54),
              ),

              const Spacer(),

              // Кнопка регистрации / входа
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF16001), Color(0xFFC10801)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Войти / Зарегистрироваться',
                      style: TextStyle(
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
      ),
    );
  }
}
