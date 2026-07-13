import 'package:flutter/material.dart';

import 'app_dimens.dart';
import 'category_colors.dart';

/// Builds light/dark [ThemeData] from the UX design tokens (§4).
class AppTheme {
  const AppTheme._();

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1D5DDF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8E2FF),
    onPrimaryContainer: Color(0xFF001A41),
    secondary: Color(0xFF565E71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE2F9),
    onSecondaryContainer: Color(0xFF131C2B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A1C1E),
    surfaceContainerHighest: Color(0xFFE1E2EC),
    onSurfaceVariant: Color(0xFF44474F),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFC4C6D0),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA9C7FF),
    onPrimary: Color(0xFF00315F),
    primaryContainer: Color(0xFF00468C),
    onPrimaryContainer: Color(0xFFD8E2FF),
    secondary: Color(0xFFBEC6DC),
    onSecondary: Color(0xFF283041),
    secondaryContainer: Color(0xFF3E4759),
    onSecondaryContainer: Color(0xFFDAE2F9),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF22252A),
    onSurface: Color(0xFFE3E2E6),
    surfaceContainerHighest: Color(0xFF43474E),
    onSurfaceVariant: Color(0xFFC4C6CF),
    outline: Color(0xFF8E9099),
    outlineVariant: Color(0xFF44474E),
  );

  /// Green "success" accent (UX doc) — not part of ColorScheme, kept here.
  static const successLight = Color(0xFF2E7D32);
  static const successDark = Color(0xFFA5D6A7);

  static ThemeData light() => _base(_lightScheme, const Color(0xFFFDFBFF));
  static ThemeData dark() => _base(_darkScheme, const Color(0xFF1A1C1E));

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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 1,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 3,
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
