import 'package:flutter/material.dart';

class AppPlate extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap; // Добавили поддержку нажатия

  const AppPlate({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.borderRadius = 20, // Увеличил до 20 для соответствия макету
    this.onTap,
  });

  // Вынес декорацию в отдельный метод, чтобы её можно было
  // использовать отдельно (например, в AnimatedContainer)
  static Decoration get decoration => ShapeDecoration(
    gradient: const RadialGradient(
      center: Alignment(-0.00, -2.20),
      radius: 1.6,
      colors: [
        Color.fromARGB(139, 214, 82, 0), // Тот самый оранжевый
        Color.fromARGB(125, 14, 14, 14), // Глубокий черный
      ],
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.08), // Тонкая "стеклянная" грань
        width: 1,
      ),
    ),
    shadows: const [
      BoxShadow(
        color: Color(0x99000000),
        blurRadius: 35,
        offset: Offset(15, 15),
        spreadRadius: 0,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );
  }
}
