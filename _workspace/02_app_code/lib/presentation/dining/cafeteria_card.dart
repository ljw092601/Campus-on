import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/dining_menu.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../shared/map_links.dart';
import 'dining_labels.dart';

/// Item rows shown before an a-la-carte / snack section folds the rest
/// behind "Show N more" — long café lists (김밥·라면·핫도그…) otherwise push
/// the next cafeteria off the screen.
const int diningFoldThreshold = 6;

/// One cafeteria for one day: name, hours line, then either the status
/// wording (closed / unpublished / unavailable) or the menu sections grouped
/// under slot headers (아침 → 점심 → 저녁 → 종일), and a "view on map" action.
///
/// Every text is wrapped or placed in an [Expanded] so the card holds at
/// 200% text scale on a 360dp phone (L-18).
class CafeteriaCard extends ConsumerWidget {
  const CafeteriaCard({
    super.key,
    required this.menu,
    required this.isToday,
    this.showCampus = false,
  });

  final CafeteriaMenu menu;

  /// Whether the day being shown is the campus "today" — picks the
  /// "today…" wording over the date-neutral one (L-11).
  final bool isToday;

  /// Show the campus badge — useful in the 구덕·부민 tab where cafeterias of
  /// two campuses are listed together.
  final bool showCampus;

  String _campusLabel(AppLocalizations l, Campus c) => switch (c) {
        Campus.seunghak => l.map_campus_seunghak,
        Campus.gudeok => l.map_campus_gudeok,
        Campus.bumin => l.map_campus_bumin,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final scheme = Theme.of(context).colorScheme;
    final dimens = context.dimens;
    final name = menu.name(locale);
    final hours = diningHoursLine(l, locale, menu);
    final status = diningStatusText(l, menu, isToday: isToday);
    final sections = menu.sectionsInOrder;

    return Semantics(
      container: true,
      // Own node for "name, status"; hours, sections and the map button stay
      // separate nodes so a screen reader can step through them and the
      // button keeps its own action instead of being folded into one blob.
      explicitChildNodes: true,
      label: l.dining_a11y_card(name, status ?? l.dining_status_open),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              dimens.spaceMd, 14, dimens.spaceMd, dimens.spaceXs + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showCampus) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _Badge(
                        text: _campusLabel(l, menu.campus),
                        background: scheme.primaryContainer,
                        foreground: scheme.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(width: dimens.spaceSm),
                  ],
                  Expanded(
                    // Name is in the Semantics label above; don't read twice.
                    child: ExcludeSemantics(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              if (hours != null) ...[
                SizedBox(height: dimens.spaceXs + 2),
                Semantics(
                  container: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Symbols.schedule,
                            size: 14, color: scheme.onSurfaceVariant),
                      ),
                      SizedBox(width: dimens.spaceXs),
                      Expanded(
                        child: Text(hours,
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: dimens.spaceSm + 2),
              if (status != null)
                Padding(
                  padding: EdgeInsets.only(bottom: dimens.spaceSm + 2),
                  child: ExcludeSemantics(
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: menu.status == DiningAvailability.unavailable
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant)),
                  ),
                )
              else
                for (var i = 0; i < sections.length; i++) ...[
                  // One header per run of equal slots; sectionsInOrder keeps
                  // slots contiguous so this is one header per slot.
                  if (i == 0 || sections[i - 1].slot != sections[i].slot)
                    _SlotHeader(
                        label: sections[i].slot.label(l), first: i == 0),
                  MenuSectionView(section: sections[i]),
                  SizedBox(height: dimens.spaceSm + 2),
                ],
              if (menu.facilityId != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.go(mapFocusLink(menu.facilityId!)),
                    icon: const Icon(Symbols.pin_drop, size: 18),
                    label: Text(l.facility_action_viewOnMap),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "점심 ───────" divider-style header above a slot's sections.
class _SlotHeader extends StatelessWidget {
  const _SlotHeader({required this.label, required this.first});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
          top: first ? 0 : context.dimens.spaceXs,
          bottom: context.dimens.spaceSm),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: scheme.primary),
            ),
          ),
          SizedBox(width: context.dimens.spaceSm),
          Expanded(
            child:
                Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}

/// One [MenuSection]: kind chip, then either a tray price + items joined
/// with " · " (정식·천원의아침밥) or one priced row per item (일품·양분식).
/// Long item lists fold after [diningFoldThreshold] rows.
class MenuSectionView extends StatefulWidget {
  const MenuSectionView({super.key, required this.section});
  final MenuSection section;

  @override
  State<MenuSectionView> createState() => _MenuSectionViewState();
}

class _MenuSectionViewState extends State<MenuSectionView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dimens = context.dimens;
    final s = widget.section;
    final emphasized = s.kind == MenuKind.thousandWon;

    final chip = _Badge(
      text: s.kind.label(l),
      background: emphasized ? scheme.primary : scheme.secondaryContainer,
      foreground: emphasized ? scheme.onPrimary : scheme.onSecondaryContainer,
    );

    final noteStyle =
        TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant);

    if (s.kind.hasSectionPrice) {
      // Read as one unit: "정식, 7,000원, 제육볶음 · 미역국 …, 셀프바".
      return MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "정식  7,000원" on one line; Wrap so a long kind label at 200%
            // text scale drops the price to the next line instead of clipping.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: dimens.spaceSm,
              runSpacing: dimens.spaceXs,
              children: [
                chip,
                if (s.price != null)
                  Text(
                    // Thousands grouping comes from the ARB placeholder
                    // format (decimalPattern), L-12d.
                    l.dining_price(s.price!),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: emphasized ? scheme.primary : scheme.onSurface),
                  ),
              ],
            ),
            if (s.items.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: dimens.spaceXs + 2),
                child: Text(
                  s.items.map((i) => i.name).join(' · '),
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                ),
              ),
            if (s.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(s.note!, style: noteStyle),
              ),
          ],
        ),
      );
    }

    final total = s.items.length;
    final foldable = total > diningFoldThreshold;
    final shown =
        foldable && !_expanded ? s.items.take(diningFoldThreshold) : s.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip and every "name — price" row are their own nodes so a screen
        // reader steps dish by dish.
        Semantics(container: true, child: chip),
        SizedBox(height: dimens.spaceXs + 2),
        for (final item in shown)
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.name,
                        style: const TextStyle(fontSize: 13.5, height: 1.5)),
                  ),
                  if (item.price != null) ...[
                    SizedBox(width: dimens.spaceSm),
                    Text(
                      l.dining_price(item.price!),
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (foldable)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: dimens.spaceSm)),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded
                  ? l.dining_showLess
                  : l.dining_showMore(total - diningFoldThreshold)),
            ),
          ),
        if (s.note != null)
          Semantics(
            container: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(s.note!, style: noteStyle),
            ),
          ),
      ],
    );
  }
}

/// Small rounded label (campus / menu kind). Plain [Text], so screen readers
/// announce it rather than treating it as decoration.
class _Badge extends StatelessWidget {
  const _Badge(
      {required this.text, required this.background, required this.foreground});
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: context.dimens.brSm,
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}
