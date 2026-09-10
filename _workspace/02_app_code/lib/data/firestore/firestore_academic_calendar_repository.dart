import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/entities/academic_event.dart';
import '../../domain/repositories/academic_calendar_repository.dart';
import 'firestore_paths.dart';
import 'repository_exceptions.dart';

/// Firestore-backed [AcademicCalendarRepository].
///
/// Documents are written only by the admin sheet sync
/// (tool/admin_sheets/, design doc _workspace/06_admin_data_pipeline.md §7);
/// clients are read-only per firestore.rules. `start` is a `yyyy-MM-dd`
/// string, so `orderBy('start')` sorts chronologically; a client-side sort
/// keeps the contract even for cache reads. A malformed document is skipped
/// (logged) instead of failing the whole list — one admin typo must not blank
/// the screen.
class FirestoreAcademicCalendarRepository
    implements AcademicCalendarRepository {
  FirestoreAcademicCalendarRepository(this._db);

  final FirebaseFirestore _db;

  Query<Map<String, dynamic>> get _query =>
      _db.collection(FirestorePaths.academicEvents).orderBy('start');

  @override
  Future<List<AcademicEvent>> getEvents() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _query.get();
    } on FirebaseException catch (e) {
      try {
        snap = await _query.get(const GetOptions(source: Source.cache));
        if (snap.docs.isEmpty) {
          throw DataRepositoryException('Failed to load academic events', e);
        }
      } on FirebaseException {
        throw DataRepositoryException('Failed to load academic events', e);
      }
    }

    final events = <AcademicEvent>[];
    for (final doc in snap.docs) {
      try {
        events.add(academicEventFromDoc(doc));
      } catch (e) {
        debugPrint('academic_events/${doc.id}: skipped malformed doc ($e)');
      }
    }
    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }
}
