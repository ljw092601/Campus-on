import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_guide.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/guide_providers.dart';
import '../shared/category_labels.dart';
import '../shared/widgets/guide_list_item.dart' show GuideCategoryTone;
import '../shared/widgets/ui_kit.dart';

/// S5 — Guide Categories (Guide tab root). The 6 categories are hardcoded (from
/// the enum) so the list always renders; only the per-category count badge is
/// data-driven and is hidden when it fails to load.
///
/// Layout follows the DONG-A-MATE mockup: a pill search field (opens the
/// full-screen search), one grouped card of tinted category rows, and a navy
/// "can't find it?" card that contacts the international office.
class GuideCategoryScreen extends ConsumerWidget {
  const GuideCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final counts = ref.watch(guideCategoryCountsProvider);
    final d = context.dimens;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.guide_appbar_title),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            tooltip: l.search_appbar_hint,
            onPressed: () => context.push('/search'),
          ),
          SizedBox(width: d.spaceXs),
        ],
      ),
      body: ListView(
        padding:
            EdgeInsets.fromLTRB(d.spaceMd, d.spaceSm, d.spaceMd, d.spaceLg),
        children: [
          const _SearchPill(),
          SizedBox(height: d.spaceMd + 4),
          GroupCard(
            children: [
              for (final cat in GuideCategory.values)
                _CategoryRow(category: cat, count: counts.valueOrNull?[cat]),
            ],
          ),
          SizedBox(height: d.spaceMd + 4),
          const _ContactCard(),
        ],
      ),
    );
  }
}

/// Tappable white pill that looks like a search field and opens S8 search.
class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l.search_appbar_hint,
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: softShadow(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.push('/search'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Icon(Symbols.search, size: 22, color: Tone.blue.fg(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.guide_search_hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, this.count});
  final GuideCategory category;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = this.count; // local promotes to non-null inside the guard
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => context.go('/guide/category/${category.name}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              IconTile(icon: category.hubIcon, tone: category.tone, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label(l),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.summary(l),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                // Visual = compact number; screen reader hears "{count}건 / items".
                Semantics(
                  label: l.guide_meta_itemCount(count),
                  excludeSemantics: true,
                  child: ToneBadge('$count', minWidth: 40),
                ),
              ],
              const SizedBox(width: 6),
              Icon(Symbols.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navy "can't find what you need?" card with a yellow contact button. Opens
/// a mail draft to the contact address (same as Settings → Contact), falling
/// back to that settings page when no mail app can handle `mailto:`.
class _ContactCard extends StatelessWidget {
  const _ContactCard();

  Future<void> _contact(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.contactEmail,
      query: 'subject=${Uri.encodeComponent('[Dong-A Mate] Feedback')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      context.go('/settings/contact');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.guide_contactCard_title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.guide_contactCard_body,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => _contact(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.navy,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            child: Text(l.settings_contact),
          ),
        ],
      ),
    );
  }
}
