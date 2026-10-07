import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/firebase_init.dart' show useFirestoreDining;
import '../../core/util/campus_clock.dart';
import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/dining_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/map_links.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/read_status.dart';

/// How far the day switcher may go back from today (L-12b). Older menus are
/// of no use to students and the admin sheet only keeps a short window.
const int diningPastDayLimit = 7;

/// How far ahead the day switcher may go (L-12b) — the admin publishes at
/// most a couple of weeks in advance.
const int diningFutureDayLimit = 14;

/// How often an open screen re-checks whether the campus date rolled over
/// (L-12a). Cheap: one `DateTime.now()` per tick, a rebuild only on change.
const Duration diningMidnightPollInterval = Duration(minutes: 1);

/// 오늘의 학식 — daily cafeteria menus per campus, with a day switcher.
/// No school API exists; real menus come from the admin sheet → Firestore
/// pipeline when `useFirestoreDining` is on (see DiningRepository). In mock
/// mode a notice banner tells users the menus are samples.
///
/// "Today" is the campus date ([CampusClock.today], Asia/Seoul), not the
/// device date (L-14). While the screen stays open across midnight the date
/// header follows along (timer + app resume, L-12a); navigation is clamped to
/// [diningPastDayLimit]/[diningFutureDayLimit] around today (L-12b) and a
/// "Today" action brings the user back whenever they left today (L-12c).
class DiningMenuScreen extends ConsumerStatefulWidget {
  const DiningMenuScreen({super.key});

  @override
  ConsumerState<DiningMenuScreen> createState() => _DiningMenuScreenState();
}

class _DiningMenuScreenState extends ConsumerState<DiningMenuScreen>
    with WidgetsBindingObserver {
  late DateTime _today;
  late DateTime _date;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _today = CampusClock.today();
    _date = _today;
    WidgetsBinding.instance.addObserver(this);
    _midnightTimer =
        Timer.periodic(diningMidnightPollInterval, (_) => _refreshToday());
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshToday();
  }

  // Day arithmetic via the constructor (not Duration) so a DST host zone
  // can never yield 23:00 of the previous day.
  static DateTime _plusDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  DateTime get _minDate => _plusDays(_today, -diningPastDayLimit);
  DateTime get _maxDate => _plusDays(_today, diningFutureDayLimit);

  bool get _isToday => _date == _today;

  bool _inRange(DateTime d) => !d.isBefore(_minDate) && !d.isAfter(_maxDate);

  bool _canShift(int days) => _inRange(_plusDays(_date, days));

  DateTime _clamp(DateTime d) {
    if (d.isBefore(_minDate)) return _minDate;
    if (d.isAfter(_maxDate)) return _maxDate;
    return d;
  }

  void _shiftDay(int days) {
    if (!_canShift(days)) return;
    setState(() => _date = _plusDays(_date, days));
  }

  void _goToday() => setState(() => _date = _today);

  /// Re-reads the campus date; when it changed (midnight passed, or the app
  /// came back from background on a later day) the header moves with it if
  /// the user was still on "today", otherwise the chosen date is only kept
  /// inside the new navigation window.
  void _refreshToday() {
    if (!mounted) return;
    final today = CampusClock.today();
    if (today == _today) return;
    setState(() {
      final wasOnToday = _isToday;
      _today = today;
      _date = wasOnToday ? today : _clamp(_date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final async = ref.watch(diningMenusProvider(_date));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.home_card_dining_title),
        actions: [
          if (!_isToday)
            TextButton.icon(
              onPressed: _goToday,
              icon: const Icon(Symbols.today, size: 18),
              label: Text(l.dining_goToday),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Symbols.chevron_left),
                  tooltip: l.dining_prevDay,
                  onPressed: _canShift(-1) ? () => _shiftDay(-1) : null,
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
                  onPressed: _canShift(1) ? () => _shiftDay(1) : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(
                message: readErrorMessage(e, l, l.dining_error_loadFailed),
                retryLabel: l.common_retry,
                onRetry: () => ref.invalidate(diningMenusProvider(_date)),
              ),
              data: (menus) => ReadStatusContent(
                  data: menus,
                  onRetry: () => ref.invalidate(diningMenusProvider(_date)),
                  child: Builder(builder: (context) {
                    // Firestore mode with no seeded cafeterias yields an empty
                    // list — show an empty state instead of a bare date header.
                    if (menus.isEmpty) {
                      return EmptyStateView(
                        icon: Symbols.restaurant,
                        title: l.dining_empty,
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        // The sample-data disclaimer only applies to mock data; in
                        // Firestore mode the menus are real admin-entered content.
                        if (!useFirestoreDining) ...[
                          _NoticeBanner(text: l.dining_placeholder_notice),
                          const SizedBox(height: 12),
                        ],
                        for (final c in menus) ...[
                          _CafeteriaCard(menu: c, isToday: _isToday),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  })),
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
  const _CafeteriaCard({required this.menu, required this.isToday});
  final CafeteriaMenu menu;

  /// Whether the day being shown is the campus "today" — picks the
  /// "today…" wording over the date-neutral one (L-11).
  final bool isToday;

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
            // Unpublished (admin hasn't entered the menu) is NOT the same as
            // an explicit closure — see design doc §7 D1.
            if (menu.status == DiningAvailability.unavailable)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(l.dining_unavailable))
            else if (menu.isUnpublished)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                    isToday ? l.dining_unpublished : l.dining_unpublished_date,
                    style: TextStyle(
                        fontSize: 13.5, color: scheme.onSurfaceVariant)),
              )
            else if (menu.isClosed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(isToday ? l.dining_closed : l.dining_closed_date,
                    style: TextStyle(
                        fontSize: 13.5, color: scheme.onSurfaceVariant)),
              )
            else
              // Slot order (breakfast → dinner) regardless of sheet row order
              // (L-15).
              for (final meal in menu.mealsInSlotOrder) ...[
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
                              style:
                                  const TextStyle(fontSize: 13.5, height: 1.5)),
                          if (meal.price != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                // Thousands grouping comes from the ARB
                                // placeholder format (decimalPattern), L-12d.
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
                      context.go(mapFocusLink(menu.facilityId!)),
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
