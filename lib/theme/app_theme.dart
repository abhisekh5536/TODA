import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  const AppColors._();

  static const Color sage = Color(0xFF8FA28A);
  static const Color mist = Color(0xFFC7D3C0);
  static const Color ivory = Color(0xFFF7F4ED);
  static const Color gold = Color(0xFFC8A96B);

  static const Color deepTeal = Color(0xFF0F3040);
  static const Color slate = Color(0xFF464858);
  static const Color terracotta = Color(0xFFA56F63);
  static const Color sand = Color(0xFFD99B7F);

  static LinearGradient primary(Brightness brightness) =>
      brightness == Brightness.dark ? _nightPrimary : _dayPrimary;

  static LinearGradient accent(Brightness brightness) =>
      brightness == Brightness.dark ? _nightAccent : _dayAccent;

  static LinearGradient ring(Brightness brightness) =>
      brightness == Brightness.dark ? _nightRing : dayRing;

  static LinearGradient danger(Brightness brightness) =>
      brightness == Brightness.dark ? _nightDanger : _dayDanger;

  static const LinearGradient _dayPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF96AA88), Color(0xFF657E5F)],
  );

  static const LinearGradient _dayAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDCC07F), Color(0xFFBD9E58)],
  );

  static const LinearGradient dayRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8FA28A), Color(0xFFCFAE6E)],
  );

  static const LinearGradient _dayDanger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97B6C), Color(0xFFAF5450)],
  );

  static const LinearGradient _nightPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC08466), Color(0xFF975C52)],
  );

  static const LinearGradient _nightAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE4AA8C), Color(0xFFC07E5F)],
  );

  static const LinearGradient _nightRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3AE8F), Color(0xFFA56F63)],
  );

  static const LinearGradient _nightDanger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE2837A), Color(0xFFC05A53)],
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static const ScrollBehavior scrollBehavior = _NoGlowScrollBehavior();

  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        );
  }

  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      );

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: isDark ? AppColors.sand : AppColors.sage,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFC98B72) : AppColors.sage,
          onPrimary: isDark ? const Color(0xFF3A1A0E) : Colors.white,
          primaryContainer: isDark
              ? const Color(0xFF4C3630)
              : const Color(0xFFDDE7D9),
          onPrimaryContainer: isDark
              ? const Color(0xFFFFDCCF)
              : const Color(0xFF2C3F2A),
          secondary: isDark ? AppColors.sand : AppColors.gold,
          onSecondary: isDark ? const Color(0xFF3D1E10) : Colors.white,
          secondaryContainer: isDark
              ? const Color(0xFF5A3A2A)
              : const Color(0xFFF0E2C7),
          onSecondaryContainer: isDark
              ? const Color(0xFFFFE0CD)
              : const Color(0xFF422E0D),
          surface: isDark ? AppColors.deepTeal : AppColors.ivory,
          onSurface: isDark ? const Color(0xFFF4ECD1) : const Color(0xFF2C3525),
          surfaceContainerLowest: isDark
              ? const Color(0xFF0C3140)
              : const Color(0xFFFBF8F1),
          surfaceContainerLow: isDark
              ? const Color(0xFF123846)
              : const Color(0xFFF2EEE6),
          surfaceContainerHigh: isDark
              ? const Color(0xFF315164)
              : const Color(0xFFE7E4D8),
          surfaceContainerHighest: isDark
              ? const Color(0xFF375468)
              : const Color(0xFFDEDBD0),
          outline: isDark ? const Color(0xFFA9BFC4) : const Color(0xFF798878),
          inverseSurface: isDark
              ? const Color(0xFFF2EBDD)
              : const Color(0xFF2F4A45),
          onInverseSurface: isDark
              ? const Color(0xFF12243C)
              : const Color(0xFFF0EDE2),
        );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: Colors.transparent,
      pageTransitionsTheme: _pageTransitionsTheme,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF1E3A4A)
            : const Color(0xFF3A4A36),
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFFF4ECD1) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: isDark ? AppColors.sand : AppColors.sage,
        selectionColor: (isDark ? AppColors.sand : AppColors.sage).withValues(
          alpha: 0.25,
        ),
        selectionHandleColor: isDark ? AppColors.sand : AppColors.sage,
      ),
    );
  }
}

class _NoGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
