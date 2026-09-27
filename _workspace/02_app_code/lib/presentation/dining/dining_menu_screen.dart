import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/firebase_init.dart' show useFirestoreDining;
import '../../core/theme/app_theme.dart';
import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/dining_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/ui_kit.dart';

/// 오늘의 학식 — daily cafeteria menus per campus, with a day switcher.
/// No school API exists; real menus come from the admin sheet → Firestore
/// pipeline when `useFirestoreDining` is on (see DiningRepository). In mock
/// mode a notice banner tells users the menus are samples.
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _DateNavigator(
              date: _date,
              localeTag: locale.toLanguageTag(),
              prevTooltip: l.dining_prevDay,
              nextTooltip: l.dining_nextDay,
              onShift: _shiftDay,
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
              data: (menus) {
                // Firestore mode with no seeded cafeterias yields an empty
                // list — show an empty state instead of a bare date header.
                if (menus.isEmpty) {
                  return EmptyStateView(
                    icon: Symbols.restaurant,
                    title: l.dining_empty,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // The sample-data disclaimer only applies to mock data; in
                    // Firestore mode the menus are real admin-entered content.
                    if (!useFirestoreDining) ...[
                      InfoBanner(text: l.dining_placeholder_notice),
                      const SizedBox(height: 16),
                    ],
                    for (final c in menus) ...[
                      _CafeteriaCard(menu: c),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill with ‹ / › chevrons around "9월 23일 (수) 2026".
class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.localeTag,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.onShift,
  });

  final DateTime date;
  final String localeTag;
  final String prevTooltip;
  final String nextTooltip;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = headingColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: softShadow(context),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Symbols.chevron_left, color: fg),
            tooltip: prevTooltip,
            onPressed: () => onShift(-1),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: DateFormat.MMMEd(localeTag).format(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    TextSpan(
                      text: '  ${DateFormat.y(localeTag).format(date)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.outline,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Symbols.chevron_right, color: fg),
            tooltip: nextTooltip,
            onPressed: () => onShift(1),
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

  Tone _campusTone(Campus c) => switch (c) {
        Campus.seunghak => Tone.navy,
        Campus.gudeok => Tone.green,
        Campus.bumin => Tone.purple,
      };

  Tone _mealTone(MealType t) => switch (t) {
        MealType.breakfast => Tone.yellow,
        MealType.lunch => Tone.blue,
        MealType.dinner => Tone.purple,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final hours = menu.hours(locale);
    final noteStyle = TextStyle(fontSize: 14, color: scheme.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: softShadow(context),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ToneBadge(
                _campusLabel(l, menu.campus),
                tone: _campusTone(menu.campus),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  menu.name(locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (hours != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Symbols.schedule,
                      size: 16, color: scheme.outline),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(hours,
                      style: TextStyle(
                          fontSize: 13, height: 1.4, color: scheme.outline)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          // Unpublished (admin hasn't entered the menu) is NOT the same as
          // an explicit closure — see design doc §7 D1.
          if (menu.isUnpublished)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.dining_unpublished, style: noteStyle),
            )
          else if (menu.isClosed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.dining_closed, style: noteStyle),
            )
          else
            for (var i = 0; i < menu.meals.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _MealRow(
                label: _mealLabel(l, menu.meals[i].type),
                tone: _mealTone(menu.meals[i].type),
                items: menu.meals[i].items.join(' · '),
                price: menu.meals[i].price == null
                    ? null
                    : l.dining_price(menu.meals[i].price!),
              ),
            ],
          if (menu.facilityId != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: SoftPillButton(
                onPressed: () => context.go('/map?focus=${menu.facilityId}'),
                icon: Symbols.location_on,
                label: l.facility_action_viewOnMap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One meal line: tinted meal-type pill · menu items · blue price.
class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.label,
    required this.tone,
    required this.items,
    required this.price,
  });

  final String label;
  final Tone tone;
  final String items;
  final String? price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ToneBadge(label, tone: tone, minWidth: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              items,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (price != null) ...[
            const SizedBox(width: 10),
            Text(
              price!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Tone.blue.fg(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
