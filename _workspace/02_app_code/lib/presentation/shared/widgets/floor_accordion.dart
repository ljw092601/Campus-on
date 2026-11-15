import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/floor_plan.dart';
import '../../classroom/floor_label.dart';
import '../../classroom/floor_plan_screen.dart';
import '../../classroom/widgets/floor_plan_view.dart';
import '../../providers/facility_providers.dart';
import '../../providers/floor_plan_providers.dart';
import 'read_status.dart';
import '../../../data/i18n/place_text.dart';
import 'ui_kit.dart';

/// Floor-by-floor accordion for one building (map Peek sheet + S4 detail).
///
/// Self-loading via [buildingFloorsProvider]; renders shrink-wrapped so it can
/// sit inside any parent scrollable. Floors keep source order (deepest basement
/// → rooftop). Room names are Korean-only for now (plan §9).
///
/// Styled as a [GroupCard]: each row is a navy floor pill ("B1F"), the bold
/// room count and a gray chevron. An expanded floor shows its drawing(s)
/// above the room names when the building has floor plans ([buildingCode];
/// one per wing, e.g. B04A/B04B) — tap to open it full screen.
class FloorAccordion extends ConsumerWidget {
  const FloorAccordion(
      {super.key,
      required this.facilityId,
      this.buildingCode,
      this.title,
      this.expandedFloor});

  final String facilityId;

  /// Campus-map building code ("S04", "B04") used to find the drawings.
  final String? buildingCode;

  /// Building name for the full-screen plan's title.
  final String? title;

  /// Floor label (e.g. "3F") whose tile starts expanded — used by the
  /// classroom-search deep link so the target floor is open on arrival.
  final String? expandedFloor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;
    final async = ref.watch(buildingFloorsProvider(facilityId));
    // Drawings are optional extras: while loading or on error the floor guide
    // simply shows without them.
    final planIndex = ref.watch(floorPlansProvider).valueOrNull;
    List<FloorPlan> plansFor(String floor) {
      final code = buildingCode;
      if (code == null || code.isEmpty || planIndex == null) return const [];
      return [
        for (final c in planCodesFor(code, planIndex.keys))
          if (planIndex[c]?[floor] case final p?) p,
      ];
    }

    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: d.spaceMd),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.symmetric(vertical: d.spaceSm),
        child: Row(
          children: [
            Expanded(
              child: Text(readErrorMessage(e, l, l.facility_floors_error),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.error)),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(buildingFloorsProvider(facilityId)),
              child: Text(l.common_retry),
            ),
          ],
        ),
      ),
      data: (building) {
        if (building == null || building.floors.isEmpty) {
          return const SizedBox.shrink();
        }
        return GroupCard(
          children: [
            for (final floor in building.floors)
              ExpansionTile(
                initiallyExpanded: floor.floor == expandedFloor,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: scheme.onSurfaceVariant,
                collapsedIconColor: scheme.onSurfaceVariant,
                // Translated floor labels are words, not 'B2F': in Vietnamese
                // at 200 % text the chip and the room count no longer share a
                // line (53px over, measured). Wrap lets the count drop under
                // the chip instead of being clipped.
                title: Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ToneBadge(
                      // Korean keeps main's "3층 / 지하 1층" wording (L-31);
                      // the other languages use the generated floor table.
                      locale.languageCode == 'ko'
                          ? localizedFloorLabel(l, floor.floor)
                          : floorLabelText(floor.floor, locale),
                      tone: Tone.navy,
                      minWidth: 48,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                    ),
                    Text(
                      l.facility_floors_roomCount(floor.rooms.length),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                children: [
                  for (final plan in plansFor(floor.floor)) ...[
                    _FloorPlanThumb(
                      plan: plan,
                      floorText: locale.languageCode == 'ko'
                          ? localizedFloorLabel(l, floor.floor)
                          : floorLabelText(floor.floor, locale),
                      title: title,
                      showCode: plansFor(floor.floor).length > 1,
                    ),
                    SizedBox(height: d.spaceSm),
                  ],
                  // With a drawing the names fold away behind a toggle: the
                  // drawing carries the numbers, the list the (translated)
                  // names — kept for that and for screen readers.
                  _RoomNames(
                    text: [for (final r in floor.rooms) roomText(r, locale)]
                        .join(' · '),
                    collapsible: plansFor(floor.floor).isNotEmpty,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Room names of one floor. Untranslated names keep their Korean — that is
/// what the door sign says, so it is also what a student compares against.
/// [collapsible] (the floor has a drawing) starts it folded behind a
/// "show room names" toggle.
class _RoomNames extends StatefulWidget {
  const _RoomNames({required this.text, required this.collapsible});

  final String text;
  final bool collapsible;

  @override
  State<_RoomNames> createState() => _RoomNamesState();
}

class _RoomNamesState extends State<_RoomNames> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final names = Align(
      alignment: Alignment.centerLeft,
      child: Text(
        widget.text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
    if (!widget.collapsible) return names;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
            label: Text(_open
                ? l.facility_floors_hideRooms
                : l.facility_floors_showRooms),
          ),
        ),
        if (_open) names,
      ],
    );
  }
}

/// One floor drawing inside an expanded floor: white card (drawings stay on
/// white in dark mode), wing code chip when the floor has several drawings,
/// tap → zoomable full-screen plan.
class _FloorPlanThumb extends StatelessWidget {
  const _FloorPlanThumb({
    required this.plan,
    required this.floorText,
    required this.title,
    required this.showCode,
  });

  final FloorPlan plan;
  final String floorText;
  final String? title;
  final bool showCode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = '${plan.buildingCode} $floorText';
    return Semantics(
      button: true,
      label: l.classroom_plan_open(label),
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => FloorPlanScreen.plan(
                plan: plan,
                title: [label, if (title != null) title].join(' · '),
              ),
            ),
          ),
          child: Stack(
            children: [
              FloorPlanView(plan: plan, decodeWidth: 1200),
              if (showCode)
                Positioned(
                  left: 8,
                  top: 8,
                  child: ToneBadge(plan.buildingCode,
                      tone: Tone.navy, fontSize: 12),
                ),
              const Positioned(
                right: 8,
                bottom: 8,
                child: Icon(Icons.zoom_in, size: 20, color: Color(0xFF1B3A7A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Total room count across all floors of [facilityId] (the "총 87곳" pill),
/// null while loading / without floor data.
int? floorRoomTotal(WidgetRef ref, String facilityId) {
  final building = ref.watch(buildingFloorsProvider(facilityId)).valueOrNull;
  if (building == null || building.floors.isEmpty) return null;
  return building.floors.fold<int>(0, (n, f) => n + f.rooms.length);
}

/// "층별 안내" section header with the neutral total-count pill on the right.
class FloorSectionHeader extends ConsumerWidget {
  const FloorSectionHeader({super.key, required this.facilityId});

  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final total = floorRoomTotal(ref, facilityId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l.facility_floors_title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
            ),
          ),
          if (total != null)
            ToneBadge(l.facility_floors_total(total), fontSize: 13),
        ],
      ),
    );
  }
}
