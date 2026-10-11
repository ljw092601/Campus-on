import 'package:flutter/material.dart';

import 'app_dimens.dart';
import 'category_colors.dart';

/// Brand palette sampled from the DONG-A-MATE UI mockups
/// (DONG-A-MATE_UI_*.png): bright blue primary, deep navy headings,
/// yellow accent, pale blue-gray page background.
class AppColors {
  const AppColors._();

  static const blue = Color(0xFF2F6FED);
  static const blueSoft = Color(0xFFE8F0FE);
  static const blueBadge = Color(0xFFCFE0FF);
  static const navy = Color(0xFF0B2B5C);
  static const yellow = Color(0xFFF8B900);
  static const yellowSoft = Color(0xFFFFF3C4);
  static const yellowInk = Color(0xFFA97306);
  static const green = Color(0xFF1FA971);
  static const greenSoft = Color(0xFFE3F6EC);
  static const coral = Color(0xFFEF6A45);
  static const coralSoft = Color(0xFFFFE9E1);
  static const purple = Color(0xFF7457E0);
  static const purpleSoft = Color(0xFFEEE9FF);
  static const red = Color(0xFFE5484D);
  static const redSoft = Color(0xFFFFE8E8);
  static const ink = Color(0xFF1B1F2A);
  static const inkMuted = Color(0xFF6B7588);
  static const pillNeutral = Color(0xFFEEF3FA);
  static const border = Color(0xFFE3E9F2);
  static const background = Color(0xFFF4F7FC);

  static const cardRadius = 24.0;
  static const fieldRadius = 20.0;
}

/// Builds light/dark [ThemeData] from the UX design tokens (§4).
class AppTheme {
  const AppTheme._();

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.blue,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: AppColors.blueSoft,
    onPrimaryContainer: AppColors.navy,
    secondary: Color(0xFF5B6475),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: AppColors.pillNeutral,
    onSecondaryContainer: AppColors.navy,
    error: Color(0xFFD93A3F),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.pillNeutral,
    onSurfaceVariant: AppColors.inkMuted,
    outline: Color(0xFF8A94A6),
    outlineVariant: AppColors.border,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8DB4FF),
    onPrimary: Color(0xFF00315F),
    primaryContainer: Color(0xFF1E3A6E),
    onPrimaryContainer: Color(0xFFD8E2FF),
    secondary: Color(0xFFBEC6DC),
    onSecondary: Color(0xFF283041),
    secondaryContainer: Color(0xFF3E4759),
    onSecondaryContainer: Color(0xFFDAE2F9),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF1C222C),
    onSurface: Color(0xFFE6E9EF),
    surfaceContainerHighest: Color(0xFF2A323F),
    onSurfaceVariant: Color(0xFFC4C6CF),
    outline: Color(0xFF8E9099),
    outlineVariant: Color(0xFF2E3644),
  );

  /// Green "success" accent (UX doc) — not part of ColorScheme, kept here.
  static const successLight = Color(0xFF2E7D32);
  static const successDark = Color(0xFFA5D6A7);

  static ThemeData light() => _base(_lightScheme, AppColors.background);
  static ThemeData dark() => _base(_darkScheme, const Color(0xFF12161D));

  static ThemeData _base(ColorScheme scheme, Color background) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
    );

    // Typography tokens (§4.2). Font family left null → system font (cost 0);
    // swap to 'Pretendard' once bundled (see pubspec + TODO).
    final t = base.textTheme;
    final textTheme = t.copyWith(
      displaySmall: t.displaySmall
          ?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.12),
      headlineSmall: t.headlineSmall
          ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
      titleMedium: t.titleMedium
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w500, height: 1.27),
      bodyLarge: t.bodyLarge
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: t.bodyMedium
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
      labelLarge: t.labelLarge
          ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
      bodySmall: t.bodySmall
          ?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
    );

    // Use copyWith on the base theme's data objects so this stays robust across
    // the Flutter *Theme → *ThemeData migrations (the getters return the right
    // data type for whatever SDK is in use).
    return base.copyWith(
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        AppDimens.standard,
        CategoryColors.standard,
      ],
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.outline,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurfaceVariant,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.fieldRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.fieldRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.fieldRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      // Bottom tab bar per DONG-A-MATE UI mockup: light-blue pill behind the
      // selected icon, primary-blue label; muted gray otherwise.
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outline,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outline,
          ),
        ),
      ),
    );
  }
}

/// Convenience accessors for theme extensions.
extension ThemeExtGetters on BuildContext {
  AppDimens get dimens =>
      Theme.of(this).extension<AppDimens>() ?? AppDimens.standard;
  CategoryColors get catColors =>
      Theme.of(this).extension<CategoryColors>() ?? CategoryColors.standard;
}
