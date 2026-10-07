import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/read_result.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

bool _canUseCache(Object error) =>
    error is TimeoutException ||
    (error is FirebaseException &&
        const {
          'unavailable',
          'deadline-exceeded',
          'network-request-failed',
        }.contains(error.code));

/// A successful server-empty response is authoritative; an empty cache is not.
/// Permission/configuration errors must not be disguised as offline results.
Future<RepositoryList<T>> readWithCache<T>({
  required Future<RepositoryList<T>> Function() server,
  required Future<RepositoryList<T>> Function() cache,
  Duration timeout = const Duration(seconds: 8),
}) async {
  try {
    final result = await server().timeout(timeout);
    if (result.fromCache && result.isEmpty) {
      throw const OfflineDataUnavailable();
    }
    return result;
  } catch (error) {
    if (!_canUseCache(error)) rethrow;
    try {
      final result = await cache().timeout(const Duration(seconds: 2));
      if (result.isNotEmpty) {
        return RepositoryList(result,
            fromCache: true, incomplete: result.incomplete);
      }
    } catch (_) {
      // An unusable cache cannot establish that data is absent.
    }
    throw const OfflineDataUnavailable();
  }
}

/// Runs a collection query with a hard `limit` (audit M-26).
///
/// [limit] is required: `firestore.rules` only allows `list` when
/// `request.query.limit <= N`, so an un-limited query is rejected server-side.
/// Pass the collection's constant from [FirestoreListLimits]. A page that
/// fills the limit may have dropped rows, so it is returned `incomplete` and
/// the UI shows the existing partial-data banner rather than a silently
/// truncated list.
Future<RepositoryList<QueryDocumentSnapshot<Map<String, dynamic>>>> readQuery(
  Query<Map<String, dynamic>> query, {
  required int limit,
}) {
  assert(limit > 0, 'readQuery limit must be positive');
  final limited = query.limit(limit);
  return readWithCache(
    server: () async {
      final snap = await limited.get(const GetOptions(source: Source.server));
      return RepositoryList(snap.docs,
          fromCache: snap.metadata.isFromCache,
          incomplete: snap.docs.length >= limit);
    },
    cache: () async {
      final snap = await limited.get(const GetOptions(source: Source.cache));
      return RepositoryList(snap.docs,
          fromCache: true, incomplete: snap.docs.length >= limit);
    },
  );
}

/// Maps a page of documents, dropping the ones that fail to parse. Every drop
/// is recorded in [FirestoreReadLog] under [collection] so a broken admin
/// write can be traced; the result is marked `incomplete` so the UI shows the
/// partial-data banner.
RepositoryList<T> mapReadDocuments<T>(
    RepositoryList<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    T Function(DocumentSnapshot<Map<String, dynamic>>) mapper,
    {String collection = ''}) {
  final values = <T>[];
  for (final doc in docs) {
    try {
      values.add(mapper(doc));
    } catch (e) {
      // Report partial data below.
      FirestoreReadLog.record(collection, doc.id, e);
    }
  }
  if (docs.isNotEmpty && values.isEmpty) {
    throw const DataRepositoryException('No readable documents');
  }
  return RepositoryList(values,
      fromCache: docs.fromCache,
      incomplete: docs.incomplete || values.length != docs.length);
}

Future<DocumentSnapshot<Map<String, dynamic>>> readDocument(
    DocumentReference<Map<String, dynamic>> ref) async {
  try {
    final doc = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 8));
    if (doc.metadata.isFromCache && !doc.exists) {
      throw const OfflineDataUnavailable();
    }
    return doc;
  } catch (error) {
    if (!_canUseCache(error)) rethrow;
    try {
      final doc = await ref
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 2));
      if (doc.exists) return doc;
    } catch (_) {/* No trustworthy cached document. */}
    throw const OfflineDataUnavailable();
  }
}

/// Maps one fetched document (audit L-23). A document that exists but cannot
/// be parsed is surfaced as a [MalformedDocumentException] naming the
/// `collection/docId` and recorded in [FirestoreReadLog], instead of leaking
/// the raw cast error (`type 'int' is not a subtype…`) up to a generic error
/// screen. Returns `null` when the document does not exist.
T? mapSingleDocument<T>(
  DocumentSnapshot<Map<String, dynamic>> doc,
  String collection,
  T Function(DocumentSnapshot<Map<String, dynamic>>) mapper,
) {
  if (!doc.exists) return null;
  try {
    return mapper(doc);
  } catch (e) {
    FirestoreReadLog.record(collection, doc.id, e);
    throw MalformedDocumentException(collection, doc.id, e);
  }
}
