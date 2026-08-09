import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F3040), Color(0xFF123B4E), Color(0xFF0B2A3A)]
              : const [Color(0xFFF7F4ED), Color(0xFFEDE9DE)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _Glow(
              color: isDark ? AppColors.sand : AppColors.sage,
              isDark: isDark,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Glow(
              color: isDark ? AppColors.terracotta : AppColors.gold,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.isDark});

  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 340,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.22 : 0.14),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
