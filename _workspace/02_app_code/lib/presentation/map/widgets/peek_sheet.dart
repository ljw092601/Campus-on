import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/facility.dart';
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
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
