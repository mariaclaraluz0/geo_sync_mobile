import 'package:flutter/material.dart';

/// Paleta e componentes compartilhados pelo GeoSync.
///
/// As telas devem obter cores variáveis pelo [Theme.of] para respeitar a
/// preferência de aparência selecionada pelo usuário.
class AppTheme {
  AppTheme._();

  static const _blue = Color(0xFF0C46FF);
  static const _darkBlue = Color(0xFF0B2A4A);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF60A5FA) : _blue,
      brightness: brightness,
      primary: isDark ? const Color(0xFF60A5FA) : _blue,
      surface: isDark ? const Color(0xFF172033) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FB),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: .35)
              : scheme.outlineVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkBlue,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension GeoSyncTheme on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get pageBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  Color get primaryTextColor => Theme.of(this).colorScheme.onSurface;

  Color get secondaryTextColor => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get borderColor => Theme.of(this).colorScheme.outlineVariant;
}
