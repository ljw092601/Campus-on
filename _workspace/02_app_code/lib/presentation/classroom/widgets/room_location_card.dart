import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/floor_plan_providers.dart';
import '../../providers/locale_provider.dart';
import '../floor_plan_screen.dart';
import '../../shared/widgets/ui_kit.dart';
import 'floor_plan_view.dart';

/// Classroom-search result inside the map peek sheet: the searched room's
/// floor plan with a red dot. Tapping opens [FloorPlanScreen] (zoomable).
/// When the building/floor has no drawing yet it says so, and the floor
/// guide below still opens at the right floor.
class RoomLocationCard extends ConsumerWidget {
  const RoomLocationCard({
    super.key,
    required this.facility,
    required this.roomCode,
    this.planCode,
  });

  final Facility facility;
  final String roomCode;

  /// Floor-plan building code ("B04A") when it differs from
  /// [Facility.buildingCode]; resolved via [planCodesFor] when null.
  final String? planCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final d = context.dimens;
    final planIndex =
        ref.watch(floorPlansProvider).valueOrNull?.keys ?? const <String>[];
    final ownCode = facility.buildingCode ?? '';
    final buildingCode = planCode ??
        switch (planCodesFor(ownCode, planIndex)) {
          [final only] => only,
          _ => ownCode,
        };
    final fullCode = '$buildingCode-$roomCode';
    final async = ref.watch(roomLocationProvider((buildingCode, roomCode)));

    final header = Row(
      children: [
        const Icon(Symbols.location_on, color: Color(0xFFE53935), fill: 1),
        SizedBox(width: d.spaceXs),
        // Expanded + ellipsis: at 320dp / 200 % text the code shrinks
        // instead of overflowing the row; the floor tag ("3F") stays whole.
        Expanded(
          child: Text(fullCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: headingColor(context))),
        ),
        if (async.valueOrNull != null)
          ToneBadge(async.valueOrNull!.plan.floorLabel, tone: Tone.navy),
      ],
    );

    return async.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (loc) {
        if (loc == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              SizedBox(height: d.spaceXs),
              Text(l.classroom_plan_unavailable,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            SizedBox(height: d.spaceSm),
            Semantics(
              button: true,
              label: l.classroom_plan_open(fullCode),
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: InkWell(
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => FloorPlanScreen(
                        location: loc,
                        title: '$fullCode · ${facility.name(locale)}',
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      FloorPlanView(
                          plan: loc.plan, room: loc.room, decodeWidth: 1200),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B3A7A)
                                    .withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Symbols.zoom_in,
                              size: 18, color: AppColors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
