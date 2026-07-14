import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/facility_providers.dart';
import '../providers/locale_provider.dart';
import '../shared/category_labels.dart';

/// S1 — Home hub. Language toggle, search entry, map banner, facility category
/// quick-chips (→ filtered S3), admin guide grid (→ S6 stub in week 3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = context.dimens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus-On'),
        actions: [
          _LangToggle(),
          SizedBox(width: d.spaceSm),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(d.spaceMd),
        children: [
          _SearchEntry(hint: l.home_searchBar_hint),
          SizedBox(height: d.spaceMd),
          _MapBanner(),
          SizedBox(height: d.spaceLg),
          Text(l.home_section_facilityCategory,
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: d.spaceSm),
          _FacilityCategoryWrap(),
          SizedBox(height: d.spaceLg),
          Text(l.home_section_guide,
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: d.spaceSm),
          _GuideGrid(),
        ],
      ),
    );
  }
}

class _LangToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return TextButton(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      child: Text(
        locale.languageCode == 'ko' ? 'KO | en' : 'ko | EN',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: context.dimens.brMd,
      onTap: () => context.push('/search'),
      child: Container(
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: context.dimens.spaceMd),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: context.dimens.brMd,
        ),
        child: Row(
          children: [
            Icon(Symbols.search, color: scheme.onSurfaceVariant),
            SizedBox(width: context.dimens.spaceSm),
            Text(hint,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _MapBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: context.dimens.brMd,
        onTap: () => context.go('/map'),
        child: Padding(
          padding: EdgeInsets.all(context.dimens.spaceMd),
          child: Row(
            children: [
              Icon(Symbols.map, size: 40, color: scheme.onPrimaryContainer),
              SizedBox(width: context.dimens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.home_mapBanner_title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: scheme.onPrimaryContainer)),
                    Text(l.home_mapBanner_subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onPrimaryContainer)),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityCategoryWrap extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: context.dimens.spaceSm,
      runSpacing: context.dimens.spaceSm,
      children: [
        for (final cat in FacilityCategory.values)
          ActionChip(
            avatar: Icon(cat.icon,
                size: 18, color: context.catColors.forFacility(cat)),
            label: Text(cat.label(l)),
            onPressed: () {
              ref.read(facilityCategoryFilterProvider.notifier).state = cat;
              context.go('/map/list');
            },
          ),
      ],
    );
  }
}

class _GuideGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: context.dimens.spaceSm,
      crossAxisSpacing: context.dimens.spaceSm,
      childAspectRatio: 1.0,
      children: [
        for (final cat in GuideCategory.values)
          _GuideTile(category: cat, label: cat.label(l)),
      ],
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.category, required this.label});
  final GuideCategory category;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.catColors.forGuide(category);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: context.dimens.brMd,
        // Deep-link into the specific guide category (S6).
        onTap: () => context.go('/guide/category/${category.name}'),
        child: Padding(
          padding: EdgeInsets.all(context.dimens.spaceSm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, color: color, size: 28),
              SizedBox(height: context.dimens.spaceXs),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
