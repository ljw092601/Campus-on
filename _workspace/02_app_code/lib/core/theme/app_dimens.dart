import 'package:flutter/material.dart';

/// Spacing / radius / elevation design tokens (UX doc §4.3–4.4) exposed as a
/// [ThemeExtension] so widgets read them via `Theme.of(context).extension`.
@immutable
class AppDimens extends ThemeExtension<AppDimens> {
  const AppDimens({
    this.spaceXs = 4,
    this.spaceSm = 8,
    this.spaceMd = 16,
    this.spaceLg = 24,
    this.spaceXl = 32,
    this.space2xl = 48,
    this.radiusSm = 8,
    this.radiusMd = 12,
    this.radiusLg = 16,
    this.radiusFull = 999,
    this.elevation1 = 1,
    this.elevation2 = 3,
    this.touchMin = 48,
  });

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double space2xl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusFull;
  final double elevation1;
  final double elevation2;
  final double touchMin;

  BorderRadius get brSm => BorderRadius.circular(radiusSm);
  BorderRadius get brMd => BorderRadius.circular(radiusMd);
  BorderRadius get brLg => BorderRadius.circular(radiusLg);

  static const AppDimens standard = AppDimens();

  @override
  AppDimens copyWith({double? spaceMd, double? radiusMd}) => AppDimens(
        spaceMd: spaceMd ?? this.spaceMd,
        radiusMd: radiusMd ?? this.radiusMd,
      );

  @override
  AppDimens lerp(ThemeExtension<AppDimens>? other, double t) => this;
}
