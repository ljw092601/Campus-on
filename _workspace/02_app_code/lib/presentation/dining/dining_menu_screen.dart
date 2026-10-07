import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/firebase_init.dart' show useFirestoreDining;
import '../../core/theme/app_theme.dart';
import '../../core/util/campus_clock.dart';
import '../../domain/entities/dining_menu.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/dining_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/read_status.dart';
import 'cafeteria_card.dart';
import 'dining_labels.dart';

export 'cafeteria_card.dart' show CafeteriaCard, diningFoldThreshold;

/// How far the day switcher may go back from today (L-12b). Older menus are
/// of no use to students and the admin sheet only keeps a short window.
const int diningPastDayLimit = 7;

/// How far ahead the day switcher may go (L-12b) — the admin publishes at
/// most a couple of weeks in advance.
const int diningFutureDayLimit = 14;

/// How often an open screen re-checks whether the campus date rolled over
/// (L-12a). Cheap: one `DateTime.now()` per tick, a rebuild only on change.
const Duration diningMidnightPollInterval = Duration(minutes: 1);

/// Cafeterias of [group] in admin display order ([CafeteriaMenu.order]).
/// Stable on equal `order` so the repository order breaks ties.
List<CafeteriaMenu> cafeteriasOfGroup(
    List<CafeteriaMenu> menus, CampusGroup group) {
  final indexed = [
    for (var i = 0; i < menus.length; i++)
      if (menus[i].campusGroup == group) (i, menus[i])
  ];
  indexed.sort((a, b) {
    final o = a.$2.order.compareTo(b.$2.order);
    return o != 0 ? o : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// 오늘의 학식 — daily cafeteria menus, one tab per campus group (승학 |
/// 구덕·부민), with a day switcher. No school API exists; real menus come from
/// the admin sheet → Firestore pipeline when `useFirestoreDining` is on (see
/// DiningRepository). In mock mode a notice banner tells users the menus are
/// samples.
///
/// "Today" is the campus date ([CampusClock.today], Asia/Seoul), not the
/// device date (L-14). While the screen stays open across midnight the date
/// header follows along (timer + app resume, L-12a); navigation is clamped to
/// [diningPastDayLimit]/[diningFutureDayLimit] around today (L-12b) and a
/// "Today" action brings the user back whenever they left today (L-12c).
/// The selected campus group survives day changes.
class DiningMenuScreen extends ConsumerStatefulWidget {
  const DiningMenuScreen({super.key, this.initialGroup = CampusGroup.seunghak});

  /// Group tab shown first.
  final CampusGroup initialGroup;

  @override
  ConsumerState<DiningMenuScreen> createState() => _DiningMenuScreenState();
}

class _DiningMenuScreenState extends ConsumerState<DiningMenuScreen>
    with WidgetsBindingObserver {
  late DateTime _today;
  late DateTime _date;
  late CampusGroup _group;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _today = CampusClock.today();
    _date = _today;
    _group = widget.initialGroup;
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
    final dimens = context.dimens;
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
          Padding(
            padding: EdgeInsets.fromLTRB(
                dimens.spaceMd, 0, dimens.spaceMd, dimens.spaceSm),
            child: SegmentedButton<CampusGroup>(
              segments: [
                for (final g in CampusGroup.values)
                  ButtonSegment(
                    value: g,
                    label: Text(g.label(l),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              selected: {_group},
              showSelectedIcon: false,
              // Fill the width so each segment gets an equal, bounded share
              // and the label can ellipsize at large text scales (L-18).
              expandedInsets: EdgeInsets.zero,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onSelectionChanged: (selection) =>
                  setState(() => _group = selection.first),
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
                    final cafeterias = cafeteriasOfGroup(menus, _group);
                    if (cafeterias.isEmpty) {
                      return EmptyStateView(
                        icon: Symbols.restaurant,
                        title: l.dining_group_empty,
                      );
                    }
                    return ListView(
                      key: PageStorageKey(_group),
                      padding: EdgeInsets.fromLTRB(dimens.spaceMd,
                          dimens.spaceXs, dimens.spaceMd, dimens.spaceLg),
                      children: [
                        // The sample-data disclaimer only applies to mock data; in
                        // Firestore mode the menus are real admin-entered content.
                        if (!useFirestoreDining) ...[
                          _NoticeBanner(text: l.dining_placeholder_notice),
                          SizedBox(height: dimens.spaceMd - 4),
                        ],
                        for (final c in cafeterias) ...[
                          CafeteriaCard(
                            key: ValueKey('cafeteria-${c.id}'),
                            menu: c,
                            isToday: _isToday,
                            showCampus: _group == CampusGroup.gudeokBumin,
                          ),
                          SizedBox(height: dimens.spaceMd - 4),
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
        borderRadius: context.dimens.brMd,
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
