import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/dining_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';

/// 오늘의 학식 — daily cafeteria menus per campus, with a day switcher.
/// Data is mock until the school menu API lands (see DiningRepository /
/// TODO(dining-api)); a notice banner tells users the menus are samples.
class DiningMenuScreen extends ConsumerStatefulWidget {
  const DiningMenuScreen({super.key});

  @override
  ConsumerState<DiningMenuScreen> createState() => _DiningMenuScreenState();
}

class _DiningMenuScreenState extends ConsumerState<DiningMenuScreen> {
  DateTime _date = diningDateKey(DateTime.now());

  void _shiftDay(int days) =>
      setState(() => _date = _date.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final async = ref.watch(diningMenusProvider(_date));

    return Scaffold(
      appBar: AppBar(title: Text(l.home_card_dining_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Symbols.chevron_left),
                  tooltip: l.dining_prevDay,
                  onPressed: () => _shiftDay(-1),
                ),
                Expanded(
                  child: Text(
                    DateFormat.yMMMEd(locale.toLanguageTag()).format(_date),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.chevron_right),
                  tooltip: l.dining_nextDay,
                  onPressed: () => _shiftDay(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: l.dining_error_loadFailed,
                retryLabel: l.common_retry,
                onRetry: () => ref.invalidate(diningMenusProvider(_date)),
              ),
              data: (menus) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _NoticeBanner(text: l.dining_placeholder_notice),
                  const SizedBox(height: 12),
                  for (final c in menus) ...[
                    _CafeteriaCard(menu: c),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Symbols.info, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _CafeteriaCard extends ConsumerWidget {
  const _CafeteriaCard({required this.menu});
  final CafeteriaMenu menu;

  String _campusLabel(AppLocalizations l, Campus c) => switch (c) {
        Campus.seunghak => l.map_campus_seunghak,
        Campus.gudeok => l.map_campus_gudeok,
        Campus.bumin => l.map_campus_bumin,
      };

  String _mealLabel(AppLocalizations l, MealType t) => switch (t) {
        MealType.breakfast => l.dining_meal_breakfast,
        MealType.lunch => l.dining_meal_lunch,
        MealType.dinner => l.dining_meal_dinner,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final hours = menu.hours(locale);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _campusLabel(l, menu.campus),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    menu.name(locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (hours != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Symbols.schedule,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(hours,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (menu.isClosed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(l.dining_closed,
                    style: TextStyle(
                        fontSize: 13.5, color: scheme.onSurfaceVariant)),
              )
            else
              for (final meal in menu.meals) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _mealLabel(l, meal.type),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSecondaryContainer),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meal.items.join(' · '),
                              style: const TextStyle(
                                  fontSize: 13.5, height: 1.5)),
                          if (meal.price != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                l.dining_price(meal.price!),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            if (menu.facilityId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.go('/map?focus=${menu.facilityId}'),
                  icon: const Icon(Symbols.pin_drop, size: 18),
                  label: Text(l.facility_action_viewOnMap),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
