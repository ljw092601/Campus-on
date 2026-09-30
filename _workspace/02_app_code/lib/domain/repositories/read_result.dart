import 'dart:collection';

/// List-compatible repository result. Filtering must preserve its read status.
/// Plain lists (mock repositories) represent complete, local sample results.
class RepositoryList<T> extends UnmodifiableListView<T> {
  RepositoryList(super.source,
      {this.fromCache = false, this.incomplete = false});
  final bool fromCache;
  final bool incomplete;
}

bool isCachedRead(Object? value) => value is RepositoryList && value.fromCache;
bool isIncompleteRead(Object? value) =>
    value is RepositoryList && value.incomplete;

RepositoryList<T> preserveReadStatus<T>(List<T> source, Iterable<T> items) =>
    RepositoryList(items.toList(),
        fromCache: isCachedRead(source), incomplete: isIncompleteRead(source));

/// No usable cached response can establish whether the requested data exists.
class OfflineDataUnavailable implements Exception {
  const OfflineDataUnavailable();
  @override
  String toString() => 'Unable to reach the server; no usable cached data';
}
