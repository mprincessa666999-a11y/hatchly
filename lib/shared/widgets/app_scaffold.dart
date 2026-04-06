import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_icons.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int currentIndex = 0;

  // Убрали '/more' — теперь 4 таба
  final List<String> _tabs = ['/', '/calendar', '/notes', '/partner'];

  void onTap(int index) {
    setState(() => currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          border: Border(top: BorderSide(color: Color(0xFF2C2C2C), width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: AppIcons.home(),
                ),
                _NavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: AppIcons.calendar(),
                ),
                _NavItem(
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: AppIcons.notes(),
                ),
                _NavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: AppIcons.lists(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget icon;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final effectiveIcon = isSelected
        ? ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFFF16001),
              BlendMode.srcIn,
            ),
            child: icon,
          )
        : icon;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: effectiveIcon,
      ),
    );
  }
}
