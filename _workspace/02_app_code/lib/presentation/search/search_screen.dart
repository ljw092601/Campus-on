import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/search_provider.dart';
import '../shared/category_labels.dart';
import '../shared/widgets/state_views.dart';

/// S8 — Unified facility + guide search. 300ms debounce, segment filter,
/// recent searches (local) when the query is empty.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _submit(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    if (value.trim().isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).add(value.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(searchQueryProvider);
    final segment = ref.watch(searchSegmentProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.search_appbar_hint,
            border: InputBorder.none,
            suffixIcon: query.isEmpty && _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Symbols.close),
                    tooltip: l.common_clear,
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  ),
          ),
          onChanged: _onChanged,
          onSubmitted: _submit,
        ),
      ),
      body: Column(
        children: [
          _SegmentBar(segment: segment),
          Expanded(
            child: query.trim().isEmpty
                ? _RecentSearches(onPick: (term) {
                    _controller.text = term;
                    _submit(term);
                  })
                : results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ErrorStateView(
                      message: l.search_error_failed,
                      retryLabel: l.common_retry,
                      onRetry: () => ref.invalidate(searchResultsProvider),
                    ),
                    data: (r) => r.isEmpty
                        ? EmptyStateView(
                            icon: Symbols.search_off,
                            title: l.search_empty_noResult(query.trim()),
                            actionLabel: l.common_resetFilter,
                            onAction: () => ref
                                .read(searchSegmentProvider.notifier)
                                .state = SearchSegment.all,
                          )
                        : _Results(results: r),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends ConsumerWidget {
  const _SegmentBar({required this.segment});
  final SearchSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(context.dimens.spaceMd),
      child: SegmentedButton<SearchSegment>(
        segments: [
          ButtonSegment(
              value: SearchSegment.all, label: Text(l.search_segment_all)),
          ButtonSegment(
              value: SearchSegment.facility,
              label: Text(l.search_segment_facility)),
          ButtonSegment(
              value: SearchSegment.guide, label: Text(l.search_segment_guide)),
        ],
        selected: {segment},
        onSelectionChanged: (s) =>
            ref.read(searchSegmentProvider.notifier).state = s.first,
      ),
    );
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final recent = ref.watch(recentSearchesProvider);
    if (recent.isEmpty) {
      return EmptyStateView(
        icon: Symbols.search,
        title: l.search_empty_hint,
      );
    }
    return ListView(
      padding: EdgeInsets.all(context.dimens.spaceMd),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.search_recent_title,
                style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).clear(),
              child: Text(l.common_clear),
            ),
          ],
        ),
        Wrap(
          spacing: context.dimens.spaceSm,
          children: [
            for (final term in recent)
              ActionChip(label: Text(term), onPressed: () => onPick(term)),
          ],
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.results});
  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return ListView(
      children: [
        if (results.facilities.isNotEmpty) ...[
          _SectionHeader(
              label: l.search_section_facility(results.facilities.length)),
          for (final f in results.facilities)
            ListTile(
              leading: Icon(f.category.icon,
                  color: context.catColors.forFacility(f.category)),
              title: Text(f.name(locale)),
              subtitle: Text(f.category.label(l)),
              onTap: () => context.go('/map/facility/${f.id}'),
            ),
        ],
        if (results.guides.isNotEmpty) ...[
          _SectionHeader(
              label: l.search_section_guide(results.guides.length)),
          for (final g in results.guides)
            ListTile(
              leading: Icon(g.categoryId.icon,
                  color: context.catColors.forGuide(g.categoryId)),
              title: Text(g.title(locale)),
              subtitle: g.summary(locale) != null
                  ? Text(g.summary(locale)!)
                  : null,
              // Week 3: → guide detail S7. Stub route for now.
              onTap: () => context.go('/guide'),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.dimens.spaceMd,
          context.dimens.spaceMd, context.dimens.spaceMd, context.dimens.spaceXs),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
    );
  }
}
