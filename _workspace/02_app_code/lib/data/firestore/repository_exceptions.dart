/// Thrown by the Firestore repositories when data cannot be loaded (and no
/// cached snapshot is available). The presentation layer already renders
/// `AsyncValue.error` → ErrorStateView + retry, so it only needs *an* exception;
/// this typed one keeps logs/QA readable without changing the repository
/// interface (which declares plain `throw`).
class DataRepositoryException implements Exception {
  const DataRepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DataRepositoryException: $message${cause == null ? '' : ' ($cause)'}';
}
