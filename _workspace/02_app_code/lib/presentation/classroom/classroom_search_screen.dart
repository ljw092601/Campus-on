import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/classroom_providers.dart';
import '../providers/facility_providers.dart';
import '../providers/locale_provider.dart';

/// Classroom-location search (entered from the home hero tile, full-screen at
/// `/classroom-search`).
///
/// Room codes are `<campus letter + 2-digit building>-<4-digit room>`, e.g.
/// S01-0301 (first two room digits = floor). The building half is a single
/// dropdown over the 48 campus-map buildings; the room half is a filtered
/// 4-digit input with suggestions from [classroomEntriesProvider] (placeholder
/// data derived from the floor guide until the real room list arrives).
/// Searching deep-links to `/map?focus=<building>&floor=<2 digits>` — pin
/// focused, peek sheet expanded at that floor.
class ClassroomSearchScreen extends ConsumerStatefulWidget {
  const ClassroomSearchScreen({super.key});

  @override
  ConsumerState<ClassroomSearchScreen> createState() =>
      _ClassroomSearchScreenState();
}

class _ClassroomSearchScreenState extends ConsumerState<ClassroomSearchScreen> {
  Facility? _building;
  final _roomCtrl = TextEditingController();

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  bool get _canSearch => _building != null && _roomCtrl.text.length == 4;

  void _search() {
    final b = _building;
    if (b == null || !_canSearch) return;
    final floor = _roomCtrl.text.substring(0, 2);
    context.go('/map?focus=${b.id}&floor=$floor');
  }

  /// Campus-map buildings sorted 승학(S) → 구덕(G) → 부민(B), then by code.
  List<Facility> _buildings(List<Facility> all) {
    final list = [
      for (final f in all)
        if (f.buildingCode != null && f.buildingCode!.isNotEmpty) f
    ];
    const campusOrder = {'S': 0, 'G': 1, 'B': 2};
    list.sort((a, b) {
      final ca = campusOrder[a.buildingCode![0]] ?? 9;
      final cb = campusOrder[b.buildingCode![0]] ?? 9;
      if (ca != cb) return ca - cb;
      return a.buildingCode!.compareTo(b.buildingCode!);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final facilitiesAsync = ref.watch(allFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.classroom_search_title)),
      body: facilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.common_loadFailed)),
        data: (all) {
          final buildings = _buildings(all);
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
                    child: DropdownMenu<Facility>(
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
                            label:
                                '${f.buildingCode} · ${f.name(locale)}',
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
                    width: 108,
                    child: TextField(
                      controller: _roomCtrl,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _search(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2),
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

/// Room-number suggestions for the selected building, prefix-filtered by the
/// current input. Backed by placeholder data (floor guide derivation) until
/// the real room list arrives.
class _SuggestionList extends ConsumerWidget {
  const _SuggestionList({
    required this.building,
    required this.query,
    required this.onPick,
  });

  final Facility building;
  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(classroomEntriesProvider(building.id));

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
        // (e.g. "101" also surfaces 0101).
        final matches = [
          for (final e in entries)
            if (e.code.contains(query)) e
        ];
        if (matches.isEmpty) {
          return _InfoNote(text: l.classroom_suggestions_empty);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in matches)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  onTap: () => onPick(e.code),
                  leading: Container(
                    constraints: const BoxConstraints(minWidth: 44),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                  subtitle: Text(e.roomName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing:
                      Icon(Symbols.north_west, size: 18, color: scheme.outline),
                ),
              ),
          ],
        );
      },
    );
  }
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
