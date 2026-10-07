import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/academic_event.dart';
import '../../domain/repositories/academic_calendar_repository.dart';
import '../../domain/repositories/read_result.dart';
import 'firestore_paths.dart';
import 'firestore_read.dart';

class FirestoreAcademicCalendarRepository
    implements AcademicCalendarRepository {
  FirestoreAcademicCalendarRepository(this._db);
  final FirebaseFirestore _db;
  @override
  Future<List<AcademicEvent>> getEvents() async {
    final docs = await readQuery(
        _db.collection(FirestorePaths.academicEvents).orderBy('start'),
        limit: FirestoreListLimits.academicEvents);
    final result = mapReadDocuments(docs, academicEventFromDoc,
        collection: FirestorePaths.academicEvents);
    final sorted = result.toList()..sort((a, b) => a.start.compareTo(b.start));
    return preserveReadStatus(result, sorted);
  }
}
