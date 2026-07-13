import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';

/// Single source of truth for Firestore collection names + document→entity
/// mapping. Keeping the mapping here (not in the entities) means the domain
/// layer stays framework-free: entities know only `fromJson` with the UX §8
/// field names; this file bridges Firestore quirks (doc id, Timestamp) onto
/// that JSON shape.
class FirestorePaths {
  const FirestorePaths._();

  /// One document per facility. Document id == [Facility.id].
  static const String facilities = 'facilities';

  /// One document per admin-guide item. Document id == [AdminGuideItem.id].
  static const String guideItems = 'guide_items';
}

/// Normalizes a raw Firestore document map onto the JSON shape the entity
/// `fromJson` expects:
///  - injects `id` from the document id (schema stores id as the doc key),
///  - converts Firestore [Timestamp] `updatedAt` into an ISO-8601 string
///    (the entity parses it with `DateTime.tryParse`).
Map<String, dynamic> _normalize(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = <String, dynamic>{...?doc.data()};
  data['id'] = doc.id;
  final ts = data['updatedAt'];
  if (ts is Timestamp) {
    data['updatedAt'] = ts.toDate().toIso8601String();
  }
  return data;
}

Facility facilityFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
    Facility.fromJson(_normalize(doc));

AdminGuideItem guideFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
    AdminGuideItem.fromJson(_normalize(doc));
