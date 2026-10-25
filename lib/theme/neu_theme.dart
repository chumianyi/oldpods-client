import 'package:flutter/material.dart';

/// Neumorphism（新拟态）调色板
class NeuPalette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color shadowLight;
  final Color shadowDark;
  final Color text;
  final Color subText;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color danger;
  final Color success;
  final Color warning;
  final Color divider;

  const NeuPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.shadowLight,
    required this.shadowDark,
    required this.text,
    required this.subText,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.divider,
  });

  static const NeuPalette lightPalette = NeuPalette(
    bg: Color(0xFFE0E5EC),
    surface: Color(0xFFE0E5EC),
    surfaceAlt: Color(0xFFE9EDF3),
    shadowLight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFFA3B1C6),
    text: Color(0xFF3A4657),
    subText: Color(0xFF7A8699),
    accent: Color(0xFF5C7CFA),
    accentSoft: Color(0xFFCBD8F8),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFE5544F),
    success: Color(0xFF3E9E68),
    warning: Color(0xFFE39B2D),
    divider: Color(0xFFC3CBD6),
  );

  static const NeuPalette darkPalette = NeuPalette(
    bg: Color(0xFF2A2E35),
    surface: Color(0xFF2A2E35),
    surfaceAlt: Color(0xFF31363E),
    shadowLight: Color(0xFF3B424C),
    shadowDark: Color(0xFF171A1F),
    text: Color(0xFFD4DAE4),
    subText: Color(0xFF8A94A3),
    accent: Color(0xFF7B93F8),
    accentSoft: Color(0xFF39456B),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFF06A68),
    success: Color(0xFF4FBC7C),
    warning: Color(0xFFEFB25E),
    divider: Color(0xFF3B434E),
  );

  static NeuPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPalette : lightPalette;
}

/// Neumorphism 主题
class NeuTheme {
  static ThemeData light() => _base(NeuPalette.lightPalette, Brightness.light);

  static ThemeData dark() => _base(NeuPalette.darkPalette, Brightness.dark);

  static ThemeData _base(NeuPalette p, Brightness b) {
    final base = ThemeData(
      brightness: b,
      useMaterial3: false,
      primaryColor: p.accent,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.surface,
      dividerColor: p.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: p.accent,
        secondary: p.accent,
        surface: p.surface,
        error: p.danger,
        onPrimary: p.onAccent,
        onSurface: p.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: p.text),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: TextStyle(color: p.text, fontSize: 22, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: p.text, fontSize: 15),
        bodyMedium: TextStyle(color: p.text, fontSize: 13.5),
        bodySmall: TextStyle(color: p.subText, fontSize: 12),
        labelLarge: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.text,
        contentTextStyle: TextStyle(color: p.bg, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent, linearTrackColor: p.shadowDark),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(color: p.bg, fontSize: 12),
      ),
    );
  }
}
