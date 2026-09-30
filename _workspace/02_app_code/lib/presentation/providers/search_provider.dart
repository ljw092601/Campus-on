import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';
import '../../domain/repositories/read_result.dart';
import 'repository_providers.dart';

enum SearchSegment { all, facility, guide }

class SearchResults {
  const SearchResults(
      {this.facilities = const [],
      this.guides = const [],
      this.facilityFailed = false,
      this.guideFailed = false});
  final bool facilityFailed;
  final bool guideFailed;
  bool get hasFailures => facilityFailed || guideFailed;
  RepositoryList<Object> get readStatus =>
      RepositoryList<Object>([...facilities, ...guides],
          fromCache: isCachedRead(facilities) || isCachedRead(guides),
          incomplete: hasFailures ||
              isIncompleteRead(facilities) ||
              isIncompleteRead(guides));
  final List<Facility> facilities;
  final List<AdminGuideItem> guides;
  bool get isEmpty => facilities.isEmpty && guides.isEmpty;
}

/// Debounced query text (the S8 screen updates this via a 300ms Timer).
// Search state belongs to the mounted search screen: pushing a result keeps it,
// closing search releases it so the next session starts with recent searches.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchSegmentProvider =
    StateProvider.autoDispose<SearchSegment>((ref) => SearchSegment.all);

/// Unified facility + guide search (S8). Returns empty for a blank query so the
/// screen shows the "recent searches" empty state instead.
final searchResultsProvider =
    FutureProvider.autoDispose<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  final segment = ref.watch(searchSegmentProvider);
  if (query.isEmpty) return const SearchResults();

  final facilityRepo = ref.watch(facilityRepositoryProvider);
  final guideRepo = ref.watch(guideRepositoryProvider);

  final wantFacility = segment != SearchSegment.guide;
  final wantGuide = segment != SearchSegment.facility;

  List<Facility> facilities = const [];
  List<AdminGuideItem> guides = const [];
  Object? facilityError, guideError;
  await Future.wait([
    if (wantFacility)
      (() async {
        try {
          facilities = await facilityRepo.search(query);
        } catch (e) {
          facilityError = e;
        }
      })(),
    if (wantGuide)
      (() async {
        try {
          guides = await guideRepo.search(query);
        } catch (e) {
          guideError = e;
        }
      })(),
  ]);
  if ((!wantFacility || facilityError != null) &&
      (!wantGuide || guideError != null)) {
    throw facilityError ?? guideError!;
  }
  return SearchResults(
      facilities: facilities,
      guides: guides,
      facilityFailed: facilityError != null,
      guideFailed: guideError != null);
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
