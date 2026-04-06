import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Фон ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0D0D); // Основной фон
  static const Color surface = Color(0xFF1A1A1A); // Поверхность карточек
  static const Color surfaceAlt = Color(
    0xFF161616,
  ); // Альтернативная поверхность

  // ── Основные акценты ────────────────────────────────────────────
  static const Color primary = Color(
    0xFFE8622A,
  ); // Основной оранжевый (для кнопок, акцентов)
  static const Color primaryNav = Color(
    0xFFE95B05,
  ); // Активный цвет иконок в навигации
  static const Color primaryDark = Color(0xFFB84A1A); // Тёмный оранжевый
  static const Color primaryLight = Color(0xFFFF8C55); // Светлый оранжевый

  // ── Иконки нижней навигации ──────────────────────────────────────
  static const Color iconInactive = Color(0xFF6F6F6F); // Неактивный серый

  // ── Цвета категорий задач ────────────────────────────────────────
  static const Color cleaning = Color(0xFFA8D3E1); // Уборка
  static const Color cooking = Color(0xFFF1D05B); // Готовка
  static const Color events = Color(0xFFF1D05B); // Мероприятия
  static const Color pets = Color(0xFFF5A300); // Питомцы
  static const Color health = Color(0xFFD1E3A5); // Здоровье

  // ── Градиенты карточек ───────────────────────────────────────────
  static const Color cardGradientStart = Color(
    0xFF2E1A0A,
  ); // Тёплый тёмно-коричневый
  static const Color cardGradientEnd = Color(0xFF0D0D0D); // Чёрный

  // Градиент для hero-карточки (лидерство на Home)
  static const Color heroGradientStart = Color(0xFFE8622A);
  static const Color heroGradientMid = Color(0xFF8B1A00);
  static const Color heroGradientEnd = Color(0xFF1A0800);

  // ── Текст ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF5A5A5A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Календарь ────────────────────────────────────────────────────
  static const Color calendarWeekend = Color(0xFFE8622A); // Сб, Вс
  static const Color calendarToday = Color(0xFFE8622A); // Обводка текущего дня
  static const Color calendarOtherMonth = Color(
    0xFF3A3A3A,
  ); // Дни другого месяца

  // ── Прогресс-бар / индикаторы ────────────────────────────────────
  static const Color progressHigh = Color(0xFFE8B84A); // Жёлто-золотой (95%)
  static const Color progressMedium = Color(0xFF4AB8E8); // Голубой (70%, 67%)
  static const Color progressLow = Color(0xFFE84A4A); // Красный (10%)

  // ── Borders / Dividers ───────────────────────────────────────────
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF222222);

  // ── Иконки ───────────────────────────────────────────────────────
  static const Color iconDefault = Color(0xFFFFFFFF);
  static const Color iconActive = primaryNav; // псевдоним
  static const Color iconInactiveNav = iconInactive; // псевдоним
  static const Color iconLight = Color(0xFFF8F6F6);

  // ── Утилиты ──────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Градиенты (готовые объекты) ──────────────────────────────────
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cardGradientStart, cardGradientEnd],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroGradientStart, heroGradientMid, heroGradientEnd],
  );

  static const RadialGradient cardRadialGlow = RadialGradient(
    center: Alignment(-0.6, 0.0),
    radius: 1.2,
    colors: [cardGradientStart, cardGradientEnd],
  );
}
