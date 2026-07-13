import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';
import 'repository_providers.dart';

enum SearchSegment { all, facility, guide }

class SearchResults {
  const SearchResults({this.facilities = const [], this.guides = const []});
  final List<Facility> facilities;
  final List<AdminGuideItem> guides;
  bool get isEmpty => facilities.isEmpty && guides.isEmpty;
}

/// Debounced query text (the S8 screen updates this via a 300ms Timer).
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchSegmentProvider =
    StateProvider<SearchSegment>((ref) => SearchSegment.all);

/// Unified facility + guide search (S8). Returns empty for a blank query so the
/// screen shows the "recent searches" empty state instead.
final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final segment = ref.watch(searchSegmentProvider);
  if (query.isEmpty) return const SearchResults();

  final facilityRepo = ref.watch(facilityRepositoryProvider);
  final guideRepo = ref.watch(guideRepositoryProvider);

  final wantFacility = segment != SearchSegment.guide;
  final wantGuide = segment != SearchSegment.facility;

  final facilities =
      wantFacility ? await facilityRepo.search(query) : <Facility>[];
  final guides = wantGuide ? await guideRepo.search(query) : <AdminGuideItem>[];

  return SearchResults(facilities: facilities, guides: guides);
});

/// Recent searches (local, most-recent-first, max 8).
class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _key = 'recent_searches_v1';
  static const _max = 8;

  @override
  List<String> build() {
    return ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
  }

  Future<void> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final list = [t, ...state.where((e) => e != t)].take(_max).toList();
    state = list;
    await ref.read(sharedPreferencesProvider).setStringList(_key, list);
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
        RecentSearchesNotifier.new);
