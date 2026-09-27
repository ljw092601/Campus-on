import 'package:flutter/widgets.dart';

/// Whether a screen should use the layout that grows with its text instead of
/// the fixed-ratio one.
///
/// Two things make a fixed layout cut text, and they are independent:
///
/// * **the text is larger** — anything above the default size needs the
///   self-sizing cards, the folded calendar row and the scrollable campus
///   chips (감사 05/037 SF-1, 05/038 SF-3);
/// * **the screen is narrow** — at 320dp even the default text does not fit.
///   Sweeping at 1.0x showed 'Admin guide' and 'Campus map' clipped on the home
///   grid, and the calendar row losing its event name, with nothing enlarged at
///   all.
///
/// One definition, so the four screens cannot drift apart.
bool prefersFlexibleLayout(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1.0) > 1.0 ||
    MediaQuery.sizeOf(context).width < 360;
