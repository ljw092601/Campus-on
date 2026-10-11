import 'dart:async';

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
import '../../core/layout/flexible_text_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../data/i18n/place_text.dart';
import '../shared/map_links.dart';
import '../shared/widgets/state_views.dart';
import '../shared/widgets/ui_kit.dart';
import 'floor_label.dart';

/// Classroom-location search (entered from the home hero tile, full-screen at
/// `/classroom-search`).
///
/// Room codes are `<campus letter + 2-digit building>-<room>`, e.g. S01-0301,
/// S04-0306-1, S04-0101-A (first two room digits = floor) or B02-B101
/// (basement 1). The building half is a single dropdown over the campus-map
/// buildings — a building whose drawings are split by wing (B04 → B04A /
/// B04B) gets one entry per wing; the room half is a free input with
/// verified suggestions from [classroomEntriesProvider]. Searching deep-links to
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

  /// Wing letter ("A" for B04A) when the drawings split the building, else
  /// null.
  String? get wing {
    final p = planCode, b = facility.buildingCode;
    if (p == null || b == null || !p.startsWith(b) || p.length <= b.length) {
      return null;
    }
    return p.substring(b.length);
  }

  /// Dropdown label: "B04A · 종합강의동 A동" — wings stay distinguishable
  /// (L-7d).
  String label(AppLocalizations l, Locale locale) =>
      '$code · ${name(l, locale)}';

  /// Localized building name, with the wing ("종합강의동 A동") when split.
  String name(AppLocalizations l, Locale locale) {
    final name = facility.name(locale);
    final w = wing;
    return w == null ? name : l.classroom_building_wing(name, w);
  }

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
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  bool get _canSearch =>
      !_searching && _building != null && floorLabelOf(_roomCtrl.text) != null;

  Future<void> _search() async {
    final b = _building;
    if (b == null || !_canSearch) return;
    final code = _roomCtrl.text;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final result = await ref.read(roomLookupProvider((b.code, code)).future);
      if (!mounted || _building != b || _roomCtrl.text != code) return;
      final l = AppLocalizations.of(context);
      if (RegExp(r'^\d{3}(-|$)').hasMatch(code) &&
          result.status != RoomLookupStatus.found) {
        setState(() => _error = l.classroom_room_invalid);
        return;
      }
      if (result.status == RoomLookupStatus.missingRoom) {
        setState(() => _error = l.classroom_room_notFound);
        return;
      }
      // "03" for 0301, "B1" for B101 (see MapScreen.focusFloorCode).
      final floor = code.substring(0, 2);
      // mapFocusLink adds `t`, making every search a new request, even an
      // identical repeat.
      unawaited(context.push(mapFocusLink(b.facility.id,
          floor: floor,
          room: code,
          plan: b.planCode,
          path: '/classroom-search/result')));
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).common_loadFailed);
        ref.invalidate(floorPlansProvider);
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
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
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final facilitiesAsync = ref.watch(allFacilitiesProvider);
    final plansAsync = ref.watch(floorPlansProvider);
    if (!plansAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.classroom_search_title,
              style: const TextStyle(fontSize: 24)),
        ),
        body: plansAsync.hasError
            ? ErrorStateView(
                message: l.common_loadFailed,
                retryLabel: l.common_retry,
                onRetry: () => ref.invalidate(floorPlansProvider),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final planIndex = plansAsync.requireValue.keys;
    final maxRoomLength = maxRoomCodeLength(plansAsync.requireValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.classroom_search_title,
            style: const TextStyle(fontSize: 24)),
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _HelpText(text: l.classroom_help),
              const SizedBox(height: 20),
              // A hint sits inside the field on one line, so at large text it
              // is cut ('건물 선택' → '건물 …') with nowhere else to read it.
              // Above the field it can wrap, and the field then needs no hint
              // (감사 05/040 SF-1, same screen).
              if (prefersFlexibleLayout(context))
                SectionCaption(
                    '${l.classroom_hint_building} · ${l.classroom_hint_room}'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _BuildingPicker(
                      choices: buildings,
                      selected: _building,
                      hint: l.classroom_hint_building,
                      showHint: !prefersFlexibleLayout(context),
                      // "B04A · 종합강의동 A동" — wings stay distinguishable
                      // (L-7d).
                      labelOf: (b) => b.label(l, locale),
                      nameOf: (b) => b.name(l, locale),
                      onSelected: (b) => setState(() {
                        _building = b;
                        _error = null;
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('-',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: scheme.outline)),
                  ),
                  SizedBox(
                    width: 118,
                    child: TextField(
                      controller: _roomCtrl,
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _search(),
                      // Plain text keyboard: the numeric pad has no hyphen
                      // on every platform, and codes need "0306-1", "0101-A"
                      // and basement "B101".
                      keyboardType: TextInputType.visiblePassword,
                      inputFormatters: [
                        const _RoomCodeFormatter(),
                        LengthLimitingTextInputFormatter(maxRoomLength),
                      ],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: scheme.onSurface),
                      decoration: InputDecoration(
                        // Same reason as the building field: a hint inside a
                        // narrow, centred number box has one line, and at large
                        // text even 'Phòng' does not fit. The label above it
                        // carries the meaning instead.
                        hintText: prefersFlexibleLayout(context)
                            ? null
                            : l.classroom_hint_room,
                        hintStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            color: scheme.outline),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: scheme.error)),
                ),
              _SearchButton(
                label: l.classroom_action_search,
                onPressed: _canSearch ? _search : null,
              ),
              if (_building != null) ...[
                const SizedBox(height: 20),
                _SuggestionList(
                  building: _building!,
                  query: _roomCtrl.text,
                  onPick: (code) {
                    _roomCtrl.text = code;
                    setState(() => _error = null);
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
/// current input. Only codes verified on a drawing are offered.
class _SuggestionList extends ConsumerWidget {
  const _SuggestionList({
    required this.building,
    required this.query,
    required this.onPick,
  });

  final _BuildingChoice building;
  final String query;
  final ValueChanged<String> onPick;

  /// Suggestions rendered at once; the rest is summarised below the list.
  static const _maxShown = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
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
        // The room's name matches too, in whichever language it was written: a
        // student who knows they want the practice room but not its number had
        // no way in before (감사 05/042 SF-1). Code matches rank first — a
        // number is a precise request — and name matches follow.
        final lower = query.toLowerCase();
        final byCode = [
          for (final e in entries)
            if (e.code.contains(query)) e
        ];
        final byName = query.trim().isEmpty
            ? const <ClassroomEntry>[]
            : [
                for (final e in entries)
                  if (!e.code.contains(query) &&
                      roomSearchForms(e.roomName)
                          .any((n) => n.toLowerCase().contains(lower)))
                    e
              ];
        final matches = [...byCode, ...byName];
        // Long lists (drawings list every room) stay light; the cut is
        // announced instead of silent (L-7c).
        final shown = matches.take(_maxShown).toList();
        final flexible = prefersFlexibleLayout(context);
        if (matches.isEmpty) {
          return _InfoNote(text: l.classroom_suggestions_empty);
        }
        final list = GroupCard(
          padding: EdgeInsets.zero,
          children: [
            for (final e in shown)
              ListTile(
                onTap: () => onPick(e.code),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: ToneBadge(localizedFloorLabel(l, e.floorLabel),
                    tone: Tone.navy, minWidth: 48),
                title: Text(
                  e.code,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
                subtitle: Text(
                  // Generic spaces read in the chosen language; tenant
                  // companies, named offices and lab brands are not in the
                  // table, so they keep the Korean that is on the door.
                  e.onPlan
                      ? l.classroom_suggestion_onPlan
                      : roomText(e.roomName, locale),
                  // At 200 % text one line leaves about five Korean
                  // characters, which is not enough to tell one room from
                  // another (감사 05/040 SF-1).
                  maxLines: flexible ? null : 1,
                  overflow:
                      flexible ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: scheme.outline),
                ),
                trailing: Icon(
                    e.onPlan ? Symbols.location_on : Symbols.north_west,
                    size: 20,
                    color: e.onPlan ? AppColors.red : scheme.outline),
              ),
          ],
        );
        if (matches.length <= shown.length) return list;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InfoNote(
                  text: l.classroom_suggestions_more(
                      matches.length - shown.length)),
            ),
            list,
          ],
        );
      },
    );
  }
}

/// Normalises typed or pasted input with [normalizeRoomCodeInput] instead of
/// silently dropping characters: full-width digits, en dashes and spaces are
/// mapped, a pasted "S04-0306-1" keeps its room half, lower case is accepted
/// (L-7a/b). The caret moves to the end only when the text actually changed.
class _RoomCodeFormatter extends TextInputFormatter {
  const _RoomCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = normalizeRoomCodeInput(newValue.text);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => InfoBanner(text: text);
}

/// Help copy: the first line as plain gray text; on the example line the
/// room codes ("S01 - 0301") are set in bold navy, per the mockup. Lines
/// starting with "※" (the name-search caveat) are pulled
/// out into an [InfoBanner] under the help so they read as warnings.
class _HelpText extends StatelessWidget {
  const _HelpText({required this.text});
  final String text;

  static final _code = RegExp(r'[A-Z]\d{2} - [0-9A-Z-]+');
  static final _note = RegExp(r'^\s*※\s*');

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final help = [
      for (final line in lines)
        if (!_note.hasMatch(line)) line
    ].join('\n');
    final notes = [
      for (final line in lines)
        if (_note.hasMatch(line)) line.replaceFirst(_note, '')
    ];

    final strong =
        TextStyle(fontWeight: FontWeight.w800, color: headingColor(context));
    final spans = <InlineSpan>[];
    help.splitMapJoin(
      _code,
      onMatch: (m) {
        spans.add(TextSpan(text: m[0], style: strong));
        return '';
      },
      onNonMatch: (t) {
        spans.add(TextSpan(text: t));
        return '';
      },
    );
    final body = Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontSize: 14,
        height: 1.75,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    if (notes.isEmpty) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: 12),
        InfoBanner(icon: Symbols.warning, text: notes.join('\n')),
      ],
    );
  }
}

/// Building field + floating list (mockup "강의실 위치 검색"): a white rounded
/// field with a chevron; tapping opens a white rounded card under the whole
/// input row listing "S01   대학본부 및 인문과학대학 (A)" rows, code in blue.
class _BuildingPicker extends StatefulWidget {
  const _BuildingPicker({
    required this.choices,
    required this.selected,
    required this.hint,
    this.showHint = true,
    required this.labelOf,
    required this.nameOf,
    required this.onSelected,
  });

  final List<_BuildingChoice> choices;
  final _BuildingChoice? selected;
  final String hint;

  /// False at large text / narrow screens: the hint moves to a caption
  /// above the row (it would be cut inside the one-line field), and the
  /// field stays empty until a building is picked.
  final bool showHint;
  final String Function(_BuildingChoice) labelOf;

  /// Row text next to the code in the list (name + wing).
  final String Function(_BuildingChoice) nameOf;
  final ValueChanged<_BuildingChoice> onSelected;

  @override
  State<_BuildingPicker> createState() => _BuildingPickerState();
}

class _BuildingPickerState extends State<_BuildingPicker> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _scroll = ScrollController();

  static const _fieldHeight = 56.0;
  static const _rowHeight = 50.0;

  /// The list spans the whole input row (this field + dash + room box).
  static const _roomBoxAndDash = 118.0 + 2 * 10 + 12;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toggle() {
    FocusScope.of(context).unfocus();
    setState(_portal.toggle);
  }

  void _close() => setState(_portal.hide);

  void _pick(_BuildingChoice b) {
    widget.onSelected(b);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final open = _portal.isShowing;
    final sel = widget.selected;
    final flexible = prefersFlexibleLayout(context);

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _menu,
      child: CompositedTransformTarget(
        link: _link,
        child: Semantics(
          button: true,
          expanded: open,
          label: widget.hint,
          value: sel == null ? null : widget.labelOf(sel),
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              // Grows with large text instead of clipping the label.
              constraints: const BoxConstraints(minHeight: _fieldHeight),
              padding: const EdgeInsets.only(left: 18, right: 14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppColors.fieldRadius),
                border: Border.all(
                  color: open ? scheme.primary : scheme.outlineVariant,
                  width: open ? 1.5 : 1,
                ),
                boxShadow: open
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.12),
                          spreadRadius: 4,
                        ),
                      ]
                    : softShadow(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sel == null
                          ? (widget.showHint ? widget.hint : '')
                          : widget.labelOf(sel),
                      maxLines: flexible ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            sel == null ? FontWeight.w500 : FontWeight.w800,
                        color: sel == null ? scheme.outline : scheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Symbols.keyboard_arrow_up
                        : Symbols.keyboard_arrow_down,
                    size: 24,
                    color: open ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext overlayContext) {
    final scheme = Theme.of(context).colorScheme;
    final box = context.findRenderObject() as RenderBox?;
    final media = MediaQuery.of(context);
    final width = (box?.size.width ?? 240) + _roomBoxAndDash;
    final fieldHeight = box?.size.height ?? _fieldHeight;
    final rowHeight = _rowHeight *
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    // Room left between the field and the screen bottom (keyboard aside).
    final top = box?.localToGlobal(Offset.zero).dy ?? 0;
    final below = media.size.height -
        media.viewInsets.bottom -
        media.padding.bottom -
        top -
        fieldHeight -
        24;
    final height = (widget.choices.length * rowHeight)
        .clamp(0.0, below.clamp(160.0, 520.0))
        .toDouble();

    return Stack(
      children: [
        // Tap outside closes the list.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, fieldHeight + 6),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppColors.cardRadius),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B3A7A).withValues(alpha: 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                type: MaterialType.transparency,
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  radius: const Radius.circular(4),
                  child: ListView.separated(
                    controller: _scroll,
                    padding: EdgeInsets.zero,
                    itemCount: widget.choices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _row(widget.choices[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(_BuildingChoice b) {
    final scheme = Theme.of(context).colorScheme;
    final selected = b == widget.selected;
    return InkWell(
      onTap: () => _pick(b),
      child: Container(
        // Min height, not fixed: at 200 % text the translated building name
        // wraps to a second line instead of being cut.
        constraints: const BoxConstraints(minHeight: _rowHeight - 1),
        color: selected ? Tone.blue.bg(context) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                b.code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Tone.blue.fg(context),
                ),
              ),
            ),
            Expanded(
              child: Text(
                widget.nameOf(b),
                maxLines: prefersFlexibleLayout(context) ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width stadium "위치 보기" button: pale gray when disabled, bright
/// blue with a glow once a building and a valid room are entered.
class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Symbols.location_on, size: 22),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
