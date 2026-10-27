import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// App theme choice: follow the device (default), or force light/dark.
/// Persisted locally with the same write policy as [LocaleNotifier]: the
/// switch always happens in memory; a failed write only means it may not
/// survive a restart.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    if (mode == state) return true;
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    try {
      if (await prefs.setString(_key, mode.name)) return true;
    } catch (_) {}
    try {
      await prefs.reload();
    } catch (_) {}
    return false;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
