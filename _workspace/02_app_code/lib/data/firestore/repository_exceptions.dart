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

/// A single Firestore document exists but cannot be mapped onto its entity
/// (audit L-23): a required field is missing or has the wrong type. Distinct
/// from [DataRepositoryException]'s "nothing readable" and from
/// `OfflineDataUnavailable` so a detail screen can tell "this one record is
/// broken" apart from "the network is down". Subclasses
/// [DataRepositoryException] so existing catch sites keep working.
class MalformedDocumentException extends DataRepositoryException {
  const MalformedDocumentException(this.collection, this.docId, Object cause)
      : super('malformed document', cause);

  final String collection;
  final String docId;

  String get path => '$collection/$docId';

  @override
  String toString() => 'MalformedDocumentException: $path ($cause)';
}

/// One skipped or rejected document, as recorded by [FirestoreReadLog].
class MalformedDocumentRecord {
  MalformedDocumentRecord({
    required this.collection,
    required this.docId,
    required this.error,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final String collection;
  final String docId;
  final Object error;
  final DateTime at;

  String get path => '$collection/$docId';

  @override
  String toString() => '$path: $error';
}

/// In-memory, bounded record of documents the mappers could not parse — the
/// structured replacement for the former `debugPrint` (audit L-23/L-27). It
/// is what QA / a future diagnostics screen reads to answer "which admin
/// write is broken", independent of log capture or build mode.
class FirestoreReadLog {
  const FirestoreReadLog._();

  /// Keep the most recent entries only; a corrupt collection must not grow
  /// memory without bound.
  static const int capacity = 100;

  static final List<MalformedDocumentRecord> _records = [];

  static List<MalformedDocumentRecord> get records =>
      List.unmodifiable(_records);

  static MalformedDocumentRecord record(
      String collection, String docId, Object error) {
    final entry = MalformedDocumentRecord(
        collection: collection, docId: docId, error: error);
    _records.add(entry);
    if (_records.length > capacity) _records.removeAt(0);
    return entry;
  }

  static void clear() => _records.clear();
}
