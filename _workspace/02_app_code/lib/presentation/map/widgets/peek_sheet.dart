import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
import '../../../domain/entities/nearby_place.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../shared/category_labels.dart';

/// Bottom Peek sheet shown when a marker is tapped or via deep link (S2).
/// Shows name · category and a "View detail" CTA → S4.
class PeekSheet extends ConsumerWidget {
  const PeekSheet({
    super.key,
    required this.facility,
    required this.onViewDetail,
  });

  final Facility facility;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final color = context.catColors.forFacility(facility.category);
    final scheme = Theme.of(context).colorScheme;

    return _PeekShell(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(facility.category.icon, color: color),
          ),
          SizedBox(width: context.dimens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name(locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(facility.category.label(l),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onViewDetail,
            child: Text(l.map_peek_viewDetail),
          ),
        ],
      ),
    );
  }
}

/// Same Peek sheet for an off-campus search result (S2 `?nearby=`): the place
/// has no detail screen of its own, so the CTA opens its Kakao Map page.
class PlacePeekSheet extends StatelessWidget {
  const PlacePeekSheet({
    super.key,
    required this.place,
    required this.onOpen,
  });

  final NearbyPlace place;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = context.catColors.forFacility(FacilityCategory.etc);
    final subtitle = [
      place.displayAddress,
      if (place.distanceMeters != null)
        l.facility_meta_distance(place.distanceMeters!),
    ].whereType<String>().join(' · ');

    return _PeekShell(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Symbols.storefront, color: color),
          ),
          SizedBox(width: context.dimens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onOpen,
            child: Text(l.map_peek_openPlace),
          ),
        ],
      ),
    );
  }
}

/// Shared sheet chrome (rounded surface + grab handle) so both peek variants
/// stay pixel-identical.
class _PeekShell extends StatelessWidget {
  const _PeekShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimens.radiusLg)),
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.dimens.spaceMd,
              context.dimens.spaceSm, context.dimens.spaceMd, context.dimens.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: context.dimens.spaceSm),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
