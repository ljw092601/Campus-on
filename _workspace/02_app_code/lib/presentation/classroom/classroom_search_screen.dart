import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/classroom_providers.dart';
import '../providers/facility_providers.dart';
import '../providers/floor_plan_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/state_views.dart';

/// Classroom-location search (entered from the home hero tile, full-screen at
/// `/classroom-search`).
///
/// Room codes are `<campus letter + 2-digit building>-<room>`, e.g. S01-0301,
/// S04-0306-1, S04-0101-A (first two room digits = floor) or B02-B101
/// (basement 1). The building half is a single dropdown over the campus-map
/// buildings — a building whose drawings are split by wing (B04 → B04A /
/// B04B) gets one entry per wing; the room half is a free input with
/// suggestions from [classroomEntriesProvider] (real codes for buildings with
/// floor-plan drawings, placeholder data derived from the floor guide
/// otherwise). Searching deep-links to
/// `/map?focus=<building>&floor=<03|B1>&room=<code>[&plan=<plan code>]` — pin
/// focused, peek sheet expanded with the room's floor plan (red dot) above
/// the floor guide.
class ClassroomSearchScreen extends ConsumerStatefulWidget {
  const ClassroomSearchScreen({super.key});

  @override
  ConsumerState<ClassroomSearchScreen> createState() =>
      _ClassroomSearchScreenState();
}

/// One dropdown entry: a campus-map building, narrowed to one set of drawings
/// ([planCode], e.g. "B04A") when it has any.
class _BuildingChoice {
  const _BuildingChoice(this.facility, this.planCode);

  final Facility facility;
  final String? planCode;

  /// Code shown to the user and used as the room-code prefix.
  String get code => planCode ?? facility.buildingCode!;

  @override
  bool operator ==(Object other) =>
      other is _BuildingChoice &&
      other.facility.id == facility.id &&
      other.planCode == planCode;

  @override
  int get hashCode => Object.hash(facility.id, planCode);
}

class _ClassroomSearchScreenState extends ConsumerState<ClassroomSearchScreen> {
  _BuildingChoice? _building;
  final _roomCtrl = TextEditingController();

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  bool get _canSearch =>
      _building != null && roomCodePattern.hasMatch(_roomCtrl.text);

  void _search() {
    final b = _building;
    if (b == null || !_canSearch) return;
    final code = _roomCtrl.text;
    // "03" for 0301, "B1" for B101 (see MapScreen.focusFloorCode).
    final floor = code.substring(0, 2);
    final plan = b.planCode == null ? '' : '&plan=${b.planCode}';
    // `t` makes every search a new request, even an identical repeat.
    final t = DateTime.now().millisecondsSinceEpoch;
    context.push(
        '/classroom-search/result?focus=${b.facility.id}&floor=$floor&room=$code$plan&t=$t');
  }

  /// Campus-map buildings (split per drawing wing) sorted 승학(S) → 구덕(G)
  /// → 부민(B), then by code.
  List<_BuildingChoice> _buildings(
      List<Facility> all, Iterable<String> planIndex) {
    final list = <_BuildingChoice>[
      for (final f in all)
        if (f.buildingCode != null && f.buildingCode!.isNotEmpty)
          ...switch (planCodesFor(f.buildingCode!, planIndex)) {
            [] => [_BuildingChoice(f, null)],
            final codes => [for (final c in codes) _BuildingChoice(f, c)],
          },
    ];
    const campusOrder = {'S': 0, 'G': 1, 'B': 2};
    list.sort((a, b) {
      final ca = campusOrder[a.code[0]] ?? 9;
      final cb = campusOrder[b.code[0]] ?? 9;
      if (ca != cb) return ca - cb;
      return a.code.compareTo(b.code);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final facilitiesAsync = ref.watch(allFacilitiesProvider);
    // No drawings yet (loading / asset error) → plain building list.
    final planIndex =
        ref.watch(floorPlansProvider).valueOrNull?.keys ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(l.classroom_search_title)),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: l.common_loadFailed,
          retryLabel: l.common_retry,
          onRetry: () => ref.invalidate(allFacilitiesProvider),
        ),
        data: (all) {
          final buildings = _buildings(all, planIndex);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                l.classroom_help,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: DropdownMenu<_BuildingChoice>(
                      expandedInsets: EdgeInsets.zero,
                      menuHeight: 420,
                      hintText: l.classroom_hint_building,
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      onSelected: (f) => setState(() => _building = f),
                      dropdownMenuEntries: [
                        for (final f in buildings)
                          DropdownMenuEntry(
                            value: f,
                            label: '${f.code} · ${f.facility.name(locale)}',
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('-',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant)),
                  ),
                  SizedBox(
                    width: 132,
                    child: TextField(
                      controller: _roomCtrl,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _search(),
                      // Plain text keyboard: the numeric pad has no hyphen
                      // on every platform, and codes need "0306-1", "0101-A"
                      // and basement "B101".
                      keyboardType: TextInputType.visiblePassword,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9A-Za-z-]')),
                        const _UpperCaseFormatter(),
                        LengthLimitingTextInputFormatter(7),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1),
                      decoration: InputDecoration(
                        hintText: l.classroom_hint_room,
                        hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _canSearch ? _search : null,
                icon: const Icon(Symbols.pin_drop),
                label: Text(l.classroom_action_search),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
              if (_building != null) ...[
                const SizedBox(height: 20),
                _SuggestionList(
                  building: _building!,
                  query: _roomCtrl.text,
                  onPick: (code) {
                    _roomCtrl.text = code;
                    setState(() {});
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Room-number suggestions for the selected building, filtered by the
/// current input. Real codes where a floor-plan drawing exists, placeholder
/// data (floor guide derivation) elsewhere.
class _SuggestionList extends ConsumerWidget {
  const _SuggestionList({
    required this.building,
    required this.query,
    required this.onPick,
  });

  final _BuildingChoice building;
  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(
        classroomEntriesProvider((building.facility.id, building.planCode)));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Text(l.common_loadFailed,
          style: TextStyle(color: scheme.error, fontSize: 13)),
      data: (entries) {
        if (entries.isEmpty) {
          return _InfoNote(text: l.classroom_noRoomData);
        }
        // Contains-match so partial input works from anywhere in the code
        // (e.g. "101" also surfaces 0101, "0306" also 0306-1 / 0306-2).
        final matches = [
          for (final e in entries)
            if (e.code.contains(query)) e
        ];
        // Long lists (drawings list every room) stay light.
        final shown = matches.take(60).toList();
        if (matches.isEmpty) {
          return _InfoNote(text: l.classroom_suggestions_empty);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in shown)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  onTap: () => onPick(e.code),
                  leading: Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.floorLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer),
                    ),
                  ),
                  title: Text(
                    e.code,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                  subtitle: e.onPlan
                      ? Text(l.classroom_suggestion_onPlan)
                      : Text(e.roomName,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Icon(
                      e.onPlan ? Symbols.location_on : Symbols.north_west,
                      size: 18,
                      color:
                          e.onPlan ? const Color(0xFFE53935) : scheme.outline),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Room codes are upper-case ("0101-A", "B101"); lets the user type either.
class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, height: 1.5, color: scheme.onSurfaceVariant)),
    );
  }
}
