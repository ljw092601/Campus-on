import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/academic_event.dart';
import 'repository_providers.dart';

/// All academic-calendar events, sorted by start date.
final academicEventsProvider = FutureProvider<List<AcademicEvent>>((ref) {
  return ref.watch(academicCalendarRepositoryProvider).getEvents();
});
