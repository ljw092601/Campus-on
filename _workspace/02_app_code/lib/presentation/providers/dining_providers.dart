import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dining_menu.dart';
import 'repository_providers.dart';

/// Menus for one calendar day. Keyed by a date normalized to midnight so two
/// DateTimes on the same day share one cache entry.
final diningMenusProvider =
    FutureProvider.family<List<CafeteriaMenu>, DateTime>((ref, date) {
  return ref.watch(diningRepositoryProvider).getMenus(date);
});

/// Normalize to a date-only key for [diningMenusProvider].
DateTime diningDateKey(DateTime d) => DateTime(d.year, d.month, d.day);
